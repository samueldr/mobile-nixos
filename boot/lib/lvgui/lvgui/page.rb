# Scrolling page.
class LVGUI::Page < LVGUI::Widget
  def initialize(parent)
    @parent = parent
    # A "holder" widget to work around idiosyncracies of pages.
    @holder = LVGL::LVContainer.new(parent)
    @holder.set_fit2(LVGL::FIT::FILL, LVGL::FIT::NONE)
    @holder.set_style(LVGL::CONT_STYLE::MAIN, LVGL::LVStyle::STYLE_TRANSP.dup)

    # The actual widget we interact with
    super(LVGL::LVPage.new(@holder))
    style = LVGL::LVStyle::STYLE_TRANSP.dup
    # Padding to zero in the actual scrolling widget makes the scrollbar visible
    style.body_padding_left = 0
    style.body_padding_right = 0

    set_style(LVGL::PAGE_STYLE::BG, style)
    set_style(LVGL::PAGE_STYLE::SCRL, style)
    set_fit2(LVGL::FIT::FILL, LVGL::FIT::NONE)

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
end
