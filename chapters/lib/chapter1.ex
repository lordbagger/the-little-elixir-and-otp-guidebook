defmodule Chapter1 do
  def sum(numbers) when is_list(numbers), do: List.foldl(numbers, 0, fn numbers, acc -> numbers + acc end)

  def with_pipe(list) when is_list(list), do: list |> List.flatten |> Enum.reverse |> Enum.map(fn elem -> elem * elem end)

  def without_pipe(list) when is_list(list) do
    Enum.map(Enum.reverse(List.flatten(list)), fn elem -> elem * elem end)
  end
end
