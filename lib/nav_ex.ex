defmodule NavEx do
  @moduledoc """
    This is the main NavEx module responsible for main project domain.
  """
  import Plug.Conn

  alias NavEx.RecordsStorage

  @key_length 128
  @cookies_key Application.compile_env(:nav_ex, :cookies_key) || "nav_ex_identity"
  @tracked_methods Application.compile_env(:nav_ex, :tracked_methods) || ["GET"]

  @doc """
    Used by ExNav.Plug.

    Takes %Plug.Conn{} as an input.

    If conn doesn't have user identity cookie it creates it.
    Then it adds the request path if its request method is in tracked methods.

    ## Examples
      iex(1)> NavEx.insert(conn)
      {:ok, %Plug.Conn{...}}
  """
  def insert(%Plug.Conn{request_path: request_path, method: method} = conn)
      when method in @tracked_methods do
    {conn, user_identity} = maybe_insert_identity(conn)
    {:ok, _result} = RecordsStorage.insert(user_identity, request_path)

    {:ok, conn}
  end

  def insert(%Plug.Conn{} = conn), do: {:ok, conn}

  @doc """
    Takes %Plug.Conn{} as an input. Based on the user identity stored in cookies
    lists user's navigation history list.

    ## Examples
      # for existing user
      iex(1)> NavEx.list(conn)
      {:ok, ["/sample/path/2", "sample/path/1]}

      # for not existing user
      iex(2)> NavEx.list(conn)
      {:error, :not_found}
  """
  def list(%Plug.Conn{} = conn) do
    with {:ok, user_identity} <- get_identity(conn),
         {:ok, [{_user_identity, list}]} <- RecordsStorage.list(user_identity) do
      {:ok, list}
    end
  end

  @doc """
    Takes %Plug.Conn{} as an input. Based on the user identity stored in cookies
    returns user's last visited path, that is 2nd path in the navigation history.

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

  @doc """
    Takes %Plug.Conn{} and number as inputs. Based on the user identity stored in cookies
    returns user's Nth visited path counted from 0.

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

      iex(4)> NavEx.path_at(conn, 999)
      ** (ArgumentError) Max history depth is 10 counted from 0 to 9. You asked for record number 999.
  """
  def path_at(%Plug.Conn{} = conn, n) when is_integer(n) do
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
