defmodule Blitzy do
  def run(n_workers, url) do
    func = fn -> Blitzy.Worker.start(url) end

    1..n_workers
    |> Enum.map(fn _ -> Task.async(func) end)
    |> Enum.map(&Task.await(&1))
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
