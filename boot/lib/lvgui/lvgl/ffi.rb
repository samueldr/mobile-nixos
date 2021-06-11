# FFI bindings to LVGL.

module LVGL::FFI
  extend Fiddle::BasicTypes
  extend Fiddle::Importer
  extend LVGL::Fiddlier

  dlload("liblvgui.so")

  # Alias all built-in types to their [u]intXX_t variants.
  [
    :SHORT,
    :LONG,
    :LONG_LONG,
    :CHAR,
    :INT,
  ].each do |type|
    [
      "",
      "unsigned",
    ].each do |signedness|
      sz = Fiddle.const_get("SIZEOF_#{type}".to_sym) * 8
      alias_name = "int#{sz}_t"
      aliased_type = type.to_s.downcase.gsub("_", " ")

      if signedness == "unsigned"
        alias_name = "u#{alias_name}"
        aliased_type = "#{signedness} #{aliased_type}"
      end
      typealias(alias_name, aliased_type)
    end
  end
  typealias("bool", "uint8_t")

  # lv_conf.h
  typealias("lv_coord_t", "int16_t")
  typedef "lv_obj_user_data_t", "void *"

  # lvgl/src/lv_misc/lv_color.h
  typealias("lv_color_t", "uint32_t")
  typealias("lv_opa_t", "uint8_t")

  # introspection.h
  extern "bool lv_introspection_is_simulator()"
  extern "bool lv_introspection_is_debug()"
  extern "bool lv_introspection_use_assert_style()"
  extern "const char * lv_introspection_display_driver()"

  # lvgl/src/lv_misc/lv_task.h
  enum!(:LV_TASK_PRIO, [
    :OFF,
    :LOWEST,
    :LOW,
    :MID,
    :HIGH,
    :HIGHEST,
  ], type: "uint8_t")
  typealias("lv_task_prio_t", "LV_TASK_PRIO")

  # lvgl/src/lv_themes/lv_theme.h
  extern "void lv_theme_set_current(lv_theme_t *)"
  extern "lv_theme_t * lv_theme_get_current(void)"

  # lvgl/src/lv_themes/lv_theme_nixos.h
  extern "lv_theme_t * lv_theme_nixos_init(lv_font_t *)"
  extern "lv_theme_t * lv_theme_get_nixos(void)"

  # lvgl/src/lv_core/lv_obj.h
  enum!(:LV_EVENT, [
    :PRESSED,             # < The object has been pressed*/
    :PRESSING,            # < The object is being pressed (called continuously while pressing)*/
    :PRESS_LOST,          # < User is still pressing but slid cursor/finger off of the object */
    :SHORT_CLICKED,       # < User pressed object for a short period of time, then released it. Not called if dragged. */
    :LONG_PRESSED,        # < Object has been pressed for at least `LV_INDEV_LONG_PRESS_TIME`.  Not called if dragged.*/
    :LONG_PRESSED_REPEAT, # < Called after `LV_INDEV_LONG_PRESS_TIME` in every
                          #   `LV_INDEV_LONG_PRESS_REP_TIME` ms.  Not called if dragged.*/
    :CLICKED,             # < Called on release if not dragged (regardless to long press)*/
    :RELEASED,            # < Called in every cases when the object has been released*/                                    
    :DRAG_BEGIN,		  
    :DRAG_END,
    :DRAG_THROW_BEGIN,
    :KEY,
    :FOCUSED,
    :DEFOCUSED,
    :VALUE_CHANGED,		  # < The object's value has changed (i.e. slider moved) */
    :INSERT,
    :REFRESH,
    :APPLY,  # < "Ok", "Apply" or similar specific button has clicked*/
    :CANCEL, # < "Close", "Cancel" or similar specific button has clicked*/
    :DELETE, # < Object is being deleted */

  ], type: "uint8_t")
  typealias("lv_event_t", "LV_EVENT")
  typedef "lv_event_cb_t", "void (*lv_event_cb_t)(struct _lv_obj_t *, lv_event_t)"
  #typedef uint8_t lv_res_t;
  enum!(:LV_RES, [
    { :INV => 0x00 },
    { :OK  => 0x01 },
  ], type: :uint8_t)
  typealias("lv_res_t", "LV_RES")

  enum!(:LV_ANIM, [
    :OFF,
    :ON,
  ])
  typealias("lv_anim_enable_t", "LV_ANIM")

  # Protect some attributes (max. 8 bit)
  enum!(:LV_PROTECT, [
    { :NONE      => 0x00 },
    { :CHILD_CHG => 0x01 },   # < Disable the child change signal. Used by the library*/
    { :PARENT    => 0x02 },   # < Prevent automatic parent change (e.g. in lv_page)*/
    { :POS       => 0x04 },   # < Prevent automatic positioning (e.g. in lv_cont layout)*/
    { :FOLLOW    => 0x08 },   # < Prevent the object be followed in automatic ordering (e.g. in
                              # lv_cont PRETTY layout)*/
    { :PRESS_LOST => 0x10 },  # < If the `indev` was pressing this object but swiped out while
                              # pressing do not search other object.*/
    { :CLICK_FOCUS => 0x20 }, # < Prevent focusing the object by clicking on it*/
  ], type: :uint8_t)
  typealias("lv_protect_t", "LV_PROTECT")


  extern "lv_obj_t * lv_obj_create(lv_obj_t *, const lv_obj_t *)"
  extern "const lv_style_t * lv_obj_get_style(const lv_obj_t *)"
  extern "void lv_obj_set_style(lv_obj_t *, const lv_style_t *)"
  extern "void lv_obj_refresh_style(lv_obj_t *)"
  extern "lv_coord_t lv_obj_get_width(const lv_obj_t *)"
  extern "lv_coord_t lv_obj_get_height(const lv_obj_t *)"
  extern "lv_coord_t lv_obj_get_width_fit(const lv_obj_t *)"
  extern "lv_coord_t lv_obj_get_height_fit(const lv_obj_t *)"
  extern "void lv_obj_set_width(lv_obj_t *, lv_coord_t)"
  extern "void lv_obj_set_height(lv_obj_t *, lv_coord_t)"
  extern "lv_coord_t lv_obj_get_x(const lv_obj_t *)"
  extern "lv_coord_t lv_obj_get_y(const lv_obj_t *)"
  extern "lv_obj_user_data_t lv_obj_get_user_data(const lv_obj_t *)"
  extern "lv_obj_user_data_t * lv_obj_get_user_data_ptr(const lv_obj_t *)"
  extern "void lv_obj_set_user_data(lv_obj_t *, lv_obj_user_data_t)"
  extern "void lv_obj_set_event_cb(lv_obj_t *, lv_event_cb_t)"
  extern "const void *lv_event_get_data()"
  extern "void lv_obj_set_opa_scale(lv_obj_t *, lv_opa_t)"
  extern "lv_opa_t lv_obj_get_opa_scale(const lv_obj_t *)"
  extern "void lv_obj_move_foreground(lv_obj_t *)"
  extern "void lv_obj_set_pos(lv_obj_t *, lv_coord_t, lv_coord_t)"
  extern "void lv_obj_set_x(lv_obj_t *, lv_coord_t)"
  extern "void lv_obj_set_y(lv_obj_t *, lv_coord_t)"
  extern "void lv_obj_set_parent(lv_obj_t *, lv_obj_t *)"
  extern "void lv_obj_set_hidden(lv_obj_t *, bool)"
  extern "void lv_obj_set_click(lv_obj_t *, bool)"
  extern "void lv_obj_set_top(lv_obj_t *, bool)"
  extern "void lv_obj_set_opa_scale_enable(lv_obj_t *, bool)"
  extern "void lv_obj_set_protect(lv_obj_t *, lv_protect_t)"
  extern "lv_opa_t lv_obj_get_opa_scale_enable(const lv_obj_t *)"
  extern "void lv_obj_clean(lv_obj_t *)"
  extern "lv_res_t lv_obj_del(lv_obj_t *)"
  extern "void lv_obj_del_async(struct _lv_obj_t *)"
  extern "lv_obj_t * lv_obj_get_parent(const lv_obj_t *)"
  extern "bool lv_obj_is_children(const lv_obj_t * obj, const lv_obj_t * target)"
  extern "lv_obj_t *lv_obj_get_child_back(const lv_obj_t *, const lv_obj_t *)"

  def handle_lv_event(obj_p, event)
    #userdata = lv_obj_get_user_data(obj_p)
    #instance = userdata.to_value
    # Pick from our registry, until we can rehydrate the object type with Fiddle.
    instance = LVGL::LVObject::REGISTRY[obj_p.to_i]
    instance.instance_exec do
      if @__event_handler_proc
        @__event_handler_proc.call(event)
      end
    end
  end
  bound_method! :handle_lv_event, "void handle_lv_event_(struct _lv_obj_t *, lv_event_t)"

  # lvgl/src/lv_objx/lv_btn.h

  enum!(:LV_BTN_STYLE, [
    :REL,
    :PR,
    :TGL_REL,
    :TGL_PR,
    :INA,
  ])
  typealias("lv_btn_style_t", "LV_BTN_STYLE")

  extern "lv_obj_t * lv_btn_create(lv_obj_t *, const lv_obj_t *)"
  extern "void lv_btn_set_ink_in_time(lv_obj_t *, uint16_t)"
  extern "void lv_btn_set_ink_wait_time(lv_obj_t *, uint16_t)"
  extern "void lv_btn_set_ink_out_time(lv_obj_t *, uint16_t)"
  extern "void lv_btn_set_style(lv_obj_t *, lv_btn_style_t, const lv_style_t *)"
  extern "const lv_style_t * lv_btn_get_style(const lv_obj_t *, lv_btn_style_t)"

  # lvgl/src/lv_objx/lv_cont.h
  #typedef uint8_t lv_layout_t;
  enum!(:LV_LAYOUT, [
    {OFF: 0}, #< No layout */
    :CENTER, #< Center objects */
    :COL_L,  #< Column left align*/
    :COL_M,  #< Column middle align*/
    :COL_R,  #< Column right align*/
    :ROW_T,  #< Row top align*/
    :ROW_M,  #< Row middle align*/
    :ROW_B,  #< Row bottom align*/
    :PRETTY, #< Put as many object as possible in row and begin a new row*/
    :GRID,   #< Align same-sized object into a grid*/
  ], type: "uint8_t")
  typealias("lv_layout_t", "LV_LAYOUT")

  enum!(:LV_FIT, [
    :NONE,  #< Do not change the size automatically*/
    :TIGHT, #< Shrink wrap around the children */
    :FLOOD, #< Align the size to the parent's edge*/
    :FILL,  #< Align the size to the parent's edge first but if there is an object out of it
            #        then get larger */
  ], type: "uint8_t")
  typealias("lv_fit_t", "LV_FIT")

  # typedef uint8_t lv_cont_style_t;
  enum!(:LV_CONT_STYLE, [
    :MAIN,
  ])
  typealias("lv_cont_style_t", "LV_CONT_STYLE")

  extern "lv_obj_t * lv_cont_create(lv_obj_t *, const lv_obj_t *)"
  extern "void lv_cont_set_layout(lv_obj_t *, lv_layout_t)"
  extern "void lv_cont_set_fit4(lv_obj_t *, lv_fit_t, lv_fit_t, lv_fit_t, lv_fit_t)"
  extern "void lv_cont_set_fit2(lv_obj_t *, lv_fit_t, lv_fit_t)"
  extern "void lv_cont_set_fit(lv_obj_t *, lv_fit_t)"

  # lvgl/src/lv_core/lv_disp.h
  extern "lv_obj_t *lv_disp_get_scr_act(lv_disp_t *)"
  extern "void lv_disp_load_scr(lv_obj_t *)"
  extern "lv_disp_t *lv_disp_get_default()"
  extern "lv_obj_t *lv_scr_act()"

  extern "lv_obj_t * lv_layer_top()"
  extern "lv_obj_t * lv_layer_sys()"

  # lvgl/src/lv_objx/lv_img.h
  extern "lv_obj_t * lv_img_create(lv_obj_t *, const lv_obj_t *)"
  extern "void lv_img_set_src(lv_obj_t *, const void *)"

  # lvgl/src/lv_objx/lv_sw.h
  enum!(:LV_SW_STYLE, [
    :BG,
    :INDIC,
    :KNOB_OFF,
    :KNOB_ON,
  ], type: "uint8_t")
  typealias("lv_sw_style_t", "LV_SW_STYLE")

  extern "lv_obj_t *lv_sw_create(lv_obj_t *, const lv_obj_t *)"
  extern "void lv_sw_on(lv_obj_t *, lv_anim_enable_t)"
  extern "void lv_sw_off(lv_obj_t *, lv_anim_enable_t)"
  extern "void lv_sw_toggle(lv_obj_t *, lv_anim_enable_t)"
  extern "void lv_sw_set_style(lv_obj_t *, lv_sw_style_t , const lv_style_t *)"
  extern "void lv_sw_set_anim_time(lv_obj_t *, uint16_t)"
  extern "bool lv_sw_get_state(const lv_obj_t *)"
  extern "uint16_t lv_sw_get_anim_time(const lv_obj_t *)"

  # lvgl/src/lv_objx/lv_label.h
  enum!(:LV_LABEL_LONG, [
    :EXPAND,     #< Expand the object size to the text size*/
    :BREAK,      #< Keep the object width, break the too long lines and expand the object
                 #  height*/
    :DOT,        #< Keep the size and write dots at the end if the text is too long*/
    :SROLL,      #< Keep the size and roll the text back and forth*/
    :SROLL_CIRC, #< Keep the size and roll the text circularly*/
    :CROP,       #< Keep the size and crop the text out of it*/
  ], type: "uint8_t")
  typealias("lv_label_long_mode_t", "LV_LABEL_LONG")

  enum!(:LV_LABEL_ALIGN, [
    :LEFT,   #< Align text to left */
    :CENTER, #< Align text to center */
    :RIGHT,  #< Align text to right */
    :AUTO,   #< Use LEFT or RIGHT depending on the direction of the text (LTR/RTL)*/
  ], type: "uint8_t")
  typealias("lv_label_align_t", "LV_LABEL_ALIGN")

  enum!(:LV_LABEL_STYLE, [
    :MAIN
  ], type: "uint8_t")
  typealias("lv_label_style_t", "LV_LABEL_STYLE")

  extern "lv_obj_t * lv_label_create(lv_obj_t *, const lv_obj_t *)"
  extern "void lv_label_set_text(lv_obj_t *, const char *)"
  # extern "void lv_label_set_text_fmt(lv_obj_t * label, const char * fmt, ...)" varargs?
  extern "void lv_label_set_long_mode(lv_obj_t *, lv_label_long_mode_t)"
  extern "void lv_label_set_align(lv_obj_t *, lv_label_align_t)"

  # lvgl/src/lv_objx/lv_page.h
  enum!(:LV_PAGE_STYLE, [
    :BG,
    :SCRL,
    :SB,
    :EDGE_FLASH,
  ], type: "uint8_t")
  typealias("lv_page_style_t", "LV_PAGE_STYLE")

  enum!(:LV_SB_MODE, [
    { :OFF    => 0x0 },
    { :ON     => 0x1 },
    { :DRAG   => 0x2 },
    { :AUTO   => 0x3 },
    { :HIDE   => 0x4 },
    { :UNHIDE => 0x5 },
  ], type: "uint8_t")
  typealias("lv_sb_mode_t", "LV_SB_MODE")

  extern "lv_obj_t * lv_page_create(lv_obj_t *, const lv_obj_t *)"
  extern "void lv_page_clean(lv_obj_t *)"
  extern "lv_obj_t * lv_page_get_scrl(const lv_obj_t *)"
  extern "void lv_page_set_scrl_layout(lv_obj_t *, lv_layout_t)"
  extern "void lv_page_glue_obj(lv_obj_t *, bool)"
  extern "const lv_style_t * lv_page_get_style(const lv_obj_t *, lv_page_style_t)"
  extern "void lv_page_set_style(lv_obj_t *, lv_page_style_t, const lv_style_t *)"
  extern "void lv_page_focus(lv_obj_t *, const lv_obj_t *, lv_anim_enable_t)"
  extern "void lv_page_set_scrl_width(lv_obj_t *, lv_coord_t)"
  extern "void lv_page_set_scrl_height(lv_obj_t *, lv_coord_t)"
  extern "lv_coord_t lv_page_get_scrl_width(const lv_obj_t *)"
  extern "lv_coord_t lv_page_get_scrl_height(const lv_obj_t *)"


  # lvgl/src/lv_objx/lv_kb.h
  enum!(:LV_KB_MODE, [
    :TEXT,
    :NUM,
    :TEXT_UPPER,
  ], type: "uint8_t")
  typealias("lv_kb_mode_t", "LV_KB_MODE")

  enum!(:LV_KB_STYLE, [
    :BG,
    :BTN_REL,
    :BTN_PR,
    :BTN_TGL_REL,
    :BTN_TGL_PR,
    :BTN_INA,
  ])
  typealias("lv_kb_style_t", "LV_KB_STYLE")

  extern "lv_obj_t * lv_kb_create(lv_obj_t *, const lv_obj_t *)"
  extern "void lv_kb_set_ta(lv_obj_t *, lv_obj_t *)"
  extern "void lv_kb_set_mode(lv_obj_t *, lv_kb_mode_t)"
  extern "void lv_kb_set_cursor_manage(lv_obj_t *, bool)"
  extern "void lv_kb_set_map(lv_obj_t *, const char * [])" # ??
  extern "void lv_kb_set_ctrl_map(lv_obj_t * , const lv_btnm_ctrl_t [])" # ??
  extern "void lv_kb_set_style(lv_obj_t *, lv_kb_style_t, const lv_style_t *)"
  extern "lv_obj_t * lv_kb_get_ta(const lv_obj_t *)"
  extern "lv_kb_mode_t lv_kb_get_mode(const lv_obj_t *)"
  extern "bool lv_kb_get_cursor_manage(const lv_obj_t *)"
  extern "const char ** lv_kb_get_map_array(const lv_obj_t *)"
  extern "const lv_style_t * lv_kb_get_style(const lv_obj_t *, lv_kb_style_t)"
  extern "void lv_kb_def_event_cb(lv_obj_t *, lv_event_t)"


  # lvgl/src/lv_objx/lv_ta.h
  enum!(:LV_CURSOR, [
    :NONE,
    :LINE,
    :BLOCK,
    :OUTLINE,
    :UNDERLINE,
    { :HIDDEN => 0x08 },
  ], type: "uint8_t")
  typealias("lv_cursor_type_t", "LV_CURSOR")

  enum!(:LV_TA_STYLE, [
    :BG,
    :SB,
    :CURSOR,
    :EDGE_FLASH,
    :PLACEHOLDER,
  ])
  typealias("lv_ta_style_t", "LV_TA_STYLE")

  extern "lv_obj_t * lv_ta_create(lv_obj_t *, const lv_obj_t *)"
  extern "void lv_ta_add_char(lv_obj_t *, uint32_t)"
  extern "void lv_ta_add_text(lv_obj_t *, const char *)"
  extern "void lv_ta_del_char(lv_obj_t *)"
  extern "void lv_ta_del_char_forward(lv_obj_t *)"
  extern "void lv_ta_set_text(lv_obj_t *, const char *)"
  extern "void lv_ta_set_placeholder_text(lv_obj_t *, const char *)"
  extern "void lv_ta_set_cursor_pos(lv_obj_t *, int16_t)"
  extern "void lv_ta_set_cursor_type(lv_obj_t *, lv_cursor_type_t)"
  extern "void lv_ta_set_cursor_click_pos(lv_obj_t *, bool)"
  extern "void lv_ta_set_pwd_mode(lv_obj_t *, bool)"
  extern "void lv_ta_set_one_line(lv_obj_t *, bool)"
  extern "void lv_ta_set_text_align(lv_obj_t *, lv_label_align_t)"
  extern "void lv_ta_set_accepted_chars(lv_obj_t *, const char *)"
  extern "void lv_ta_set_max_length(lv_obj_t *, uint16_t)"
  #extern "void lv_ta_set_insert_replace(lv_obj_t *, const char *)"
  extern "void lv_ta_set_sb_mode(lv_obj_t *, lv_sb_mode_t)"
  extern "void lv_ta_set_scroll_propagation(lv_obj_t *, bool)"
  extern "void lv_ta_set_edge_flash(lv_obj_t *, bool)"
  extern "void lv_ta_set_style(lv_obj_t *, lv_ta_style_t, const lv_style_t *)"
  extern "void lv_ta_set_text_sel(lv_obj_t *, bool)"
  extern "void lv_ta_set_pwd_show_time(lv_obj_t *, uint16_t)"
  extern "void lv_ta_set_cursor_blink_time(lv_obj_t *, uint16_t)"
  extern "const char * lv_ta_get_text(const lv_obj_t *)"
  extern "const char * lv_ta_get_placeholder_text(lv_obj_t *)"
  extern "lv_obj_t * lv_ta_get_label(const lv_obj_t *)"
  extern "uint16_t lv_ta_get_cursor_pos(const lv_obj_t *)"
  extern "lv_cursor_type_t lv_ta_get_cursor_type(const lv_obj_t *)"
  extern "bool lv_ta_get_cursor_click_pos(lv_obj_t *)"
  extern "bool lv_ta_get_pwd_mode(const lv_obj_t *)"
  extern "bool lv_ta_get_one_line(const lv_obj_t *)"
  extern "const char * lv_ta_get_accepted_chars(lv_obj_t *)"
  extern "uint16_t lv_ta_get_max_length(lv_obj_t *)"
  extern "lv_sb_mode_t lv_ta_get_sb_mode(const lv_obj_t *)"
  extern "bool lv_ta_get_scroll_propagation(lv_obj_t *)"
  extern "bool lv_ta_get_edge_flash(lv_obj_t *)"
  extern "const lv_style_t * lv_ta_get_style(const lv_obj_t *, lv_ta_style_t)"
  extern "bool lv_ta_text_is_selected(const lv_obj_t *)"
  extern "bool lv_ta_get_text_sel_en(lv_obj_t *)"
  extern "uint16_t lv_ta_get_pwd_show_time(lv_obj_t *)"
  extern "uint16_t lv_ta_get_cursor_blink_time(lv_obj_t *)"
  extern "void lv_ta_clear_selection(lv_obj_t *)"
  extern "void lv_ta_cursor_right(lv_obj_t *)"
  extern "void lv_ta_cursor_left(lv_obj_t *)"
  extern "void lv_ta_cursor_down(lv_obj_t *)"
  extern "void lv_ta_cursor_up(lv_obj_t *)"

  # lvgl/src/lv_core/lv_style.h

  #typedef uint8_t lv_border_part_t
  enum!(:LV_BORDER, [
    { :NONE     => 0x00 },
    { :BOTTOM   => 0x01 },
    { :TOP      => 0x02 },
    { :LEFT     => 0x04 },
    { :RIGHT    => 0x08 },
    { :FULL     => 0x0F },
    { :INTERNAL => 0x10 },
  ], type: :uint8_t)
  typealias("lv_border_part_t", "LV_BORDER")

  enum!(:LV_SHADOW, [
    :BOTTOM,
    :FULL,
  ], type: :uint8_t)
  typealias("lv_shadow_type_t", "LV_SHADOW")

  #extern "void lv_style_init(void)"
  extern "void lv_style_copy(lv_style_t *, const lv_style_t *)"

  # Animations
  typealias "lv_anim_value_t", "int16_t"
  typedef "lv_anim_exec_xcb_t", "void (*lv_anim_exec_xcb_t)(void *, lv_anim_value_t)"
  typedef "lv_anim_path_cb_t", "lv_anim_value_t (*lv_anim_path_cb_t)(const struct _lv_anim_t *)"
  extern "void lv_anim_init(lv_anim_t *)"
  extern "void lv_anim_set_exec_cb(lv_anim_t *, void *, lv_anim_exec_xcb_t)"
  extern "void lv_anim_create(lv_anim_t *)"
  extern "void lv_anim_del(lv_anim_t *)"
  extern "void lv_anim_clear_repeat(lv_anim_t *)"
  extern "void lv_anim_set_repeat(lv_anim_t *, uint16_t)"
  extern "void lv_anim_set_playback(lv_anim_t *, uint16_t)"
  extern "void lv_anim_set_time(lv_anim_t *, int16_t, int16_t)"
  extern "void lv_anim_set_path_cb(lv_anim_t *, lv_anim_path_cb_t)"
  extern "void lv_anim_set_values(lv_anim_t *, lv_anim_value_t, lv_anim_value_t)"

  # Colors
  extern "lv_color_t lv_color_mix(lv_color_t, lv_color_t, uint8_t)"

  # Focus groups
  typedef "lv_group_focus_cb_t", "void (*lv_group_focus_cb_t)(struct _lv_group_t *)"
  extern "void lv_anim_core_init()"
  extern "lv_group_t * lvgui_get_focus_group()"
  extern "void lvgui_focus_ring_disable()"
  extern "void lv_group_add_obj(lv_group_t *, lv_obj_t *)"
  extern "void lv_group_remove_obj(lv_obj_t *)"
  extern "void lv_group_remove_all_objs(lv_group_t *)"
  extern "void lv_group_focus_obj(lv_obj_t *)"
  extern "void lv_group_focus_next(lv_group_t *)"
  extern "void lv_group_focus_prev(lv_group_t *)"
  extern "void lv_group_focus_freeze(lv_group_t *, bool)"
  extern "void lv_group_set_click_focus(lv_group_t *, bool)"
  extern "void lv_group_set_wrap(lv_group_t *, bool)"
  extern "lv_obj_t *lv_group_get_focused(const lv_group_t *)"
  extern "void lv_group_set_focus_cb(lv_group_t *, lv_group_focus_cb_t)"
  extern "lv_obj_t * lv_group_get_focused(const lv_group_t *)"

  typedef "lv_group_user_data_t", "void *"
  extern "lv_group_user_data_t *lv_group_get_user_data(lv_group_t *)"
  extern "void lv_group_set_user_data(lv_group_t *, lv_group_user_data_t)"

  def handle_lv_focus(group_p)
    #userdata = lv_group_get_user_data(group_p)
    #instance = userdata.to_value
    # Pick from our registry, until we can rehydrate the object type with Fiddle.
    instance = LVGL::LVGroup::REGISTRY[group_p.to_i]
    instance.instance_exec do
      prc = @focus_handler_proc_stack.last
      if prc
        prc.call()
      end
    end
  end
  bound_method! :handle_lv_focus, "void handle_lv_focus_(_lv_group_t *)"

  # Fonts
  extern "lv_font_t * lvgui_get_font(char*, uint16_t)"
end
