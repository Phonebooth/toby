defmodule Toby.App do
  @moduledoc """
  The main application.
  """

  @behaviour Ratatouille.App
  require Logger

  alias Ratatouille.Runtime.{Command, Subscription}

  alias Toby.App.Update

  alias Toby.App.Views.{
    Applications,
    Help,
    Load,
    Memory,
    MenuBar,
    NodeSelect,
    Ports,
    Processes,
    StatusBar,
    System,
    Tables
  }

  import Ratatouille.View
  import Ratatouille.Constants, only: [key: 1]

  @arrow_up key(:arrow_up)
  @arrow_down key(:arrow_down)
  @arrow_left key(:arrow_left)
  @arrow_right key(:arrow_right)

  @tab_keymap %{
    ?s => :system,
    ?o => :load,
    ?m => :memory,
    ?a => :applications,
    ?p => :processes,
    ?r => :ports,
    ?t => :tables,
    ?? => :help,
    ?H => :help
  }
  @tab_keys Map.keys(@tab_keymap)

  @init_cursor %{position: 0, size: 0, continuous: true}

  #until I figure out why logger crashes
  def filewriter(filename, data) do
	  File.open(filename, [:append]) 
	  |> elem(1) 
	  |> IO.binwrite(data)
          |> IO.binwrite("\n") 
  end

  @impl true
  def init(%{window: window}) do
    model = %{
      selected_tab: :system,
      selected_node: Node.self(),
      overlay: nil,
      tabs: %{
        system: %{data: :not_loaded},
        load: %{data: :not_loaded, cursor_y: @init_cursor},
        memory: %{data: :not_loaded, cursor_y: @init_cursor},
        applications: %{
          data: :not_loaded,
          cursors_y: [@init_cursor, @init_cursor],
          cursor_x: %{@init_cursor | size: 2, continuous: false}
        },
        processes: %{
          data: :not_loaded,
          cursor_x: %{@init_cursor | size: 30, continuous: false},
          cursor_y: @init_cursor,
          sort_column: :reductions
        },
        ports: %{
          data: :not_loaded,
          cursor_x: %{@init_cursor | size: 30, continuous: false},
          cursor_y: @init_cursor
        },
        tables: %{
          data: :not_loaded,
          cursor_x: %{@init_cursor | size: 30, continuous: false},
          cursor_y: @init_cursor,
          sort_column: :size
        },
        help: %{data: :not_loaded}
      },
      node: %{data: :not_loaded, cursor_y: @init_cursor},
      search: %{
        focused: false,
        query: ""
      },
      window: window
    }

    {model,
     Command.batch([
       Update.request_refresh(model, model.selected_tab),
       Update.request_refresh(model, :node)
     ])}
  end

  @impl true
  def update(model, msg) do
    case {model, msg} do
      ## Search:

      {_, {:event, %{ch: ?/}}} ->
        Update.focus_search(model)

      {%{search: %{focused: true}}, {:event, event}} ->
        Update.search(model, event)

      ## Show or act on an overlay:

      {_, {:event, %{ch: ch}}} when ch in [?n, ?N] ->
        Update.show_overlay(model, :node_selection)

      {%{overlay: overlay}, {:event, event}} when not is_nil(overlay) ->
        Update.overlay_action(model, event)

      ## Change the selected tab:

      {_, {:event, %{ch: ch}}} when ch in @tab_keys ->
        Update.select_tab(model, @tab_keymap[ch])

      ## Process sorting:

      {%{selected_tab: :processes}, {:event, %{ch: ch}}} when ch == ?R ->
        Update.update_sort(model, [:tabs, :processes, :sort_column], :reductions)
      
      {%{selected_tab: :processes}, {:event, %{ch: ch}}} when ch == ?M ->
        Update.update_sort(model, [:tabs, :processes, :sort_column], :memory)

      {%{selected_tab: :processes}, {:event, %{ch: ch}}} when ch == ?L ->
        Update.update_sort(model, [:tabs, :processes, :sort_column], :message_queue_len)
      
      ## Tables sorting:

      {%{selected_tab: :tables}, {:event, %{ch: ch}}} when ch == ?S ->
        Update.update_sort(model, [:tabs, :tables, :sort_column], :size)
      
      {%{selected_tab: :tables}, {:event, %{ch: ch}}} when ch == ?M ->
        Update.update_sort(model, [:tabs, :tables, :sort_column], :memory)

      ## Move the active cursor:

      {_, {:event, %{ch: ch, key: key}}} when ch == ?j or key == @arrow_down ->
        Update.move_cursor(model, [:tabs, model.selected_tab, :cursor_y], :next)

      {_, {:event, %{ch: ch, key: key}}} when ch == ?k or key == @arrow_up ->
        Update.move_cursor(model, [:tabs, model.selected_tab, :cursor_y], :prev)

      {_, {:event, %{ch: ch, key: key}}} when ch == ?h or key == @arrow_left ->
        Update.move_cursor(model, [:tabs, model.selected_tab, :cursor_x], :prev)

      {_, {:event, %{ch: ch, key: key}}} when ch == ?l or key == @arrow_right ->
        Update.move_cursor(model, [:tabs, model.selected_tab, :cursor_x], :next)

      ## Update the window in response to resize:

      {_, {:resize, event}} ->
        Update.resize(model, event)

      ## Handle tick:

      {_, :tick} ->
        {model,
         Command.batch([
           Update.request_refresh(model, model.selected_tab),
           Update.request_refresh(model, :node)
         ])}

      {_, {{:refreshed, key}, data}} ->
        Update.refresh(model, key, data)

      ## Unhandled events (no update):

      _ ->
        model
    end
  end

  @impl true
  def subscribe(_model) do
    Subscription.interval(1_000, :tick)
  end

  @impl true
  def render(model) do
    menu_bar = MenuBar.render(model.selected_node, model.selected_tab, model.window.width)
    status_bar = StatusBar.render(model.selected_tab, model.search)
    tab_loaded? = model.tabs[model.selected_tab].data != :not_loaded

    view(top_bar: menu_bar, bottom_bar: status_bar) do
      if tab_loaded? do
        tab_view(model)
      else
        label(content: "Loading...")
      end

      overlay_view(model)
    end
  end

  def tab_view(model) do
    case model.selected_tab do
      :system ->
        System.render(model.tabs.system)

      :load ->
        Load.render(model.tabs.load)

      :memory ->
        Memory.render(model.tabs.memory)

      :applications ->
        Applications.render(model.tabs.applications)

      :processes ->
        Processes.render(model.tabs.processes, model.window)

      :ports ->
        Ports.render(model.tabs.ports, model.window)

      :tables ->
        Tables.render(model.tabs.tables, model.window)

      :help ->
        Help.render(model.tabs.help)
    end
  end

  def overlay_view(%{overlay: :node_selection, node: node}) do
    overlay(padding: 10) do
      NodeSelect.render(node)
    end
  end

  def overlay_view(_other), do: nil
end
