begin

data = JSON.parse(File.read(ARGV.first))

$exit = false
$code = data["code"]
$color = data["color"]
$delay = data["delay"]
$message = data["message"]
$status = data["status"]
$title = data["title"]

$color = $color.rjust(6, "0").rjust(8, "F").to_i(16)

class UI
  # As this is not using BaseWindow, LVGUI::init isn't handled for us.
  LVGUI.init(assets_path: "boot-error/assets")

  def initialize()
    add_screen

    # First add the title bar, other elements will sit under.
    add_title_bar
    # Then, action pane, so we can get its height
    add_actions_pane
    # Finally, messages pane, which takes the remainder.
    add_messages_pane

    # Re-compute the layout
    relayout()
  end

  def add_screen()
    @screen = LVGL::LVContainer.new()

    # Create a new style
    style = @screen.get_style(LVGL::CONT_STYLE::MAIN).dup
    @screen.set_style(LVGL::CONT_STYLE::MAIN, style)

    style.body_main_color = $color
    style.body_grad_color = $color
  end

  def add_title_bar()
    @title_bar = LVGL::LVContainer.new(@screen)
    @title_bar.set_width(@screen.get_width())
    @title_bar.set_height(16*unit)
    @title_bar.set_pos(0, 0)

    @title_bar.get_style(LVGL::CONT_STYLE::MAIN).dup.tap do |style|
      @title_bar.set_style(LVGL::CONT_STYLE::MAIN, style)
      style.body_main_color = 0x00000000
      style.body_grad_color = 0x00000000
      style.body_border_width = 0
      style.body_radius = 0
      style.body_opa = (255 * 0.30).to_i
    end

    add_sad_phone
    add_title
  end

  def add_actions_pane()
    @actions_pane = LVGL::LVContainer.new(@screen)
    @actions_pane.set_width(get_pane_width())

    # When horizontal, we know it's placed to the right, full height.
    if horizontal?
      @actions_pane.set_height(@screen.get_height() - @title_bar.get_height())
      @actions_pane.set_pos(get_pane_width(), @title_bar.get_height())
    end

    @actions_pane.get_style(LVGL::CONT_STYLE::MAIN).dup.tap do |style|
      @actions_pane.set_style(LVGL::CONT_STYLE::MAIN, style)
      style.body_main_color = 0x00000000
      style.body_grad_color = 0x00000000
      style.body_border_width = 0
      style.body_radius = 0
      style.body_opa = (255 * 0.20).to_i
    end

    add_time_left
  end

  def add_messages_pane()
    @messages_pane = LVGL::LVContainer.new(@screen)
    @messages_pane.set_width(get_pane_width())
    @messages_pane.set_pos(0, @title_bar.get_height())

    # When horizontal, full height
    if horizontal?
      @messages_pane.set_height(@screen.get_height() - @title_bar.get_height())
    end

    @messages_pane.get_style(LVGL::CONT_STYLE::MAIN).dup.tap do |style|
      @messages_pane.set_style(LVGL::CONT_STYLE::MAIN, style)
      style.body_main_color = 0x00000000
      style.body_grad_color = 0x00000000
      style.body_border_width = 0
      style.body_radius = 0
      style.body_opa = (255 * 0).to_i
    end

    add_message_title
    add_message
  end

  # Title elements

  def add_sad_phone()
    @sad_phone = LVGL::LVImage.new(@screen)
    @sad_phone.set_src("#{LVGL::Hacks.get_asset_path("sad.svg")}?height=#{@title_bar.get_height - 2 * padding}")
    @sad_phone.set_pos(2 * padding, padding)
  end

  def add_title()
    @title = new_text($code, parent: @title_bar)
    @title.set_align(LVGL::LABEL_ALIGN::LEFT)
    @title.set_x(@sad_phone.get_x()*2 + @sad_phone.get_width())
    @title.set_y(@title_bar.get_height / 2 - @title.get_height / 2)
    @title.set_width(@title_bar.get_width() - @title.get_x())
  end

  # Messages pane elements

  def add_message_title()
    @message_title = new_text($title, parent: @messages_pane)
    @message_title.set_align(LVGL::LABEL_ALIGN::LEFT)
    @message_title.set_pos(
      padding,
      padding,
    )
  end

  def add_message()
    @message = new_text($message, parent: @messages_pane)
    @message.set_align(LVGL::LABEL_ALIGN::LEFT)
    @message.set_pos(
      padding,
      @message_title.get_height() + @message_title.get_y() + padding
    )
  end

  # Actions pane elements

  def add_time_left()
    @time_left = new_text("", parent: @actions_pane)
    set_time_left($delay)
    @time_left.set_x(@actions_pane.get_width / 2 - @time_left.get_width / 2)
    @time_left.set_y(padding)
  end

  def set_actions(actions)
    @action_buttons ||= []
    @action_buttons.each do |el|
      el.del()
    end

    y_position = @time_left.get_y() + @time_left.get_height() + padding()

    @action_buttons = actions.map do |action_pair|
      label, action = action_pair

      LVGUI::Button.new(@actions_pane).tap do |btn|
        LVGUI.focus_group.add_obj(btn)
        btn.glue_obj(true)
        btn.set_label(label)
        btn.set_y(y_position)
        btn.event_handler = ->(event) do
          case event
          when LVGL::EVENT::CLICKED
            action.call()
          end
        end

        # For the next item
        y_position = btn.get_y() + btn.get_height() + padding()
      end
    end

    relayout()
  end

  # Layout helpers

  def relayout()
    unless horizontal?
      @messages_pane.set_height(
        @screen.get_height() - @title_bar.get_height() - @actions_pane.get_height()
      )

      # The actions pane has to be as high as required in vertical mode.
      last_element =  @actions_pane.get_children.reduce do |a, b|
        if b
          a_end = a.get_y() + a.get_height() 
          b_end = b.get_y() + b.get_height() 
          if a_end > b_end
            a
          else
            b
          end
        else
          a
        end
      end

      @actions_pane.set_height(
        last_element.get_y() + last_element.get_height() + padding
      )

      # Always push it as far down as possible!
      @actions_pane.set_pos(0, @screen.get_height() - @actions_pane.get_height())
    end
  end

  # Misc. helpers

  # Creates a label with some useful defaults.
  def new_text(text, parent: nil)
    parent ||= @screen

    el = ShadedText.new(parent)
    el.set_long_mode(LVGL::LABEL_LONG::BREAK)
    el.set_align(LVGL::LABEL_ALIGN::CENTER)
    el.set_width((parent.get_width - 2*padding).to_i)
    el.set_text(text)
    el
  end

  # Updates the UI with the time left.
  def set_time_left(value)
    if value
      @time_left.set_text("#{value} seconds left before crashing.")
    else
      @time_left.set_text("Select an option:")
    end
  end

  def hide_actions()
    @actions_pane.set_opa_scale_enable(true)
    @actions_pane.set_opa_scale(0)
  end

  def get_pane_width()
    if horizontal?
      @screen.get_width() / 2
    else
      @screen.get_width()
    end
  end

  def unit()
    (if horizontal?
      @screen.get_height()
    else
      @screen.get_width()
    end) / 128
  end

  def padding()
    2 * unit
  end

  def horizontal?()
    @screen.get_height < @screen.get_width
  end
