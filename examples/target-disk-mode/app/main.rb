class LVGUI::BaseWindow
  attr_reader :header_bar

  def on_initialization_finished()
    @header_bar.refresh_sizes()
  end

  def on_header_init()
    @header_bar = MobileNixOS::EnhancedHeaderBar.new(@screen)
    @header_bar.set_label("Target Disk Mode")
  end
end

GUI::MainWindow.instance.present

LVGUI.main_loop
