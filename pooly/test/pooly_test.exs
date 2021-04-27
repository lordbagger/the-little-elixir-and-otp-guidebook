defmodule PoolyTest do
  use ExUnit.Case
  doctest Pooly

  test "starts with 5 workers in the pool" do
    assert Pooly.status() == {5, 0}
  end
end
