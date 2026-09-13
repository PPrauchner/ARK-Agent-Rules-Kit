# Política de release do template

> Como uma Versão vigente sai daqui. Vale **só para este repositório** — é meta do
> template, não parte dele. Nada disto vive em `.claude/`, justamente para que
> nenhum Projeto adotado herde uma regra sobre versionar o template.
>
> Termos em maiúscula (Template, Projeto adotado, Versão vigente, Marcador de
> origem) estão definidos em [`CONTEXT.md`](../CONTEXT.md).

## Toda mudança de skill ou comando vira uma release

Sem branches novas — só tags anotadas + GitHub Releases na `versao_vigente`.

## Régua de bump (odômetro, **não** semver)

| Situação | Bump | Exemplo |
|---|---|---|
| Skill ou comando **novo** | MAJOR | `v1.0.0` → `v2.0.0` |
| **Alteração** de skill/comando existente | PATCH | `v2.0.0` → `v2.0.1` |
| PATCH passaria de 9 | rola para o MINOR | `v1.0.9` → `v1.1.0` |
| MINOR passaria de 9 | continua contando | `v1.9.0` → `v1.10.0` |

Não é semver porque não há breaking change a sinalizar: quem consome é o
`/update-claude`, e ele preserva o que o projeto customizou independentemente do
número. O MAJOR marca capacidade nova, não incompatibilidade.

O MINOR **nunca** invade o MAJOR: um acúmulo de patches não pode se disfarçar de
skill nova. O dígito do meio existe só como transbordo do PATCH.

## Unidade de release: a mudança lógica

Uma release por **capacidade entregue**, mesmo que toque vários comandos — cada tag
tem que ser um estado do template que funciona. Um `/start-issue` que move a issue
para *In progress* sem o `/open-pr` que move para *In review* é meia-feature e não
merece tag própria.

- Arquivos de apoio (`scripts/`, `hooks/`, `rules/`) entram na release da skill que
  servem.
- `README` e `docs/` sozinhos **não** geram release.
- Se a mudança lógica inclui um comando novo, a release inteira é MAJOR — foi o caso
  da `v2.0.0` (board sync trouxe o `/open-pr` junto).

## Procedimento

**Antes do tag, suba a `tag` de [`.claude/.template.json`](../.claude/.template.json)
para a versão que vai sair, e commite.** Esse marcador viaja na cópia crua da pasta,
e é ele que dá base ao primeiro `/update-claude` de quem copiou à mão. Marcador
atrasado é pior que marcador ausente: ele afirma uma base falsa com cara de fato, que
é exatamente o que o [ADR-0001](./adr/0001-nao-inferir-a-versao-de-origem.md) recusa
fazer por heurística. Nada automatiza essa checagem — o hook de drift não a cobre.

```bash
git tag -a vX.Y.Z -m "vX.Y.Z - <resumo>"
git push origin versao_vigente
git push origin vX.Y.Z
gh release create vX.Y.Z --title "vX.Y.Z — <título>" --notes "<notas>"
```

Notas de release em português, com as seções que se aplicarem: **Novo**, **Alterado**,
**Configuração**, **Decisões de projeto**. Explique *por que* a mudança existe — a
release é o changelog que você vai reler daqui a seis meses.

### Antes de cortar

O hook local `readme-drift` barra o `git tag -a` enquanto houver skill, comando,
script, hook, toggle, diretório de `.claude/` ou artefato gerado sem linha no README
correspondente. Ele é ferramenta desta máquina e não é versionado — ver
[README § Manutenção deste repositório](../README.md#manutenção-deste-repositório).

## Histórico

Resumo de uma linha por release; as notas completas estão na aba *Releases*.

| Versão | Conteúdo |
|---|---|
| `v1.0.0` | Baseline: rules, biblioteca de skills, comandos de workflow, hooks, scripts. |
| `v2.0.0` | Board sync (`board-move.sh`, `BOARD_SYNC`) + comando novo `/open-pr`. |
| `v3.0.0` | Skill nova `adopt-repo`. |
| `v3.0.1` | `/review-pr` com um subagente por issue (`PR_REVIEW_PARALLEL`). |
| `v4.0.0` | Comando novo `/update-claude` + marcador `.claude/.template.json`. |
| `v4.0.1` | `/update-claude`: commit (não objeto tag) no marcador; para em branch de tópico. |
| `v4.0.2` | `/update-claude`: direção do fim-de-linha era o inverso; `.sh` com CRLF não roda. |
| `v4.0.3` | Template renomeado para ARK; `/update-claude` aponta para o repositório novo. |
| `v4.0.4` | `/review-pr`: qualidade vira subagente com brief próprio. Marcador de origem passa a viajar na cópia. |
| `v4.0.5` | `/start-issue` e `/afk-queue` criam a branch de trabalho ao partir de um tronco (`AUTO_BRANCH`). |
| `v4.0.6` | `/start-issue` genérico: tracker via `docs/agents/`, plano vira checklist na issue, régua de complexidade verificável. |
| `v4.0.7` | `/commit` e `/open-pr` genéricos: tracker via `docs/agents/`, checklist mantido no `/commit`, base real do PR. |
| `v4.0.8` | `/review-pr` genérico: baseline via tracker/`domain.md`, branch restaurada por nome, briefs sem stack presumida. |
| `v4.0.9` | `/afk-queue` alinhado ao pipeline: checklist permitido no unattended, exceções de TDD espelhadas, validação de worktree perguntada. |
| `v4.1.0` | `/update-claude` preciso: origem pelo marcador, tronco sem `gh`. Calibragem de projeto sai de `commands/` para `rules/work-calibration.md`. |
| `v5.0.0` | Instalação global: comando novo `/sync-global`, instaladores `install-global.{sh,ps1}` e `ARK_HOME`. O kit passa a valer em qualquer diretório sem copiar `.claude/`. |

**Próxima:** skill/comando novo → `v6.0.0`; alteração → `v5.0.1`.
