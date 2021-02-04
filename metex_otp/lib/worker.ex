defmodule Metex.Worker do

  use GenServer

  ## CLIENT API

  @name Metex

  def start_link(opts \\ []) do
    ## __MODULE__ = name of the module 'init' is implemented
    ## :ok = arguments to be passed to 'init' function
    ## opts = list of options to be passed to GenServer.start_link
    GenServer.start(__MODULE__, :ok, opts ++ [name: Metex])
  end

  def get_temperature(location) do
    GenServer.call(@name, {:location, location})
  end

  def get_stats do
    GenServer.call(@name, :get_stats)
  end

  def reset_stats do
    GenServer.cast(@name, :reset_stats)
  end

  def stop do
    GenServer.cast(@name, :stop)
  end

  ## SERVER API

  ## boots the server declares its initial state
  def init(:ok) do
    {:ok, %{}}
  end

  ## first argument: expected request to be handled
  ## second: tuple in the form of {pid, tag} where pid is the pid of the client and tag is a unique reference to the message
  ## third: the internal state of the server
  def handle_call({:location, location}, _from, stats) do
    case temperature_of(location) do
      {:ok, temp} ->
          new_status = update_stats(stats, location)
          {:reply, "#{temp} °C", new_status}
       _ ->
          {:reply, :error, stats}
    end
  end

  def handle_call(:get_stats, _from, stats) do
    {:reply, stats, stats}
  end

  def handle_cast(:reset_stats, _stats) do
    {:noreply, %{}}
  end

  def handle_cast(:stop, stats) do
    {:stop, :normal, stats}
  end

  def handle_info(msg, stats) do
    IO.puts "Received #{inspect msg}"
    {:noreply, stats}
  end

  def terminate(reason, stats) do
    IO.puts "Server terminated because of #{reason}"
      inspect stats
    :ok
  end

  ## HELPER FUNCTIONS

  defp update_stats(old_stats, location) do
    case Map.has_key?(old_stats, location) do
      true ->
        ## &(&1 + 1) can also be written as= fn(val) -> val + 1 end
        Map.update!(old_stats, location, &(&1 + 1))
      false ->
      Map.put_new(old_stats, location, 1)
    end
  end

  defp temperature_of(location) do
    url_for(location) |> HTTPoison.get |> parse_response
  end

    defp url_for(location) do
      location = URI.encode(location)
      "http://api.openweathermap.org/data/2.5/weather?q=#{location}&appid=#{api_key()}"
    end

    defp parse_response({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
      body |> JSON.decode! |> compute_temperature
    end

    defp parse_response(_) do
      :error
    end

    defp compute_temperature(json) do
      try do
        temp = (json["main"]["temp"] - 273.15) |> Float.round(1)
        {:ok, temp}
      rescue
        _ -> :error
      end
    end

    defp api_key do
      "e70e47205e60022804b32a6707d22685"
    end
end
