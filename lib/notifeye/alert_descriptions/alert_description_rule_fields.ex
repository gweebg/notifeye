defmodule Notifeye.AlertDescriptions.Rule.Fields do
  @moduledoc """
  Describes the available fields to be used on a rule creation.
  """

  @severities ~w(low medium high)

  @equality_operators ~w(is is_not)
  @string_operators ~w(contains does_not_contain matches does_not_match starts_with ends_with)
  @list_operators ~w(include exclude)
  @datetime_operators ~w(after_datetime before_datetime)
  @time_operators ~w(after_time before_time)

  @fields %{
    "alert_title" => %{operators: @equality_operators ++ @string_operators},
    "alert_description" => %{operators: @equality_operators ++ @string_operators},
    "alert_severity" => %{operators: @equality_operators, values: @severities},
    "alert_tags" => %{operators: @list_operators},
    "start" => %{operators: @time_operators, format: :time},
    "end" => %{operators: @time_operators, format: :time},
    "inserted_at" => %{operators: @datetime_operators, format: :datetime}
  }

  def definitions, do: @fields
  def valid_fields, do: Map.keys(@fields)
  def valid_operators(field), do: @fields[field][:operators] || []
  def valid_values(field), do: @fields[field][:values] || []
  def format_for(field), do: @fields[field][:format]
  def severities, do: @severities

  def alert_field_mapping(alert, field) do
    case field do
      "alert_title" -> alert.alert_title
      "alert_description" -> alert.alert_description
      "alert_severity" -> alert.alert_severity
      "alert_tags" -> alert.alert_tags
      "start" -> alert.start
      "end" -> alert.end
      "inserted_at" -> alert.inserted_at
      _ -> nil
    end
  end

  def op_to_func("is"), do: &(&1 == &2)
  def op_to_func("is_not"), do: &(&1 != &2)
  def op_to_func("contains"), do: fn a, b -> is_binary(a) and String.contains?(a, b) end

  def op_to_func("does_not_contains"),
    do: fn a, b -> is_binary(a) and not String.contains?(a, b) end

  def op_to_func("matches"), do: &regex_match?(&1, &2)
  def op_to_func("does_not_match"), do: not (&regex_match?(&1, &2))
  def op_to_func("starts_with"), do: fn a, b -> is_binary(a) and String.starts_with?(a, b) end
  def op_to_func("ends_with"), do: fn a, b -> is_binary(a) and String.ends_with?(a, b) end
  def op_to_func("include"), do: fn a, b -> is_list(a) and b in a end
  def op_to_func("exclude"), do: fn a, b -> is_list(a) and b not in a end
  def op_to_func("before_datetime"), do: &compare_datetime(&1, &2, :before)
  def op_to_func("after_datetime"), do: &compare_datetime(&1, &2, :after)
  def op_to_func("before_time"), do: &compare_time(&1, &2, :before)
  def op_to_func("after_time"), do: &compare_time(&1, &2, :after)
  def op_to_func(_), do: nil

  defp regex_match?(value, pattern) when is_binary(value) and is_binary(pattern) do
    case Regex.compile(pattern, "i") do
      {:ok, re} -> String.match?(value, re)
      {:error, _} -> false
    end
  end

  defp regex_match?(_, _), do: false

  defp compare_datetime(nil, _, _), do: false

  defp compare_datetime(a_dt, expected, cmp) do
    case DateTime.from_iso8601(expected) do
      {:ok, b_dt, _} ->
        compare_values(DateTime.compare(a_dt, b_dt), cmp)

      _ ->
        false
    end
  end

  defp compare_time(nil, _, _), do: false

  defp compare_time(%Time{} = a, expected, cmp) when is_binary(expected) do
    case Time.from_iso8601(expected) do
      {:ok, b} ->
        compare_values(Time.compare(a, b), cmp)

      _ ->
        false
    end
  end

  defp compare_values(:lt, :before), do: true
  defp compare_values(:gt, :after), do: true
  defp compare_values(_, _), do: false
end
