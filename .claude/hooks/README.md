# Hooks

Scripts que o Claude Code executa sozinho, em eventos da sessão. Ao contrário das
skills e dos comandos, **ninguém os invoca** — eles rodam a partir do registro em
[`../settings.json`](../settings.json).

- **[stop-commit-reminder.sh](./stop-commit-reminder.sh)** (`Stop`) — ao encerrar a
  sessão, lista o que ficou sem commitar (staged, modificado, novo) e a issue ativa
  (lida por [`current-issue.sh`](../scripts/current-issue.sh), na raiz do projeto),
  com o comando de commit já montado. Se a pasta do projeto não for um repositório
  — uma pasta de trabalho que agrupa repositórios irmãos —, confere cada subpasta de
  primeiro nível que for repositório git. Só avisa; não commita nada nem bloqueia o
  encerramento.
- **[grill-log.sh](./grill-log.sh)** (`UserPromptExpansion`, matcher
  `grill-(me|with-docs)`) — injeta no contexto a diretiva para registrar a sessão de
  grill em `docs/grills_logs/<assunto>.md`, com o horário de início. O hook não
  escreve arquivo nem sabe o assunto: quem escolhe o slug e escreve o log é o agente.
  Dispara apenas quando você **digita** `/grill-me` ou `/grill-with-docs` — invocar a
  skill por linguagem natural não aciona o evento.

## Desligar

`GRILL_LOG=off` no bloco `env` de [`../settings.json`](../settings.json) desativa o
log de grill. O lembrete de commit não tem toggle: para tirá-lo, remova a entrada
`Stop` do `settings.json`.

## Fim de linha

São arquivos `.sh` executados por bash — precisam de fim de linha **LF**. Com CRLF,
o bash falha com `\r: command not found`. Se editar no Windows, confira o EOL antes
de commitar.
