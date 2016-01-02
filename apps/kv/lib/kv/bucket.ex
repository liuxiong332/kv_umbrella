defmodule KV.Bucket do
  @doc """
    start a new bucket instance
  """
  def start_link(options \\ []) do
    Agent.start_link(fn -> HashDict.new end, options)
  end

  @doc """
    put a new key-value into the `bucket`
  """
  def put(bucket, key, value) do
    Agent.update(bucket, &(Dict.put(&1, key, value)))
  end

  @doc """
    get the value by `key` in the `bucket`
  """
  def get(bucket, key) do
    Agent.get(bucket, &(Dict.get(&1, key)))
  end

  @doc """
    delete `key` in the `bucket`
  """
  def delete(bucket, key) do
    Agent.get_and_update(bucket, &(HashDict.pop(&1, key)))
  end

  @doc """
    stop the bucket instance
  """
  def stop(agent) do
    Agent.stop(agent)
  end
end
