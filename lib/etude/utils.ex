defmodule Etude.Utils do
  def ready do
    :__ETUDE_READY__
  end

  def get_bin_or_atom(attrs, key, default \\ nil) do
    Dict.get(attrs, key, Dict.get(attrs, to_string(key), default))
  end
end