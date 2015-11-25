defmodule Etude.Codegen do
  def to_forms(contents, _opts) do
    string = contents |> to_string |> String.to_char_list
    {:ok, tokens, _} = :erl_scan.string(string)
    {forms, _} = Enum.reduce(tokens, {[], []}, fn
      ({:dot, _} = dot, {forms, acc}) ->
        {:ok, form} = :erl_parse.parse_form(:lists.reverse([dot | acc]))
        {[form | forms], []}
      (token, {forms, acc}) ->
        {forms, [token | acc]}
    end)
    forms
    |> :lists.reverse
    |> :rebind.parse_transform([])
    |> :lineo.parse_transform([])
  end

  def to_beam(forms, opts) do
    opts = [
      :binary,
      :report_errors,
      {:source, to_char_list(opts[:file])},
      :no_error_module_mismatch
    ] ++ opts

    case :compile.forms(forms, opts) do
      {:ok, mod, bin} ->
        {:ok, mod, opts[:main], bin}
      other ->
        other
    end
  end
end
