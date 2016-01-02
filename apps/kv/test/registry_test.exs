defmodule KV.RegistryTest do
  use ExUnit.Case
  alias KV.Registry

  defmodule EventHandler do
    use GenEvent

    def handle_event(event, parent) do
      send(parent, event)
      {:ok, parent}
    end
  end

  defp start_registry(ets) do
    {:ok, events} = GenEvent.start_link
    GenEvent.add_mon_handler(events, EventHandler, self())
    {:ok, supervisor} = KV.Bucket.Supervisor.start_link
    {:ok, registry} = KV.Registry.start_link(events, supervisor, ets)
    registry
  end

  setup do
    ets = :ets.new(:registry_table, [:set, :public])
    registry = start_registry(ets)
    {:ok, registry: registry, ets: ets}
  end

  test "lookup and create bucket in registry", %{registry: registry} do
    assert Registry.lookup(registry, "name") == :error

    Registry.create(registry, "name")
    assert {:ok, _} = Registry.lookup(registry, "name")
  end

  test "terminate the bucket", %{registry: registry} do
    Registry.create(registry, "name")
    assert {:ok, bucket} = Registry.lookup(registry, "name")

    KV.Bucket.stop(bucket)
    assert :error = Registry.lookup(registry, "name")
  end

  test "test event handler", %{registry: registry} do
    Registry.create(registry, "name")
    assert {:ok, bucket} = Registry.lookup(registry, "name")
    assert_receive {:create, "name", ^bucket}

    KV.Bucket.stop(bucket)
    assert_receive {:exit, "name", ^bucket}
  end

  test "monitor the existing bucket", %{registry: registry, ets: ets} do
    Registry.create(registry, "name")
    assert {:ok, _} = Registry.lookup(registry, "name")

    Process.unlink(registry)
    Process.exit(registry, :shutdown)

    registry = start_registry(ets)
    assert {:ok, bucket} = Registry.lookup(registry, "name")

    Agent.stop(bucket)
    assert_receive {:exit, "name", ^bucket}
    assert :error = Registry.lookup(registry, "name")
  end
end
