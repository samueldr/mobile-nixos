# Wraps multiple elements in a line element that allows the end-user to pick
# one option among a selection.
class LVGUI::OptionSelection < LVGUI::Widget
  attr_reader :options
  attr_reader :selected

  # Cached accessor to the container styles
  def self.container_style()
    return @@_container_styles if class_variable_defined?(:@@_container_styles)

    cont = LVGL::LVContainer.new()
    # Dup to ensure we don't modify the existing styles
    @@_container_styles = cont.get_style(LVGL::CONT_STYLE::MAIN).dup()
    cont.del()
    @@_container_styles
  end

  # The overlay_location will hold the actual "selection" interface
  # It should be a "layer" on top of your app, which does not scroll with the
  # app's contents.
  def initialize(parent, overlay_location)
    super(FlatishButtonBase.new(parent))

    # The "overlay" window, which actually includes the options you select from.
    # (Implementation at the bottom of this file.)
    @overlay = Overlay.new(self)
    @overlay.on_select = ->(value) { self.select(value) }

    # Selected option
    @selected = nil

    # Add a container for the labels
    @label_container = LVGL::LVContainer.new(self).tap do |container|
      tr_style = LVGL::LVStyle::STYLE_TRANSP.dup
      tr_style.body_padding_left = 0
      tr_style.body_padding_right = 0
      container.set_style(LVGL::CONT_STYLE::MAIN, tr_style)

      # The layout is a column, two distinct lines, top to bottom.
      container.set_layout(LVGL::LAYOUT::COL_L)

      # Width will be computed in set_width; automatic layout from LVGL fails.
      container.set_fit2(LVGL::FIT::NONE, LVGL::FIT::TIGHT)

      container.set_click(false)
    end

    # Add the main label
    @main_label = LVGL::LVLabel.new(@label_container).tap do |label|
      label.set_long_mode(LVGL::LABEL_LONG::BREAK)
      label.set_click(false)
    end
    set_label(nil)

    # The chosen option label (second row, optional)
    @chosen_option_label = LVGL::LVLabel.new(@label_container).tap do |label|
      style = label.get_style(LVGL::LABEL_STYLE::MAIN).dup()
      # It's a bit more subdued
      style.text_color = 0xffaaaaaa
      label.set_style(LVGL::LABEL_STYLE::MAIN, style)
      label.set_long_mode(LVGL::LABEL_LONG::BREAK)
      label.set_click(false)
    end
    set_chosen_option_label(nil)

    # Drill down icon
    @icon = LVGL::LVLabel.new(self).tap do |icon|
      icon.set_text("\uF054")
      icon.set_click(false)
    end

    # Call on @widget since we re-define event_handler=() for users of this class.
    @widget.event_handler = ->(event) {
      case event
      when LVGL::EVENT::RELEASED
        @overlay.open()
      end
    }

    # Defaults to full width
    self.set_width(parent.get_width_fit())
  end

  # Like the parent function.
  # Also recomputes the layout of internal elements
  def set_width(width)
    super(width)

    # Resize the label container to fill, working around segfault.
    @label_container.set_width(self.get_width_fit - @icon.get_width - LVGUI.col_padding()*2)
    @main_label.set_width(@label_container.get_width_fit)
    @chosen_option_label.set_width(@label_container.get_width_fit)
  end

  # Sets the main label, optionally hiding it.
  # When hidden, it takes no vertical space in the layout.
  def set_label(text)
    @main_label_text = text
    @main_label.set_text(text)
    if text
      @main_label.set_hidden(false)
    else
      @main_label.set_hidden(true)
    end
  end

  def get_label()
    @main_label_text
  end

  # Set all available options, ordered list of pairs.
  def set_options(options)
    @options = options
    if options.map(&:first).include?(@selected)
      # Refresh label
      select(@selected)
    else
      # Unset value (and label)
      @selected = nil
      set_chosen_option_label("")
    end
  end

  # Force a selection for the given value
  def select(value)
    label = @options.to_h[value]

    # Fails silently to change on wrong option
    return unless label

    @selected = value
    set_chosen_option_label(label)

    if @event_handler
      @event_handler.call(LVGL::EVENT::VALUE_CHANGED)
    end
  end

  def event_handler=(prc)
    @event_handler = prc
  end

  def event_handler()
    @event_handler
  end

  # Open the overlay; this is how you select a new value.
  def open()
    @overlay.open()
  end

  private

  # Sets the description label, optionally hiding it.
  # When hidden, it takes no vertical space in the layout.
  def set_chosen_option_label(text)
    @chosen_option_label.set_text(text)
  end
