defmodule Pooly.Supervisor do
  use Supervisor
  import Supervisor.Spec

  def start_link(pools_config) do
    Supervisor.start_link(__MODULE__, pools_config, name: __MODULE__)
  end

  def init(pools_config) do
    child_specs = [
      supervisor(Pooly.PoolsSupervisor, []),
      worker(Pooly.Server, [pools_config])
    ]

    # Specifies options for the Supervisor
    opts = [strategy: :one_for_all]

    Supervisor.init(child_specs, opts)
  end
end
