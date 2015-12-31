defmodule KV.Registry do
  use GenServer

  # SERVER api

  @doc """
    start the registry.
  """
  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, :ok, options)
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

  def init(:ok) do
    names = HashDict.new
    refs = HashDict.new
    {:ok, {names, refs}}
  end

  def handle_call({:lookup, name}, _from, {dict, refs}) do
    {:reply, HashDict.fetch(dict, name), {dict, refs}}
  end

  def handle_cast({:create, name}, {dict, refs}) do
    if HashDict.has_key?(dict, name) do
      {:noreply, {dict, refs}}
    else
      {:ok, bucket} = KV.Bucket.start_link
      ref = Process.monitor(bucket)
      names = HashDict.put(dict, name, bucket)
      refs = HashDict.put(refs, ref, name)
      {:noreply, {names, refs}}
    end
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end

  def handle_info({:DOWN, ref, :process, pid, :normal}, {names, refs}) do
     {name, refs} = HashDict.pop(refs, ref)
     names = HashDict.delete(names, name)
     {:noreply, {names, refs}}
  end
end
