# Widget that is obviously a placeholder
class LVGUI::Placeholder < LVGUI::Widget
  def initialize(parent)
    super(LVGL::LVContainer.new(parent))
    set_style(LVGL::CONT_STYLE::MAIN, LVGL::LVStyle::STYLE_TRANSP.dup)
    style = get_style(LVGL::CONT_STYLE::MAIN)
    style.body_border_width   = 0
    style.body_padding_top    = 0
    style.body_padding_bottom = 0
    style.body_padding_left   = 0
    style.body_padding_right  = 0
    style.body_main_color = 0xFF_FF00FF
    style.body_grad_color = style.body_main_color
    style.body_opa = LVGL::OPA::COVER
  end
end
