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

  setup do
    {:ok, events} = GenEvent.start_link
    GenEvent.add_mon_handler(events, EventHandler, self())
    {:ok, supervisor} = KV.Bucket.Supervisor.start_link
    {:ok, registry} = KV.Registry.start_link(events, supervisor, :registry_table)
    {:ok, registry: registry}
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
end
