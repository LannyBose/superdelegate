defmodule SuperdelegateTest do
  use ExUnit.Case
  doctest Superdelegate

  test "greets the world" do
    assert Superdelegate.hello() == :world
  end
end
