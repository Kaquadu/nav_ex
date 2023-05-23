defmodule NavEx.Application do
  @moduledoc false
  use Application

  @adapter Application.compile_env(:nav_ex, :adapter) || NavEx.Adapters.ETS
  @doc false
  def start(_type, _args) do
    children = @adapter.children()

    opts = [strategy: :one_for_one, name: NavEx.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
