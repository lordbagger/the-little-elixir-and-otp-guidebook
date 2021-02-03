defmodule Chapter2 do
  def sum(numbers) when is_list(numbers), do: List.foldl(numbers, 0, fn numbers, acc -> numbers + acc end)

  #flattens a list, reverses the order of the elements and returns the squares
  def transform_with_pipe(list) when is_list(list), do: list |> List.flatten |> Enum.reverse |> Enum.map(fn elem -> elem * elem end)

  #same thing as above, but without the 'pipe' operator
  def transform_without_pipe(list) when is_list(list) do
    Enum.map(Enum.reverse(List.flatten(list)), fn elem -> elem * elem end)
  end
end
