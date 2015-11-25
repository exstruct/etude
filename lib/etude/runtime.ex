defmodule Etude.Runtime do
  case :erlang.system_info(:otp_release) do
    '17' ->
      def hash(value) do
        value
        |> prepare_hash()
        |> :erlang.phash2()
      end
      def prepare_hash(value) when is_tuple(value) do
        value
        |> :erlang.tuple_to_list()
        |> prepare_hash()
        |> :erlang.list_to_tuple()
      end
      def prepare_hash(value) when is_map(value) do
        {:___ERLANG__MAPS___, value
        |> :maps.to_list()
        |> prepare_hash()}
      end
      def prepare_hash(value) when is_list(value) do
        for i <- value do
          prepare_hash(i)
        end
      end
      def prepare_hash(other) do
        other
      end
    _ ->
      defdelegate hash(value), to: :erlang, as: :phash2
  end
end
