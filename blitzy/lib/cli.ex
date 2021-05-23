defmodule Blitzy.CLI do
  alias Blitzy.TasksSupervisor
  require Logger

  def main(args) do
    Application.get_env(:blitzy, :master_node)
    |> Node.start()

    Application.get_env(:blitzy, :slave_nodes)
    |> Enum.each(&Node.connect(&1))

    args |> parse_args |> process_options([node() | Node.list()])
  end

  defp parse_args(args) do
    OptionParser.parse(args, aliases: [n: :requests], strict: [requests: :integer])
  end

  defp process_options(options, nodes) do
    case options do
      {[requests: n], [url], []} ->
        do_requests(n, url, nodes)

      _ ->
        do_help()
    end
  end

  defp do_help do
    IO.puts("""
    Usage:
    blitzy -n [requests] [url]
    Options:
    -n, [--requests]      # Number of requests
    Example:
    ./blitzy -n 100 http://www.bieberfever.com
    """)

    System.halt(0)
  end

  defp do_requests(n, url, nodes) do
    Logger.info("Pummeling #{url} with #{n} requests")

    total_nodes = Enum.count(nodes)
    req_per_node = div(n, total_nodes)

    nodes
    |> Enum.flat_map(fn node ->
      1..req_per_node
      |> Enum.map(fn _ ->
        Task.Supervisor.async({TasksSupervisor, node}, Blitzy.Worker, :start, [url])
      end)
    end)
    |> Enum.map(&Task.await(&1, :infinity))
    |> parse_results
  end

  defp parse_results(results) do
    {successes, _failures} =
      results
      |> Enum.split_with(fn r ->
        {
          case r do
            {:ok, _} -> true
            _ -> false
          end
        }
      end)

    total_workers = Enum.count(results)
    total_success = Enum.count(successes)
    total_failure = total_workers - total_success

    data = successes |> Enum.map(fn {:ok, time} -> time end)
    shortest_time = Enum.min(data)
    longest_time = Enum.max(data)

    average_time = calculate_average(data)

    IO.puts("""
    Total workers    : #{total_workers}
    Successful reqs  : #{total_success}
    Failed res       : #{total_failure}
    Average (msecs)  : #{average_time}
    Longest (msecs)  : #{longest_time}
    Shortest (msecs) : #{shortest_time}
    """)
  end

  defp calculate_average(data) do
    sum = Enum.sum(data)

    if sum > 0 do
      sum / Enum.count(data)
    else
      0
    end
  end
end
