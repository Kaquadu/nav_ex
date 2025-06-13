defmodule NavEx.Adapters.ETS do
  @moduledoc """
    NavEx.Adapters.ETS is adapter for keeping user's navigation history
    utilizing ETS. It uses NavEx.Adapters.ETS.RecordsStorage as the
    module to interact with the ETS table.

     ## Adapter config
     adapter_config: %{
        identity_key: "nav_ex_identity", # name of the key in session where the user's identity is saved
        table_name: :navigation_history # name of the ETS table
     }

     ## This adapter supports both Plug.Conn and Phoenix.LiveView.Socket.
     For LiveView sockets you have to make sure to put the same user's identity
     that was stored in the session into the socket assigns under the identity key (as atom!).
  """

  @behaviour NavEx.Adapter
  import Plug.Conn

  alias NavEx.Adapters.ETS.RecordsStorage

  @key_length 128
  @session_key Application.compile_env(:nav_ex, :adapter_config)[:identity_key] ||
                 "nav_ex_identity"

  @excluded_paths Application.compile_env(:nav_ex, :excluded_paths) || ["/exclude"]

  @impl NavEx.Adapter
  def children, do: [NavEx.Adapters.ETS.RecordsStorage]

  @impl NavEx.Adapter
  def insert(%Plug.Conn{request_path: request_path} = conn) do
    {conn, user_identity} = maybe_insert_identity(conn)

    if Enum.any?(@excluded_paths, &String.starts_with?(request_path, &1)) do
      {:ok, conn}
    else
      RecordsStorage.insert(user_identity, request_path)
      {:ok, conn}
    end
  end

  @impl NavEx.Adapter
  def insert(%Phoenix.LiveView.Socket{assigns: assigns} = socket, path) do
    key = String.to_atom(@session_key)
    user_identity = Map.get(assigns, key)

    if is_nil(user_identity) do
      raise ArgumentError,
            "NavEx.Adapters.ETS requires user identity to be set in socket assigns under the key ':#{@session_key}'."
    end

    if Enum.any?(@excluded_paths, &String.starts_with?(path, &1)) do
      {:ok, socket}
    else
      RecordsStorage.insert(user_identity, path)
      {:ok, socket}
    end
  end

  @impl NavEx.Adapter
  def list(%Plug.Conn{} = conn) do
    with {:ok, user_identity} <- get_identity(conn),
         {:ok, [{_user_identity, list}]} <- RecordsStorage.list(user_identity) do
      {:ok, list}
    end
  end

  @impl NavEx.Adapter
  def list(%Phoenix.LiveView.Socket{assigns: assigns} = _socket) do
    key = String.to_atom(@session_key)
    user_identity = Map.get(assigns, key)

    if is_nil(user_identity) do
      {:error, :not_found}
    else
      case RecordsStorage.list(user_identity) do
        {:ok, [{_user_identity, list}]} -> {:ok, list}
        error -> error
      end
    end
  end

  @impl NavEx.Adapter
  def last_path(%Plug.Conn{} = conn) do
    conn
    |> get_identity()
    |> case do
      {:ok, user_identity} ->
        RecordsStorage.last_path(user_identity)

      error ->
        error
    end
  end

  @impl NavEx.Adapter
  def last_path(%Phoenix.LiveView.Socket{assigns: assigns} = _socket) do
    key = String.to_atom(@session_key)
    user_identity = Map.get(assigns, key)

    case user_identity do
      nil ->
        {:error, :not_found}

      _ ->
        RecordsStorage.last_path(user_identity)
    end
  end

  @impl NavEx.Adapter
  def path_at(%Plug.Conn{} = conn, n) do
    conn
    |> get_identity()
    |> case do
      {:ok, user_identity} ->
        RecordsStorage.path_at(user_identity, n)

      error ->
        error
    end
  end

  @impl NavEx.Adapter
  def path_at(%Phoenix.LiveView.Socket{assigns: assigns}, n) do
    key = String.to_atom(@session_key)
    user_identity = Map.get(assigns, key)

    case user_identity do
      nil ->
        {:error, :not_found}

      _ ->
        RecordsStorage.path_at(user_identity, n)
    end
  end

  ###

  defp maybe_insert_identity(%Plug.Conn{} = conn) do
    case get_session(conn, @session_key) do
      nil ->
        user_identity = create_user_identity()
        conn = put_session(conn, @session_key, user_identity)
        {conn, user_identity}

      user_identity ->
        {conn, user_identity}
    end
  end

  defp get_identity(%Plug.Conn{} = conn) do
    case get_session(conn, @session_key) do
      nil ->
        {:error, :not_found}

      user_identity ->
        {:ok, user_identity}
    end
  end

  defp create_user_identity do
    :crypto.strong_rand_bytes(@key_length) |> Base.url_encode64() |> binary_part(0, @key_length)
  end
end
