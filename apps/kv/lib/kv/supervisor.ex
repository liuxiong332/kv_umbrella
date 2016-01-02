defmodule KV.Supervisor do
  use Supervisor

  @event_name GenEvent
  @bucket_sup_name KV.Bucket.Supervisor
  @registry_name KV.Registry
  @ets_registry_name KV.Registry

  def start_link(options \\ []) do
    Supervisor.start_link(__MODULE__, :ok, options)
  end

  def init(:ok) do
    ets = :ets.new(@ets_registry_name, [:set, :public, :named_table, read_concurrency: true])

    children = [
      worker(GenEvent, [[name: @event_name]]),
      supervisor(KV.Bucket.Supervisor, [[name: @bucket_sup_name]]),
      worker(KV.Registry, [@event_name, @bucket_sup_name, ets, [name: @registry_name]])
    ]
    supervise(children, strategy: :one_for_one)
  end
end
