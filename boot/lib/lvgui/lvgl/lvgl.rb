module LVGL
  [
    :ANIM,
    :BTN_STYLE,
    :BORDER,
    :CONT_STYLE,
    :CURSOR,
    :EVENT,
    :FIT,
    :KB_MODE,
    :KB_STYLE,
    :LABEL_ALIGN,
    :LABEL_LONG,
    :LABEL_STYLE,
    :LAYOUT,
    :PAGE_STYLE,
    :PROTECT,
    :SHADOW,
    :SW_STYLE,
    :TASK_PRIO,
    :TA_STYLE,
  ].each do |enum_name|
    const_set(enum_name, LVGL::FFI.const_get("LV_#{enum_name}".to_sym))
    LVGL.const_get(enum_name).module_exec do
      def self.from_value(needle)
        self.constants.find do |name|
          needle == self.const_get(name)
        end
      end
    end
  end

  def self.ffi_call!(klass, meth, *args, _initiator_class: nil)
    _initiator_class ||= klass
    unless klass.const_defined?(:LV_TYPE)
      raise "Tried to ffi_call!(..., #{meth}) with a #{_initiator_class.name}, which does not define LV_TYPE"
    end

    ffi_name = "lv_#{klass.const_get(:LV_TYPE)}_#{meth}".to_sym
    if LVGL::FFI.respond_to?(ffi_name)
      args = args.map do |arg|
        case arg
        when  nil
          0
        when false
          0
        when true
          1
        else
          if arg.respond_to? :lv_obj_pointer
            arg.lv_obj_pointer
          else
            arg
          end
        end
      end
      return LVGL::FFI.send(ffi_name, *args)
    else
      if klass.superclass
        return ffi_call!(klass.superclass, meth, *args, _initiator_class: _initiator_class)
      else
        raise "Could not find #{meth} in the class hierarchy."
      end
    end
  end

  def self.layer_top()
    LVObject.from_pointer(LVGL::FFI.lv_layer_top())
  end

  def self.layer_sys()
    LVObject.from_pointer(LVGL::FFI.lv_layer_sys())
  end

  class LVDisplay
    # This is not actually an object type in LVGL proper.

    # Get default display
    def self.get_default()
      LVGL::FFI.lv_disp_get_default()
    end

    # Gets the current active screen.
    def self.get_scr_act()
      LVObject.from_pointer(
        LVGL::FFI.lv_disp_get_scr_act(get_default())
      )
    end
  end

  class LVObject
    LV_TYPE = :obj

    # Hack...
    # I need to figure out how to use Fiddle's #to_value to rehydrate an mruby
    # Object into its proper form.
    REGISTRY = {
      # @self_pointer int value => instance
    }

    def initialize(parent = nil, pointer: nil)
      @__event_handler_proc = nil

      unless pointer
        parent_ptr =
          if parent
            parent.lv_obj_pointer
          else
            nil
          end

        @self_pointer = LVGL.ffi_call!(self.class, :create, parent_ptr, nil)
      else
        @self_pointer = pointer
      end
      register_userdata
      unless parent or pointer
        $stderr.puts("[HACK] Creating #{self.class.name} as screen. (Switching lv_disp_load_scr!)")
        LVGL::FFI.lv_disp_load_scr(@self_pointer)
      end
    end

    def lv_obj_pointer()
      @self_pointer
    end

    def self.from_pointer(pointer)
      if REGISTRY[pointer.to_i]
        REGISTRY[pointer.to_i]
      else
        self.new(pointer: pointer)
      end
    end

    def get_style()
      style = LVGL.ffi_call!(self.class, :get_style, @self_pointer)
      LVGL::LVStyle.from_pointer(style)
    end

    def set_style(style)
      # Prevents the object from being collected
      @style = style
      LVGL.ffi_call!(self.class, :set_style, @self_pointer, style.lv_style_pointer)
    end

    def glue_obj(value)
      value =
        if value
          1
        else
          0
        end
      LVGL::FFI.lv_page_glue_obj(@self_pointer, value)
    end

    def method_missing(meth, *args)
      LVGL.ffi_call!(self.class, meth, @self_pointer, *args)
    end

    def event_handler=(cb_proc)
      # Hook the handler on-the-fly, assuming it wasn't set if we didn't have
      # a handler proc.
      unless @__event_handler_proc
        LVGL.ffi_call!(self.class, :set_event_cb, @self_pointer, LVGL::FFI["handle_lv_event"])
      end
      @__event_handler_proc = cb_proc
    end

    def event_handler()
      @__event_handler_proc
    end

    def register_userdata()
      userdata = Fiddle::Pointer[self]
      REGISTRY[@self_pointer.to_i] = self
      LVGL.ffi_call!(self.class, :set_user_data, @self_pointer, userdata)
    end

    def get_parent()
      ptr = LVGL.ffi_call!(self.class, :get_parent, @self_pointer)
      LVObject.from_pointer(ptr)
    end

    def get_children()
      children = []
      last_child = nil
      loop do
        ptr = LVGL.ffi_call!(self.class, :get_child_back, @self_pointer, last_child)
        break if ptr.null?
        last_child = LVObject.from_pointer(ptr)
        children << last_child
      end
      children
    end
  end

  class LVContainer < LVObject
    LV_TYPE = :cont

    def set_layout(*args)
      LVGL::FFI.lv_cont_set_layout(@self_pointer, *args)
    end

    def get_style(type)
      # type is unused, see lvgl/src/lv_objx/lv_cont.h
      super()
    end

    def set_style(type, style)
      # type is unused, see lvgl/src/lv_objx/lv_cont.h
      super(style)
    end
  end

  class LVLabel < LVObject
    LV_TYPE = :label

    def get_style(type)
      # type is unused, see lvgl/src/lv_objx/lv_label.h
      super()
    end

    def set_style(type, style)
      # type is unused, see lvgl/src/lv_objx/lv_label.h
      super(style)
    end

    def set_text(text)
      text ||= ""
      # The "\0" thing is a bit scary; it seems that *something* related
      # to C string and "\0" in either mruby or LVGL, likely mruby, may
      # cause issues when using something like `split` to split a bigger
      # string.
      #
      # My assumption is that the ruby string is not \0 completed, and
      # given as-is to the C world via ffi.
      LVGL.ffi_call!(self.class, :set_text, @self_pointer, text + "\0")
    end
  end

  class LVImage < LVObject
    LV_TYPE = :img
  end

  class LVPage < LVContainer
    LV_TYPE = :page

    def set_style(type, style)
      # Prevents the object from being collected
      @style = style
      LVGL.ffi_call!(self.class, :set_style, @self_pointer, type, style.lv_style_pointer)
    end

    def get_style(style_type)
      style = LVGL.ffi_call!(self.class, :get_style, @self_pointer, style_type)
      LVGL::LVStyle.from_pointer(style)
    end

    def focus(obj, anim)
      ptr =
        if obj.respond_to?(:lv_obj_pointer)
          obj.lv_obj_pointer
        else
          obj
        end
      LVGL.ffi_call!(self.class, :focus, @self_pointer, ptr, anim)
    end
  end

  class LVButton < LVContainer
    LV_TYPE = :btn

    def get_style(style_type)
      style = LVGL.ffi_call!(self.class, :get_style, @self_pointer, style_type)
      LVGL::LVStyle.from_pointer(style)
    end

    def set_style(style_type, style)
      # Prevents the object from being collected
      @_style ||= {}
      @_style[style_type] = style
      LVGL.ffi_call!(self.class, :set_style, @self_pointer, style_type, style.lv_style_pointer)
    end
  end

  class LVSwitch < LVObject
    LV_TYPE = :sw

    def on(anim = false)
      LVGL.ffi_call!(self.class, :on, @self_pointer, anim)
    end

    def off(anim = false)
      LVGL.ffi_call!(self.class, :off, @self_pointer, anim)
    end

    def toggle(anim = false)
      LVGL.ffi_call!(self.class, :toggle, @self_pointer, anim)
    end

    def get_state()
      LVGL.ffi_call!(self.class, :get_state, @self_pointer) != 0
    end

    def get_style(style_type)
      style = LVGL.ffi_call!(self.class, :get_style, @self_pointer, style_type)
      LVGL::LVStyle.from_pointer(style)
    end

    def set_style(style_type, style)
      # Prevents the object from being collected
      @_style ||= {}
      @_style[style_type] = style
      LVGL.ffi_call!(self.class, :set_style, @self_pointer, style_type, style.lv_style_pointer)
    end
  end

  class LVTextArea < LVObject
    LV_TYPE = :ta

    def add_text(text)
      # The "\0" thing is a bit scary; it seems that *something* related
      # to C string and "\0" in either mruby or LVGL, likely mruby, may
      # cause issues when using something like `split` to split a bigger
      # string.
      #
      # My assumption is that the ruby string is not \0 completed, and
      # given as-is to the C world via ffi.
      LVGL.ffi_call!(self.class, :add_text, @self_pointer, text + "\0")
    end

    def set_text(text)
      # The "\0" thing is a bit scary; it seems that *something* related
      # to C string and "\0" in either mruby or LVGL, likely mruby, may
      # cause issues when using something like `split` to split a bigger
      # string.
      #
      # My assumption is that the ruby string is not \0 completed, and
      # given as-is to the C world via ffi.
      LVGL.ffi_call!(self.class, :set_text, @self_pointer, text + "\0")
    end

    def set_placeholder_text(text)
      # The "\0" thing is a bit scary; it seems that *something* related
      # to C string and "\0" in either mruby or LVGL, likely mruby, may
      # cause issues when using something like `split` to split a bigger
      # string.
      #
      # My assumption is that the ruby string is not \0 completed, and
      # given as-is to the C world via ffi.
      LVGL.ffi_call!(self.class, :set_placeholder_text, @self_pointer, text + "\0")
    end

    def set_accepted_chars(text)
      # The "\0" thing is a bit scary; it seems that *something* related
      # to C string and "\0" in either mruby or LVGL, likely mruby, may
      # cause issues when using something like `split` to split a bigger
      # string.
      #
      # My assumption is that the ruby string is not \0 completed, and
      # given as-is to the C world via ffi.
      LVGL.ffi_call!(self.class, :set_accepted_chars, @self_pointer, text + "\0")
    end

    def get_style(style_type)
      style = LVGL.ffi_call!(self.class, :get_style, @self_pointer, style_type)
      LVGL::LVStyle.from_pointer(style)
    end

    def set_style(style_type, style)
      # Prevents the object from being collected
      @_style ||= {}
      @_style[style_type] = style
      LVGL.ffi_call!(self.class, :set_style, @self_pointer, style_type, style.lv_style_pointer)
    end
  end

  class LVKeyboard < LVObject
    LV_TYPE = :kb

    def get_style(style_type)
      style = LVGL.ffi_call!(self.class, :get_style, @self_pointer, style_type)
      LVGL::LVStyle.from_pointer(style)
    end

    def set_style(style_type, style)
      # Prevents the object from being collected
      @_style ||= {}
      @_style[style_type] = style
      LVGL.ffi_call!(self.class, :set_style, @self_pointer, style_type, style.lv_style_pointer)
    end
  end

  # Wraps an +lv_style_t+ in a class with some light duty housekeeping.
  class LVStyle
    # Given a +Fiddle::Pointer+ pointing to an +lv_style_t+, instantiates
    # an LVStyle class, wrapping the struct.
    def self.from_pointer(pointer)
      instance = LVGL::LVStyle.new()
      instance.instance_exec do
        @self_pointer = pointer
      end

      instance
    end

    # Allocates a new +lv_style_t+, and copies the styles using the LVGL
    # +lv_style_copy+.
    def initialize_copy(orig)
      @self_pointer = LVGL::FFI.lvgui_allocate_lv_style()
      LVGL::FFI.lv_style_copy(@self_pointer, orig.lv_style_pointer)
    end

    def lv_style_pointer()
      @self_pointer
    end

    # Proxy all methods to the struct accessors we are wrapping.
    # It's dumb, but it works so well!
    def method_missing(meth, *args)
      meth =
        if meth.to_s.match(/=$/)
          "lvgui_set_lv_style__#{meth.to_s[0..-2]}".to_sym
        else
          "lvgui_get_lv_style__#{meth}".to_sym
        end

      LVGL::FFI.send(meth, @self_pointer, *args)
    end

    private

    def initialize()
    end

    public

    # Initializes global styles
    [
        "scr",
        "transp",
        "transp_tight",
        "transp_fit",
        "plain",
        "plain_color",
        "pretty",
        "pretty_color",
        "btn_rel",
        "btn_pr",
        "btn_tgl_rel",
        "btn_tgl_pr",
        "btn_ina",
    ].each do |name|
      global_name = "lv_style_#{name}".downcase
      const_name = "style_#{name}".upcase.to_sym
      wrapped = self.from_pointer(
        LVGL::FFI.handler.sym(global_name)
      )
      const_set(const_name, wrapped)
   end
  end

  class LVGroup
    LV_TYPE = :group

    REGISTRY = {
      # @self_pointer int value => instance
    }

    def initialize(pointer: nil)
      @focus_handler_proc_stack = [nil]
      @focus_groups_stack = [[]]
      @last_focused_in_stack = []

      unless pointer
        raise "(FIXME) Creating a focus group is not implemented"
        #@self_pointer = LVGL.ffi_call!(self.class, :create)
      else
        @self_pointer = pointer
      end
      register_userdata
    end

    # Given a +Fiddle::Pointer+ pointing to an +lv_group_t+, instantiates
    # an LVGroup class, wrapping the struct.
    def self.from_pointer(pointer)
      if REGISTRY[pointer.to_i]
        REGISTRY[pointer.to_i]
      else
        self.new(pointer: pointer)
      end
    end

    def initialize_copy(orig)
      raise "Not implemented"
    end

    def lv_group_pointer()
      @self_pointer
    end

    def method_missing(meth, *args)
      LVGL.ffi_call!(self.class, meth, @self_pointer, *args)
    end

    def add_obj(obj)
      @focus_groups_stack.last << obj
      _add_obj(obj)
    end

    def focus_obj(obj)
      # Automatic bindings fail since there is no "self" argument here.
      ptr =
        if obj.respond_to?(:lv_obj_pointer)
          obj.lv_obj_pointer
        else
          obj
        end
      LVGL.ffi_call!(self.class, :focus_obj, ptr)
    end

    def get_focused()
      LVObject.from_pointer(
        LVGL.ffi_call!(self.class, :get_focused, @self_pointer)
      )
    end

    def remove_all_objs()
      # Evict the current array from the stack
      @focus_groups_stack.pop()
      # Don't forget to add a new one!
      @focus_groups_stack.push([])
      LVGL.ffi_call!(self.class, :remove_all_objs, @self_pointer)
    end

    def focus_handler=(cb_proc)
      # Replace the last item from the stack
      @focus_handler_proc_stack.pop()
      @focus_handler_proc_stack << cb_proc
      _set_focus_handler(cb_proc)
    end

    def register_userdata()
      LVGL.ffi_call!(self.class, :remove_all_objs, @self_pointer)
      userdata = Fiddle::Pointer[self]
      REGISTRY[@self_pointer.to_i] = self
      LVGL.ffi_call!(self.class, :set_user_data, @self_pointer, userdata)
    end

    # Keep the previous focus group aside in memory, and empty the focus group.
    # Use +#pop+ to put back the last focus group
    def push()
      @last_focused_in_stack << get_focused()
      @focus_groups_stack << []
      @focus_handler_proc_stack << nil
      _set_focus_handler(@focus_handler_proc_stack.last)
      LVGL.ffi_call!(self.class, :remove_all_objs, @self_pointer)
    end

    # Empties the current focus group, and puts back the previous one from the
    # stack.
    def pop()
      LVGL.ffi_call!(self.class, :remove_all_objs, @self_pointer)
      @focus_groups_stack.pop()
      @focus_groups_stack.last.each do |obj|
        _add_obj(obj)
      end
      focus_obj(@last_focused_in_stack.pop())
      @focus_handler_proc_stack.pop()
      _set_focus_handler(@focus_handler_proc_stack.last)
    end

    private

    def _add_obj(obj)
      ptr =
        if obj.respond_to?(:lv_obj_pointer)
          obj.lv_obj_pointer
        else
          obj
        end
      LVGL.ffi_call!(self.class, :add_obj, @self_pointer, ptr)
    end

    def _set_focus_handler(cb_proc)
      # Hook the handler on-the-fly.
      LVGL.ffi_call!(self.class, :set_focus_cb, @self_pointer, LVGL::FFI["handle_lv_focus"])
    end
  end

  # Wraps an +lv_anim_t+ in a class with some light duty housekeeping.
  class LVAnim
    LV_TYPE = :anim

    # Given a +Fiddle::Pointer+ pointing to an +lv_anim_t+, instantiates
    # an LVAnim class, wrapping the struct.
    def self.from_pointer(pointer)
      instance = LVGL::LVAnim.new()
      instance.instance_exec do
        @self_pointer = pointer
      end

      instance
    end

    def initialize()
      @self_pointer = LVGL::FFI.lvgui_allocate_lv_anim()
      self.init
    end

    def lv_anim_pointer()
      @self_pointer
    end

    def set_exec_cb(obj, cb_name)
      fn = LVGL::FFI[cb_name.to_s]
      raise "No function for #{cb_name} on LVGL::FFI" unless fn
      LVGL.ffi_call!(self.class, "set_exec_cb", @self_pointer, obj.lv_obj_pointer, fn)
    end

    def method_missing(meth, *args)
      LVGL.ffi_call!(self.class, meth, @self_pointer, *args)
    end

    module Path
      # Initializes global animation paths
      [
        "linear",
        "step",
        "ease_in",
        "ease_out",
        "ease_in_out",
        "overshoot",
        "bounce",
      ].each do |name|
        const_set(
          name.upcase.to_sym,
          LVGL::FFI.handler.sym("lv_anim_path_#{name}".downcase)
        )
      end
    end
  end

  module Symbols
    AUDIO          = "\xef\x80\x81" # 61441, 0xF001
    VIDEO          = "\xef\x80\x88" # 61448, 0xF008
    LIST           = "\xef\x80\x8b" # 61451, 0xF00B
    OK             = "\xef\x80\x8c" # 61452, 0xF00C
    CLOSE          = "\xef\x80\x8d" # 61453, 0xF00D
    POWER          = "\xef\x80\x91" # 61457, 0xF011
    SETTINGS       = "\xef\x80\x93" # 61459, 0xF013
    HOME           = "\xef\x80\x95" # 61461, 0xF015
    DOWNLOAD       = "\xef\x80\x99" # 61465, 0xF019
    DRIVE          = "\xef\x80\x9c" # 61468, 0xF01C
    REFRESH        = "\xef\x80\xa1" # 61473, 0xF021
    MUTE           = "\xef\x80\xa6" # 61478, 0xF026
    VOLUME_MID     = "\xef\x80\xa7" # 61479, 0xF027
    VOLUME_MAX     = "\xef\x80\xa8" # 61480, 0xF028
    IMAGE          = "\xef\x80\xbe" # 61502, 0xF03E
    EDIT           = "\xef\x8C\x84" # 62212, 0xF304
    PREV           = "\xef\x81\x88" # 61512, 0xF048
    PLAY           = "\xef\x81\x8b" # 61515, 0xF04B
    PAUSE          = "\xef\x81\x8c" # 61516, 0xF04C
    STOP           = "\xef\x81\x8d" # 61517, 0xF04D
    NEXT           = "\xef\x81\x91" # 61521, 0xF051
    EJECT          = "\xef\x81\x92" # 61522, 0xF052
    LEFT           = "\xef\x81\x93" # 61523, 0xF053
    RIGHT          = "\xef\x81\x94" # 61524, 0xF054
    PLUS           = "\xef\x81\xa7" # 61543, 0xF067
    MINUS          = "\xef\x81\xa8" # 61544, 0xF068
    EYE_OPEN       = "\xef\x81\xae" # 61550, 0xF06E
    EYE_CLOSE      = "\xef\x81\xb0" # 61552, 0xF070
    WARNING        = "\xef\x81\xb1" # 61553, 0xF071
    SHUFFLE        = "\xef\x81\xb4" # 61556, 0xF074
    UP             = "\xef\x81\xb7" # 61559, 0xF077
    DOWN           = "\xef\x81\xb8" # 61560, 0xF078
    LOOP           = "\xef\x81\xb9" # 61561, 0xF079
    DIRECTORY      = "\xef\x81\xbb" # 61563, 0xF07B
    UPLOAD         = "\xef\x82\x93" # 61587, 0xF093
    CALL           = "\xef\x82\x95" # 61589, 0xF095
    CUT            = "\xef\x83\x84" # 61636, 0xF0C4
    COPY           = "\xef\x83\x85" # 61637, 0xF0C5
    SAVE           = "\xef\x83\x87" # 61639, 0xF0C7
    CHARGE         = "\xef\x83\xa7" # 61671, 0xF0E7
    PASTE          = "\xef\x83\xAA" # 61674, 0xF0EA
    BELL           = "\xef\x83\xb3" # 61683, 0xF0F3
    KEYBOARD       = "\xef\x84\x9c" # 61724, 0xF11C
    GPS            = "\xef\x84\xa4" # 61732, 0xF124
    FILE           = "\xef\x85\x9b" # 61787, 0xF158
    WIFI           = "\xef\x87\xab" # 61931, 0xF1EB
    BATTERY_FULL   = "\xef\x89\x80" # 62016, 0xF240
    BATTERY_3      = "\xef\x89\x81" # 62017, 0xF241
    BATTERY_2      = "\xef\x89\x82" # 62018, 0xF242
    BATTERY_1      = "\xef\x89\x83" # 62019, 0xF243
    BATTERY_EMPTY  = "\xef\x89\x84" # 62020, 0xF244
    USB            = "\xef\x8a\x87" # 62087, 0xF287
    BLUETOOTH      = "\xef\x8a\x93" # 62099, 0xF293
    TRASH          = "\xef\x8B\xAD" # 62189, 0xF2ED
    BACKSPACE      = "\xef\x95\x9A" # 62810, 0xF55A
    SD_CARD        = "\xef\x9F\x82" # 63426, 0xF7C2
    NEW_LINE       = "\xef\xA2\xA2" # 63650, 0xF8A2
  end

  # OPA_50 -> OPA::50 is illegal
  # enum {                  
  #   LV_OPA_TRANSP = 0,  
  #   LV_OPA_0      = 0,  
  #   LV_OPA_10     = 25, 
  #   LV_OPA_20     = 51, 
  #   LV_OPA_30     = 76, 
  #   LV_OPA_40     = 102,
  #   LV_OPA_50     = 127,
  #   LV_OPA_60     = 153,
  #   LV_OPA_70     = 178,
  #   LV_OPA_80     = 204,
  #   LV_OPA_90     = 229,
  #   LV_OPA_100    = 255,
  #   LV_OPA_COVER  = 255,
  # };                      
  module OPA
    TRANSP = 0
    COVER = 255
    HALF = 127 # 50

    # 0-100
    def self.scale(num)
      (255*num/100.0).round
    end
  end

  module LVColor
    def self.mix(col1, col2, mix)
      LVGL::FFI.lv_color_mix(col1, col2, mix)
    end
  end
end
