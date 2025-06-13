defmodule NavEx.Adapters.Session do
  @moduledoc """
    NavEx.Adapters.Session is adapter for keeping user's navigation history
    utilizing Plug.Conn session. **Doesn't support LiveView sockets.**

     ## Adapter config
      adapter_config: %{
        history_key: "nav_ex_history" # name of the key in session where navigation history is saved
      }

    ## This adapter supports only Plug.Conn - no LiveView support due to session usage.
    For LiveView sockets you have to use NavEx.Adapters.ETS.
  """

  @behaviour NavEx.Adapter

  import Plug.Conn

  @session_key Application.compile_env(:nav_ex, :adapter_config)[:history_key] || "nav_ex_history"
  @history_length (Application.compile_env(:nav_ex, :history_length) || 10) + 1

  @impl NavEx.Adapter
  def children, do: []

  @impl NavEx.Adapter
  def insert(%Plug.Conn{request_path: request_path} = conn) do
    case get_session(conn, @session_key) do
      nil ->
        {:ok, put_session(conn, @session_key, [request_path])}

      history ->
        {:ok, handle_history(conn, history, request_path)}
    end
  end

  @impl NavEx.Adapter
  def insert(%Phoenix.LiveView.Socket{} = _socket, _path) do
    raise ArgumentError,
          "NavEx.Adapters.Session doesn't support LiveView sockets. Please use Plug.Conn instead."
  end

  @impl NavEx.Adapter
  def list(%Plug.Conn{} = conn) do
    case get_session(conn, @session_key) do
      nil ->
        {:error, :not_found}

      history ->
        {:ok, history}
    end
  end

  @impl NavEx.Adapter
  def list(%Phoenix.LiveView.Socket{} = _socket) do
    raise ArgumentError,
          "NavEx.Adapters.Session doesn't support LiveView sockets. Please use Plug.Conn instead."
  end

  @impl NavEx.Adapter
  def last_path(%Plug.Conn{} = conn) do
    case get_session(conn, @session_key) do
      nil ->
        {:error, :not_found}

      history when length(history) > 1 ->
        {:ok, Enum.at(history, 1)}

      _history ->
        {:ok, nil}
    end
  end

  @impl NavEx.Adapter
  def last_path(%Phoenix.LiveView.Socket{} = _socket) do
    raise ArgumentError,
          "NavEx.Adapters.Session doesn't support LiveView sockets. Please use Plug.Conn instead."
  end

  @impl NavEx.Adapter
  def path_at(%Plug.Conn{} = conn, n) do
    case get_session(conn, @session_key) do
      nil ->
        {:error, :not_found}

      history ->
        {:ok, Enum.at(history, n)}
    end
  end

  @impl NavEx.Adapter
  def path_at(%Phoenix.LiveView.Socket{} = _socket, _n) do
    raise ArgumentError,
          "NavEx.Adapters.Session doesn't support LiveView sockets. Please use Plug.Conn instead."
  end

  ###

  defp handle_history(conn, history, path) do
    if length(history) < @history_length do
      put_session(conn, @session_key, [path | history])
    else
      [_last | cut_navigation_history] = Enum.reverse(history)
      to_be_stored = Enum.reverse(cut_navigation_history)

      put_session(conn, @session_key, [path | to_be_stored])
    end
  end
end
