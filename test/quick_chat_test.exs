defmodule QuickChatTest do
  use ExUnit.Case
  doctest QuickChat

  test "greets the world" do
    assert QuickChat.hello() == :world
  end
end
