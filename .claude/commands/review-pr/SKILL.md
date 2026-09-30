---
name: review-pr
description: Revisa um Pull Request quanto à conformidade com a issue/DoD e a documentação do projeto, delega a análise de qualidade de código a um subagente, e executa a ação escolhida (aprovar, solicitar mudanças, comentar). Use when reviewing a pull request. $ARGUMENTS
---

# Review PR

Revisa o PR `#$ARGUMENTS` em duas frentes complementares:

- **Conformidade** (foco deste comando): *construíram a coisa certa?* — o PR cumpre
  a Definition of Done da issue e respeita a terminologia (`CONTEXT.md`) e as
  decisões (`docs/adr/`).
- **Qualidade de código** (delegada): *o código está bom?* — bugs, simplificações,
  eficiência. Vai para um subagente próprio, que analisa o PR inteiro de uma vez.

O veredito final funde as duas frentes em um único relatório.

> **Este comando é GitHub.** Revisar PR é operação de forge, não de tracker: usa
> `gh pr` de ponta a ponta e não tem equivalente configurável. O que ele lê do
> projeto — a issue que serve de baseline e a documentação de domínio — é genérico.

`$ARGUMENTS` é opcional: sem ele, o PR é derivado da branch atual
(`gh pr view --json number --jq .number`). Se a branch não tiver PR aberto, **pare**
e peça o número — é a mesma postura do `/open-pr`, que também trabalha a partir da
branch.

## Workflow

### 1. Buscar dados do PR
```bash
gh pr view $ARGUMENTS --json number,title,body,headRefName,headRefOid,baseRefName,state,author,additions,deletions,files,url
```
Extraia do corpo as issues referenciadas (`Closes #N`, `Fixes #N`, `Part of #N`).
Guarde o `headRefOid`: é o commit revisado, do começo ao fim.

### 2. Preparar a worktree
A revisão acontece numa worktree própria, com HEAD destacado no `headRefOid`. A pasta
principal **nunca é tocada nem lida**: não importa se ela tem pendências nem em que
branch está, e outra sessão trabalhando nela não é afetada pela revisão (nem a afeta).
```bash
git worktree prune                           # registro órfão de revisão interrompida
git fetch origin pull/<N>/head <baseRefName>
git worktree add --detach <scratchpad>/pr-<N> <headRefOid>
```
- **Onde:** no scratchpad da sessão — caminho liberado sem prompt de permissão, o que
  importa com vários subagentes lendo em paralelo. Sem scratchpad declarado, use
  `mktemp -d`.
- **Por que destacado, e não uma branch local:** não sobra branch se a limpeza falhar,
  duas sessões revisando o mesmo PR não colidem (o git recusa a mesma *branch* em duas
  worktrees, não o mesmo commit), e a revisão fica presa ao commit lido mesmo que o
  autor dê push no meio.
- **Por que o SHA do `gh`, e não `FETCH_HEAD`:** o `FETCH_HEAD` é do repositório
  inteiro — um `fetch` de outra sessão no meio o sobrescreve.

Daqui em diante, **todo caminho é absoluto, dentro da worktree** (`<worktree>`). O
diretório de trabalho da sessão continua sendo a pasta principal, então um caminho
relativo cairia nela. O diff do PR é:
```bash
git -C <worktree> diff origin/<baseRefName>...HEAD
```
Três pontos: compara com o merge-base, o mesmo recorte que o GitHub mostra. Não use
`gh pr diff` — ele traz o head atual do GitHub, que pode já não ser o da worktree.

Remova a worktree **em toda saída**, inclusive a antecipada — subagente que aborta,
`gh` que erra, revisão interrompida:
```bash
git worktree remove --force <worktree>
```
Esquecê-la não quebra nada — ocupa disco e polui o `git worktree list`, e o `prune` da
próxima revisão recolhe o registro —, mas é resto que a revisão deixou.

### 3. Estabelecer o baseline (o que deveria ter sido feito)
- **Com issue(s) vinculada(s):** busque cada uma com o comando que
  [`docs/agents/issue-tracker.md`](../../../docs/agents/issue-tracker.md) define para
  este repositório. Sem esse arquivo, assuma GitHub
  (`gh issue view N --json number,title,body,labels`) e avise em uma linha. Os
  critérios de aceite da issue são o baseline primário.
