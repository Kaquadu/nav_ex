defmodule NavEx.LiveOnMount do
  @moduledoc """
  NavEx.LiveOnMount is a module that provides functionality to hook the 
  navigation history with on_mount callback in Phoenix LiveView applications.
  """

  use Phoenix.LiveView

  @session_key Application.compile_env(:nav_ex, :identity_key) || "nav_ex_identity"

  @doc """
  Mounts the LiveView and assigns the user identity from the session.

  on_mount: [{NavEx.LiveOnMount, :nav_ex_init}]
  """
  def on_mount(:nav_ex_init, _params, session, socket) do
    user_identity = Map.get(session, @session_key)

    if is_nil(user_identity) do
      raise ArgumentError,
            "NavEx requires user identity to be set in session under the key '#{@session_key}'."
    end

    {:cont, assign(socket, :nav_ex_user_identity, user_identity)}
  end
end
