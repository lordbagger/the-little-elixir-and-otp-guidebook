defmodule Chapter3 do

  def ping_pong do
    ping_pid = spawn(Chapter3, :ping, [])
    pong_pid = spawn(Chapter3, :pong, [0, 3])
    send(pong_pid, {:pong, ping_pid})
  end

  def ping do
    receive do
      {:ping, sender_pid} ->
        IO.puts "Pong"
        send(sender_pid, {:pong, self()})
        ping()
      {:exit, sender_pid} ->
        IO.puts("PING: Process terminated")
        send(sender_pid, :exit)
      _ ->
        IO.puts("Can't handle this message")
    end
  end

  def pong(interactions, expected) do
    receive do
      {:pong, sender_pid} ->
        if interactions == expected do
          send(sender_pid, {:exit, self()})
        end
        IO.puts "Ping"
        new_interactions = interactions + 1
        send(sender_pid, {:ping, self()})
        pong(new_interactions, expected)
      :exit ->
        IO.puts("PONG: Process terminated")
      _ ->
        IO.puts("Can't handle this message")
    end
  end
end
