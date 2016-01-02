defmodule KV.Registry do
  use GenServer

  # SERVER api

  @doc """
    start the registry.
  """
  def start_link(event_manager, buckets, table, options \\ []) do
    IO.puts inspect(table)
    GenServer.start_link(__MODULE__, {event_manager, buckets, table}, options)
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

  def init({event_manager, buckets, table}) do
    refs = HashDict.new
    ets = :ets.new(table, [:named_table, read_concurrency: true])
    {:ok, %{refs: refs, events: event_manager, buckets: buckets, ets: ets}}
  end

  def handle_call({:lookup, name}, _from, state) do
    case :ets.lookup(state.ets, name) do
      [{^name, bucket}] -> {:reply, {:ok, bucket}, state}
      [] -> {:reply, :error, state}
    end
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end

  def handle_cast({:create, name}, state) do
    case :ets.lookup(state.ets, name) do
      [{^name, _}] -> {:noreply, state}
      [] ->
        {:ok, bucket} = KV.Bucket.Supervisor.start_bucket state.buckets
        ref = Process.monitor(bucket)
        :ets.insert(state.ets, {name, bucket})
        refs = HashDict.put(state.refs, ref, name)
        GenEvent.sync_notify(state.events, {:create, name, bucket})
        {:noreply, %{state | refs: refs}}
    end
  end

  def handle_info({:DOWN, ref, :process, pid, :normal}, state) do
     {name, refs} = HashDict.pop(state.refs, ref)
     :ets.delete(state.ets, name)
     GenEvent.sync_notify(state.events, {:exit, name, pid})
     {:noreply, %{state | refs: refs}}
  end
end
