module LVGUI
  # Wraps an LVGL widget.
  class Widget
    def initialize(widget)
      @widget = widget
    end
    def method_missing(*args)
      @widget.send(*args)
    end

    # Needed to make respond_to? work.
    def lv_obj_pointer()
      @widget.lv_obj_pointer
    end
  end
end
