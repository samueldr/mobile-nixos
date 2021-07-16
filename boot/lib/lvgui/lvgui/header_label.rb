class LVGUI::HeaderLabel < LVGUI::Widget
  def initialize(parent)
    super(LVGL::LVLabel.new(parent))
    set_align(LVGL::LABEL_ALIGN::LEFT)
    set_long_mode(LVGL::LABEL_LONG::BREAK)

    style = get_style(LVGL::LABEL_STYLE::MAIN).dup()
    set_style(LVGL::LABEL_STYLE::MAIN, style)
    style.text_font = LVGL::Hacks.get_font("fonts/overpass-extrabold.otf", 42)
  end

  def text=(val)
    set_text(val)
  end
end
