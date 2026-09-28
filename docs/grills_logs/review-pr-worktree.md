# Proposta — `/review-pr` revisando numa worktree isolada

**Início:** 2026-09-28
**Estado:** proposta, **não decidida**. Este arquivo registra a discussão que motivou a
ideia para uma sessão de grill futura verificar se vale a pena mudar o comando. Nada no
`review-pr/` foi alterado.

## O incidente que motivou

Revisão do PR #91 de `PPrauchner/OOPA-RPIV`. O comando seguiu o fluxo atual:
`gh pr checkout 91` na pasta principal do clone, subagente de qualidade lendo ali,
restauração pelo nome da branch guardada (`git checkout develop`). Até aí, correto.

Depois, com a sessão já de volta na `develop`, o usuário pediu merge + exclusão da
branch. O `gh pr merge --delete-branch` funcionou, mas ao conferir o estado a pasta
principal estava em `fix/issue-76-auditoria-reset-senha` — uma troca que **esta sessão
não fez**. O reflog mostrou:

```
16:17:00  checkout: moving from fix/issue-89-dogs-isolation-test to develop   ← restauração do /review-pr
16:18:53  checkout: moving from develop to fix/issue-76-auditoria-reset-senha ← outra sessão
16:19:11  (merge do PR #91 via gh)
```

Outra sessão do Claude Code estava operando **na mesma working tree** (provavelmente
revisando outro PR em sequência — o reflog tem vários `develop → <branch> → develop`
de minutos antes). A sessão não voltou para a `develop` para não quebrar a outra.

