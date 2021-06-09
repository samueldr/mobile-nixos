class LVGUI::Button < LVGUI::Widget
  def initialize(parent)
    super(LVGL::LVButton.new(parent))
    set_layout(LVGL::LAYOUT::COL_M)
    set_ink_in_time(200)
    set_ink_wait_time(100)
    set_ink_out_time(500)
    set_fit2(LVGL::FIT::FILL, LVGL::FIT::TIGHT)
    @label = LVGL::LVLabel.new(self)
  end

  def set_label(label)
    @label.set_text(label)
  end
end
