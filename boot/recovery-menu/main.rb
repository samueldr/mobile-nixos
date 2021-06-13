# File with boot selection
STAGE = Configuration["stage"]
SELECTIONS = "/run/boot/selection.json"

# Runs and prints a command. Probably.
def run(*cmd)
  $stderr.puts " $ " + cmd.join(" ")
  system(*cmd) unless LVGL::Introspection.simulator?
end

module BootGUI
  class MainWindow < LVGUI::BaseWindow
    include LVGUI::ButtonPalette

    def initialize()
      super()

      # An explanatory label
      LVGL::LVLabel.new(@container).tap do |label|
        label.set_long_mode(LVGL::LABEL_LONG::BREAK)
        label.set_text(%Q{Your device booted in recovery mode.})
        label.set_align(LVGL::LABEL_ALIGN::CENTER)
        label.set_width(@container.get_width_fit)
      end

      # Our buttons palette!
      add_button("Generations  #{LVGL::Symbols::RIGHT}", style: :primary) do
        GenerationsWindow.instance.present
      end
      add_buttons([
        *(Hal::RebootModes.options),
      ])
      add_button("Power off") do
        run("poweroff")
      end
    end

    def on_initialization_finished()
      @header_bar.refresh_sizes()
    end

    def on_header_init()
      @header_bar = MobileNixOS::EnhancedHeaderBar.new(@screen)
      @header_bar.set_label("Recovery")
    end
  end

  # Shows the list of generations to boot into.
  class GenerationsWindow < LVGUI::BaseWindow
    include LVGUI::BaseUIElements
    include LVGUI::ButtonPalette
    include LVGUI::Window::WithBackButton
    goes_back_to ->() { MainWindow.instance }

    def update_switch_label()
      if use_generation_kernel?
        @use_generation_kernel.set_description("Use kexec with the generation kernel")
      else
        @use_generation_kernel.set_description("Continue directly to stage-2")
      end
    end

    def use_generation_kernel?()
      return false unless STAGE == 0
      @use_generation_kernel.get_state()
    end

    def initialize()
      super()

      if STAGE == 0
        # Add a toggle switch
        @use_generation_kernel = add_switch(
          "Boot using generation kernel",
          initial: true,
        ) do |new_state|
          update_switch_label()
        end

        update_switch_label()
      end

      if File.exist?(::SELECTIONS)
        # Assume the first is primary
        first = true
        JSON.parse(File.read(::SELECTIONS)).each do |selection|
          add_button(selection["name"], style: (if first then :primary else nil end)) do
            File.open("/run/boot/choice", "w") do |file|
              file.write({
                generation: selection["id"],
                use_generation_kernel: use_generation_kernel?,
              }.to_json())
            end

            # Put back the console on the framebuffer
            VTConsole.map_console(1)
            exit 0
          end

          first = false
        end
      else
        LVGL::LVLabel.new(@container).tap do |label|
          text = "No generations could be found.\n\n"

          if LVGL::Introspection.simulator?
            text += "This is normal in the simulator."
          else
            text += "This is anormal, and may be a sign of things being wrong."
          end

          label.set_long_mode(LVGL::LABEL_LONG::BREAK)
          label.set_text(text)
          label.set_align(LVGL::LABEL_ALIGN::CENTER)
          label.set_width(@container.get_width_fit)
        end
      end
    end
  end
end

# We need to start somewhere...
BootGUI::MainWindow.instance.present

# And keep the GUI active.
LVGUI.main_loop
