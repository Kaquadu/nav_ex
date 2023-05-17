defmodule NavEx do
  import Plug.Conn

  alias NavEx.RecordsStorage

  @key_length 128
  @cookies_key Application.compile_env(:nav_ex, :cookies_key) || "nav_ex_identity"
  @tracked_methods Application.compile_env(:nav_ex, :tracked_methods) || ["GET"]

  def insert(%Plug.Conn{request_path: request_path, method: method} = conn)
      when method in @tracked_methods do
    {conn, user_identity} = maybe_insert_identity(conn)
    {:ok, _result} = RecordsStorage.insert(user_identity, request_path)

    {:ok, conn}
  end

  def insert(%Plug.Conn{} = conn), do: {:ok, conn}

  def list(%Plug.Conn{} = conn) do
    with {:ok, user_identity} <- get_identity(conn),
         {:ok, [{_user_identity, list}]} <- RecordsStorage.list(user_identity) do
      {:ok, list}
    end
  end

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
    conn
    |> fetch_cookies()
    |> case do
      %{cookies: %{@cookies_key => user_identity}} ->
        {conn, user_identity}

      _no_identity ->
        user_identity = create_user_identity()
        conn = put_resp_cookie(conn, @cookies_key, user_identity)
        {conn, user_identity}
    end
  end

  defp get_identity(%Plug.Conn{} = conn) do
    conn
    |> fetch_cookies()
    |> case do
      %{cookies: %{@cookies_key => user_identity}} ->
        {:ok, user_identity}

      _no_identity ->
        {:error, :not_found}
    end
  end

  defp create_user_identity() do
    :crypto.strong_rand_bytes(@key_length) |> Base.url_encode64() |> binary_part(0, @key_length)
  end
end
