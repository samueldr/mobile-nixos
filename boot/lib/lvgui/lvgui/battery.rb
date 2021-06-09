# Implements a battery widget as a wrapped LVLabel.
class LVGUI::Battery < LVGUI::Widget
  def initialize(parent)
    super(LVGL::LVLabel.new(parent))
    set_align(LVGL::LABEL_ALIGN::RIGHT)
    set_long_mode(LVGL::LABEL_LONG::CROP)

    @battery = LVGUI::HAL::Battery.main_battery

    # Update the text once
    update_text

    # Then register a task to update regularly.
    @task = LVGL::Hacks::LVTask.create_task(1000 * 15, LVGL::TASK_PRIO::LOW, ->() do
      update_text
    end)
  end

  def update_text()
    if @battery
      symbol =
        if @battery.charging? then
          LVGL::Symbols::CHARGE
        elsif @battery.percent == "unknown"
          ""
        elsif @battery.percent > 95
          LVGL::Symbols::BATTERY_FULL
        elsif @battery.percent > 75
          LVGL::Symbols::BATTERY_3
        elsif @battery.percent > 45
          LVGL::Symbols::BATTERY_2
        elsif @battery.percent > 10
          LVGL::Symbols::BATTERY_1
        else
          LVGL::Symbols::BATTERY_EMPTY
        end

      set_text("#{symbol} #{@battery.percent}%")
    else
      set_text("")
    end
  end
end
