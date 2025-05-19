defmodule Toby.Data.Samples do
  @moduledoc """
  Collects samples of the current VM state for later use in charts.
  """

  alias Toby.Data.Node

  def collect(node) do
    %{
      sampled_at: Node.monotonic_time(node),
      scheduler_utilization: Node.sample_schedulers(node),
      memory: Node.memory(node),
      io: Node.statistics(node, :io),
      allocation: Node.allocators(node)
    }
  end

  def historical_memory(samples) do
    memory_samples = for %{memory: memory} <- samples, do: memory

    for sample <- memory_samples do
      sample[:total] / :math.pow(1024, 2)
    end
  end

  def historical_io(samples) do
    io_samples = for %{io: io} <- samples, do: io

    for {{:input, input}, {:output, output}} <- io_samples do
      (input + output) / 1
    end
  end

  def historical_scheduler_utilization(samples) do
    case samples do
	[] -> []
	_ ->
	    util_samples = for %{scheduler_utilization: util} <- samples, do: util
	    for {sample, next_sample} <- Enum.zip(util_samples, Enum.drop(util_samples, 1)) do
	      [{:total, total, _} | rest] = :scheduler.utilization(sample, next_sample)

	      for {:normal, id, util, _} <- rest, into: %{total: total * 100} do
		{id, util * 100}
	      end
	    end
	end
  end

  def historical_allocation(samples) do
    for %{allocation: allocation} <- samples do
      for {type, data} <- allocation, into: %{} do
        {type, data[:carrier_size] / :math.pow(1024, 2)}
      end
    end
  end
end

#21:45:11.932 [error] Task #PID<0.227.0> started from #PID<0.213.0> terminating
#** (stop) exited in: GenServer.call(Toby.Data.Server, {:fetch, {:"dog_trainer@dog-qa-aws01", :load}}, 5000)
#    ** (EXIT) an exception was raised:
#        ** (FunctionClauseError) no function clause matching in :lists.zip/2
#            (stdlib) lists.erl:387: :lists.zip({:EXIT, {:undef, [{:scheduler, :sample, [], []}]}}, {:EXIT, {:undef, [{:scheduler, :sample, [], []}]}})
#            scheduler.erl:96: :scheduler.utilization/2
#            (toby) lib/toby/data/samples.ex:42: anonymous fn/2 in Toby.Data.Samples.historical_scheduler_utilization/1
#            (elixir) lib/enum.ex:1940: Enum."-reduce/3-lists^foldl/2-0-"/3
#            (toby) lib/toby/data/samples.ex:41: Toby.Data.Samples.historical_scheduler_utilization/1
#            (toby) lib/toby/data/provider.ex:61: Toby.Data.Provider.provide/2
#            (toby) lib/toby/data/server.ex:80: Toby.Data.Server.fetch_new/2 
#            (toby) lib/toby/data/server.ex:38: Toby.Data.Server.handle_call/3
#    (elixir) lib/gen_server.ex:989: GenServer.call/3
#    (toby) lib/toby/data/server.ex:22: Toby.Data.Server.fetch!/2
#    (ratatouille) lib/ratatouille/runtime.ex:214: anonymous fn/2 in Ratatouille.Runtime.process_command_async/1
#    (elixir) lib/task/supervised.ex:90: Task.Supervised.invoke_mfa/2
#    (stdlib) proc_lib.erl:249: :proc_lib.init_p_do_apply/3
#Function: #Function<2.132652128/0 in Ratatouille.Runtime.process_command_async/1>
#    Args: []