end

# Create the UI
$ui = UI.new

# Run tasks once to "realize" the UI.
LVGL::Hacks::LVTask.handle_tasks

def run(*cmd)
  $stderr.puts " $ " + cmd.join(" ")
  system(*cmd) unless LVGL::Introspection.simulator?
end

def cleanup_and_exit()
  $ui.hide_actions()

  # Ensure the next scheduled handle_tasks will run
  LVGL::Hacks::LVTask.handle_tasks
  sleep(0.1)

  # Refresh the UI one last time.
  LVGL::Hacks::LVTask.handle_tasks

  puts "Exiting error applet!"
  puts "exit(#{$status})"

  # Ensures console is flushed entirely.
  $stdout.flush()
  $stderr.flush()

  # Ensures all kernel work is done before it kernel panics at exit.
  sleep(0.1)

  # Exit, which will crash the kernel.
  exit $status
end

$ui.set_actions([[
  "Cancel time-out", ->() do
    $delay = nil
    $ui.set_time_left(nil)

    $ui.set_actions([
      ["Power off", ->() { run("poweroff") }],
      ["Kernel panic", ->() { $exit = true }],
      *(Hal::RebootModes.options),
    ])
  end
]])

start = Time.now
LVGUI.main_loop do
  if $delay
    elapsed = Time.now - start
    left = $delay - elapsed
    $ui.set_time_left(left.floor)

    if elapsed >= $delay
      $exit = true
    end
  end

  # We're using `$exit` as a flag to ensure we exit after all event handlers
  # have been completed.
  # This is because we will not be able to force a render of the UI during
  # an event handler.
  cleanup_and_exit() if $exit
end

# Handles outputing the error and, more importantly, flushing the output.
# When simply existing, the system might not flush the output due to the
# kernel panic.
rescue => e
  $stderr.puts("")
  $stderr.puts("Unexpected error in error handler:")
  $stderr.puts("")
  $stderr.puts(e.inspect)
  $stderr.puts("")

  $stdout.flush()
  $stderr.flush()

  sleep(1)
  exit 128
end