end

class LVGUI::OptionSelection::FlatishButtonBase < LVGUI::Widget
  def initialize(parent)
    super(LVGL::LVButton.new(parent))

    # Styles
    [
      :REL,
      :PR,
      :TGL_REL,
      :TGL_PR,
      :INA,
    ].each do |sym|
      get_style(LVGL::BTN_STYLE.const_get(sym)).dup.tap do |style|
        style.body_radius = LVGUI.pixel_scale(16)

        ## Button paddings are quite harsh by default
        style.body_padding_left = LVGUI::OptionSelection.container_style.body_padding_inner
        style.body_padding_right = LVGUI::OptionSelection.container_style.body_padding_inner
        style.body_padding_top = style.body_padding_top / 2
        style.body_padding_bottom = style.body_padding_bottom / 2
        style.body_shadow_width = 0
        set_style(LVGL::BTN_STYLE.const_get(sym), style)
      end
    end

    get_style(LVGL::BTN_STYLE::REL).dup.tap do |style|
      main_color = LVGUI::OptionSelection.container_style.body_main_color
      set_style(LVGL::BTN_STYLE::REL, style)
    end

    set_ink_in_time(200)
    set_ink_wait_time(100)
    set_ink_out_time(500)

    # Set layout for the line, labels left, "drill down icon" right, so a row.
    set_layout(LVGL::LAYOUT::ROW_M)
    set_fit2(LVGL::FIT::NONE, LVGL::FIT::TIGHT)
  end
end

# Version of the button with a built-in label.
class LVGUI::OptionSelection::OptionButton < LVGUI::OptionSelection::FlatishButtonBase
  class Pip < LVGUI::Widget
    def initialize(parent, background)
      @background = background
      super(LVGL::LVObject.new(parent))
      set_height(25)
      set_width(get_height())
      get_style().dup().tap do |style|
        style.body_radius = get_height()/2 - 1
        style.body_border_width = 4
        style.body_border_opa = LVGL::OPA::COVER
        style.body_border_color = 0xFFFFFFFF
        style.body_main_color = @background
        style.body_grad_color = @background
        set_style(style)
      end
      set_opa_scale_enable(true)
      set_opa_scale(LVGL::OPA.scale(20))
    end

    def selected=(val)
      style = get_style()
      if val
        set_opa_scale(LVGL::OPA.scale(90))
        style.body_main_color = style.body_border_color
        style.body_grad_color = style.body_border_color
      else
        set_opa_scale(LVGL::OPA.scale(50))
        style.body_main_color = @background
        style.body_grad_color = @background
      end
    end
  end

  def initialize(parent)
    super(parent)

    set_fit2(LVGL::FIT::FILL, LVGL::FIT::TIGHT)

    # Add a container for the labels
    @label_container = LVGL::LVContainer.new(self).tap do |container|
      tr_style = LVGL::LVStyle::STYLE_TRANSP.dup
      tr_style.body_padding_left = 0
      tr_style.body_padding_right = 0
      container.set_style(LVGL::CONT_STYLE::MAIN, tr_style)

      # The layout is a row, [icon] [label              ]
      container.set_layout(LVGL::LAYOUT::ROW_M)
      container.set_fit2(LVGL::FIT::FILL, LVGL::FIT::TIGHT)

      container.set_click(false)
    end

    @icon = Pip.new(@label_container, get_style(LVGL::BTN_STYLE::REL).body_main_color)

    @label = LVGL::LVLabel.new(@label_container)
    @label.set_long_mode(LVGL::LABEL_LONG::BREAK)
    @label.set_width(get_width_fit - @label.get_x() - @icon.get_x())

    # The defaults for FlatishButtonBase are too small to be comfortably
    # touchable as a one-liner element.
    [
      :REL,
      :PR,
      :TGL_REL,
      :TGL_PR,
      :INA,
    ].each do |sym|
      get_style(LVGL::BTN_STYLE.const_get(sym)).tap do |style|
        style.body_padding_top = style.body_padding_top * 2
        style.body_padding_bottom = style.body_padding_bottom * 2
      end
    end
  end

  def set_label(label)
    @label.set_text(label)
  end

  def selected=(val)
    @icon.selected = val
  end
