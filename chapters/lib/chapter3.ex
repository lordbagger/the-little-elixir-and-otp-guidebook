defmodule Chapter3 do

  def ping_pong do
    ping_pid = spawn(Chapter3, :ping, [])
    pong_pid = spawn(Chapter3, :pong, [])
    send(pong_pid, {:pong, ping_pid})
  end

  def ping do
    receive do
      {:ping, sender_pid} ->
        IO.puts "Pong"
        send(sender_pid, {:pong, self()})
      _ ->
        IO.puts("Can't handle this message")
    end
  end

  def pong() do
    receive do
      {:pong, sender_pid} ->
        IO.puts "Ping"
        send(sender_pid, {:ping, self()})
      _ ->
        IO.puts("Can't handle this message")
    end
  end
end
