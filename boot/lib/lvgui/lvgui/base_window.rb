module LVGUI
  # Extend this to make a "window"
  class BaseWindow
    include ::Singleton

    def self.inherited(superclass)
      superclass.class_eval do
        unless self.class_variable_defined?(:@@_after_initialize_callback)
          self.class_variable_set(:@@_after_initialize_callback, [])
        end
      end
    end

    def initialize()
      super()
      # Initializes LVGUI things if required...
      LVGUI.init

      # Preps a basic display
      @screen = Screen.new()
      @status_bar = StatusBar.new(@screen)
      on_header_init()
      @toolbar = Toolbar.new(@screen)
      @container = Page.new(@screen)

      @focus_group = []
      # Dummy object used as a "null" focus
      LVGUI::Dummy.new(@screen).tap do |obj|
        add_to_focus_group(obj)
      end
      reset_focus_group

      self.class.class_variable_get(:@@_after_initialize_callback).each do |cb|
        instance_eval &cb
      end

      on_initialization_finished()
    end

    # Adds an object to the focus group list, and add it to the
    # current focus group.
    def add_to_focus_group(obj)
        @focus_group << obj
        LVGUI.focus_group.add_obj(obj)
    end

    # Re-build the focus group from the elements on the window.
    def reset_focus_group()
      # Clear the focus group
      LVGUI.focus_group.remove_all_objs()

      LVGUI.focus_group.focus_handler = ->() do
        @container.focus(
          LVGUI.focus_group.get_focused,
          LVGL::ANIM::OFF
        )
      end

      @focus_group.each do |el|
        LVGUI.focus_group.add_obj(el)
      end
    end

    # Switch to this window
    def present()
      LVGL::FFI.lv_disp_load_scr(@screen.lv_obj_pointer)
      reset_focus_group

      # Allow the window to do some work every time it is switched to.
      on_present
    end

    # Hooking point for custom behaviour on present
    def on_present()
    end

    # Hooking point to customize header building
    def on_header_init()
    end

    # Hooking point to customize initialization
    def on_initialization_finished()
    end
  end
end