end

# Implementation of the scrollable area, which depends on the implementation of
# the OptionSelection overlay.
class LVGUI::OptionSelection::ScrollableArea < LVGUI::Widget
  def initialize(parent, overlay)
    # Remove all styling
    style = LVGL::LVStyle::STYLE_TRANSP.dup
    # Padding to zero in the actual scrolling widget makes the scrollbar visible
    style.body_padding_left = 0
    style.body_padding_right = 0
    style.body_padding_top = 0
    style.body_padding_bottom = 0

    @overlay = overlay
    # A "holder" widget to work around idiosyncrasies of pages.
    @holder = LVGL::LVContainer.new(parent)
    @holder.set_fit2(LVGL::FIT::FILL, LVGL::FIT::TIGHT)
    @holder.set_style(LVGL::CONT_STYLE::MAIN, style)

    # The actual widget we interact with
    super(LVGL::LVPage.new(@holder))

    set_style(LVGL::PAGE_STYLE::BG, style)
    set_style(LVGL::PAGE_STYLE::SCRL, style)
    set_fit2(LVGL::FIT::FILL, LVGL::FIT::TIGHT)

    # Make this scroll
    set_scrl_layout(LVGL::LAYOUT::COL_M)

    refresh
  end

  # Re-computes the scrollable area's metrics.
  def refresh()
    @holder.set_height(@overlay.get_scrollable_area)

    # First reduce to a minimum
    set_fit2(LVGL::FIT::FILL, LVGL::FIT::NONE)
    set_height(0)

    # Then re-compute height according to LVGL
    set_fit2(LVGL::FIT::FILL, LVGL::FIT::TIGHT)

    if get_height_fit > @overlay.get_scrollable_area
      # If too big, resize manually
      @holder.set_fit2(LVGL::FIT::FILL, LVGL::FIT::NONE)
      set_fit2(LVGL::FIT::FILL, LVGL::FIT::NONE)
      set_height(@overlay.get_scrollable_area)
    else
      # Otherwise fit tightly!
      @holder.set_fit2(LVGL::FIT::FILL, LVGL::FIT::TIGHT)
    end
  end

  def set_height(v)
    # Send to the original function
    method_missing(:set_height, v)
    @holder.set_height(v)
  end

  def set_hidden(v)
    @holder.set_hidden(v)
  end
end

