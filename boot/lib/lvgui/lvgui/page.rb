# Scrolling page.
class LVGUI::Page < LVGUI::Widget
  def initialize(parent)
    @parent = parent
    # A "holder" widget to work around idiosyncracies of pages.
    @holder = LVGL::LVContainer.new(parent)
    @holder.set_fit2(LVGL::FIT::FILL, LVGL::FIT::NONE)
    @holder.set_style(LVGL::CONT_STYLE::MAIN, LVGL::LVStyle::STYLE_TRANSP.dup)
    @holder.get_style(LVGL::CONT_STYLE::MAIN).tap do |style|
      style.body_padding_right = 0
      style.body_padding_left  = 0
    end

    # The actual widget we interact with
    super(LVGL::LVPage.new(@holder))
    style = LVGL::LVStyle::STYLE_TRANSP.dup
    # Padding to zero in the actual scrolling widget makes the scrollbar visible
    style.body_padding_left = 0
    style.body_padding_right = 0
    style.body_padding_top = 0
    style.body_padding_bottom = 0

    set_style(LVGL::PAGE_STYLE::BG, style.dup().tap do |style|
      style.body_main_color = 0xFF_0000ff
      style.body_grad_color = style.body_main_color
      style.body_padding_right = LVGUI.col_padding
      style.body_padding_left  = LVGUI.col_padding
    end)

    set_style(LVGL::PAGE_STYLE::SCRL, style.dup().tap do |style|
      style.body_main_color = 0xFF_00ff00
      style.body_grad_color = style.body_main_color
      style.body_padding_inner = LVGUI.col_padding
      style.body_padding_bottom = LVGUI.col_padding*2
      style.body_padding_top = LVGUI.col_padding - LVGUI.pixel_scale(10)
    end)

    # Scrollbar
    sb_style = LVGL::LVStyle::STYLE_PLAIN.dup().tap do |style|
      style.body_padding_right  = LVGUI.pixel_scale(2)
      style.body_padding_bottom = LVGUI.pixel_scale(2)
      style.body_opa = 128
      style.body_main_color = 0xFF_304673
      style.body_grad_color = style.body_main_color
      style.body_padding_inner = LVGUI.pixel_scale(8)
    end
    set_style(LVGL::PAGE_STYLE::SB, sb_style)

    set_width(@holder.get_width())

    # Make this scroll
    set_scrl_layout(LVGL::LAYOUT::COL_M)

    refresh
  end

  # Call this function when the position of the Page is changed.
  # Mainly, this would be after filling the toolbar.
  def refresh()
    # Filling the parent that is at the root of the screen is apparently broken :/.
    @holder.set_height(@parent.get_height_fit - @holder.get_y)
    set_height(@holder.get_height - get_y)
  end

  def inner_padding=(val)
    get_style(LVGL::PAGE_STYLE::SCRL).tap do |style|
      style.body_padding_inner = val
    end
  end
end
