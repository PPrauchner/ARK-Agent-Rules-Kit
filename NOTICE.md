# Atribuição

Este repositório contém trabalho de terceiros. Tudo aqui está sob a licença MIT
(ver [`LICENSE`](./LICENSE)), que é a licença do material original — a condição
dela é preservar o aviso de copyright, e é isso que este arquivo faz.

---

## Material de terceiros

### `mattpocock/skills`

- **Origem:** https://github.com/mattpocock/skills
- **Autor:** Matt Pocock
- **Licença:** MIT — Copyright (c) 2026 Matt Pocock
- **Importado em:** commit `a41ec41` (2026-07-08), sem modificações no conteúdo
  das skills.

As seguintes skills em `.claude/skills/` vieram desse repositório:

| Skill | |
|---|---|
| `caveman` | `to-issues` |
| `diagnose` | `to-prd` |
| `grill-me` | `triage` |
| `grill-with-docs` | `write-a-skill` |
| `handoff` | `zoom-out` |
| `improve-codebase-architecture` | |
| `prototype` | |
| `setup-matt-pocock-skills` | |
| `tdd` | |
| `teach` | |

O índice `.claude/skills/README.md` também deriva do original, com entradas
adicionadas para o que foi escrito aqui.

### `multica-ai/andrej-karpathy-skills`

- **Origem:** https://github.com/multica-ai/andrej-karpathy-skills
- **Licença:** o repositório declara MIT no README, mas não inclui arquivo
  `LICENSE` nem nomeia um titular de copyright. Por isso não há aviso a
  reproduzir em [`LICENSE`](./LICENSE) — esta seção é a atribuição.

`.claude/rules/karpathy-principles.md` é uma tradução para português do
`CLAUDE.md` daquele repositório: os quatro princípios (pense antes de codar,
simplicidade primeiro, mudanças cirúrgicas, execução orientada a metas) vêm de
lá, na mesma ordem e estrutura.

O texto original é da multica-ai; os princípios que ele sistematiza são
observações de **Andrej Karpathy** sobre erros comuns de LLMs em coding, como a
própria descrição do repositório indica. Karpathy não é autor do texto nem
está associado a nenhum dos repositórios.

---

## Material autoral deste repositório

Copyright (c) 2026 Pietro Mendes Prauchner — MIT.

- `.claude/skills/adopt-repo/` — adoção de repositórios já em andamento.
- `.claude/commands/` — `/commit`, `/start-issue`, `/review-pr`, `/open-pr`,
  `/afk-queue`.
- `.claude/rules/` — `code-conventions.md`, `python-conventions.md`,
  `java-conventions.md`, `javascript-conventions.md`, `typescript-conventions.md`,
  `c-conventions.md`, `cpp-conventions.md`, `html-conventions.md`,
  `css-conventions.md`, `shell-conventions.md` e `sql-conventions.md`
  (`karpathy-principles.md` não; ver acima).
- `.claude/hooks/` — `stop-commit-reminder.sh`, hook de log de grill.
- `.claude/scripts/` — `link-skills.sh`, `list-skills.sh`, `board-move.sh`.
- `.claude/settings.json` e o template `settings.local.json.example`.
- `docs/grills_logs/` e o `README.md` da raiz.
