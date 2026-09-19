# relatorioB.exs
# Executar:
# elixir .\relatorioB.exs .\log_semana_esquenta.txt

[path] = System.argv()

# Extrair o nome base do arquivo de entrada (sem caminho e sem extensão)
nome_base =
  path
  |> Path.basename(".txt")           # ex: "log_semana_esquenta"
  |> String.replace_prefix("log_", "") # remove prefixo "log_" se houver

# Nome dinâmico de saída
nome_saida = "regulatorio_sem_5xx_#{nome_base}.csv"

# Ler e filtrar logs válidos (sem status 5xx)
logs =
  File.stream!(path)
  |> Stream.map(&String.trim/1)
  |> Stream.map(&String.split(&1, " "))
  |> Stream.filter(fn partes -> length(partes) == 6 end)
  |> Enum.map(fn [timestamp, metodo, endpoint, status_str, latency_str, user_id] ->
    %{
      timestamp: timestamp,
      metodo: metodo,
      endpoint: endpoint,
      status: String.to_integer(status_str),
      latency: String.to_integer(latency_str),
      user_id: user_id
    }
  end)
  |> Enum.filter(fn l -> l.status < 500 end)

# Métricas gerais
total_requisicoes = length(logs)
usuarios_distintos = logs |> Enum.map(& &1.user_id) |> Enum.uniq() |> length()
endpoints_distintos = logs |> Enum.map(& &1.endpoint) |> Enum.uniq() |> length()

# Contar classes de status
qtd_2xx = Enum.count(logs, fn l -> l.status >= 200 and l.status < 300 end)
qtd_3xx = Enum.count(logs, fn l -> l.status >= 300 and l.status < 400 end)
qtd_4xx = Enum.count(logs, fn l -> l.status >= 400 and l.status < 500 end)

# Endpoints mais acessados (sem 5xx)
top_endpoints =
  logs
  |> Enum.group_by(& &1.endpoint)
  |> Enum.map(fn {endpoint, lista} ->
    latencias = Enum.map(lista, & &1.latency)
    media = Enum.sum(latencias) / length(latencias)
    {endpoint, length(lista), Float.round(media, 2)}
  end)
  |> Enum.sort_by(fn {_ep, qtd, _lat} -> -qtd end)
  |> Enum.take(5)

# Usuários com mais respostas 4xx
usuarios_4xx =
  logs
  |> Enum.filter(fn l -> l.status >= 400 and l.status < 500 end)
  |> Enum.group_by(& &1.user_id)
  |> Enum.map(fn {user, lista} -> {user, length(lista)} end)
  |> Enum.sort_by(fn {_u, qtd} -> -qtd end)
  |> Enum.take(5)

# Montar CSV principal
cabecalho = [
  "total_requisicoes",
  "usuarios_distintos",
  "endpoints_distintos",
  "qtd_2xx",
  "qtd_3xx",
  "qtd_4xx"
]

linha_principal = [
  total_requisicoes,
  usuarios_distintos,
  endpoints_distintos,
  qtd_2xx,
  qtd_3xx,
  qtd_4xx
]

# Escrever CSV
linhas_csv = [
  Enum.join(cabecalho, ","),
  Enum.join(Enum.map(linha_principal, &to_string/1), ","),
  "",
  "Top 5 Endpoints (sem 5xx): endpoint,qtd,latencia_media",
  Enum.map(top_endpoints, fn {e, q, l} -> "#{e},#{q},#{l}" end) |> Enum.join("\n"),
  "",
  "Top 5 Usuários com mais 4xx: user_id,qtd_4xx",
  Enum.map(usuarios_4xx, fn {u, q} -> "#{u},#{q}" end) |> Enum.join("\n")
]

csv = Enum.join(linhas_csv, "\n")

File.write!(nome_saida, csv)

IO.puts("Relatório gerado: #{nome_saida}")
