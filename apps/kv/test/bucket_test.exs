defmodule KV.BucketTest do
  use ExUnit.Case, async: true
  alias KV.Bucket

  setup do
    {:ok, bucket} = KV.Bucket.start_link
    {:ok, bucket: bucket}
  end

  test "get and put value", %{bucket: bucket} do
    assert Bucket.get(bucket, "key") == nil

    Bucket.put(bucket, "key", "value")
    assert Bucket.get(bucket, "key") == "value"

    Bucket.delete(bucket, "key")
    assert Bucket.get(bucket, "key") == nil
  end
end
