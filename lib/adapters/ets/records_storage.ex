defmodule NavEx.Adapters.ETS.RecordsStorage do
  @moduledoc """
  NavEx.Adapters.ETS.RecordsStorage is a GenServer that manages the navigation history of users using ETS (Erlang Term Storage).
  """
  use GenServer

  @table_name Application.compile_env(:nav_ex, :adapter_config)[:table_name] ||
                :navigation_history
  @history_length (Application.compile_env(:nav_ex, :history_length) || 10) + 1

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_opts) do
    table = :ets.new(@table_name, [:set, :public, :named_table])
    {:ok, %{table_name: table}}
  end

  ###

  def insert(user_identity, request_path) do
    case :ets.lookup(@table_name, user_identity) do
      [] ->
        {:ok, :ets.insert(@table_name, {user_identity, [request_path]})}

      [user_data] ->
        handle_user_data(user_data, request_path)
    end
  end

  def list(user_identity) do
    {:ok, :ets.lookup(@table_name, user_identity)}
  end

  def last_path(user_identity) do
    case :ets.lookup(@table_name, user_identity) do
      [] ->
        {:error, :not_found}

      [{_user_identity, history}] ->
        {:ok, Enum.at(history, 1)}
    end
  end

  def path_at(user_identity, n) when n < @history_length - 1 do
    case :ets.lookup(@table_name, user_identity) do
      [] ->
        {:error, :not_found}

      [{_user_identity, history}] ->
        {:ok, Enum.at(history, n)}
    end
  end

  def delete_user(user_identity) do
    :ets.delete(@table_name, user_identity)
  end

  def delete_all_objects, do: :ets.delete_all_objects(@table_name)

  ###

  defp handle_user_data({user_identity, navigation_history}, request_path) do
    if length(navigation_history) < @history_length do
      {:ok, :ets.insert(@table_name, {user_identity, [request_path | navigation_history]})}
    else
      [_last | cut_navigation_history] = Enum.reverse(navigation_history)
      to_be_stored = Enum.reverse(cut_navigation_history)

      {:ok, :ets.insert(@table_name, {user_identity, [request_path | to_be_stored]})}
    end
  end
end
