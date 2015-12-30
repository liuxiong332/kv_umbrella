defmodule KV.BucketTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, bucket} = KV.Bucket.start_link
    {:ok, bucket: bucket}
  end

  test "get and put value", %{bucket: bucket} do
    assert KV.Bucket.get(bucket, "key") == nil
  end
end
