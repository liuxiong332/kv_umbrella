defmodule KV.Registry do
  use GenServer

  # SERVER api

  @doc """
    start the registry.
  """
  def start_link(event_manager, options \\ []) do
    GenServer.start_link(__MODULE__, event_manager, options)
  end

  @doc """
    lookup in `registry` by `name.
    return {:ok, value} if `name` exists, otherwise :error
  """
  def lookup(registry, name) do
    GenServer.call(registry, {:lookup, name})
  end

  def stop(registry) do
    GenServer.call(registry, :stop)
  end

  @doc """
    create the new bucket
  """
  def create(registry, name) do
    GenServer.cast(registry, {:create, name})
  end

  # cLIENT api

  def init(event_manager) do
    names = HashDict.new
    refs = HashDict.new
    {:ok, %{names: names, refs: refs, events: event_manager}}
  end

  def handle_call({:lookup, name}, _from, state) do
    {:reply, HashDict.fetch(state.names, name), state}
  end

  def handle_cast({:create, name}, state) do
    if HashDict.has_key?(state.names, name) do
      {:noreply, state}
    else
      {:ok, bucket} = KV.Bucket.start_link
      ref = Process.monitor(bucket)
      names = HashDict.put(state.names, name, bucket)
      refs = HashDict.put(state.refs, ref, name)
      GenEvent.sync_notify(state.events, {:create, name, bucket})
      {:noreply, %{state | names: names, refs: refs}}
    end
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end

  def handle_info({:DOWN, ref, :process, pid, :normal}, state) do
     {name, refs} = HashDict.pop(state.refs, ref)
     names = HashDict.delete(state.names, name)
     GenEvent.sync_notify(state.events, {:exit, name, pid})
     {:noreply, %{state | names: names, refs: refs}}
  end
end
