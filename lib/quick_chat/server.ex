defmodule QuickChat.Server do
  use GenServer

  # ===== #
  # Setup #
  # ===== #

  def init() do
    room = Node.self()
    log("Registered as #{name} in room #{room}", "#{name} in #{room}", "🔌", :green)

    {:ok, %QuickChat.Session{me: {name, room}}}
  end

  def handle_info(unknown, status) do
    log("Unknown message received: #{unknown}", "SYSTEM", "❗", :red)
    {:noreply, status}
  end

  # ==== #
  # Sync #
  # ==== #

  def handle_call({:broadcast, text}, from, %{me: {name, room}, nonces: nonces, peers: peers} = state) when from == self() do
    log(text, "Me", "😃", :yellow)

    new_nonce = nonce()
    forward(peers, {:msg, name, room, new_nonce, text}) # Broadcast to friends

    {
      :noreply,
      %{state | nonces: MapSet.put(nonces, new_nonce)}
    }
  end

  def handle_call({:send_dm, to, text}, from, %{me: {name, room}, nonces: nonces} = state) when from == self() do
    new_nonce = nonce()
    GenServer.cast(to, {:msg, {name, room, new_nonce, text}}) # Broadcast to friends

    {
      :noreply,
      %{state | nonces: MapSet.put(nonces, new_nonce)}
    }
  end

  def handle_call(:list_peers, %{peers: peers} = state), do: {:reply, peers, state}

  # ===== #
  # Async #
  # ===== #

  def handle_cast({:newcomer, name, room} = payload, %{me: me, peers: peers} = state) do
    newcomer = {name, room}

    if newcomer == me or MapSet.member?(peers, newcomer) do
      {:noreply, state}
    else
      log("#{name} joined from #{room}", "Alert", "👋🏻", :green)

      GenServer.cast(newcomer, {:peers, peers}) # Send newcomer list of all known peers

      forward(peers, payload) # Broadcast to friends

      {
        :noreply,
        %{state | peers: MapSet.put(peers, {name, room})}
      }
    end
  end

  # incoming peer addresses
  def handle_cast({:peers, external}, %{peers: internal} = state) do
    {
      :noreply,
      %{state | peers: MapSet.merge(external, internal)}
    }
  end

  def handle_cast({:msg, name, room, nonce, text} = msg, %{nonces: nonces, peers: peers} = state) do
    if MapSet.member?(nonces, nonce) do
      {:noreply, state}
    else
      log(text, name, "🗣")
      forward(peers, msg)

      {
        :noreply,
        %{state | peers: MapSet.put(peers, {name, room})}
      }
    end
  end

  def handle_cast({:dm, name, room, nonce, text}, %{nonces: nonces, peers: peers} = state) do
    unless MapSet.member?(nonces, nonce), do: log(name, text, "🙈", :blue)

    {
      :noreply,
      %{state | peers: MapSet.put(peers, {name, room})}
    }
  end

  # ======= #
  # Helpers #
  # ======= #

  def log(text, sender, icon, colour \\ :white) do
    IO.puts("---")
    IO.puts("#{icon} #{sender}")

    text
    |> colorize(colour)
    |> IO.puts()
  end

  def colorize(text, colour), do: IO.ANSI.format([colour, text], true)

  def nonce, do: :crypto.strong_rand_bytes(8)

  def forward(peers, payload) do
    Enum.each(peers, fn(peer) ->
      GenServer.cast(peer, payload)
    end)
  end
end
