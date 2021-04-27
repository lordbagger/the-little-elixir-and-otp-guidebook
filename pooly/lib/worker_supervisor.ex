defmodule Pooly.WorkerSupervisor do
  use Supervisor

  def start_link({_, _, _} = mfa) do
    Supervisor.start_link(__MODULE__, mfa)
  end

  def init({m, f, a}) do
    # Creates the child specifications
    child_specs = Supervisor.child_spec(m, start: {m, f, a}, restart: :permanent)

    # Specifies options for the Supervisor
    opts = [strategy: :simple_one_for_one, max_restarts: 5, max_seconds: 5]

    Supervisor.init([child_specs], opts)
  end
end
