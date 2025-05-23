defmodule Toby.App.Views.Processes do
  @moduledoc """
  Builds a view for displaying information about processes
  """

  import Ratatouille.Constants, only: [attribute: 1, color: 1]
  import Ratatouille.View

  import Toby.Util.Formatting, only: [format_func: 1, left_pad: 2]

  alias Toby.App.Views.{Links, Monitors}
  alias Toby.Util.Selection

  @style_header [
    attributes: [attribute(:bold)]
  ]

  @style_selected [
    color: color(:black),
    background: color(:white)
  ]

  # The number of rows that make up the application and table frame, used to
  # calculate the number of displayable rows.
  #
  # TODO: Currently ratatouille does not expose the rendered size of an element
  # (this is internal to the rendering engine), but we'd need to expose the box
  # model in order to calculate this dynamically.
  @frame_rows 7

  def render(%{filtered: processes, cursor_x: cursor_x, cursor_y: cursor_y, sort_column: sort_column}, window) do
    processes_sorted = Enum.sort_by(processes, fn(r) -> r[sort_column] end, &>=/2)
    processes_slice =
      Selection.slice(processes_sorted, window.height - @frame_rows, cursor_y.position)

    selected = Enum.at(processes_sorted, cursor_y.position)

    row do
      column(size: 8) do
        panel(title: "Processes", height: :fill) do
          viewport(offset_x: cursor_x.position) do
            table do
              table_row(@style_header) do
                table_cell(content: "PID")
                table_cell(content: "Name or Initial Func")
                table_cell(content: left_pad("Reds",6))
                table_cell(content: left_pad("Memory",4))
                table_cell(content: left_pad("MsgQ",6))
                table_cell(content: "Current Function")
              end

              for proc <- processes_slice do
                table_row(if(proc == selected, do: @style_selected, else: [])) do
                  table_cell(content: inspect(proc.pid))
                  table_cell(content: name_or_initial_func(proc))
                  table_cell(content: left_pad(to_string(proc[:reductions]), 10))
                  table_cell(content: left_pad(inspect(proc[:memory]), 8))
                  table_cell(content: left_pad(to_string(proc[:message_queue_len]), 5))
                  table_cell(content: format_func(proc[:current_function]))
                end
              end
            end
          end
        end
      end

      column(size: 4) do
        process_details(selected)
      end
    end
  end

  def process_details(%{pid: pid} = process) do
    title = inspect(pid) <> " " <> name_or_initial_func(process)

    panel(title: title, height: :fill) do
      table do
        table_row do
          table_cell(content: "Initial Call")
          table_cell(content: format_func(process[:initial_call]))
        end

        table_row do
          table_cell(content: "Current Function")
          table_cell(content: format_func(process[:current_function]))
        end

        table_row do
          table_cell(content: "Registered Name")
          table_cell(content: to_string(process[:registered_name]))
        end

        table_row do
          table_cell(content: "Status")
          table_cell(content: to_string(process[:status]))
        end

        table_row do
          table_cell(content: "Message Queue Len")
          table_cell(content: to_string(process[:message_queue_len]))
        end

        table_row do
          table_cell(content: "Group Leader")
          table_cell(content: inspect(process[:group_leader]))
        end

        table_row do
          table_cell(content: "Priority")
          table_cell(content: to_string(process[:priority]))
        end

        table_row do
          table_cell(content: "Trap Exit")
          table_cell(content: to_string(process[:trap_exit]))
        end

        table_row do
          table_cell(content: "Reductions")
          table_cell(content: to_string(process[:reductions]))
        end

        table_row do
          table_cell(content: "Error Handler")
          table_cell(content: to_string(process[:error_handler]))
        end

        table_row do
          table_cell(content: "Trace")
          table_cell(content: to_string(process[:trace]))
        end
      end

      label(content: "")
      Links.render(process.links)
      Monitors.render(process.monitors, process.monitored_by)
    end
  end

  def process_details(nil) do
    panel(title: "(None selected)", height: :fill)
  end

  defp name_or_initial_func(process) do
    case process do
      %{registered_name: name} when not is_nil(name) ->
        to_string(name)

      %{initial_call: call} when not is_nil(call) ->
        format_func(call)

      %{pid: pid} ->
        inspect(pid)
    end
  end
end
