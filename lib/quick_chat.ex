defmodule QuickChat do
  @doc "Set up"
  def start(), do: GenServer.start(QuickChat.Server, [self()], name: :chat)

  @doc "Get all of your registered peers"
  def peers(), do: GenServer.call(:chat, :list_peers)

  @doc "Send a public message"
  def msg(text), do: GenServer.call(:chat, {:broadcast, text})

  @doc """
  Send a direct message

  Also doubles as a connection to the network. If you DM a user that doesn't know
  about you, it will broadcast your node's address to the rest of the network.
  """
  def dm(to, text), do: GenServer.call(:chat, {:send_dm, to, text})
end
