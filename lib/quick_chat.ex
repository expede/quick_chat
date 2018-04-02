defmodule QuickChat do
  @doc "Set up"
  def connect(), do: GenServer.start_link(QuickChat.Server, :quick_chat)

  @doc "Send a public message"
  def msg(me, text), do: GenServer.call(me, {:broadcast, text})

  @doc "Send a direct message"
  def dm(me, to, text), do: GenServer.call(me, {:send_dm, to, text})

  @doc "Get all of your registered peers"
  def peers(me), do: GenServer.call(me, :list_peers)
end
