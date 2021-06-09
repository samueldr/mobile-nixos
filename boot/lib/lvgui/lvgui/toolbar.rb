# A container, with a new name
class LVGUI::Toolbar < LVGUI::Widget
  def initialize(parent)
    super(LVGL::LVContainer.new(parent))
    set_height(0)
    set_fit2(LVGL::FIT::FILL, LVGL::FIT::TIGHT)

    set_style(LVGL::CONT_STYLE::MAIN, LVGL::LVStyle::STYLE_TRANSP.dup)
    style = get_style(LVGL::CONT_STYLE::MAIN)
    style.body_padding_top = 0
    style.body_padding_bottom = 0
  end
end
