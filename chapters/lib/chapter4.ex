defmodule Cache do

  use GenServer

  @name Cache

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts ++  [name: Cache])
  end

  def write(key, value) do
    GenServer.call(@name, {:write, key, value})
  end

  def read(key) do
    GenServer.call(@name, {:read, key})
  end

  def exist?(key) do
    GenServer.call(@name, {:exist, key})
  end

  def delete(key) do
    GenServer.cast(@name, {:delete, key})
  end

  def clear do
    GenServer.cast(@name, :clear)
  end

  def stop do
    GenServer.cast(@name, :stop)
  end

  def init(:ok) do
    {:ok, %{}}
  end

  def handle_call({:write, key, value}, _from, stats) do
    new_stats = update_stats(key, value, stats)
    {:reply, new_stats, new_stats}
  end

  def handle_call({:read, key}, _from, stats) do
    {:reply, Map.get(stats, key), stats}
  end

  def handle_call({:exist, key}, _from, stats) do
    {:reply, Map.has_key?(stats, key), stats}
  end

  def handle_cast({:delete, key}, stats) do
    new_stats = delete(stats, key)
    {:noreply, new_stats}
  end

  def handle_cast(:clear, _stats) do
    new_stats = %{}
    {:noreply, new_stats}
  end

  def handle_cast(:stop, stats) do
    {:stop, :normal, stats}
  end

  def terminate(reason, stats) do
    IO.puts "Terminating server because of: #{inspect reason}"
    inspect stats
    :ok
  end

  defp update_stats(key, value, stats) do
    case Map.has_key?(stats, key) do
      true ->
        Map.replace(stats, key, value)
      false ->
        Map.put_new(stats, key, value)
    end
  end

  defp delete(stats, key) do
    Map.delete(stats, key)
  end
end
