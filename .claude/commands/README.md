# Workflow

Commands de workflow

- **[afk-queue](./afk-queue/SKILL.md)** — Work through a queue of AFK-ready issues unattended, one clean-context subagent per issue, so the session never accumulates unrelated history.
- **[commit](./commit/SKILL.md)** — Analisa mudanças não-commitadas e realiza commits atômicos seguindo as convenções do projeto.
- **[start-issue](./start-issue/SKILL.md)** — Inicia o trabalho em uma issue: lê a issue no tracker do projeto (`docs/agents/issue-tracker.md`), avalia complexidade e prepara a implementação. Move a issue para *In progress* no board.
- **[open-pr](./open-pr/SKILL.md)** — Abre o PR da branch atual, descobrindo nos rodapés dos commits quais issues foram implementadas, e move essas issues para *In review*.
- **[review-pr](./review-pr/SKILL.md)** — Revisa um PR quanto à conformidade com a issue/DoD e a documentação, delegando a análise de qualidade de código a um subagente sobre o PR inteiro, e executa a ação escolhida no GitHub. Com 2+ issues, avalia cada uma em um subagente paralelo.
- **[update-claude](./update-claude/SKILL.md)** — Atualiza o `.claude/` deste repositório para a versão vigente do template, preservando as customizações do projeto. Fora do pipeline: roda quando quiser, sem argumentos.
- **[sync-global](./sync-global/SKILL.md)** — Atualiza a [instalação global](../../README.md#instalação-global-sem-copiar-claude-por-projeto): puxa o clone do ARK e refaz os links em `~/.claude/skills`, trazendo skill nova e podando órfã. Fora do pipeline, e o par do `/update-claude` para o outro modelo de reuso — este escreve no perfil do usuário, aquele no `.claude/` de um projeto. Sem argumentos.

## Pipeline

`/start-issue` → `/tdd` → `/commit` → `/open-pr` → `/review-pr`, com o `/afk-queue`
orquestrando o trecho `start-issue → commit` para uma fila inteira de issues.

A sincronização com o GitHub Projects (*In progress* ao iniciar, *In review* ao abrir
o PR) é feita por [`scripts/board-move.sh`](../scripts/board-move.sh) e se desliga com
`BOARD_SYNC=off` no bloco `env` de `.claude/settings.json`.

## Toggles (`env` de `.claude/settings.json`)

| Chave | Efeito quando `off` |
|-------|---------------------|
| `BOARD_SYNC` | Issues não são movidas no board por `/start-issue` e `/open-pr`. |
| `PR_REVIEW_PARALLEL` | `/review-pr` avalia a conformidade de todas as issues inline, sem subagentes. |
| `GRILL_LOG` | Sessões de grill não são registradas em `docs/grills_logs/`. |
