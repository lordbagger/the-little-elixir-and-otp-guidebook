defmodule ThySupervisorTest do
  use ExUnit.Case
  doctest ThySupervisor

  test "it is started correctly" do
    {:ok, pid} = ThySupervisor.start_link([])
    assert is_pid(pid)
    assert {:links, [pid]} == Process.info(self(), :links)
  end
end
