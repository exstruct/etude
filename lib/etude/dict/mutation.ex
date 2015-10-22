defmodule Etude.Dict.Mutation do
  defstruct dict: nil,
            operations: []

  defmodule NewNotSupported do
    defexception [:message]
  end

  use Dict

  def wrap(%__MODULE__{} = mutation, _) do
    mutation
  end
  def wrap(dict, function, arguments) do
    %__MODULE__{dict: dict, operations: [operation_id(dict, function, arguments)]}
  end

  def unwrap(%{dict: dict}) do
    dict
  end

  def operation_id(dict, function, arguments) do
    cache_key = Etude.Dict.cache_key(dict)
    Etude.Runtime.hash({cache_key, function, arguments})
  end

  ## Dict interface

  def new do
    raise NewNotSupported
  end

  def delete(prev = %{dict: dict, operations: operations}, key) do
    operation = operation_id(dict, :delete, [key])
    %{prev | dict: Dict.delete(dict, key), operations: [operation | operations]}
  end

  def fetch(%{dict: dict}, key) do
    Dict.fetch(dict, key)
  end

  def put(prev = %{dict: dict, operations: operations}, key, value) do
    operation = operation_id(dict, :put, [key, value])
    %{prev | dict: Dict.put(dict, key, value), operations: [operation | operations]}
  end

  def reduce(%{dict: dict}, acc, fun) do
    Enumerable.reduce(dict, acc, fun)
  end

  def size(%{dict: dict}) do
    Dict.size(dict)
  end
end

defimpl Etude.Dict, for: Etude.Dict.Mutation do
  use Etude.Dict

  def cache_key(%{operations: operations, dict: dict}) do
    {__MODULE__, Etude.Runtime.hash(operations), Etude.Dict.cache_key(dict)}
  end

  def delete(prev = %{dict: dict, operations: operations}, key, op_ref) do
    case Etude.Dict.delete(dict, key, op_ref) do
      {:ok, value, fetched} ->
        operation = Etude.Dict.Mutation.operation_id(dict, :delete, [key])
        {:ok, %{prev | dict: value, operations: [operation | operations]}, %{prev | dict: fetched}}
      {:error, error, fetched} ->
        {:error, error, %{prev | dict: fetched}}
      {:pending, fetched} ->
        {:pending, %{prev | dict: fetched}}
      {:pending, pid, fetched} ->
        {:pending, pid, %{prev | dict: fetched}}
    end
  end

  def fetch(prev = %{dict: dict}, key, op_ref) do
    case Etude.Dict.fetch(dict, key, op_ref) do
      {:ok, value, fetched} ->
        {:ok, value, %{prev | dict: fetched}}
      {:error, fetched} ->
        {:error, %{prev | dict: fetched}}
      {:error, error, fetched} ->
        {:error, error, %{prev | dict: fetched}}
      {:pending, fetched} ->
        {:pending, %{prev | dict: fetched}}
      {:pending, pid, fetched} ->
        {:pending, pid, %{prev | dict: fetched}}
    end
  end

  def load(prev = %{dict: dict}, op_ref) do
    case Etude.Dict.load(dict, op_ref) do
      {:ok, fetched} ->
        {:ok, %{prev | dict: fetched}}
      {:error, fetched} ->
        {:error, %{prev | dict: fetched}}
      {:error, error, fetched} ->
        {:error, error, %{prev | dict: fetched}}
      {:pending, fetched} ->
        {:pending, %{prev | dict: fetched}}
      {:pending, pid, fetched} ->
        {:pending, pid, %{prev | dict: fetched}}
    end
  end

  def put(prev = %{dict: dict, operations: operations}, key, value, op_ref) do
    case Etude.Dict.put(dict, key, value, op_ref) do
      {:ok, value, fetched} ->
        operation = Etude.Dict.Mutation.operation_id(dict, :put, [key, value])
        {:ok, %{prev | dict: value, operations: [operation | operations]}, %{prev | dict: fetched}}
      {:error, error, fetched} ->
        {:error, error, %{prev | dict: fetched}}
      {:pending, fetched} ->
        {:pending, %{prev | dict: fetched}}
      {:pending, pid, fetched} ->
        {:pending, pid, %{prev | dict: fetched}}
    end
  end

  def size(prev = %{dict: dict}, op_ref) do
    case Etude.Dict.size(dict, op_ref) do
      {:ok, value, fetched} ->
        {:ok, value, %{prev | dict: fetched}}
      {:error, error, fetched} ->
        {:error, error, %{prev | dict: fetched}}
      {:pending, fetched} ->
        {:pending, %{prev | dict: fetched}}
      {:pending, pid, fetched} ->
        {:pending, pid, %{prev | dict: fetched}}
    end
  end
end
