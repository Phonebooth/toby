defmodule Toby.App.Views.MenuBar do
  @moduledoc """
  Builds the menu bar for the application.
  """

  import Ratatouille.View
  import Ratatouille.Constants, only: [color: 1]

  def render(node, tab, width) do
    bar do
      label do
	case tab do
          :tables ->
		text(
		  color: color(:black),
		  background: color(:white),
		  content: String.pad_trailing("#{node} ([N]odes), Sort: ([S]ize|[M]emory",width)
		)
          :processes ->
		text(
		  color: color(:black),
		  background: color(:white),
		  content: String.pad_trailing("#{node} ([N]odes), Sort: ([R]eds|[M]emory Queue|[L]en)",width)
		)
          _ ->
		text(
		  color: color(:black),
		  background: color(:white),
		  content: String.pad_trailing("#{node} ([N]odes)",width)
		)
        end
      end
    end
  end
end
