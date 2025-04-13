defmodule Logzio.LogzioClient do
  @moduledoc false

  @behaviour Logzio.Logzio

  alias Req.{Request, Response}

  @impl true
  def me, do: endpoint("/whoami")

  @impl true
  def get_alert_by_id(alert_id) when is_integer(alert_id) and alert_id > 0 do
    endpoint("/alerts/#{alert_id}")
  end

  defp endpoint(path, method \\ :get, params \\ []) when method in [:get, :post] do
    url = put_params(base_url() <> path, params)

    req =
      Req.new(method: method, url: url)
      |> Request.put_new_header("Content-Type", "application/json")
      |> Request.put_new_header("X-API-Key", api_key())

    case Request.run_request(req) do
      {_, %Response{status: 200} = response} ->
        response.body

      {_, %Response{status: status}} ->
        {:error, status}

      {_, exception} ->
        {:error, RuntimeError.exception(inspect(exception))}
    end
  end

  defp put_params(url, params) do
    encoded = URI.encode_query(params)
    url <> "?" <> encoded
  end

  def test_env, do: IO.puts(base_url() <> " " <> api_key())

  defp base_url, do: Application.get_env(:notifeye, :logz_base_url)

  defp api_key, do: Application.get_env(:notifeye, :logz_api_key)
end
