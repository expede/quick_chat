defmodule QuickChat.Server do
  use GenServer

  @doc """
  Set up GenServer

  ... more text

  """
  def init([owner]) do
    log(nil, Node.self(), "🔌", :green)
    {:ok, {owner, MapSet.new(), MapSet.new()}}
  end

  @doc """
  Synchronous actions specified by the `GenServer.handle_call/3` callback

  * `{:broadcast, text}` - Send all peers text
  * `{:send_dm, text}` - Send text to one peer only
  * `:list_peers` - Return a list of all currently-known peers

  """
  def handle_call({:broadcast, text}, {from, _}, {owner, nonces, peers}) when from == owner do
    log(text, "Me", "😎", :yellow)

    new_nonce = nonce()
    forward(peers, {:msg, me(), new_nonce, text})

    {:reply, :ok, {owner, MapSet.put(nonces, new_nonce), peers}}
  end

  def handle_call({:send_dm, to, text}, {from, _}, {owner, nonces, peers}) when from == owner do
    log(text, "Me (to #{to})", "🙈", :yellow)

    new_nonce = nonce()
    GenServer.cast(address(to), {:dm, me(), new_nonce, text})

    unless MapSet.member?(peers, to) do
      GenServer.cast(address(to), {:add_peers, peers})
      forward(peers, {:newcomer, to})
    end

    {:reply, :ok, {owner, MapSet.put(nonces, new_nonce), MapSet.put(peers, to)}}
  end

  def handle_call(:list_peers, _from, {_, _, peers} = session) do
    {:reply, MapSet.to_list(peers), session}
  end

  @doc """
  Asynchronous

  ... more text

  """
  def handle_cast({:newcomer, newcomer}, {owner, _, _} = session) when newcomer == owner do
    {:noreply, session}
  end

  def handle_cast({:newcomer, newcomer} = payload, {owner, nonces, peers} = session) do
    if MapSet.member?(peers, newcomer) do
      {:noreply, session}
    else
      log("#{newcomer} has joined", "Alert", "👋🏻", :green)

      GenServer.cast(address(newcomer), {:add_peers, peers})
      forward(peers, payload)

      {:noreply, {owner, nonces, MapSet.put(peers, newcomer)}}
    end
  end

  def handle_cast({:add_peers, external}, {owner, nonces, internal} = session) do
    external
    |> MapSet.difference(internal)
    |> MapSet.size()
    |> case do
      0 ->
        {:noreply, session}

      count ->
        log("Attached to #{count} new peer(s)", "Alert", "👋🏻", :green)

        {:noreply, {owner, nonces, MapSet.union(internal, external)}}
    end
  end

  def handle_cast({:msg, peer, nonce, text} = msg, {owner, nonces, peers} = session) do
    if MapSet.member?(nonces, nonce) do
      {:noreply, session}
    else
      log(text, peer, "😁")
      forward(peers, msg)
      {:noreply, {owner, MapSet.put(nonces, nonce), peers}}
    end
  end

  def handle_cast({:dm, sender, nonce, text}, {owner, nonces, peers} = session) do
    unless MapSet.member?(nonces, nonce), do: log(text, sender, "🙈", :blue)
    handle_cast({:newcomer, sender}, session)
  end

  # ======= #
  # Helpers #
  # ======= #

  @spec me() :: String.t()
  def me, do: to_string(node())

  @spec address(atom() | String.t()) :: {:chat, atom()}
  def address(room) when is_bitstring(room), do: room |> String.to_atom() |> address()
  def address(room), do: {:chat, room}

  @spec log(String.t(), String.t(), String.t(), atom()) :: :ok
  def log(text, sender, icon, colour \\ :white) do
    [colour, "#{icon} #{sender}\n#{text}\n"]
    |> IO.ANSI.format(true)
    |> IO.puts()
  end

  @spec nonce() :: String.t()
  def nonce, do: :crypto.strong_rand_bytes(8)

  @spec forward([String.t() | atom(), any()]) :: :ok
  def forward(peers, payload) do
    Enum.each(peers, fn peer ->
      peer
      |> address()
      |> GenServer.cast(payload)
    end)
  end
end
