defmodule Etude.Fixtures.User do
  defstruct id: nil,
            name: nil,
            email: nil,
            friends: :unfetched,
            __status__: :unfetched

  # use Dict

  def fetch(%{id: id}, :id) do
    {:ok, id}
  end
  def fetch(%{name: name}, :name) do
    {:ok, name}
  end
  def fetch(%{email: email}, :email) do
    {:ok, email}
  end
  def fetch(%{friends: friends}, :friends) do
    {:ok, friends}
  end
  def fetch(_, _) do
    :error
  end
end

defimpl Etude.Dict, for: Etude.Fixtures.User do
  use Etude.Dict

  def cache_key(%{id: id}) do
    {Etude.Fixtures.User, id}
  end

  def fetch(dict = %{id: id}, :id, _) do
    {:ok, id, dict}
  end
  def fetch(dict = %{id: id, __status__: :unfetched}, key, ref) when key in [:name, :email] do
    pid = Etude.Async.spawn(ref, fn ->
      EtudeTestHelper.Random.sleep(10, 50)
      case id do
        "1" ->
          op = %{name: "Robert", email: "robert@example.com", __status__: :fetched}
          {:ok, op}
        "2" ->
          op = %{name: "Joe", email: "joe@example.com", __status__: :fetched}
          {:ok, op}
        "3" ->
          op = %{name: "Mike", email: "mike@example.com", __status__: :fetched}
          {:ok, op}
        _ ->
          {:error, :not_found}
      end
    end)
    {:pending, pid, %{dict | __status__: :fetching}}
  end
  def fetch(dict = %{id: id, friends: :unfetched}, :friends, ref) do
    pid = Etude.Async.spawn(ref, fn ->
      EtudeTestHelper.Random.sleep(10, 50)

      friends = ["1", "2", "3"]
      |> Enum.filter(&(&1 != id))
      |> Enum.map(&(%Etude.Fixtures.User{id: &1}))

      {:ok, %{friends: friends}}
    end)
    {:pending, pid, %{dict | friends: :fetching}}
  end
  def fetch(dict = %{__status__: :unfetched}, _, _) do
    {:error, dict}
  end
  def fetch(dict = %{friends: :fetching}, _, _) do
    {:pending, dict}
  end
  def fetch(dict = %{__status__: :fetching}, _, _) do
    {:pending, dict}
  end
  def fetch(dict = %{friends: friends}, :friends, _) do
    {:ok, friends, dict}
  end
  def fetch(dict = %{__status__: :fetched}, key, _) do
    case Dict.fetch(dict, key) do
      {:ok, value} ->
        {:ok, value, dict}
      :error ->
        {:error, dict}
    end
  end
end
