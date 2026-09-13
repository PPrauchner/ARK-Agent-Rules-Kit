---
name: start-issue
description: Inicia o trabalho em uma issue. Lê a issue no tracker do projeto, identifica docs relevantes, avalia complexidade e prepara a implementação. Use when starting work on an issue. $ARGUMENTS
---

# Start Issue

Inicia o trabalho na issue `#$ARGUMENTS`.

Nada é escrito em lugar nenhum — nem arquivo de sessão, nem board, nem branch, nem
comentário — antes da confirmação do passo 3. Um número errado ou um plano recusado
não deixa rastro.

## 1. Ler a issue

O tracker é definido por [`docs/agents/issue-tracker.md`](../../../docs/agents/issue-tracker.md):
ele diz o que significa "buscar o ticket" neste repositório (`gh issue view` no
GitHub, `glab issue view` no GitLab, abrir um arquivo em `.scratch/` no markdown
local, ou o que estiver descrito ali). Use o comando de lá.

**Se o arquivo não existir**, assuma GitHub e avise em uma linha:

> sem `docs/agents/issue-tracker.md` — assumindo GitHub; rode
> `/setup-matt-pocock-skills` se não for.

Não pare por causa disso. O `/afk-queue` exige esse arquivo e para sem ele; aqui o
fallback basta. A diferença é proposital: lá a fila roda sem ninguém olhando, e uma
suposição errada estraga N issues em silêncio; aqui o usuário lê o aviso e corrige.

Receita GitHub:
```bash
gh issue view $ARGUMENTS --comments --json number,title,body,labels,assignees,comments
```

Leia **corpo e comentários**. Se houver um comentário *Agent Brief* (postado pelo
`/triage`), trate-o como a especificação mais recente — acima do corpo, que pode ter
sido escrito antes da triagem. Os demais comentários são discussão legítima
posterior; leve-os em conta.

Se a issue não existir ou o tracker não responder, **pare e diga isso** — não
invente o escopo.

## 2. Ler docs e código relevantes

Onde mora a documentação de domínio, em ordem de preferência:

1. `docs/agents/domain.md` — diz se o repo é single-context ou multi-context e onde
   cada contexto vive.
2. Sem ele, `CONTEXT-MAP.md` na raiz — multi-context; siga o mapa até o `CONTEXT.md`
   do contexto que a issue toca.
3. Sem ele, `CONTEXT.md` + `docs/adr/` na raiz.
4. Sem nada disso, siga em silêncio — a ausência de docs não é erro.

Use o glossário para acertar a terminologia e as ADRs para não reabrir decisão já
tomada. Leia também os arquivos de código diretamente relacionados à issue, para
entender o que já existe antes de implementar.

## 3. Avaliar complexidade e apresentar o plano — aguardar

Consulte o [guia de complexidade](./complexity-guide.md) para decidir se a issue
deve ser quebrada.

Apresente, em qualquer dos casos:

- **Resumo** do que será feito e arquivos a modificar.
- **Caminho de implementação** — `tdd` por padrão; se for uma das exceções do passo
  6, diga qual e por quê.
- **Branch**, se a sessão estiver num tronco (ver passo 4): a linha
  `branch: issue/<N>-<slug>`.
- **Se COMPLEXA**, a avaliação de complexidade e a lista de sub-tarefas (título,
  escopo, dependências).

Uma confirmação só, para tudo. **Aguarde.**

## 4. Registrar o trabalho

Só **depois** da confirmação, os três efeitos colaterais, nesta ordem:

```bash
mkdir -p .claude && echo "$ARGUMENTS" > .claude/current-issue
bash "${ARK_HOME:-.claude}/scripts/board-move.sh" $ARGUMENTS in-progress
bash "${ARK_HOME:-.claude}/scripts/ensure-branch.sh" issue $ARGUMENTS "<título da issue>"
```

**`board-move.sh`** move a issue para *In progress* no GitHub Projects. É silencioso
com `BOARD_SYNC=off` (`.claude/settings.json`) e **nunca falha** — se o board não
estiver configurado, ou se o tracker deste repo não for GitHub, ele avisa e o
trabalho segue. Não trate aviso de board como erro.

**`ensure-branch.sh`** cria `issue/<N>-<slug-do-título>` a partir da branch atual
**apenas** se ela for um tronco (`main`, `master`, `dev`, `develop`, `development`
ou a branch default do repositório). Fora do tronco ele não faz nada e a issue é
implementada na branch atual — é assim que duas issues relacionadas empilham commits
de propósito, e é o que mantém o `/afk-queue` sequencial com uma branch só para a
fila inteira.

Ao contrário do `board-move.sh`, este script **falha** se não conseguir criar a
branch (exit ≠ 0). É proposital: seguir sem ela despejaria os commits no tronco,
exatamente o que ele existe para evitar. Se ele falhar, **pare** e mostre o erro ao
usuário. Se a branch já existia, ele avisa e retoma o trabalho nela.

Desligar: `AUTO_BRANCH=off` no bloco `env` de `.claude/settings.json` — aí a branch
volta a ser inteiramente decisão do usuário.

## 5. Publicar o plano na issue — só se COMPLEXA

As sub-tarefas confirmadas viram um checklist **na issue**, para sobreviverem à
perda de contexto e darem rastro ao revisor. Elas moram num comentário **do
agente**, com o título fixo `## Plano de execução`; o corpo da issue é do autor
humano e não deve ser tocado.

```markdown
## Plano de execução

- [ ] Título da sub-tarefa 1 — escopo em uma linha
- [ ] Título da sub-tarefa 2 — escopo em uma linha (depende da 1)
```

Regras:

- **Um comentário só.** Antes de postar, procure um comentário existente que comece
  com `## Plano de execução`. Se houver, **atualize-o**; re-rodar `/start-issue` na
  mesma issue nunca duplica o plano.
- **Quem marca é o `/commit`.** Este comando cria o checklist; marcar os itens é do
  `/commit`, que roda depois de cada sub-tarefa e sabe o que de fato foi gravado.
  Marcar aqui registraria intenção, não trabalho.

Receita GitHub — criar:
```bash
gh issue comment $ARGUMENTS --body-file plano.md
```

Receita GitHub — localizar e atualizar o comentário existente:
```bash
gh issue view $ARGUMENTS --json comments \
  --jq '.comments[] | select(.body | startswith("## Plano de execução")) | .url' \
  | sed 's/.*issuecomment-//'
gh api -X PATCH repos/{owner}/{repo}/issues/comments/<id> -F body=@plano.md
```

Em outros trackers, use o equivalente descrito em `docs/agents/issue-tracker.md`
("comentar numa issue"). No markdown local, o checklist vai para a seção
`## Comments` do arquivo da issue.

## 6. Iniciar implementação

Comece pela primeira sub-tarefa (ou pela issue diretamente, se simples).

**Implemente via `tdd`** (skill em `.claude/skills/tdd/SKILL.md`) — é o caminho
padrão. As exceções, que devem ser **declaradas no passo 3**, não descobertas no
meio do caminho:

- **O repositório não tem runner de teste.** Escrever o primeiro teste do projeto é
  uma decisão do usuário, não um efeito colateral de começar uma issue — proponha,
  não imponha.
- **A issue não altera comportamento executável** — documentação, configuração,
  chore. Não existe teste que falhe primeiro; TDD ali é teatro.

Fora essas duas, TDD. "Vai ser mais rápido sem" não é exceção.

Ao terminar, o pipeline segue em `/commit` e depois `/open-pr` — é o `/open-pr` que
move a issue para *In review*, ao publicar o PR.
