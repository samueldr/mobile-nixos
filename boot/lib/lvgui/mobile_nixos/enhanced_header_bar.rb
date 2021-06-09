class MobileNixOS::EnhancedHeaderBar < LVGUI::HeaderBar
  def initialize(parent)
    super(parent)

    logo_path = LVGL::Hacks.get_asset_path("logo.svg")
    if File.exist?(logo_path)
      set_fit2(LVGL::FIT::NONE, LVGL::FIT::NONE)
      set_layout(LVGL::LAYOUT::OFF)
      set_height(LVGUI.pixel_scale(128))
      set_width(LVGUI.pixel_scale(720))

      @logo = LVGL::LVImage.new(self).tap do |el|
        el.set_height(LVGUI.pixel_scale(82))
        el.set_width(LVGUI.pixel_scale(375))
        el.set_x(LVGUI.pixel_scale(19))
        el.set_y(LVGUI.pixel_scale(25))
        el.set_src("#{logo_path}?width=#{el.get_width()}")
      end

      @label.set_width(LVGUI.pixel_scale(720) - @logo.get_width_fit() - LVGUI.col_padding*2)
      @label.set_align(LVGL::LABEL_ALIGN::CENTER)
      @label.set_y(LVGUI.pixel_scale(62))
      @label.set_x([
        @logo.get_x(),
        @logo.get_width(),
        LVGUI.col_padding,
      ].inject(&:+))
    end
  end
end
