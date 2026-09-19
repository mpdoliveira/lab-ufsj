# executar_todos.exs
# Executa todos os relatórios (A, B, C, D) para os dois arquivos de log

# Lista de logs e scripts
logs = [
  "log_semana_esquenta.txt",
  "log_hora_virada_antecipada.txt"
]

relatorios = [
  "relatorioA.exs",
  "relatorioB.exs",
  "relatorioC.exs",
  "relatorioD.exs"
]

# Verifica se todos os arquivos existem antes de rodar
Enum.each(logs ++ relatorios, fn arquivo ->
  unless File.exists?(arquivo) do
    IO.puts("Arquivo não encontrado: #{arquivo}")
    System.halt(1)
  end
end)

# Função auxiliar para rodar um script e capturar saída
defmodule Executor do
  def run(script, log) do
    IO.puts("\nRodando #{script} para #{log} ...")

    {saida, status} =
      System.cmd("elixir", [script, log], stderr_to_stdout: true)

    IO.puts(saida)

    if status == 0 do
      IO.puts("#{script} concluído com sucesso!\n")
    else
      IO.puts("Erro ao executar #{script} para #{log}\n")
    end
  end
end

# Executa todos
Enum.each(logs, fn log ->
  IO.puts("\n===============================")
  IO.puts("Processando: #{log}")
  IO.puts("===============================")

  Enum.each(relatorios, fn script ->
    Executor.run(script, log)
  end)
end)

IO.puts("\n🎉 Todos os relatórios foram gerados com sucesso!")
