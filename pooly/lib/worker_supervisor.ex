defmodule Pooly.WorkerSupervisor do
  use Supervisor

  def start_link(pool_server, {_, _, _} = mfa) do
    Supervisor.start_link(__MODULE__, [pool_server, mfa])
  end

  def init([pool_server, {m, f, a}]) do
    Process.link(pool_server)

    # Creates the child specifications
    child_specs = Supervisor.child_spec(m, start: {m, f, a}, restart: :temporary, shutdown: 5000)

    # Specifies options for the Supervisor
    opts = [strategy: :simple_one_for_one, max_restarts: 5, max_seconds: 5]

    Supervisor.init([child_specs], opts)
  end
end
