defmodule QuickChat.Session do
  defstruct me: nil,
    peers: MapSet.new(),
    nonces: MapSet.new()
end
