defmodule EtudeTest.QC.Helper do
  def start_link do
    Agent.start_link(fn ->
      {HashSet.new}
    end, name: __MODULE__)
  end

  def get_vars() do
    Agent.get(__MODULE__, fn {vars} ->
      vars |> HashSet.to_list
    end)
  end

  def put_var(name) do
    Agent.update(__MODULE__, fn {vars} ->
      {Set.put(vars, name)}
    end)
  end

  def delete_var(name) do
    Agent.update(__MODULE__, fn {vars} ->
      {Set.delete(vars, name)}
    end)
  end

  def exists_var(name) do
    Agent.get(__MODULE__, fn {vars} ->
      Set.member?(vars, name)
    end)
  end

  def reset do
    Agent.update(__MODULE__, fn _ ->
      {HashSet.new}
    end)
  end
end