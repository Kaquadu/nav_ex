defmodule NavEx.Adapter do
  @moduledoc """
    Behaviour of the NavEx adapter saving the navigation history data.
  """

  @doc """
    Lists children of the adapter to be started with the application.
    For example ETS table if your adapter needs it.
  """
  @callback children() :: list

  @doc """
    Inserts the path into user's navigation history. Takes %Plug.Conn{} as
    an argument, based on that fetches or creates user's identity (for
    example as an ID in session) and saves his path into the storage.
  """
  @callback insert(%Plug.Conn{}) :: {:ok, %Plug.Conn{}}
  @callback insert(%Phoenix.LiveView.Socket{}, String.t()) :: {:ok, %Phoenix.LiveView.Socket{}}

  @doc """
    Lists user navigation history. In case if user is not found returns
    {:error, :not_found} tuple.
  """
  @callback list(%Plug.Conn{}) :: {:ok, list} | {:error, :not_found}
  @callback list(%Phoenix.LiveView.Socket{}) :: {:ok, list} | {:error, :not_found}

  @doc """
    Returns user's last path. In case if user is not found or has no last
    path returns error tuple.
  """
  @callback last_path(%Plug.Conn{}) :: {:ok, String.t()} | {:error, atom}
  @callback last_path(%Phoenix.LiveView.Socket{}) :: {:ok, String.t()} | {:error, atom}

  @doc """
    Returns user's Nth last path. In case if user is not found returns
    an error tuple. In case if number exceeds the navigation history limit
    returns an error tuple. In case if number exceed the user's navigation
    history records number returns an error tuple.
  """
  @callback path_at(%Plug.Conn{}, number) :: {:ok, String.t()} | {:error, atom}
  @callback path_at(%Phoenix.LiveView.Socket{}, number) :: {:ok, String.t()} | {:error, atom}
end
