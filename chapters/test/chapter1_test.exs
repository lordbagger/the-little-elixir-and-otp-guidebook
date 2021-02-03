defmodule Chapter1Test do
  use ExUnit.Case

  test "sums all numbers from a list" do
    assert Chapter1.sum([1, 2, 3]) == 6
  end

  test "flattens a list, reverses and returns the squares for each element (with pipe operator)" do
    assert Chapter1.with_pipe([1, [2, [3]]]) == [9, 4, 1]
  end

  test "flattens a list, reverses and returns the squares for each element (without pipe operator)" do
    assert Chapter1.without_pipe([1, [2, [3]]]) == [9, 4, 1]
  end

  test "with_pipe and without_pipe functions return the same results" do
    assert Chapter1.without_pipe([1, [2, [3]]]) == Chapter1.with_pipe([1, 2, 3])
  end
end
