defmodule NavEx.RecordsStorage do
  use GenServer

  @table_name Application.compile_env(:nav_ex, :table_name) || :navigation_history
  @history_length (Application.compile_env(:nav_ex, :table_name) || 10) + 1

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_opts) do
    table = :ets.new(@table_name, [:set, :public, :named_table])
    {:ok, %{table_name: table}}
  end

  ###

  def insert(hashed_user, request_path) do
    case :ets.lookup(@table_name, hashed_user) do
      [] ->
        {:ok, :ets.insert(@table_name, {hashed_user, [request_path]})}

      [user_data] ->
        handle_user_data(user_data, request_path)
    end
  end

  def list(hashed_user) do
    {:ok, :ets.lookup(@table_name, hashed_user)}
  end

  def last_path(hashed_user) do
    case :ets.lookup(@table_name, hashed_user) do
      [] ->
        {:error, :not_found}

      [{_hashed_user, history}] ->
        {:ok, Enum.at(history, 1)}
    end
  end

  def path_at(hashed_user, n) when n < @history_length - 1 do
    case :ets.lookup(@table_name, hashed_user) do
      [] ->
        {:error, :not_found}

      [{_hashed_user, history}] ->
        {:ok, Enum.at(history, n)}
    end
  end

  def path_at(_hashed_user, n) do
    raise ArgumentError,
      message:
        "Max history depth is #{@history_length - 1} counted from 0 to #{@history_length - 2}. You asked for record number #{n}."
  end

  def delete_user(hashed_user) do
    :ets.delete(@table_name, hashed_user)
  end

  def delete_all_objects, do: :ets.delete_all_objects(@table_name)

  ###

  defp handle_user_data({hashed_user, navigation_history}, request_path) do
    if length(navigation_history) < @history_length do
      {:ok, :ets.insert(@table_name, {hashed_user, [request_path | navigation_history]})}
    else
      cut_navigation_history =
        navigation_history
        |> Enum.reverse()
        |> tl()
        |> Enum.reverse()

      {:ok, :ets.insert(@table_name, {hashed_user, [request_path | cut_navigation_history]})}
    end
  end
end
