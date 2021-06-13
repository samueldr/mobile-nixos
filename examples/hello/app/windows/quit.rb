module GUI
  class QuitWindow < LVGUI::BaseWindow
    include LVGUI::ButtonPalette
    include LVGUI::Window::WithBackButton
    goes_back_to ->() { MainWindow.instance }

    def run(*cmd)
      $stderr.puts " $ " + cmd.join(" ")
      system(*cmd) unless LVGL::Introspection.simulator?
    end

    def initialize()
      super()

      add_button("Reboot", style: :enticing) do
        run("reboot")
      end

      add_button("Power off", style: :danger) do
        run("poweroff")
      end

      if LVGL::Introspection.simulator?
        add_button("Quit", style: :primary) { exit(0) }
      end
    end
  end
end
