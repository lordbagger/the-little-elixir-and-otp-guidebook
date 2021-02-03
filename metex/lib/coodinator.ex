defmodule Metex.Coordinator do

  def loop(results \\ [], expected_results) do
    receive do
      {:ok, result} ->
        new_results = [result|results]
        if expected_results == Enum.count(new_results) do
          send self(), :exit
        end
        loop(new_results, expected_results)
      :exit ->
        IO.puts(results |> Enum.sort |> Enum.join(", "))
      _ ->
        loop(results, expected_results)
    end
  end
end
