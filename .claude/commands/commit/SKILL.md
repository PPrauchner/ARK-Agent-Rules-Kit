---
name: commit
description: Analisa mudanças não-commitadas e realiza commits atômicos seguindo as convenções do projeto. Use when the user wants to commit changes, stage files, or create a structured commit message. $ARGUMENTS
---

# Commit

## Workflow

### 1. Diagnosticar
```bash
git status
git diff --stat HEAD
```
Se a working tree estiver limpa, informe o usuário e pare.

### 2. Ler convenções
- [`atomicity-rules.md`](./atomicity-rules.md) — tipos, escopos, regras de atomicidade
- `.claude/rules/code-conventions.md` — convenções de código do projeto
- **O histórico do próprio repositório** — nenhum arquivo de convenção define o
  idioma da mensagem de commit, porque ele não é nem código nem documentação:

```bash
git log --format=%s -20
```

Imite o que encontrar — idioma, acentuação, formato do escopo. Repositório com
histórico em inglês recebe commit em inglês; em português sem acento, idem. Num
repositório sem histórico, siga o idioma da documentação do projeto.

### 3. Identificar issue ativa
```bash
issue=$(bash "${ARK_HOME:-.claude}/scripts/current-issue.sh" get); echo "${issue:-(nenhuma)}"
```

O script lê da raiz do projeto, onde o `/start-issue` gravou — não do cwd, que pode
ter derivado para dentro de um subrepositório. Não troque por `cat
.claude/current-issue`.

Para ler a issue, use o comando que [`docs/agents/issue-tracker.md`](../../../docs/agents/issue-tracker.md)
define para este repositório. **Se o arquivo não existir**, assuma GitHub e avise em
uma linha:

> sem `docs/agents/issue-tracker.md` — assumindo GitHub; rode
> `/setup-matt-pocock-skills` se não for.

Não pare por causa disso. O `/afk-queue` exige esse arquivo e para sem ele; aqui o
fallback basta. A diferença é proposital: lá a fila roda sem ninguém olhando, e uma
suposição errada estraga N issues em silêncio; aqui o usuário lê o aviso e corrige.

Receita GitHub:
```bash
gh issue view "$(bash "${ARK_HOME:-.claude}/scripts/current-issue.sh" get)" --json number,title,body,labels 2>/dev/null
```

### 4. Inspecionar mudanças
```bash
git diff          # não-staged
git diff --cached # staged
git ls-files --others --exclude-standard  # untracked
```
Leia arquivos novos relevantes com Read para entender o que fazem.

### 5. Agrupar em commits atômicos
Aplique as [regras de atomicidade](./atomicity-rules.md). Regra de ouro: se precisar de mais de uma frase para descrever **o que** foi feito (não o porquê), divida o commit.

### 6. Propor plano — aguardar confirmação
```
Plano de commits (N commits):

1. tipo(escopo): descrição curta
   Arquivos: path/arquivo1.py, path/arquivo2.py
   Corpo: [porquê da mudança, se necessário]
```
Se houver issue ativa, o último commit relevante deve referenciar no rodapé (`Closes #N` ou `Part of #N`). **Aguardar confirmação antes de executar.**

### 7. Executar após confirmação
```bash
git add caminho/arquivo1 caminho/arquivo2
git commit -m "tipo(escopo): descrição

Corpo opcional (wrap a 72 chars).

Closes #N"
```

**Confira a mensagem gravada, não só o assunto.** Erro de sintaxe de shell numa
mensagem multilinha não faz o commit falhar — ele grava a mensagem errada e segue
calado, e `--oneline` não mostra isso:

```bash
git log -1 --format=%B   # sempre que a mensagem tiver corpo
```

Se o que foi gravado não for o que foi proposto, corrija no ato com
`git commit --amend`. O amend aqui é seguro: o commit acabou de nascer e nunca foi
publicado.

### 8. Marcar o checklist da issue
Se a issue ativa tiver um comentário `## Plano de execução` (criado pelo
`/start-issue` quando a issue foi julgada complexa), marque os itens que **estes
commits** concluíram e reescreva o comentário.

Marca-se o que aconteceu, não o que se pretendia — por isso é aqui, e não no
`/start-issue`. Vale igual no `/afk-queue`, onde o subagente roda `/commit` sem
ninguém acompanhando.

Receita GitHub — localizar e atualizar:
```bash
gh issue view <N> --json comments \
  --jq '.comments[] | select(.body | startswith("## Plano de execução")) | .url' \
  | sed 's/.*issuecomment-//'
gh api -X PATCH repos/{owner}/{repo}/issues/comments/<id> -F body=@plano.md
```

Em outros trackers, use o equivalente descrito em `docs/agents/issue-tracker.md`.
Sem issue ativa, ou sem esse comentário, pule o passo em silêncio.

### 9. Resumo final
```bash
git log --oneline -N
```
Perguntar se deseja **abrir o PR agora via `/open-pr`** (que faz o push, cria o PR e
move as issues para *In review*). Se a resposta for não, parar aqui — sem push.