- **Sem issue vinculada:** use o título + corpo do PR como declaração de intenção.
  Registre no veredito que a DoD foi **inferida do PR** (não havia issue).
- **Documentação (ler preguiçosamente, só se existir):** onde ela mora, em ordem —
  `docs/agents/domain.md`; senão `CONTEXT-MAP.md` na raiz, seguindo o mapa até o
  contexto que o PR toca; senão `CONTEXT.md` + `docs/adr/` na raiz; senão siga sem
  eles. Num monorepo, o `CONTEXT.md` da raiz costuma não ser o certo — é por isso que
  a ordem importa.

  Procure tudo isso **na worktree**, não na pasta principal: o baseline é a
  documentação na versão do PR. Um PR que acrescenta um termo ao glossário e passa a
  usá-lo está conforme; contra o glossário de uma branch qualquer, não estaria.
- **CI:** `gh pr checks $ARGUMENTS`. Testes não rodam na revisão — a worktree nasce
  sem dependências instaladas, e o CI é o portão que roda em ambiente limpo. **CI
  vermelho é 🔴 BLOQUEADOR**; checks pendentes entram no veredito como pendentes; PR
  sem CI, uma linha dizendo isso.

### 4. Qualidade de código — preparar o subagente
Preencha o template de [QUALITY-REVIEW-BRIEF.md](./QUALITY-REVIEW-BRIEF.md) com o
título e o corpo do PR **verbatim** — o subagente não vê esta conversa, e é do corpo
que ele tira os pontos de julgamento que o autor deixou em aberto. Preencha também o
caminho da worktree e a branch base: é deles que sai o diff.

**Não spawne ainda:** o passo 5 dispara este agente na mesma mensagem que os de
conformidade, para que rodem concorrentes. Se a conformidade for inline (1 issue,
nenhuma, ou `PR_REVIEW_PARALLEL=off`), spawne-o aqui e siga para o passo 5 enquanto
ele roda.

Este agente roda **uma vez, sobre o PR inteiro** — nunca por issue. Recortar o diff
por issue é inviável (issues compartilham arquivos) e N execuções produziriam os
mesmos achados repetidos. A divisão é: *qualidade = PR inteiro, conformidade = por
issue*.

Ele roda **sempre**, inclusive com `PR_REVIEW_PARALLEL=off`: aquele toggle existe para
não multiplicar agentes de conformidade, e a qualidade é sempre um agente só.

### 5. Conformidade — o que deveria vs. o que foi feito

Com **2 ou mais issues** vinculadas e `PR_REVIEW_PARALLEL` diferente de `off`
(`.claude/settings.json`), avalie **uma issue por subagente, em paralelo**: um PR de 4
issues vira 4 revisões independentes em vez de uma análise que dilui as quatro DoDs.

1. Para cada issue, preencha o template de
   [ISSUE-REVIEW-BRIEF.md](./ISSUE-REVIEW-BRIEF.md) com o corpo da issue **verbatim**
   — o subagente não vê esta conversa. Passe também o caminho da worktree, a branch
   base e os **caminhos absolutos** (na worktree) do glossário e dos ADRs que você
   localizou no passo 3: o subagente não repete essa busca.
2. Spawne todos com `Agent` (`subagent_type: general-purpose`) **numa única
   mensagem**, junto com o agente de qualidade do passo 4, para que rodem
   concorrentemente.
3. Eles compartilham a worktree em modo leitura. Por isso o brief proíbe
   escrever, commitar e trocar de branch: um subagente que mexesse na árvore
   corromperia a revisão dos outros.
4. Use apenas o relatório final de cada um — o formato de resposta já é o que entra no
   veredito, sem reescrita.

**Com 1 issue, nenhuma issue, ou `PR_REVIEW_PARALLEL=off`:** avalie inline, você
mesmo. Spawnar um subagente para uma issue só custa contexto e tempo sem paralelizar
nada.

Compare o baseline (passo 3) com o diff do passo 2. Procure:
- Critérios de aceite da issue não cumpridos (DoD incompleta).
- Divergências de terminologia vs. `CONTEXT.md` (campo/conceito fora do glossário).
- Violações de decisões registradas em `docs/adr/`.
- Alteração no próprio glossário ou num ADR que o corpo do PR não justifica — o
  baseline é a versão do PR, então um PR que reescreve a regra para caber nela passaria
  calado. É 🟡 DESVIO.

