# Common pattern for a "back button".
# Handles its presentation, and handles its behaviour.
class LVGUI::BackButton < LVGUI::Button
  # +parent+: Parent object
  # +location+: An instance on which `present` can be called.
  def initialize(parent, location)
    @holder = LVGL::LVContainer.new(parent)
    @holder.set_fit2(LVGL::FIT::FILL, LVGL::FIT::TIGHT)
    @holder.set_style(LVGL::CONT_STYLE::MAIN, LVGL::LVStyle::STYLE_TRANSP.dup)
    style = @holder.get_style(LVGL::CONT_STYLE::MAIN)
    style.body_padding_top = LVGUI.pixel_scale(32)
    style.body_padding_left = 0
    style.body_padding_right = 0
    style.body_padding_bottom = style.body_padding_top

    super(@holder)

    @location = location
    # heh, using spaces to add mandatory padding
    set_label("    #{LVGL::Symbols::LEFT}  Back    ")
    set_fit2(LVGL::FIT::TIGHT, LVGL::FIT::TIGHT)
    set_x(0)

    self.event_handler = ->(event) do
      case event
      when LVGL::EVENT::CLICKED
        location.present()
      end
    end
  end
end

