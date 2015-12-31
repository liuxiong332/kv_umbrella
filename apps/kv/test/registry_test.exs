defmodule KV.RegistryTest do
  use ExUnit.Case, async: true
  alias KV.Registry

  setup do
    {:ok, registry} = KV.Registry.start_link
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
end
