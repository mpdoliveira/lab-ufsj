# relatorioA.exs
# Executar no terminal:
# elixir .\relatorioA.exs .\log_semana_esquenta.txt

[path] = System.argv()

# Extrair o nome base do arquivo (sem caminho e sem extensão)
nome_base =
  path
  |> Path.basename(".txt")           # ex: "log_semana_esquenta"
  |> String.replace_prefix("log_", "") # remove prefixo "log_" se houver

# Nome dinâmico do arquivo de saída
nome_saida = "histograma_por_hora_#{nome_base}.csv"

# Ler e converter o log em uma lista de mapas
logs =
  File.stream!(path)
  |> Stream.map(&String.trim/1)
  |> Stream.map(&String.split(&1, " "))
  |> Stream.filter(fn partes -> length(partes) == 6 end) # ignora linhas inválidas
  |> Enum.map(fn [timestamp, _metodo, _endpoint, status_str, latency_str, _user_id] ->
    # Extrai a hora (UTC) do timestamp ISO (ex.: 2025-11-22T14:05:23Z → 14)
    hora =
      case String.slice(timestamp, 11, 2) do
        nil -> 0
        h -> String.to_integer(h)
      end

    %{
      hora: hora,
      status: String.to_integer(status_str),
      latency: String.to_integer(latency_str)
    }
  end)

# Agrupar por hora
agrupado = Enum.group_by(logs, fn log -> log.hora end)

# Calcular métricas para cada hora
linhas =
  Enum.map(agrupado, fn {hora, lista} ->
    latencias = Enum.map(lista, & &1.latency)
    total = length(latencias)
    media = Enum.sum(latencias) / total

    # Calcular mediana
    ordenadas = Enum.sort(latencias)
    mediana =
      if rem(total, 2) == 1 do
        Enum.at(ordenadas, div(total, 2))
      else
        meio = div(total, 2)
        (Enum.at(ordenadas, meio - 1) + Enum.at(ordenadas, meio)) / 2
      end

    # Contar erros 5xx
    erros_5xx = Enum.count(lista, fn l -> l.status >= 500 and l.status < 600 end)

    [hora, total, Float.round(media, 2), mediana, erros_5xx]
  end)

# Gerar o CSV ordenado por hora
cabecalho = ["hora", "total_requisicoes", "latencia_media", "latencia_mediana", "erros_5xx"]

csv =
  [cabecalho | Enum.sort_by(linhas, fn [hora | _] -> hora end)]
  |> Enum.map(&Enum.join(&1, ","))
  |> Enum.join("\n")

File.write!(nome_saida, csv)

IO.puts("Relatório gerado: #{nome_saida}")
