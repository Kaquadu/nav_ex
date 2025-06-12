defmodule NavEx.Adapter.SessionTest do
  use NavEx.ConnCase

  alias NavEx.Adapters.Session

  @session_options Plug.Session.init(
                     store: Plug.Session.COOKIE,
                     key: "_hello_key",
                     signing_salt: "CXlmrshG"
                   )

  setup do
    %{conn: conn(:get, "/sample/path") |> Plug.Session.call(@session_options) |> fetch_session()}
  end

  describe "insert/1" do
    test "for new user inserts a new history record and identity into conn session", %{conn: conn} do
      assert {:ok, conn} = Session.insert(conn)
      assert get_session(conn, "nav_ex_history") == [conn.request_path]
    end

    test "for existing user inserts a new history record for the same identity at the start of the list",
         %{conn: conn} do
      assert {:ok, conn} = Session.insert(conn)

      assert {:ok, new_conn} =
               conn
               |> Map.put(:request_path, "/sample/path/1")
               |> Plug.Session.call(@session_options)
               |> fetch_session()
               |> Session.insert()

      assert get_session(new_conn, "nav_ex_history") == [new_conn.request_path, conn.request_path]
    end

    test "when overfilling the list it will pop last element and put the request path in the front",
         %{conn: conn} do
      conn =
        Enum.reduce(1..11, conn, fn n, conn ->
          {:ok, conn} =
            conn
            |> Map.put(:request_path, "/sample/path/#{n}")
            |> Plug.Session.call(@session_options)
            |> fetch_session()
            |> Session.insert()

          conn
        end)

      [last_path | _history] = get_session(conn, "nav_ex_history")

      assert last_path == "/sample/path/11"
    end
  end

  describe "list/1" do
    test "if connection has navigation history returns it", %{conn: conn} do
      assert {:ok, conn} = Session.insert(conn)
      assert {:ok, [zero_path]} = Session.list(conn)
      assert zero_path == conn.request_path
    end

    test "for not existing navigation history returns not found error", %{conn: conn} do
      assert {:error, :not_found} == Session.list(conn)
    end
  end

  describe "last_path/1" do
    test "if user existis and has at least 2 records returns success tuple with 2nd record", %{
      conn: conn
    } do
      conn =
        Enum.reduce(1..10, conn, fn n, conn ->
          {:ok, conn} =
            conn
            |> Map.put(:request_path, "/sample/path/#{n}")
            |> Plug.Session.call(@session_options)
            |> fetch_session()
            |> Session.insert()

          conn
        end)

      assert {:ok, last_path} = Session.last_path(conn)
      [_zero_path, second_to_last | _rest] = get_session(conn, "nav_ex_history")
      assert last_path == second_to_last
    end

    test "if user existis and has only 1 record returns success tuple with nil", %{conn: conn} do
      {:ok, conn} =
        conn
        |> Map.put(:request_path, "/sample/path/1")
        |> Plug.Session.call(@session_options)
        |> fetch_session()
        |> Session.insert()

      assert {:ok, nil} = Session.last_path(conn)
    end

    test "for not existing navigation history returns not found error", %{conn: conn} do
      assert {:error, :not_found} = Session.last_path(conn)
    end
  end

  describe "path_at/2" do
    test "if user existis returns Nth record counting from 0", %{conn: conn} do
      conn =
        Enum.reduce(1..10, conn, fn n, conn ->
          {:ok, conn} =
            conn
            |> Map.put(:request_path, "/sample/path/#{n}")
            |> Plug.Session.call(@session_options)
            |> fetch_session()
            |> Session.insert()

          conn
        end)

      assert {:ok, path} = Session.path_at(conn, 0)
      [zero_path | _rest] = get_session(conn, "nav_ex_history")
      assert zero_path == path

      assert {:ok, path} = Session.path_at(conn, 3)
      [_zero, _one, _two, third_path | _rest] = get_session(conn, "nav_ex_history")
      assert third_path == path
    end

    test "if user existis but N exceeds user history returns success tuple with nil", %{
      conn: conn
    } do
      conn =
        Enum.reduce(1..5, conn, fn n, conn ->
          {:ok, conn} =
            conn
            |> Map.put(:request_path, "/sample/path/#{n}")
            |> Plug.Session.call(@session_options)
            |> fetch_session()
            |> Session.insert()

          conn
        end)

      assert {:ok, nil} = Session.path_at(conn, 10)
    end

    test "for not existing user returns not found error", %{conn: conn} do
      assert {:error, :not_found} = Session.path_at(conn, 2)
    end
  end
end
