defmodule NavEx.LiveOnMountTest do
  use NavEx.ConnCase, async: true

  alias NavEx.LiveOnMount

  @session_key Application.compile_env(:nav_ex, :session_key) || "nav_ex_user_identity"

  test "on_mount assigns user identity from session" do
    user_identity = "test_user"
    session = %{@session_key => user_identity}

    {:cont, socket} = LiveOnMount.on_mount(:nav_ex_init, %{}, session, %Phoenix.LiveView.Socket{})

    assert socket.assigns[:nav_ex_user_identity] == user_identity
  end

  test "on_mount raises error if user identity is not in session" do
    session = %{}

    assert_raise ArgumentError, fn ->
      LiveOnMount.on_mount(:nav_ex_init, %{}, session, %Phoenix.LiveView.Socket{})
    end
  end
end
