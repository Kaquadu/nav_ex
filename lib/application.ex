defmodule NavEx.Application do
  use Application

  def start(_type, _args) do
    children = [
      NavEx.RecordsStorage
    ]

    opts = [strategy: :one_for_one, name: NavEx.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
