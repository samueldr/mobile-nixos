module GUI
  class LogsWindow < BaseLogWindow
    LOG_LINES = 200

    def initialize()
      super(explanation: "Showing the last #{LOG_LINES} lines from journald")
    end

    def on_present()
      set_text(`journalctl -b0 -n #{LOG_LINES}`)
    end
  end
end
