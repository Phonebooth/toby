defmodule Toby.App.Views.StatusBar do
  @moduledoc """
  A component that displays the status bar for navigation between views.
  """

  import Ratatouille.View
  import Ratatouille.Constants, only: [attribute: 1]

  @tabs [
    {:system, "[s]ystem"},
    {:load, "L[o]ad Charts"},
    {:memory, "[m]emory Allocators"},
    {:applications, "[a]pplications"},
    {:processes, "[p]rocesses"},
    {:ports, "Po[r]ts"},
    {:tables, "[t]ables"},
    {:help, "[?]"}
  ]

  @style_selected [
    attributes: [attribute(:bold)]
  ]

  def render(selected_tab, search) do
    bar do
      if search.focused do
        label do
          text(attributes: [attribute(:bold)], content: "Search: ")
          text(content: search.query)
        end
      else
        label do
          render_tabs(selected_tab)
        end
      end
    end
  end

  defp render_tabs(selected) do
    rendered_options =
      for {key, label} <- @tabs do
        if key == selected do
          text(@style_selected ++ [content: label])
        else
          text(content: label)
        end
      end

    Enum.intersperse(rendered_options, text(content: " "))
  end
end
