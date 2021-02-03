defmodule ChaptersTest do
  use ExUnit.Case
  doctest Chapters

  test "greets the world" do
    assert Chapters.hello() == :world
  end
end
