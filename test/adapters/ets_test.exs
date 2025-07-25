defmodule NavEx.Adapter.ETSTest do
  use NavEx.ConnCase

  alias NavEx.Adapters.ETS
  alias NavEx.Adapters.ETS.RecordsStorage

  @session_options Plug.Session.init(
                     store: Plug.Session.COOKIE,
                     key: "_hello_key",
                     signing_salt: "CXlmrshG"
                   )

  describe "insert/1 (Plug.Conn)" do
    setup do
      RecordsStorage.delete_all_objects()

      %{}
    end

    test "for new user inserts a new history record and identity into conn session" do
      request_path = "/sample/request"
      conn = conn(:get, request_path) |> Plug.Session.call(@session_options) |> fetch_session()

      assert {:ok, conn} = ETS.insert(conn)

      refute is_nil(get_session(conn, "nav_ex_identity"))

      assert {:ok, [result_path]} = ETS.list(conn)
      assert result_path == request_path
    end

    test "for existing user inserts a new history record for the same identity at the start of the list" do
      request_path = "/sample/request/2"

      conn =
        conn(:get, "/sample/request") |> Plug.Session.call(@session_options) |> fetch_session()

      assert {:ok, conn} = ETS.insert(conn)

      assert {:ok, conn} =
               conn
               |> Map.put(:request_path, request_path)
               |> ETS.insert()

      assert {:ok, [result_path, _old_path]} = ETS.list(conn)
      assert result_path == request_path
    end

    test "when overfilling the list it will pop last element and put the request path in the front" do
      conn =
        Enum.reduce(1..20, conn(:get, "/sample/request/0"), fn n, conn ->
          request_path = "/sample/request/#{n}"

          conn =
            conn
            |> Map.put(:request_path, request_path)
            |> Plug.Session.call(@session_options)
            |> fetch_session()

          {:ok, conn} = ETS.insert(conn)
          conn
        end)

      assert {:ok, [result_path | _list] = history} = ETS.list(conn)
      assert result_path == "/sample/request/20"
      assert length(history) == 11
    end

    test "respects excluded paths and does not insert them into history" do
      request_path = "/excluded/path"
      conn = conn(:get, request_path) |> Plug.Session.call(@session_options) |> fetch_session()

      assert {:ok, conn} = ETS.insert(conn)

      assert {:ok, []} = ETS.list(conn)
    end
  end

  describe "insert/2 (Phoenix.LiveView.Socket)" do
    setup do
      RecordsStorage.delete_all_objects()

      %{}
    end

    test "inserts user navigation if called with Phoenix.LiveView.Socket containing nav_ex_identity key" do
      socket = %Phoenix.LiveView.Socket{assigns: %{nav_ex_identity: "user_1"}}

      request_path = "/sample/request/0"

      assert {:ok, socket} = ETS.insert(socket, request_path)
      assert {:ok, [result_path]} = ETS.list(socket)
      assert result_path == request_path
    end

    test "raises error if called with Phoenix.LiveView.Socket without nav_ex_identity key" do
      socket = %Phoenix.LiveView.Socket{assigns: %{}}

      assert_raise ArgumentError, fn ->
        ETS.insert(socket, "/sample/request/0")
      end
    end

    test "respoects excluded paths and does not insert them into history" do
      socket = %Phoenix.LiveView.Socket{assigns: %{nav_ex_identity: "user_1"}}
      request_path = "/excluded/path"

      assert {:ok, socket} = ETS.insert(socket, request_path)

      assert {:ok, []} = ETS.list(socket)
    end
  end

  describe "list/1 (Plug.Conn)" do
    setup do
      RecordsStorage.delete_all_objects()

      %{}
    end

    test "if user exists in records returns tuple with the navigation history" do
      conn =
        Enum.reduce(1..11, conn(:get, "/sample/request/0"), fn n, conn ->
          request_path = "/sample/request/#{n}"

          conn =
            conn
            |> Map.put(:request_path, request_path)
            |> Plug.Session.call(@session_options)
            |> fetch_session()

          {:ok, conn} = ETS.insert(conn)
          conn
        end)

      assert {:ok, [result_path | _list] = history} = ETS.list(conn)
      assert result_path == "/sample/request/11"
      assert length(history) == 11
    end

    test "for not existing user returns not found error" do
      conn =
        conn(:get, "/sample/request") |> Plug.Session.call(@session_options) |> fetch_session()

      assert {:error, :not_found} = ETS.list(conn)
    end
  end

  describe "list/1 (Phoenix.LiveView.Socket)" do
    setup do
      RecordsStorage.delete_all_objects()

      %{}
    end

    test "if user exists in records returns tuple with the navigation history" do
      socket = %Phoenix.LiveView.Socket{assigns: %{nav_ex_identity: "user_1"}}

      Enum.reduce(1..11, socket, fn n, socket ->
        request_path = "/sample/request/#{n}"
        {:ok, socket} = ETS.insert(socket, request_path)
        socket
      end)

      assert {:ok, [result_path | _list] = history} = ETS.list(socket)
      assert result_path == "/sample/request/11"
      assert length(history) == 11
    end

    test "for not existing user returns not found error" do
      socket = %Phoenix.LiveView.Socket{assigns: %{}}

      assert {:error, :not_found} = ETS.list(socket)
    end
  end

  describe "last_path/1 (Plug.Conn)" do
    setup do
      RecordsStorage.delete_all_objects()

      %{}
    end

    test "if user existis and has at least 2 records returns success tuple with 2nd record" do
      conn =
        Enum.reduce(1..2, conn(:get, "/sample/request/0"), fn n, conn ->
          request_path = "/sample/request/#{n}"

          conn =
            conn
            |> Map.put(:request_path, request_path)
            |> Plug.Session.call(@session_options)
            |> fetch_session()

          {:ok, conn} = ETS.insert(conn)
          conn
        end)

      assert {:ok, result_path} = ETS.last_path(conn)
      assert result_path == "/sample/request/1"
    end

    test "if user existis and has only 1 record returns success tuple with nil" do
      request_path = "/sample/request/0"
      conn = conn(:get, request_path) |> Plug.Session.call(@session_options) |> fetch_session()
      {:ok, conn} = ETS.insert(conn)

      assert {:ok, nil} = ETS.last_path(conn)
    end

    test "for not existing user returns not found error" do
      conn =
        conn(:get, "/sample/request") |> Plug.Session.call(@session_options) |> fetch_session()

      assert {:error, :not_found} = ETS.last_path(conn)
    end
  end

  describe "last_path/1 (Phoenix.LiveView.Socket)" do
    setup do
      RecordsStorage.delete_all_objects()

      %{}
    end

    test "if user existis and has at least 2 records returns success tuple with 2nd record" do
      socket = %Phoenix.LiveView.Socket{assigns: %{nav_ex_identity: "user_1"}}

      Enum.reduce(1..2, socket, fn n, socket ->
        request_path = "/sample/request/#{n}"
        {:ok, socket} = ETS.insert(socket, request_path)
        socket
      end)

      assert {:ok, result_path} = ETS.last_path(socket)
      assert result_path == "/sample/request/1"
    end

    test "if user existis and has only 1 record returns success tuple with nil" do
      socket = %Phoenix.LiveView.Socket{assigns: %{nav_ex_identity: "user_1"}}
      request_path = "/sample/request/0"

      {:ok, socket} = ETS.insert(socket, request_path)

      assert {:ok, nil} = ETS.last_path(socket)
    end

    test "for not existing user returns not found error" do
      socket = %Phoenix.LiveView.Socket{assigns: %{}}

      assert {:error, :not_found} = ETS.last_path(socket)
    end
  end

  describe "path_at/2 (Plug.Conn)" do
    setup do
      RecordsStorage.delete_all_objects()

      %{}
    end

    test "if user existis returns Nth record counting from 0" do
      conn =
        Enum.reduce(1..2, conn(:get, "/sample/request/0"), fn n, conn ->
          request_path = "/sample/request/#{n}"

          conn =
            conn
            |> Map.put(:request_path, request_path)
            |> Plug.Session.call(@session_options)
            |> fetch_session()

          {:ok, conn} = ETS.insert(conn)
          conn
        end)

      assert {:ok, result_path} = ETS.path_at(conn, 1)
      assert result_path == "/sample/request/1"
    end

    test "if user existis but N exceeds user history returns success tuple with nil" do
      request_path = "/sample/request/0"
      conn = conn(:get, request_path) |> Plug.Session.call(@session_options) |> fetch_session()
      {:ok, conn} = ETS.insert(conn)

      assert {:ok, nil} = ETS.path_at(conn, 9)
    end

    test "for not existing user returns not found error" do
      conn =
        conn(:get, "/sample/request") |> Plug.Session.call(@session_options) |> fetch_session()

      assert {:error, :not_found} = ETS.last_path(conn)
    end
  end

  describe "path_at/2 (Phoenix.LiveView.Socket)" do
    setup do
      RecordsStorage.delete_all_objects()

      %{}
    end

    test "if user existis returns Nth record counting from 0" do
      socket = %Phoenix.LiveView.Socket{assigns: %{nav_ex_identity: "user_1"}}

      Enum.reduce(1..2, socket, fn n, socket ->
        request_path = "/sample/request/#{n}"
        {:ok, socket} = ETS.insert(socket, request_path)
        socket
      end)

      assert {:ok, result_path} = ETS.path_at(socket, 1)
      assert result_path == "/sample/request/1"
    end

    test "if user existis but N exceeds user history returns success tuple with nil" do
      socket = %Phoenix.LiveView.Socket{assigns: %{nav_ex_identity: "user_1"}}
      request_path = "/sample/request/0"

      {:ok, socket} = ETS.insert(socket, request_path)

      assert {:ok, nil} = ETS.path_at(socket, 9)
    end

    test "for not existing user returns not found error" do
      socket = %Phoenix.LiveView.Socket{assigns: %{}}

      assert {:error, :not_found} = ETS.last_path(socket)
    end
  end
end
