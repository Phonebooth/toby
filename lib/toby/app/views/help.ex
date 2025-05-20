defmodule Toby.App.Views.Help do
  @moduledoc """
  Displays help information for toby.
  """

  import Ratatouille.View
  import Ratatouille.Constants, only: [attribute: 1]

  @bold attribute(:bold)

  def render(%{data: %{version: version}}) do
    row do
      column(size: 12) do
        label()
        label(content: "toby (#{version})", attributes: [@bold])
        label(content: "Source/Issues: https://github.com/ndreynolds/toby")
        label()
        label()
        label(content: "Keyboard Controls", attributes: [@bold])
        label()
        label(content: "Tabs / Panes")
        control_label("s", "System            (Summary of Erlang & BEAM stats)")
        control_label("o", "Load Charts       (Charts of system load)")
        control_label("m", "Memory Allocators (Charts of memory allocation)")
        control_label("a", "Applications      (Lists applications)")
        control_label("p", "Processes         (Lists processes)")
        control_label("t", "Tables            (Lists ETS/DETS/Mnesia tables)")
        control_label("n", "Nodes             (Shows Erlang node selection)")
        control_label("h ?", "Help              (Shows this help screen)")
        label()
        label(content: "Navigation / Actions")
        control_label("UP/DOWN j/k   ", "Scroll vertically")
        control_label("LEFT/RIGHT h/l", "Scroll horizontally (when supported)")
        control_label("/             ", "Search/filter content (when supported)")
        control_label("ESC           ", "Cancel/exit an overlay or action")
      end
    end
  end

  def control_label(keys, description) do
    label do
      text(attributes: [@bold], content: "  #{keys}")
      text(content: "   #{description}")
    end
  end
end
