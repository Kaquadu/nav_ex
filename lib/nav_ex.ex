defmodule NavEx do
  @moduledoc """
    NavEx is a navigation history tool that uses adapter pattern
    and lets you choose between available adapters or just to
    write your own adapter.

    There are 2 available adapters right now - ETS adapter storing
    user navigation history in the ETS and Session adapter storing
    user navigation history in user's sessions.
  """

  @adapter Application.compile_env(:nav_ex, :adapter) || NavEx.Adapters.ETS
  @tracked_methods Application.compile_env(:nav_ex, :tracked_methods) || ["GET"]
  @history_length (Application.compile_env(:nav_ex, :history_length) || 10) + 1

  @doc """
    Used by ExNav.Plug. Takes %Plug.Conn{} as an input.

    Calls Adapter `insert/1` function. Always returns `{:ok, %Plug.Conn{}}` tuple.

    ## Examples
      iex(1)> NavEx.insert(conn)
      {:ok, %Plug.Conn{...}}
  """
  def insert(%Plug.Conn{method: method} = conn)
      when method in @tracked_methods,
      do: @adapter.insert(conn)

  def insert(%Plug.Conn{} = conn), do: {:ok, conn}

  @doc """
    Takes %Plug.Conn{} as an input. Calls Adapter `list/1` function.

    ## Examples
      # for existing user
      iex(1)> NavEx.list(conn)
      {:ok, ["/sample/path/2", "sample/path/1]}

      # for not existing user
      iex(2)> NavEx.list(conn)
      {:error, :not_found}
  """
  def list(%Plug.Conn{} = conn), do: @adapter.list(conn)

  @doc """
    Takes %Plug.Conn{} as an input. Calls Adapter `last_path/1` function.

    ## Examples
      # for existing user
      iex(1)> NavEx.last_path(conn)
      {:ok, "/sample/path"}

      # for existing user, but without 2 paths
      iex(2)> NavEx.last_path(conn)
      {:ok, nil}

      # for not existing user
      iex(3)> NavEx.last_path(conn)
      {:error, :not_found}
  """
  def last_path(%Plug.Conn{} = conn), do: @adapter.last_path(conn)

  @doc """
    Takes %Plug.Conn{} and number as inputs. Calls Adapter `path_at/1` function.

    ## Examples
      # for existing user
      iex(1)> NavEx.path_at(conn, 5)
      {:ok, "/sample/path"}

      # for existing user but exceeding paths number
      iex(2)> NavEx.path_at(conn, 5)
      {:ok, nil}

      # for not existing user
      iex(3)> NavEx.path_at(conn, 5)
      {:error, :not_found}

      # exceeding history limit
      iex(4)> NavEx.path_at(conn, 999)
      ** (ArgumentError) Max history depth is 10 counted from 0 to 9. You asked for record number 999.
  """
  def path_at(%Plug.Conn{} = conn, n) when is_integer(n) and n < @history_length - 1,
    do: @adapter.path_at(conn, n)
end
