# Executar: elixir relatorio_endpoints_mais_lentos_semana_esquenta.exs log_semana_esquenta.txt

[path] = System.argv()

linhas =
  File.stream!(path)
  |> Enum.map(&String.trim/1)
  |> Enum.filter(& &1 != "")

# Função para cálculo de mediana
defmodule Estat do
  def mediana(valores) do
    ordenados = Enum.sort(valores)
    n = length(ordenados)

    case rem(n, 2) do
      1 ->
        Enum.at(ordenados, div(n, 2))

      0 ->
        (Enum.at(ordenados, div(n, 2) - 1) + Enum.at(ordenados, div(n, 2))) / 2
    end
  end
end

dados =
  linhas
  |> Enum.map(fn linha ->
    [timestamp, _method, endpoint, status_str, latency_str, _user] =
      String.split(linha, " ")

    status = String.to_integer(status_str)
    latency = String.to_integer(latency_str)

    {endpoint, status, latency}
  end)
  |> Enum.filter(fn {_e, status, _l} ->
    status >= 200 and status <= 499
  end)
  |> Enum.group_by(fn {endpoint, _status, _latency} -> endpoint end)
  |> Enum.map(fn {endpoint, reqs} ->
    latencias = Enum.map(reqs, fn {_e, _s, latency} -> latency end)
    qtd = length(latencias)
    media = Enum.sum(latencias) / qtd
    mediana = Estat.mediana(latencias)

    {endpoint, qtd, media, mediana}
  end)
  |> Enum.filter(fn {_e, qtd, _m, _d} ->
    qtd >= 2  # ajuste se necessário: volume mínimo por endpoint
  end)
  |> Enum.sort_by(fn {_e, _qtd, media, _d} -> media end, :desc)

csv_rows =
  [["endpoint", "qtd_requisicoes", "latencia_media_ms", "latencia_mediana_ms"]] ++
    Enum.map(dados, fn {endpoint, qtd, media, mediana} ->
      [
        endpoint,
        qtd,
        :erlang.float_to_binary(media, decimals: 2),
        :erlang.float_to_binary(mediana, decimals: 2)
      ]
    end)

csv =
  csv_rows
  |> Enum.map(&Enum.join(&1, ","))
  |> Enum.join("\n")

File.write!("endpoints_mais_lentos_semana_esquenta.csv", csv)

IO.puts("Relatório gerado: endpoints_mais_lentos_semana_esquenta.csv")
