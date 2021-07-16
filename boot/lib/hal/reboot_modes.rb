module Hal
  module RebootModes
    extend self

    Android = {
      "recovery"   => ["Reboot to recovery", ->() { run("reboot recovery") }],
      "bootloader" => ["Reboot to bootloader", ->() { run("reboot bootloader") }],
    }

    def reboot_modes()
      if Configuration["HAL"] && 
         Configuration["HAL"]["boot"] && 
         Configuration["HAL"]["boot"]["rebootModes"]
         Configuration["HAL"]["boot"]["rebootModes"]
      else
        []
      end
    end

    def options()
      [
        ["Reboot to system", ->() { run("reboot") }],
      ] + 
        reboot_modes.map do |identifier|
          const, key = identifier.split(".", 2)
          const_get(const)[key]
        end
    end
  end
end