class LVGUI::OptionSelection::Overlay < LVGUI::Widget
  def initialize(linked_select)
    parent = LVGL.layer_top
    super(LVGL::LVContainer.new(parent))
    @linked_select = linked_select

    # Dummy object used as a "null" focus
    @dummy = LVGUI::Dummy.new(linked_select)

    # Fill the parent with this background overlay
    set_width(parent.get_width_fit())
    set_height(parent.get_height())
    set_x(0)
    set_y(0)

    set_layout(LVGL::LAYOUT::CENTER)

    # Make the backdrop half-transparent
    get_style(LVGL::CONT_STYLE::MAIN).dup().tap do |style|
      style.body_opa = LVGL::OPA::HALF
      # Compute from the default paddings
      style.body_padding_left   *= 2
      style.body_padding_right  *= 2
      style.body_padding_top    *= 4
      style.body_padding_bottom *= 4
      set_style(LVGL::CONT_STYLE::MAIN, style)
    end

    # Hide by default
    set_hidden(true)

    # Actual items will live in this container, which will live on top of
    # the "page overlay".
    @container = LVGL::LVContainer.new(self).tap do |cont|
      cont.set_layout(LVGL::LAYOUT::COL_M)
      cont.set_fit2(LVGL::FIT::FILL, LVGL::FIT::TIGHT)
    end

    # Add a label for the title
    @title = LVGL::LVLabel.new(@container).tap do |label|
      label.set_long_mode(LVGL::LABEL_LONG::BREAK)
      label.set_align(LVGL::LABEL_ALIGN::CENTER)
      label.set_width(@container.get_width_fit())
      label.set_click(false)
    end

    LVGUI::HorizontalSeparator.new(@container)

    # This is where the content will live, scrollable, without affecting
    # either the title or the cancel button.
    @options = LVGUI::OptionSelection::ScrollableArea.new(@container, self)

    LVGUI::HorizontalSeparator.new(@container)

    # A button to cancel out. Touching the overlay background does exit too,
    # but that's not user-friendly, give them a "real" option.
    @cancel = LVGUI::Button.new(@container).tap do |button|
      button.set_label("Cancel")
      button.event_handler = ->(event) do
        case event
        when LVGL::EVENT::RELEASED
          self.close()
        end
      end
    end

    # Close (without changing selection) on overlay press
    self.event_handler = ->(event) {
      case event
      when LVGL::EVENT::RELEASED
        self.close()
      end
    }
  end

  def open()
    # Refresh the title
    set_title(@linked_select.get_label())

    # Create a new focus group on the "stack"
    LVGUI.focus_group.push()

    # Ensure we scroll down as needed to the focused element
    LVGUI.focus_group.focus_handler = ->() do
      @options.focus(
        LVGUI.focus_group.get_focused,
        LVGL::ANIM::OFF
      )
    end

    # Start with the dummy item (default selected)
    LVGUI.focus_group.add_obj(@dummy)

    # Remove children
    @options.clean()

    selected = @linked_select.selected
    
    # Then make fresh children, ensuring labels are updated, and the selected
    # state is updated too.
    @linked_select.options.each do |pair|
      sym, label = pair
      LVGUI::OptionSelection::OptionButton.new(@options).tap do |option|
        option.selected = (selected == sym)
        option.set_label(label)
        option.event_handler = ->(event) do
          case event
          when LVGL::EVENT::RELEASED
            if @on_select_handler
              @on_select_handler.call(sym)
            end
            self.close()
          end
        end
        # Don't forget to add to the focus group
        LVGUI.focus_group.add_obj(option)
      end
    end

    # Refresh the metrics of the scrollable area
    @options.refresh()

    # Add the cancel button too, otherwise we're in for a bad time.
    LVGUI.focus_group.add_obj(@cancel)

    set_hidden(false)
  end

  def close()
    LVGUI.focus_group.pop()
    set_hidden(true)
  end

  def set_title(text)
    @title.set_text(text)
  end

  # For the scrollable area widget
  def get_scrollable_area()
    return 0 unless @options && @cancel

    @container.set_fit2(LVGL::FIT::FILL, LVGL::FIT::FLOOD)
    @options.set_hidden(true)
    offset = height = @cancel.get_y() + @cancel.get_height()
    height = get_height_fit() - offset
    @options.set_hidden(false)
    @container.set_fit2(LVGL::FIT::FILL, LVGL::FIT::TIGHT)

    height
  end

  # Will call this proc with the new value on selection.
  def on_select=(prc)
    @on_select_handler = prc
  end

  def on_select()
    @on_select_handler
  end
end
