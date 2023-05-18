defmodule NavEx.Plug do
  @moduledoc """
    This is the Plug gathering data about visited paths.
  """

  import Plug.Conn

  @doc false
  def init(opts), do: opts

  @doc false
  def call(%Plug.Conn{} = conn, _opts) do
    {:ok, conn} = NavEx.insert(conn)

    conn
  end
end
