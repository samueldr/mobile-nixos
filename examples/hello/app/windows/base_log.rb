module GUI
  class BaseLogWindow < LVGUI::BaseWindow
    include LVGUI::ButtonPalette
    include LVGUI::Window::WithBackButton
    goes_back_to ->() { MainWindow.instance }

    def initialize(explanation:)
      super()
      @explanation = LVGL::LVLabel.new(@toolbar).tap do |label|
        label.set_long_mode(LVGL::LABEL_LONG::SROLL_CIRC)
        label.set_align(LVGL::LABEL_ALIGN::CENTER)
        label.set_y(@toolbar.get_height + @toolbar.get_style(LVGL::CONT_STYLE::MAIN).body_padding_inner)
        label.set_width(@toolbar.get_width_fit)
        label.set_text(explanation)
      end
      @container.inner_padding = 0
      @container.set_scrl_layout(LVGL::LAYOUT::COL_R)
      @container.refresh
    end

    def set_text(text)
      @container.clean
      text.split("\n").each do |line|
        LVGL::LVLabel.new(@container).tap do |label|
          label.set_long_mode(LVGL::LABEL_LONG::BREAK)
          label.set_align(LVGL::LABEL_ALIGN::LEFT)
          label.set_width(@container.get_width_fit)
          label.set_text(line)
        end
      end
    end
  end
end
