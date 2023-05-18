defmodule NavEx.Adapters.Session do
  @behaviour NavEx.Adapter

  import Plug.Conn

  @session_key Application.compile_env(NavEx.Adapters.Session, :history_key) || "nav_ex_history"
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
  def list(%Plug.Conn{} = conn) do
    case get_session(conn, @session_key) do
      nil ->
        {:error, :not_found}

      history ->
        {:ok, history}
    end
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
  def path_at(%Plug.Conn{} = conn, n) do
    case get_session(conn, @session_key) do
      nil ->
        {:error, :not_found}

      history ->
        {:ok, Enum.at(history, n)}
    end
  end

  ###

  defp handle_history(conn, history, path) do
    if length(history) < @history_length do
      put_session(conn, @session_key, [path | history])
    else
      cut_history =
        history
        |> Enum.reverse()
        |> tl()
        |> Enum.reverse()

      put_session(conn, @session_key, [path | cut_history])
    end
  end
end
