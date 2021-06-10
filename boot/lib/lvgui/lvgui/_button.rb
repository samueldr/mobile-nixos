class LVGUI::Button < LVGUI::Widget
  module StyleMods
    extend self

    def primary(button)
      style = button.get_style(LVGL::BTN_STYLE::REL).dup
      style.body_main_color = LVGUI::Colors::GREEN
      style.body_grad_color = style.body_main_color
      button.set_style(LVGL::BTN_STYLE::REL, style)

      style = button.get_style(LVGL::BTN_STYLE::PR).dup
      style.body_main_color = LVGL::LVColor.mix(LVGUI::Colors::GREEN, LVGUI::Colors::BLACK, 200)
      style.body_grad_color = style.body_main_color
      button.set_style(LVGL::BTN_STYLE::PR, style)
    end

    # Orange styling
    # Not the primary action, but one the user might want to check
    def enticing(button)
      style = button.get_style(LVGL::BTN_STYLE::REL).dup
      style.body_main_color = LVGUI::Colors::ORANGE
      style.body_grad_color = style.body_main_color
      button.set_style(LVGL::BTN_STYLE::REL, style)

      style = button.get_style(LVGL::BTN_STYLE::PR).dup
      style.body_main_color = LVGL::LVColor.mix(LVGUI::Colors::ORANGE, LVGUI::Colors::BLACK, 200)
      style.body_grad_color = style.body_main_color
      button.set_style(LVGL::BTN_STYLE::PR, style)
    end

    # Red styling
    # A normally destructive action.
    # Think twice when using them.
    def danger(button)
      style = button.get_style(LVGL::BTN_STYLE::REL).dup
      style.body_main_color = LVGUI::Colors::RED
      style.body_grad_color = style.body_main_color
      button.set_style(LVGL::BTN_STYLE::REL, style)

      style = button.get_style(LVGL::BTN_STYLE::PR).dup
      style.body_main_color = LVGL::LVColor.mix(LVGUI::Colors::RED, LVGUI::Colors::BLACK, 200)
      style.body_grad_color = style.body_main_color
      button.set_style(LVGL::BTN_STYLE::PR, style)
    end
  end

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
