# Implements a clock as a wrapped LVLabel.
class LVGUI::Clock < LVGUI::Widget
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
