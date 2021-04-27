defmodule Pooly.Supervisor do
  use Supervisor

  def start_link(pool_config) do
    Supervisor.start_link(__MODULE__, pool_config)
  end

  def init(pool_config) do
    child_specs = [
      {Pooly.Server, [self(), pool_config]}
    ]

    # Specifies options for the Supervisor
    opts = [strategy: :one_for_all]

    Supervisor.init(child_specs, opts)
  end
end