Leia com `Read` os arquivos alterados que precisarem de contexto — pelo caminho
absoluto na worktree.

Quando **todos** os subagentes tiverem terminado, remova a worktree (passo 2).

### 6. Fundir em um veredito único
Severidade dos achados, venham eles da conformidade ou da qualidade:

- **BLOQUEADOR** — DoD não cumprida OU bug crítico. Impede o merge.
- **DESVIO** — divergência de requisito, terminologia (`CONTEXT.md`) ou decisão (`docs/adr/`).
- **MENOR** — nit, convenção, sugestão de simplificação.

A conformidade é apresentada **por issue**, não fundida numa lista só: um PR pode
cumprir a issue #41 inteira e falhar na #42, e quem revisa precisa saber que a #41
pode fechar. A qualidade de código fica numa seção própria, porque é do PR inteiro e
não pertence a nenhuma issue.

Estrutura do veredito (exibir **inline**, não salvar arquivo):

```markdown
## Revisão — PR #<N> @ `<headRefOid curto>` [vs. Issues #<A>, #<B> | DoD inferida do PR]

**Veredito:** PRONTO PARA MERGE / PRECISA DE MUDANÇAS / COM RESSALVAS
[1-2 frases: o que foi entregue e o julgamento geral.]

**CI:** ✓ verde | 🔴 BLOQUEADOR: vermelho em <check> | pendente | sem CI

### Issue #<A> — ✓ DoD cumprida
[uma frase]
- ⚪ MENOR: [nit]

### Issue #<B> — ✗ DoD incompleta
[uma frase]
- 🔴 BLOQUEADOR: [critério de aceite não cumprido, com arquivo/linha]
- 🟡 DESVIO: [divergência, citando a issue / CONTEXT.md / ADR]

### Qualidade de código (PR inteiro)
- 🔴 BLOQUEADOR: [bug, com arquivo/linha]
- ⚪ MENOR: [simplificação]
```

Tanto as seções por issue quanto a de qualidade são os relatórios dos subagentes,
**colados como vieram** — o formato dos briefs já é este. Não reescreva nem resuma:
reescrever achado de revisão é como se perde a referência de arquivo/linha.

Omita seções e severidades vazias. Qualquer BLOQUEADOR torna o veredito PRECISA DE
MUDANÇAS. Sem issues vinculadas, use uma única seção "Conformidade (DoD inferida do
PR)" no lugar das seções por issue.

O veredito descreve o **estado do PR**, não a ação: a ação (aprovar, solicitar
mudanças, comentar ou nada) é decidida no passo 7.

### 7. Apresentar e perguntar a ação
Exiba o veredito.

**PR mergeado ou fechado:** a revisão para aqui, inline. Não ofereça ação de review —
aprovar o que já foi mergeado não significa nada, e solicitar mudanças num PR fechado
não tem a quem endereçar. Diga o estado do PR no relatório.

**PR `OPEN`:** pergunte qual ação tomar:

1. **Aprovar** — `gh pr review $ARGUMENTS --approve --body "<resumo>"`
2. **Solicitar mudanças** — `gh pr review $ARGUMENTS --request-changes --body "<bloqueadores>"`
3. **Apenas comentar** — `gh pr comment $ARGUMENTS --body "<veredito>"`
4. **Nada** — não escrever no GitHub, só deixar o veredito no chat

### 8. Executar a ação escolhida
Antes de publicar, confira que o PR não andou:
```bash
gh pr view $ARGUMENTS --json headRefOid --jq .headRefOid
```
Se mudou, **pare** e avise ("revisei `<antigo>`, o PR agora está em `<novo>`") antes
de publicar qualquer coisa: um `--approve` no GitHub aprova o head atual — um commit
que ninguém revisou.

Rode apenas o comando `gh` correspondente à escolha. Confirme no relatório final que a
worktree foi removida.

**Não** mova issues em board. Não é que board seja assunto de outro comando — o
`/start-issue` e o `/open-pr` movem, via `board-move.sh`. É que **revisar não muda o
estado da issue**: aprovado, quem fecha é o merge; mudanças solicitadas, a issue
segue em *In review* até o autor voltar. Não há transição para representar.
