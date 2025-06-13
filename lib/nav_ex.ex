defmodule NavEx do
  @moduledoc """
    NavEx is a navigation history tool that uses adapter pattern
    and lets you choose between available adapters or just to
    write your own adapter.

    There are 2 available adapters right now - ETS adapter storing
    user navigation history in the ETS and Session adapter storing
    user navigation history in user's sessions.

    ## Configuration:
        config :nav_ex,
        tracked_methods: ["GET"], # what methods to track
        excluded_paths: ["/admin", "/dev], # paths you won't need to keep track on
        history_length: 10, # what is the history list length per user
        adapter: NavEx.Adapters.ETS # adapter used by NavEx to save data
        adapter_config: ... # adapter specific configuration

    ### ETS Adapter config
      adapter_config: %{
        identity_key: "nav_ex_identity", # name of the key in session where the user's identity is saved
        table_name: :navigation_history # name of the ETS table
      }

    ## Session Adapter config
      adapter_config: %{
        history_key: "nav_ex_history" # name of the key in session where navigation history is saved
      }
  """

  @adapter Application.compile_env(:nav_ex, :adapter) || NavEx.Adapters.ETS
  @tracked_methods Application.compile_env(:nav_ex, :tracked_methods) || ["GET"]
  @history_length (Application.compile_env(:nav_ex, :history_length) || 10) + 1

  @doc """
    Used by ExNav.Plug. Takes %Plug.Conn{} as an input.

    Calls Adapter `insert/1` function. Returns `{:ok, %Plug.Conn{}}` or `{:ok, %Phoenix.LiveView.Socket{}}` tuple.

    ## Examples
      iex(1)> NavEx.insert(conn)
      {:ok, %Plug.Conn{...}}

      iex(2)> NavEx.insert(socket, "/sample/path")
      {:ok, %Phoenix.LiveView.Socket{...}}
  """
  def insert(%Plug.Conn{method: method} = conn)
      when method in @tracked_methods,
      do: @adapter.insert(conn)

  def insert(%Plug.Conn{} = conn), do: {:ok, conn}

  def insert(%Phoenix.LiveView.Socket{} = socket, path)
      when is_binary(path) do
    @adapter.insert(socket, path)
  end

  @doc """
    Takes %Plug.Conn{} or %Phoenix.LiveView.Socket{} as an input. Calls Adapter `list/1` function.

    ## Examples
      # for existing user
      iex(1)> NavEx.list(conn)
      {:ok, ["/sample/path/2", "sample/path/1]}

      # for not existing user
      iex(2)> NavEx.list(conn)
      {:error, :not_found}

      # for sockets
      iex(3)> NavEx.list(socket)
      {:ok, ["/sample/path/2", "sample/path/1]}
  """
  def list(%Plug.Conn{} = conn), do: @adapter.list(conn)

  def list(%Phoenix.LiveView.Socket{} = socket), do: @adapter.list(socket)

  @doc """
    Takes %Plug.Conn{} or %Phoenix.LiveView.Socket{} as an input. Calls Adapter `last_path/1` function.

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

      # for sockets
      iex(4)> NavEx.last_path(socket)
      {:ok, "/sample/path"}
  """
  def last_path(%Plug.Conn{} = conn), do: @adapter.last_path(conn)

  def last_path(%Phoenix.LiveView.Socket{} = socket),
    do: @adapter.last_path(socket)

  @doc """
    Takes %Plug.Conn{} or %Phoenix.LiveView.Socket{} and number as inputs. Calls Adapter `path_at/1` function.

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

      # for sockets
      iex(5)> NavEx.path_at(socket, 5)
      {:ok, "/sample/path"}
  """
  def path_at(%Plug.Conn{} = conn, n) when is_integer(n) and n < @history_length - 1,
    do: @adapter.path_at(conn, n)

  def path_at(%Plug.Conn{} = _conn, n) when is_integer(n) do
    raise ArgumentError,
          "Max history depth is #{@history_length - 1} counted from 0 to #{@history_length - 2}. You asked for record number #{n}."
  end

  def path_at(%Phoenix.LiveView.Socket{} = socket, n)
      when is_integer(n) and n < @history_length - 1,
      do: @adapter.path_at(socket, n)

  def path_at(%Phoenix.LiveView.Socket{} = _socket, n) when is_integer(n) do
    raise ArgumentError,
          "Max history depth is #{@history_length - 1} counted from 0 to #{@history_length - 2}. You asked for record number #{n}."
  end
end