O que o incidente mostra: o passo 1 do `/review-pr` ("guarde a branch, restaure pelo
nome, nunca `git checkout -`") protege contra trocas **dentro da própria sessão**, mas
não contra **outra sessão no mesmo diretório**. Com a pasta principal compartilhada,
qualquer checkout de uma sessão move o chão da outra — inclusive o risco que o próprio
comando descreve: "o próximo `/commit` comita lá".

## Como o `git worktree` resolveria

Um repositório tem um banco de objetos (`.git/`) e, por padrão, uma pasta de trabalho.
`git worktree` cria pastas de trabalho extras ligadas ao mesmo `.git/`, cada uma com
sua própria branch em checkout:

```bash
git fetch origin pull/91/head:review/pr-91
git worktree add <scratchpad>/pr-91 review/pr-91
git worktree list
git worktree remove --force <scratchpad>/pr-91
git branch -D review/pr-91
```

Propriedades relevantes:

- Commits, branches e `fetch` são compartilhados entre as pastas.
- Uma branch só pode estar em checkout numa worktree de cada vez — o git recusa a
  segunda. É proteção, não atrito.
- `node_modules` (e qualquer artefato não versionado) **não** é compartilhado: a
  worktree nasce sem dependências instaladas.
- Arquivos não rastreados ficam na pasta onde foram criados.

## Mudança proposta no comando

| Passo | Hoje | Com worktree |
|---|---|---|
| 1. Pré-condição | exige árvore limpa, guarda a branch atual | **desaparece** — a pasta principal nunca é tocada |
| 4. Checkout | `gh pr checkout N` | `git fetch origin pull/N/head:review/pr-N` + `git worktree add <scratchpad>/pr-N review/pr-N` |
| 5. Subagentes | "a branch do PR já está em checkout no seu diretório" | recebem o **caminho da worktree** como diretório de trabalho |
| Saída (normal e antecipada) | `git checkout <branch guardada>` | `git worktree remove --force <pasta>` + `git branch -D review/pr-N` |

Arquivos afetados: `SKILL.md`, `QUALITY-REVIEW-BRIEF.md`, `ISSUE-REVIEW-BRIEF.md`.

### Ganhos

1. **Elimina a classe de problema do incidente:** a revisão não move a branch de
   ninguém e ninguém move a dela.
2. **Remove a exigência de árvore limpa:** não é preciso pedir commit/stash antes de
   revisar.
3. **Limpeza mais simples e idempotente:** remover uma pasta não depende de lembrar o
   nome certo da branch, e a saída antecipada deixa de ser perigosa.

### Custos e riscos

1. **`node_modules`:** o subagente de qualidade do PR #91 rodou `vitest`. Numa worktree
   nova isso exige `npm ci` antes (minutos, e o comando é genérico — em outro projeto é
   `uv sync`, `cargo build`…). Duas saídas:
   - **(a)** o brief manda instalar dependências na worktree antes de rodar testes;
   - **(b)** o subagente não roda testes; a verificação executável vem do CI
     (`gh pr checks N`), que já é o portão oficial. **Inclinação da sessão original: (b).**
2. **Branch local `review/pr-N` sobra** se a limpeza falhar — `git worktree prune` +
   `git branch -D` resolvem, mas é mais um estado a documentar.
3. **Ferramentas que assumem a pasta principal** (hooks, `.claude/settings.local.json`,
   arquivos não versionados como `.claude/current-issue`) não existem na worktree. Para
   leitura de código isso não importa; vale confirmar que nenhum passo do comando
   depende deles.
4. **O problema de fundo continua fora do `/review-pr`:** duas sessões na mesma pasta
   também quebram `/commit`, `/start-issue` e `/open-pr`. Resolver só no `/review-pr`
   pode ser tratar o sintoma. Alternativa: orientar (no README ou num hook) que sessões
   paralelas usem worktrees próprias — o Claude Code já tem `EnterWorktree` e
   `isolation: "worktree"` nos agentes.

## Perguntas em aberto

1. Vale mudar o `/review-pr`, ou a correção certa é uma regra geral de "uma sessão
   por working tree" (custo 4)?
2. Se mudar: testes locais com instalação de dependências (a) ou confiar no CI (b)?
3. A worktree vai no scratchpad da sessão (some sozinha, mas é caminho específico do
   Claude Code) ou num diretório irmão do clone (`../<repo>-pr-N`, genérico mas polui)?
4. O `gh pr checkout` tinha uma vantagem: configura o upstream da branch do PR, útil
   se o revisor quiser empurrar um fix. Com `pull/N/head` isso se perde — importa?
5. Com a pré-condição de árvore limpa removida, o passo 1 do `SKILL.md` e sua
   justificativa ("terminar largado na branch do PR é pior que não revisar") saem
   inteiros, ou algo deles ainda vale?

## Sessão — 2026-09-28 16:29

Grill da proposta acima (`/grill-with-docs`).

**P1:** Escopo — mudar o `/review-pr`, criar uma regra geral de "uma sessão por working tree" (custo 4), ou os dois?
**R:** Mudar o `/review-pr` agora. A regra geral (README/hook para sessões paralelas usarem worktree própria) fica para depois, como item separado — ela resolve "duas sessões na mesma pasta"; a worktree no `/review-pr` resolve "revisar mexe na pasta", que acontece mesmo com uma sessão só.

**P2:** Testes na worktree — instalar dependências e rodar (a), ou não rodar e confiar no CI (b)?
**R:** (b). Os briefs já não mandam rodar teste (o `vitest` do PR #91 foi iniciativa do subagente, usando o `node_modules` da pasta principal); passa a ser proibição explícita — instalar dependências também violaria o "não altere o repositório". O orquestrador roda `gh pr checks N` e põe o estado no veredito. CI vermelho = 🔴 BLOQUEADOR automático; PR sem CI → o veredito diz isso em uma linha.

**P3:** A worktree precisa de branch local `review/pr-N`? (absorve a pergunta 4 da proposta e o custo 2)
**R:** Não. HEAD destacado no SHA do PR: `sha=$(gh pr view N --json headRefOid --jq .headRefOid)`, `git fetch origin pull/N/head`, `git worktree add --detach <pasta> "$sha"`. Sem branch que sobra, sem colisão entre duas sessões revisando o mesmo PR, revisão fixa no commit lido (mesmo se o autor der push no meio), SHA vindo do `gh` e não do `FETCH_HEAD` compartilhado. Upstream para empurrar fix fica fora do escopo — o brief proíbe commitar.

**P4:** Onde fica a worktree — scratchpad da sessão, diretório irmão ou outro lugar?
**R:** Scratchpad (`<scratchpad>/pr-N`), com `mktemp -d` de fallback se a sessão não declarar um. "Específico do Claude Code" não é custo — o ARK todo é. Decisivo: o scratchpad não dispara prompt de permissão para os `Read`/`Grep` dos subagentes paralelos; diretório irmão fica fora do diretório de trabalho. `.git/…` descartado (ferramentas tratam caminho oculto de forma inconsistente). Limpeza: `git worktree prune` no início (remove registro órfão de revisão interrompida) + `git worktree remove --force` em toda saída.

**P5:** O que sobra do passo 1 (árvore limpa, guardar/restaurar branch, restaurar em saída antecipada)?
**R:** Sai inteiro como pré-condição e vira "Preparar a worktree". Árvore limpa: sai. Guardar/restaurar branch: sai. "Restaure em toda saída antecipada" → "remova a worktree em toda saída antecipada", com justificativa honesta (worktree esquecida só ocupa disco/polui `git worktree list`; o `prune` da próxima recolhe). Passo 8 "confirme em qual branch ficou" → "confirme que a worktree foi removida". Passos 1 e 2 invertem: `gh pr view` primeiro (com `headRefOid` no `--json`), worktree depois — uma chamada `gh` só. O `gh pr checkout` do passo 4 some.

**P6:** De qual árvore vêm glossário, ADRs e os `Read` inline do orquestrador?
**R:** Tudo da worktree, em caminhos absolutos (`<worktree>/CONTEXT.md`); a pasta principal nunca é lida. Corrige inconsistência atual: o passo 3 lê a doc na branch do usuário (antes do checkout) e os subagentes leem os mesmos caminhos relativos já na branch do PR. Versão do PR é o baseline certo (PR que adiciona termo e o usa está conforme). Caminho absoluto porque o cwd continua sendo a pasta principal. Brief de conformidade ganha: "se o PR altera glossário ou ADR, avalie contra a versão do PR, mas reporte a alteração como 🟡 DESVIO se o corpo do PR não a justificar".

**P7:** Diff via `gh pr diff` (head atual no GitHub) ou `git diff` na worktree (SHA fixado)?
**R:** `git fetch origin <baseRefName>` + `git -C <worktree> diff origin/<baseRefName>...HEAD` (três pontos = merge-base, mesmo recorte do GitHub). Briefs e passo 5 trocam `gh pr diff` por esse comando, preenchido pelo orquestrador. No passo 8, antes de `gh pr review`: re-buscar `headRefOid`; se mudou, avisar ("revisei X, PR agora em Y") e perguntar antes de publicar — `--approve` aprova o head atual, ou seja, commit não revisado.

**P8:** Implementar nesta sessão ou virar issue?
**R:** Implementar agora. Escopo fechado em `SKILL.md` + os dois briefs; release PATCH. Mudanças não relacionadas pendentes (`start-issue/SKILL.md`, `scripts/README.md`, `ensure-branch.sh`) ficam fora.

Verificado sem pergunta: custo 3 não se aplica — `PR_REVIEW_PARALLEL` é env da sessão; `docs/agents/*` passa a vir da worktree (P6); o comando não usa hook, `settings.local.json` nem `.claude/current-issue`. Sem ADR (reversível com um commit) e sem termo novo no `CONTEXT.md` (worktree é mecanismo, não domínio).

**Desfecho:** proposta **decidida e implementada** em `review-pr/SKILL.md`, `QUALITY-REVIEW-BRIEF.md` e `ISSUE-REVIEW-BRIEF.md` (não commitado). Mecânica testada neste repo com commit local no lugar do `headRefOid` (sem PR aqui): prune → fetch → `add --detach` no scratchpad → `git -C … diff` → `remove --force`; a pasta principal ficou na mesma branch e com as pendências intactas.
