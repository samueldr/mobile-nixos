class LVGUI::BaseWindow
  attr_reader :header_bar

  def on_initialization_finished()
    @header_bar.refresh_sizes()
  end

  def on_header_init()
    @header_bar = MobileNixOS::EnhancedHeaderBar.new(@screen)
    @header_bar.set_label("Demo UI")
  end
end

GUI::MainWindow.instance.present

if LVGL::Introspection.simulator?
  LVGUI.main_loop do
    # Torture test
    GC.start()
  end
else
  LVGUI.main_loop
end
