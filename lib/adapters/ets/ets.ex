defmodule NavEx.Adapters.ETS do
  @moduledoc """
    NavEx.Adapters.ETS is adapter for keeping user's navigation history
    utilizing ETS. It uses NavEx.Adapters.ETS.RecordsStorage as the
    module to interact with the ETS table.

     ## Adapter config
      config NavEx.Adapters.ETS,
        identity_key: "nav_ex_identity", # name of the key in cookies where the user's identity is saved
        table_name: :navigation_history # name of the ETS table
  """

  @behaviour NavEx.Adapter
  import Plug.Conn

  alias NavEx.Adapters.ETS.RecordsStorage

  @key_length 128
  @cookies_key Application.compile_env(:nav_ex, :adapter_config)[:identity_key] ||
                 "nav_ex_identity"

  @impl NavEx.Adapter
  def children, do: [NavEx.Adapters.ETS.RecordsStorage]

  @impl NavEx.Adapter
  def insert(%Plug.Conn{request_path: request_path} = conn) do
    {conn, user_identity} = maybe_insert_identity(conn)
    {:ok, _result} = RecordsStorage.insert(user_identity, request_path)

    {:ok, conn}
  end

  @impl NavEx.Adapter
  def list(%Plug.Conn{} = conn) do
    with {:ok, user_identity} <- get_identity(conn),
         {:ok, [{_user_identity, list}]} <- RecordsStorage.list(user_identity) do
      {:ok, list}
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

  ###

  defp maybe_insert_identity(%Plug.Conn{} = conn) do
    case fetch_cookies(conn) do
      %{cookies: %{@cookies_key => user_identity}} ->
        {conn, user_identity}

      _no_identity ->
        user_identity = create_user_identity()
        conn = put_resp_cookie(conn, @cookies_key, user_identity)
        {conn, user_identity}
    end
  end

  defp get_identity(%Plug.Conn{} = conn) do
    case fetch_cookies(conn) do
      %{cookies: %{@cookies_key => user_identity}} ->
        {:ok, user_identity}

      _no_identity ->
        {:error, :not_found}
    end
  end

  defp create_user_identity do
    :crypto.strong_rand_bytes(@key_length) |> Base.url_encode64() |> binary_part(0, @key_length)
  end
end
