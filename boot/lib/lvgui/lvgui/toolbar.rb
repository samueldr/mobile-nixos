# A container, with a new name
class LVGUI::Toolbar < LVGUI::Widget
  def initialize(parent)
    super(LVGL::LVContainer.new(parent))

    # Defaults "hidden"
    set_height(0)

    # And mostly transparent
    set_style(LVGL::CONT_STYLE::MAIN, LVGL::LVStyle::STYLE_TRANSP.dup)
    style = get_style(LVGL::CONT_STYLE::MAIN)
    style.body_border_width = 0
    style.body_padding_top = LVGUI.row_padding() - LVGUI.pixel_scale(10)
    style.body_padding_bottom = 0
    style.body_padding_left = LVGUI.col_padding()
    style.body_padding_right = LVGUI.col_padding()

    # Fills the width, fits content
    set_fit2(LVGL::FIT::FLOOD, LVGL::FIT::TIGHT)

    # Layout...
    set_layout(LVGL::LAYOUT::PRETTY)
  end
end
