# Helpers for window types

module LVGUI
  # Helper methods to help creating a "button palette" kind of window.
  module ButtonPalette
    def add_button(label, style: nil)
      Button.new(@container).tap do |btn|
        add_to_focus_group(btn)
        btn.glue_obj(true)
        btn.set_label(label)
        btn.event_handler = ->(event) do
          case event
          when LVGL::EVENT::CLICKED
            yield
          end
        end
        if style
          Button::StyleMods.send(style, btn)
        end
      end
    end

    def add_buttons(list)
      list.each do |pair|
        label, action = pair
        add_button(label, &action)
      end
    end
  end

  module BaseUIElements
    def add_main_text(text, alignment: LVGL::LABEL_ALIGN::CENTER)
      LVGL::LVLabel.new(@container).tap do |label|
        label.set_long_mode(LVGL::LABEL_LONG::BREAK)
        label.set_text(text)
        label.set_align(alignment)
        label.set_width(@container.get_width_fit)
      end
    end

    def add_switch(label, description: nil, initial: false)
      LVGUI::SwitchLine.new(@container).tap do |switch|
        add_to_focus_group(switch.switch_control)
        if initial
          switch.on
        else
          switch.off
        end
        switch.set_label(label)
        switch.set_description(description)
        switch.event_handler = ->(event) do
          case event
          when LVGL::EVENT::VALUE_CHANGED
            yield(switch.get_state())
          end
        end
      end
    end

    def add_select(label, options, initial: nil)
      LVGUI::OptionSelection.new(@container, @screen).tap do |select|
        select.set_label(label)
        select.set_options(options)
        select.select(initial)
        add_to_focus_group(select)

        select.event_handler = ->(event) do
          case event
          when LVGL::EVENT::VALUE_CHANGED
            yield(select.selected())
          end
        end
      end
    end
  end

  module Window
    # Include with +include LVGUI::Window::WithBackButton+ and
    # use e.g. +goes_back_to ->() { MainWindow.instance }+
    module WithBackButton
      def self.included(base)
        base.extend ClassMethods
      end

      # Class methods included by WithBackButton
      module ClassMethods
        # A lambda (or proc)'s return value will determine which instance
        # of an object the button will link to.
        #
        # This is done through a proc/lambda because otherwise it ends up
        # depending on the singleton instance of windows directly.
        def goes_back_to(prc)
          class_variable_get(:@@_after_initialize_callback) << proc do
            btn = LVGUI::BackButton.new(@toolbar, prc.call())
            add_to_focus_group(btn)
            @container.refresh
          end
        end
      end
    end
  end
end
