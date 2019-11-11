defmodule ExGdax.Api do
  @moduledoc """
  Provides basic HTTP interface with GDAX API.
  """
  alias ExGdax.Config

  def get(path, params \\ %{}, config \\ nil) do
    config = Config.config_or_env_config(config)
    qs = query_string(path, params)

    qs
    |> url(config)
    |> HTTPoison.get(headers("GET", qs, %{}, config))
    |> parse_response()
  end

  def post(path, params \\ %{}, config \\ nil) do
    config = Config.config_or_env_config(config)

    path
    |> url(config)
    |> HTTPoison.post(Jason.encode!(params), headers("POST", path, params, config))
    |> parse_response()
  end

  def delete(path, config \\ nil) do
    config = Config.config_or_env_config(config)

    path
    |> url(config)
    |> HTTPoison.delete(headers("DELETE", path, %{}, config))
    |> parse_response()
  end

  defp url(path, config), do: config.api_url <> path

  defp query_string(path, params) when map_size(params) == 0, do: path

  defp query_string(path, params) do
    query =
      params
      |> Enum.map(fn {key, val} -> "#{key}=#{val}" end)
      |> Enum.join("&")

    path <> "?" <> query
  end

  defp headers(method, path, body, config) do
    timestamp = :os.system_time(:seconds)

    [
      "Content-Type": "application/json",
      "CB-ACCESS-KEY": config.api_key,
      "CB-ACCESS-SIGN": sign_request(timestamp, method, path, body, config),
      "CB-ACCESS-TIMESTAMP": timestamp,
      "CB-ACCESS-PASSPHRASE": config.api_passphrase
    ]
  end

  defp sign_request(timestamp, method, path, body, config) do
    key = Base.decode64!(config.api_secret || "")
    body = if Enum.empty?(body), do: "", else: Jason.encode!(body)
    data = "#{timestamp}#{method}#{path}#{body}"

    :sha256
    |> :crypto.hmac(key, data)
    |> Base.encode64()
  end

  defp parse_response({:ok, %HTTPoison.Response{body: body, status_code: code}}) when code in 200..299, do: Jason.decode(body)
  defp parse_response({:ok, %HTTPoison.Response{body: body, status_code: code}}) do
    {:error, {case Jason.decode(body) do
      {:ok, json} -> json["message"]
      {:error, _} -> body
    end, code}}
  end
  defp parse_response({:error, %HTTPoison.Error{reason: reason}}), do: {:error, reason}
end
