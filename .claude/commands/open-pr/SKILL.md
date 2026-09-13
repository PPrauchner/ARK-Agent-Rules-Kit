---
name: open-pr
description: Abre o Pull Request da branch atual, descobrindo nos rodapés dos commits quais issues foram implementadas, e move essas issues para "In review" no board. Use when opening a pull request. $ARGUMENTS
---

# Open PR

Fecha o pipeline `start-issue → tdd → commit → open-pr`: publica a branch atual como
PR e move para *In review* as issues que ela implementou.

> **Este comando é GitHub.** Abrir PR é operação de forge, não de tracker: usa `gh`
> de ponta a ponta e não tem equivalente configurável. Um projeto pode rastrear
> issues em GitLab ou em markdown local — o `/start-issue` e o `/commit` lidam com
> isso — e ainda assim não usar este comando. Em GitLab, abra o MR à mão.

As issues **não** são passadas como argumento — são descobertas nos rodapés
`Closes #N` / `Fixes #N` / `Part of #N` dos commits, que é justamente o que o
`/commit` escreve. Um PR pode fechar várias issues (é o caso normal depois de um
`/afk-queue`, em que N issues empilham commits na mesma branch).

`$ARGUMENTS`, se fornecido, vira o título do PR; senão o título é derivado dos commits.

## Workflow

### 1. Pré-condições e base do PR
```bash
git rev-parse --abbrev-ref HEAD
git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null   # base, se houver
gh repo view --json defaultBranchRef --jq .defaultBranchRef.name   # base, senão
git status --porcelain
```

**A base do PR é a branch de onde esta saiu, não o tronco por decreto.** Se a branch
atual tem upstream configurado e ele não é ela mesma no `origin`, essa é a base;
senão, a branch default do repositório. Isso importa porque o `ensure-branch.sh`
deixa empilhar de propósito — uma segunda issue na branch da primeira, ou um
`/afk-queue` sobre uma branch já preparada. Contra o tronco, esse PR levaria junto os
commits da branch-pai e anunciaria `Closes #N` de issues que outro PR já fecha.

- **Branch atual == base:** **pare.** Não existe PR de uma branch para ela mesma.
  Peça ao usuário para criar a branch e mover os commits para lá — **não crie você**.
  O `/start-issue` e o `/afk-queue` criam a branch *antes* de implementar
  (`ensure-branch.sh`); aqui os commits já estão no tronco, e tirá-los de lá é outra
  operação, com risco de perder trabalho. Chegar neste ponto significa que a branch
  não foi criada lá atrás — provavelmente `AUTO_BRANCH=off`, ou commits feitos fora
  do pipeline.
- **Árvore suja:** **pare** e peça para rodar `/commit` antes. Abrir o PR deixando
  mudanças para trás produz um PR que não corresponde ao trabalho feito.
- **Já existe PR para esta branch** (`gh pr view --json url,state`): não crie outro.
  Informe a URL, pule para o passo 6 (o board ainda precisa ser atualizado) e diga
  que o PR foi apenas atualizado pelo push.

### 2. Descobrir as issues implementadas
```bash
git log <base>..HEAD --pretty=%B
```
Use a **mesma base** do passo 1 — é o que garante que só as issues desta branch
entrem no PR.

Extraia todo `Closes #N`, `Fixes #N`, `Part of #N`; deduplique preservando a ordem de
aparição. Se nenhuma issue for encontrada, siga mesmo assim, mas **avise no resumo**
que nenhuma issue será fechada no merge nem movida no board.

### 3. Montar título e corpo
- **Título:** `$ARGUMENTS` se houver. Senão, com uma issue só, o título dela; com
  várias, um resumo do tema comum dos commits.
- **Corpo:** o que mudou e por quê (a partir dos commits, não do diff linha a linha),
  seguido de uma linha `Closes #N` para cada issue descoberta.

Use `Closes` apenas para issues cujo escopo o PR **realmente completa**; para as que
seguem abertas depois do merge, use `Part of #N` — a linha errada aqui fecha issue
que não deveria fechar.

### 4. Apresentar e confirmar — aguardar
Mostre branch de origem, **base escolhida e por quê** (upstream ou branch default),
título, corpo e a lista de issues que serão movidas para *In review*. **Aguarde
confirmação**: publicar um PR é ação externa e visível.

### 5. Publicar
```bash
git push -u origin <branch>
gh pr create --title "<título>" --body "<corpo>" --base <base>
```

### 6. Mover as issues no board
Para **cada** issue descoberta no passo 2:
```bash
bash "${ARK_HOME:-.claude}/scripts/board-move.sh" <N> in-review
```
O script é silencioso quando `BOARD_SYNC=off` e nunca falha o comando — se o board
não estiver configurado, ou se o tracker deste repo não for GitHub, ele avisa e o PR
continua aberto normalmente. Não trate aviso de board como erro do `/open-pr`.

### 7. Reportar
URL do PR, base, issues movidas e issues que ficaram de fora (e por quê).

Não peça review, não faça merge, não mexa em labels — isso é decisão do usuário.

> Quando o PR for mergeado, o `Closes #N` fecha as issues e o workflow nativo do
> GitHub Projects ("Item closed → Done") as move para *Done*. Por isso este comando
> não precisa cuidar da coluna final.
