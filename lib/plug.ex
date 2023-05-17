defmodule NavEx.Plug do
  @moduledoc """
    NavEx keeps the contexts that define your domain
    and business logic.
  """

  def init(opts), do: opts

  def call(%Plug.Conn{} = conn, _opts) do
    {:ok, conn} = NavEx.insert(conn)

    conn
  end
end
