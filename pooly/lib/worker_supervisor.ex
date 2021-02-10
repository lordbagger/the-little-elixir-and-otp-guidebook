defmodule Pooly.WorkerSupervisor do
  use Supervisor

  def start_link({_, _, _} = mfa) do
    Supervisor.start_link(__MODULE__, mfa)
  end

  # expects a supervisor specifications as a return value
  def init({m, f, a} = x) do
    # specifies that the worker will always be restarted, and the function to start the worker
    worker_opts = [restart: :permanent, function: f]

    # creats a list of the child processes
    children = [worker(m, a, worker_opts)]

    # specifies the options to the Supervisor
    opts = [strategy: :simple_one_for_one, max_restarts: 5, max_seconds: 5]

    # creates the child specifications
    supervise(children, opts)
  end
end
