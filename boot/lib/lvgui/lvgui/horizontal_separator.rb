# Horizontal separator between elements
class LVGUI::HorizontalSeparator < LVGUI::Widget
  def initialize(parent)
    super(LVGL::LVObject.new(parent))
    set_width(parent.get_width_fit())
    set_height(1)

    LVGL::LVStyle::STYLE_PLAIN.dup().tap do |style|
      style.body_main_color = 0x99BBBBBB
      style.body_grad_color = style.body_main_color
      style.body_border_width = 0
      set_style(style)
    end
  end
end
