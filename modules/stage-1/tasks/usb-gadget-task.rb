module System::ConfigFSUSB
  CONFIGFS     = "/sys/kernel/config"
  CONFIGFS_USB = File.join(CONFIGFS, "usb_gadget")

  module Quirks
    def self.gsi_rndis()
      # Activate the IPA stuff... ugh.
      System.write("/dev/ipa", 1)
    end
  end

  # This is a bit underdocumented in the configfs and gadgetfs docs, but this
  # would be used to translate strings in multiple languages.
  # In practice, it never happens and is hardcoded to en-US.
  # https://docs.microsoft.com/en-us/windows/win32/intl/language-identifier-constants-and-strings
  # https://docs.microsoft.com/en-us/windows/win32/msi/localizing-the-error-and-actiontext-tables
  # Yes, the language identifiers are the Microsoft ones. I haven't found a
  # detailed explanation for this, but it's part of the USB spec.
  STRINGS_SUFFIX = "strings/0x409" # en-US ¯\_(ツ)_/¯

  class Gadget
    attr_reader :name
    attr_accessor :features

    # Initializes a USB gadget
    # The name is actually arbitrary, but it is customary to use `gn` where n
    # is an incrementing number.
    def initialize(name)
      @name = name
      FileUtils.mkdir_p(File.join(path_prefix, STRINGS_SUFFIX))
    end

    def path_prefix()
      File.join(CONFIGFS_USB, name)
    end

    def id_vendor=(value)
      set_id("idVendor", value)
    end

    def id_product=(value)
      set_id("idProduct", value)
    end

    def manufacturer=(value)
      set_string("manufacturer", value)
    end

    def product=(value)
      set_string("product", value)
    end

    def serial_number=(value)
      set_string("serialnumber", value)
    end

    def set_id(kind, value)
      value = ["0", value.sub(/^0x/, "")].join("x")
      System.write(File.join(path_prefix, kind), value)
    end

    def set_string(name, value)
      System.write(File.join(path_prefix, STRINGS_SUFFIX, name), value)
    end

    def activate!()
      # TODO: explore more than one "config" in a gadget. (c.1)
      # First, "document" features.
      config_dir = File.join(path_prefix, "configs/c.1")
      FileUtils.mkdir_p(File.join(config_dir, STRINGS_SUFFIX))
      System.write(File.join(config_dir, STRINGS_SUFFIX, "configuration"), features.join(","))

      # Then activate features.
      features.each do |feature|
        log("setting up feature")
        log(feature)
        # We're using a "feature name -> function name" mapping to make a better
        # end-user UX. They don't care *how* rndis is enabled, only that rndis
        # has to be enabled.
        # Though here we need to know *how* to enable e.g. rndis.
        # This is why `function_name` exists, it's the gadgetfs function name
        # for the required "logical" feature.
        function_name = Configuration["boot"]["usb"]["functions"][feature]
        function_dir = File.join(path_prefix, "functions", function_name)
        feature_dir = File.join(config_dir, feature)
        FileUtils.mkdir_p(function_dir)
        File.symlink(function_dir, feature_dir)

        quirk_name = function_name.gsub(/\./, "_").to_sym
        Quirks.send(quirk_name) if Quirks.respond_to?(quirk_name)
      end

      # Then, attach to the USB driver.
      if features.length > 0 then
        # Equivalent to:
        # (cd /sys/class/udc; echo *) > g1/UDC
        # The idea is to give a controller name taken from the filesystem.
        System.write(
          File.join(path_prefix, "UDC"),
          Dir.children("/sys/class/udc").first
        )
      end
    end

  end
end

class System::AndroidUSB
  include Singleton
  attr_accessor :features
  attr_accessor :id_vendor, :id_product

  ANDROID_USB  = "/sys/class/android_usb"

  def path_prefix()
    File.join(ANDROID_USB, "android0")
  end

  def manufacturer=(value)
    set_string("iManufacturer", value)
  end

  def product=(value)
    set_string("iProduct", value)
  end

  def serial_number=(value)
    set_string("iSerial", value)
  end

  def set_id(kind, value)
    value = value.sub(/^0x/, "")
    System.write(File.join(path_prefix, kind), value)
  end

  def set_string(name, value)
    System.write(File.join(path_prefix, name), value)
  end

  def activate!()
    System.write(File.join(path_prefix, "enable"), "0")
    set_id("idVendor", @id_vendor)
    set_id("idProduct", @id_product)
    System.write(File.join(path_prefix, "bDeviceClass"), "0")
    System.write(File.join(path_prefix, "bDeviceSubClass"), "0")
    System.write(File.join(path_prefix, "bDeviceProtocol"), "0")
    System.write(File.join(path_prefix, "functions"), @features.join(","))
    sleep(0.1)
    System.write(File.join(path_prefix, "enable"), "1")
    sleep(0.1)
  end
end

# This task detects which gadget mode to use, and sets it up.
class Tasks::SetupGadgetMode < SingletonTask
  def initialize()
    add_dependency(:Mount, "/sys")
    add_dependency(:Mount, System::ConfigFSUSB::CONFIGFS)
    # If there's a `/vendor` mount point, it's likely that it's highly possible
    # that it's going to be required for firmwares.
    if Configuration["nixos"]["boot"]["specialFileSystems"]["/vendor"]
      add_dependency(:Mount, "/vendor")
    end
    Targets[:SwitchRoot].add_dependency(:Task, self)
  end

  def run()
    mode = Configuration["usb"]["mode"]
    gadget =
      case mode
      when "gadgetfs"
        log("Configuring CONFIGFS USB Gadget.")
        gadget = System::ConfigFSUSB::Gadget.new("g1")
      when "android_usb"
        log("Configuring ANDROID_USB Gadget.")
        gadget = System::AndroidUSB.instance()
      else
        log("No way to configure USB Gadget found.")
        return
      end

    gadget.id_vendor = Configuration["usb"]["idVendor"]
    gadget.id_product = Configuration["usb"]["idProduct"]
    gadget.product = Configuration["device"]["name"]
    # FIXME : could this cause issues?
    gadget.manufacturer = "Mobile NixOS"
    gadget.serial_number = "0123456789"
    gadget.features = Configuration["boot"]["usb"]["features"]
    gadget.activate!
  end
end

# This task is a bit hacky.
# It ensures ffs aliases are being configured before the functionfs mounts.
# This is because otherwise, on some devices, it fails.
class Tasks::SetupFFSAlias < SingletonTask
  ALIASES_PATH = "/sys/class/android_usb/android0/f_ffs/aliases"
  def initialize()
    @with_ffs = false
    add_dependency(:Mount, "/sys")
    mount_task = Tasks::Mount.registry["/dev/usb-ffs/adb"]
    if mount_task
      @with_ffs = true
      mount_task.add_dependency(:Task, self)
    end
  end

  def run()
    if @with_ffs and File.exist?(ALIASES_PATH)
      System.write(ALIASES_PATH, "adb")
    end
  end
end
