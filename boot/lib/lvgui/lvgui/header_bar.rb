# Contains the app logo + name
class LVGUI::HeaderBar < LVGUI::Widget
  attr_reader :label

  def initialize(parent)
    super(LVGL::LVContainer.new(parent))

    set_style(LVGL::CONT_STYLE::MAIN, LVGL::LVStyle::STYLE_TRANSP.dup)
    style = get_style(LVGL::CONT_STYLE::MAIN)
    style.body_padding_left   = 0
    style.body_padding_right  = 0
    style.body_padding_top    = 0
    style.body_padding_bottom = 0
    style.body_padding_inner  = 0
    style.body_main_color = LVGUI::Colors::HEADER_BAR
    style.body_grad_color = style.body_main_color
    style.body_opa = LVGL::OPA::COVER

    set_height(LVGUI.pixel_scale(3*32))
    set_fit2(LVGL::FIT::FILL, LVGL::FIT::NONE)
    set_layout(LVGL::LAYOUT::CENTER)

    @label = LVGL::LVLabel.new(self).tap do |label|
      label.set_align(LVGL::LABEL_ALIGN::LEFT)
      label.set_long_mode(LVGL::LABEL_LONG::CROP)
      label.set_width(self.get_width_fit() - 2*LVGUI.col_padding)
      style = label.get_style(LVGL::LABEL_STYLE::MAIN).dup()
      label.set_style(LVGL::LABEL_STYLE::MAIN, style)
      style.text_font = LVGUI::Fonts.secondary()
      label.set_height(LVGUI.point_scale(32))
    end

    @shadow = LVGL::LVObject.new(parent).tap do |el|
      el.set_opa_scale_enable(true)
      el.set_protect(LVGL::PROTECT::POS)
      el.set_x(0)
      el.set_height(LVGUI.pixel_scale(6))
      el.set_width(parent.get_width())

      el.set_style(LVGL::LVStyle::STYLE_TRANSP.dup)
      style = el.get_style()
      style.body_padding_left   = 0
      style.body_padding_right  = 0
      style.body_padding_top    = 0
      style.body_padding_bottom = 0
      style.body_padding_inner  = 0
      style.body_main_color = 0xFF_000000
      style.body_grad_color = 0xFF_304673
      style.body_opa = 100
    end

    refresh_sizes()
  end

  def set_label(txt)
    @label.set_text(txt)
  end

  def refresh_sizes()
    if @shadow
      @shadow.set_y(self.get_y() + self.get_height())
      @shadow.move_foreground()
    end
  end

  def set_height(val)
    super(val)
    refresh_sizes()
  end
end
