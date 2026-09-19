# Executar:
# elixir relatorio_rotas_mais_custosas_semana_esquenta.exs log_semana_esquenta.txt

[path] = System.argv()

# Ler logs e transformar em mapa
logs =
  File.stream!(path)
  |> Enum.map(fn linha ->
    [timestamp, _metodo, endpoint, status_str, latency_str, _user_id] =
      String.split(String.trim(linha), " ")

    %{
      endpoint: endpoint,
      status: String.to_integer(status_str),
      latency: String.to_integer(latency_str)
    }
  end)

# Agrupar por endpoint
por_endpoint = Enum.group_by(logs, fn log -> log.endpoint end)

# Calcular métricas
linhas =
  Enum.map(por_endpoint, fn {endpoint, lista} ->
    total = length(lista)
    soma_latencias = Enum.sum_by(lista, & &1.latency)

    # custo estimado (ajustável)
    custo = soma_latencias * 0.001

    [endpoint, total, soma_latencias, Float.round(custo, 3)]
  end)

# Ordenar por custo (desc) e pegar Top-5
top5 =
  linhas
  |> Enum.sort_by(fn [_endpoint, _total, _sum, custo] -> custo end, :desc)
  |> Enum.take(5)

# Cabeçalho
cabecalho = ["endpoint", "total_requisicoes", "soma_latencias_ms", "custo_estimado"]

# Nome do arquivo com padrão exigido
nome_campanha =
  path
  |> Path.basename(".txt")
  |> String.replace("log_", "")

nome_arquivo = "rotas_mais_custosas_#{nome_campanha}.csv"

# Gerar o CSV final
csv =
  [cabecalho | top5]
  |> Enum.map(&Enum.join(&1, ","))
  |> Enum.join("\n")

File.write!(nome_arquivo, csv)
IO.puts("Relatório gerado: #{nome_arquivo}")
