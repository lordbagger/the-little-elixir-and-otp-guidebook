defmodule PoolyTest do
  use ExUnit.Case
  doctest Pooly

  test "starts with 5 workers in the pool" do
    assert Pooly.status("Pool1") == {2, 0}
    assert Pooly.status("Pool2") == {3, 0}
    assert Pooly.status("Pool3") == {4, 0}
  end
end
