defmodule ThyWorker do
  def start_link do
    spawn_link(fn -> loop() end)
  end

  def loop do
    receive do
      :exit ->
        :ok

      msg ->
        IO.inspect(msg)
        loop()
    end
  end
end
