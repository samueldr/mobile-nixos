module LVGUI
  # Refreshing at 120 times per second *really* helps with the drag operations
  # responsiveness. At 60 it feels a bit sluggish.
  # This likely comes from the naïve implementation that we are not refreshing at
  # 60 times per seconds, but rather, refresh and wait 1/60th of a second. This
  # makes the refresh rate a tad slower.
  # Boosting to 120 doesn't seem to have ill effects. It's simply refreshed more.
  REFRESH_RATE = 120

  def self.pixel_scale(x)
    dpi = LVGL::Hacks.dpi()
    (dpi * x/200).to_i
  end

  def self.col_padding()
    pixel_scale(32)
  end

  def self.row_padding()
    pixel_scale(32)
  end

  def self.horizontal_grid()
    (pixel_scale(20.5*2)/2).to_i
  end

  def self.vertical_grid()
    pixel_scale(32)
  end

  module Colors
    WHITE        = 0xFF_FFFFFF
    BLACK        = 0xFF_000000
    NOT_BLACK    = 0xFF_3A3A3A
    BLUE_DARKER  = 0xFF_27385D
    BLUE_DARK2   = 0xFF_405D99
    BLUE_DARK    = 0xFF_5277C3
    BLUE         = 0xFF_6586C8
    BLUE_LIGHT   = 0xFF_7EBAE4
    BLUE_LIGHTER = 0xFF_F2F8FD
    GREEN        = 0xFF_6AD541
    GRAY_DARK    = 0xFF_6A6A6A
    GRAY_LIGHT   = 0xFF_D8D8D8
    GRAY_LIGHTER = 0xFF_F4F4F4
    YELLOW       = 0xFF_FFFECA
    ORANGE_DARK  = 0xFF_FF8657
    ORANGE       = 0xFF_FFAB0D
    ORANGE_LIGHT = 0xFF_FFF5E1
    RED          = 0xFF_FF0D0D

    STATUS_BAR = 0xFF_1E2C48
    HEADER_BAR = BLUE_DARKER
  end

  # Sets things up; back box for some ugly hacks.
  def self.init()
    return if @initialized
    @initialized = true

    # This is used by the "simulator".
    if Args.get(:resolution)
      pair = Args.get(:resolution).split("x")
      unless pair.length == 2
        $stderr.puts "--resolution <width>x<height>"
        exit 2
      end
      LVGL::Hacks.monitor_width = pair.first.to_i
      LVGL::Hacks.monitor_height = pair.last.to_i
    else
      LVGL::Hacks.monitor_width = 720
      LVGL::Hacks.monitor_height = 1280
    end

    # Get exclusive control of the framebuffer
    # By design we will not restore the console at exit.
    # We are assuming the target does not necessarily have a console attached to
    # the framebuffer, so this program has to be enough by itself.
    VTConsole.map_console(0)

    # XXX : here is the hang
    # Prepare LVGL
    LVGL::Hacks.init()

    # Start the animation core
    LVGL::FFI.lv_anim_core_init()

    # And switch to the desired theme
    LVGL::Hacks.theme_nixos()
  end

  # Runs the app, black boxes LVGL things.
  def self.main_loop()
    # Main loop
    while true
      LVGL::Hacks::LVTask.handle_tasks
      sleep(1.0/REFRESH_RATE)
      yield if block_given?
    end
  end

  def self.focus_group()
    LVGL::LVGroup.from_pointer(
      LVGL::FFI.lvgui_get_focus_group
    )
  end

  def self.focus_ring_disable()
    LVGL::FFI.lvgui_focus_ring_disable()
  end

  module Styles
    def self.debug(color)
      LVGL::LVStyle::STYLE_PLAIN.dup.tap do |style|
        style.body_main_color = color
        style.body_grad_color = color
      end
    end
  end

  # Used mainly to create an intangible object that the focus ring can default
  # on so it doesn't focus anything by default.
  class Dummy < Widget
    def initialize(parent)
      super(LVGL::LVObject.new(parent))
      set_width(0)
      set_height(0)
      set_style(LVGL::LVStyle::STYLE_TRANSP)
    end
  end

  # Common pattern for a "back button".
  # Handles its presentation, and handles its behaviour.
  class BackButton < Button
    # +parent+: Parent object
    # +location+: An instance on which `present` can be called.
    def initialize(parent, location)
      @holder = LVGL::LVContainer.new(parent)
      @holder.set_fit2(LVGL::FIT::FILL, LVGL::FIT::TIGHT)
      @holder.set_style(LVGL::CONT_STYLE::MAIN, LVGL::LVStyle::STYLE_TRANSP.dup)
      style = @holder.get_style(LVGL::CONT_STYLE::MAIN)
      style.body_padding_top = 0
      style.body_padding_left = 0
      style.body_padding_right = 0
      style.body_padding_bottom = 0

      super(@holder)

      @location = location
      set_label("#{LVGL::Symbols::LEFT}  Back")
      set_fit2(LVGL::FIT::NONE, LVGL::FIT::TIGHT)
      set_width(@holder.get_width / 2)
      set_x(0)

      self.event_handler = ->(event) do
        case event
        when LVGL::EVENT::CLICKED
          location.present()
        end
      end
    end
  end

  # Implements a clock as a wrapped LVLabel.
  class Clock < Widget
    def initialize(parent)
      super(LVGL::LVLabel.new(parent))
      set_align(LVGL::LABEL_ALIGN::LEFT)
      set_long_mode(LVGL::LABEL_LONG::CROP)

      # Update the text once
      update_clock

      # Then register a task to update regularly.
      @task = LVGL::Hacks::LVTask.create_task(250, LVGL::TASK_PRIO::MID, ->() do
        update_clock
      end)
    end

    def update_clock()
      now = Time.now
      set_text([
        :hour,
        :min,
        :sec,
      ].map{|fn| now.send(fn).to_s.rjust(2, "0") }.join(":"))
    end
  end

  # Widget implementing the topmost status bar
  class StatusBar < Widget
    def initialize(parent)
      super(LVGL::LVContainer.new(parent))

      style = get_style(LVGL::CONT_STYLE::MAIN).dup
      set_style(LVGL::CONT_STYLE::MAIN, style)
      style.glass = 1
      style.body_main_color = LVGUI::Colors::STATUS_BAR
      style.body_grad_color = style.body_main_color
      style.body_border_width = 0
      style.body_padding_bottom = style.body_padding_top 
      style.body_padding_top = 0
      style.body_radius = 0

      set_fit2(LVGL::FIT::FILL, LVGL::FIT::NONE)
      set_layout(LVGL::LAYOUT::ROW_M)

      set_height(LVGUI.pixel_scale(64))

      # Split 50/50
      child_width = (
        get_width -
        style.body_padding_left -
        style.body_padding_right -
        style.body_padding_inner*2
      ) / 2

      # [00:00                           ]
      @clock = Clock.new(self)
      @clock.set_width(child_width)

      # [                             69%]
      @battery = Battery.new(self)
      @battery.set_width(child_width)
    end
  end
end
