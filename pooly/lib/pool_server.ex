defmodule Pooly.PoolServer do
  use GenServer
  import Supervisor.Spec
  require IEx

  defmodule State do
    defstruct pool_sup: nil,
              worker_sup: nil,
              size: nil,
              workers: nil,
              mfa: nil,
              monitors: nil,
              name: nil,
              max_overflow: nil,
              overflow: nil,
              waiting: nil
  end

  def start_link(pool_sup, pool_config) do
    GenServer.start_link(__MODULE__, [pool_sup, pool_config], name: name(pool_config[:name]))
  end

  def checkout(pool_name, block, timeout) do
    GenServer.call(name(pool_name), {:checkout, block}, timeout)
  end

  def checkin(pool_name, worker_pid) do
    GenServer.cast(name(pool_name), {:checkin, worker_pid})
  end

  def status(pool_name) do
    GenServer.call(name(pool_name), :status)
  end

  def init([pool_sup, pool_config]) do
    Process.flag(:trap_exit, true)
    monitors = :ets.new(:monitors, [:private])
    waiting = :queue.new()
    state = %State{pool_sup: pool_sup, monitors: monitors, waiting: waiting}
    init(pool_config, state)
  end

  def init([{:mfa, mfa} | rest], state) do
    init(rest, %{state | mfa: mfa})
  end

  def init([{:size, size} | rest], state) do
    init(rest, %{state | size: size})
  end

  def init([{:name, name} | rest], state) do
    init(rest, %{state | name: name})
  end

  def init([{:max_overflow, max_overflow} | rest], state) do
    init(rest, %{state | max_overflow: max_overflow})
  end

  def init([], state) do
    send(self(), :start_worker_supervisor)
    {:ok, state}
  end

  def init([_ | rest], state) do
    init(rest, state)
  end

  def handle_call(:status, _from, %{workers: workers, monitors: monitors} = state) do
    {:reply, {state_name(state)}, {length(workers), :ets.info(monitors, :size)}, state}
  end

  def handle_call(
        {:checkout, block},
        {from_pid, _ref} = from,
        %{
          worker_sup: worker_sup,
          workers: workers,
          monitors: monitors,
          max_overflow: max_overflow,
          overflow: overflow,
          waiting: waiting
        } = state
      ) do
    case workers do
      [worker | rest] ->
        ref = Process.monitor(from_pid)
        true = :ets.insert(monitors, {worker, ref})
        {:reply, worker, %{state | workers: rest}}

      [] when max_overflow > 0 and overflow < max_overflow ->
        worker = new_worker(worker_sup)
        ref = Process.monitor(from_pid)
        true = :ets.insert(monitors, {worker, ref})
        {:reply, worker, %{state | overflow: overflow + 1}}

      [] when block == true ->
        ref = Process.monitor(from_pid)
        waiting = :queue.in({from, ref}, waiting)
        {:noreply, %{state | waiting: waiting}, :infinity}

      [] ->
        {:reply, :full, state}
    end
  end

  def handle_cast({:checkin, worker_pid}, %{workers: workers, monitors: monitors} = state) do
    case :ets.lookup(monitors, worker_pid) do
      [{pid, ref}] ->
        true = Process.demonitor(ref)
        true = :ets.delete(monitors, pid)
        new_state = handle_checkin(worker_pid, state)
        {:noreply, new_state}

      [] ->
        {:noreply, state}
    end
  end

  def handle_info(
        :start_worker_supervisor,
        state = %{pool_sup: pool_sup, mfa: mfa, size: size, name: name}
      ) do
    {:ok, worker_sup} = Supervisor.start_child(pool_sup, supervisor_spec(name, mfa))
    workers = prepopulate(size, worker_sup)
    {:noreply, %{state | worker_sup: worker_sup, workers: workers}}
  end

  def handle_info({:DOWN, ref, _, _, _}, state = %{monitors: monitors, workers: workers}) do
    case :ets.match(monitors, {:"$1", ref}) do
      [[pid]] ->
        true = :ets.delete(monitors, pid)
        new_state = %{state | workers: [pid | workers]}
        {:noreply, new_state}

      [[]] ->
        {:noreply, state}
    end
  end

  def handle_info(
        {:EXIT, pid, _reason},
        %{worker_sup: worker_sup, monitors: monitors, workers: workers} = state
      ) do
    case :ets.lookup(monitors, pid) do
      [{pid, ref}] ->
        true = Process.demonitor(ref)
        true = :ets.delete(monitors, pid)
        new_state = handle_worker_exit(pid, state)
        {:noreply, new_state}

      _ ->
        {:noreply, state}
    end
  end

  def handle_info({:EXIT, worker_sup, reason}, %{worker_sup: worker_sup} = state) do
    {:stop, reason, state}
  end

  def terminate(_reason, _state) do
    :ok
  end

  defp name(pool_name) do
    :"#{pool_name}Server"
  end

  defp prepopulate(size, worker_sup) do
    prepopulate(size, worker_sup, [])
  end

  defp prepopulate(size, _worker_sup, workers) when size < 1 do
    workers
  end

  defp prepopulate(size, worker_sup, workers) do
    prepopulate(size - 1, worker_sup, [new_worker(worker_sup) | workers])
  end

  defp new_worker(worker_sup) do
    {:ok, worker} = Supervisor.start_child(worker_sup, [[]])
    Process.link(worker)
    worker
  end

  defp supervisor_spec(name, mfa) do
    id = name <> "WorkerSupervisor"
    opts = [id: id, restart: :temporary]
    supervisor(Pooly.WorkerSupervisor, [self(), mfa], opts)
  end

  defp handle_checkin(pid, state) do
    %{worker_sup: worker_sup, workers: workers, monitors: monitors, overflow: overflow} = state

    if overflow > 0 do
      :ok = dismiss_worker(worker_sup, pid)
      %{state | overflow: overflow - 1}
    else
      %{state | workers: [pid | workers], overflow: 0}
    end
  end

  defp handle_worker_exit(pid, state) do
    %{worker_sup: worker_sup, workers: workers, monitors: monitors, overflow: overflow} = state

    if overflow > 0 do
      %{state | overflow: overflow - 1}
    else
      %{state | workers: [new_worker(worker_sup) | workers], overflow: 0}
    end
  end

  defp dismiss_worker(sup, pid) do
    true = Process.unlink(pid)
    Supervisor.terminate_child(sup, pid)
  end

  defp state_name(%{workers: workers, overflow: overflow, max_overflow: max_overflow})
       when overflow < 1 do
    case length(workers) == 0 do
      true ->
        if max_overflow < 1 do
          :full
        else
          :overflow
        end

      false ->
        :ready
    end
  end

  defp state_name(%{overflow: max_overflow, max_overflow: max_overflow}) do
    :full
  end

  defp state_name(_state) do
    :overflow
  end
end
