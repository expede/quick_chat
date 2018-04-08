defmodule QuickChat do
  @moduledoc """
  A simple GenServer chat demo.

  This module contains the primary CLI for the application.

  ## Examples

  An example session looks something like this:

      iex> start()
      🔌 willow@10.0.1.4
      {:ok, #PID<0.118.0>}

      iex> dm "buffy@10.0.1.4", "hi"
      🙈 Me (to buffy@10.0.1.4)
      hi

      👋🏻 Alert
      Attached to 1 new peer(s)
      :ok

      iex> peers
      ["bufft@10.0.1.4", "xander@10.0.1.4"]
  """

  @doc "Set up a QuickChat server"
  @spec start() :: GenServer.on_start()
  def start(), do: GenServer.start(QuickChat.Server, [self()], name: :chat)

  @doc "Set up a linked QuickChat server"
  @spec start_link() :: GenServer.on_start()
  def start_link(), do: GenServer.start_link(QuickChat.Server, [self()], name: :chat)

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
