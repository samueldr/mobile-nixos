# Empty invisible widget
class LVGUI::Screen < LVGUI::Widget
  def initialize()
    super(LVGL::LVContainer.new())
    set_layout(LVGL::LAYOUT::COL_M)

    style = get_style(LVGL::CONT_STYLE::MAIN).dup
    set_style(LVGL::CONT_STYLE::MAIN, style)
    style.body_padding_top = 0
    style.body_padding_left = 0
    style.body_padding_right = 0
    style.body_padding_bottom = 0
    style.body_padding_inner = 0
  end
end
