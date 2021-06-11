# Widget implementing the topmost status bar
class LVGUI::StatusBar < LVGUI::Widget
  def initialize(parent)
    super(LVGL::LVContainer.new(parent))

    style = get_style(LVGL::CONT_STYLE::MAIN).dup
    set_style(LVGL::CONT_STYLE::MAIN, style)
    style.glass = 1
    style.body_main_color = LVGUI::Colors::STATUS_BAR
    style.body_grad_color = style.body_main_color
    style.body_border_width = 0
    style.body_padding_top = 0
    style.body_padding_bottom = style.body_padding_top 
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
    @clock = LVGUI::Clock.new(self)
    @clock.instance_exec do
      style = get_style(LVGL::LABEL_STYLE::MAIN).dup()
      set_style(LVGL::LABEL_STYLE::MAIN, style)
      style.text_font = LVGUI::Fonts.primary(19)
      set_height(LVGUI.point_scale(19))
    end
    @clock.set_width(child_width)

    # [                             69%]
    @battery = LVGUI::Battery.new(self)
    @battery.set_width(child_width)
    @battery.instance_exec do
      style = get_style(LVGL::LABEL_STYLE::MAIN).dup()
      set_style(LVGL::LABEL_STYLE::MAIN, style)
      style.text_font = LVGUI::Fonts.primary(19)
      set_height(LVGUI.point_scale(19))
    end
  end
end
