---
name: sync-global
description: Atualiza a instalação global do ARK — puxa o clone e refaz os links em ~/.claude/skills, trazendo skill nova e removendo órfã. Use when syncing the global ARK installation, after adding or renaming a skill, or when a skill exists in the repo but not in ~/.claude/skills.
---

# Sync Global

Traz a instalação global (`~/.claude/`) para o estado atual do clone do ARK.

É o par do `/update-claude`, para o outro modelo de reuso: o `/update-claude` atualiza
o `.claude/` **de um projeto que copiou** a pasta; o `/sync-global` atualiza os **links
no perfil do usuário**. Cada um escreve num lugar, e nenhum dos dois escreve no do
outro.

Não recebe argumentos.

## Quando roda de fato

Só duas situações precisam deste comando:

| Mudança no ARK | Precisa? |
|---|---|
| Skill existente alterada (aqui ou via `git pull`) | **não** — o link aponta para o arquivo, já vale |
| Skill ou comando **novo** | **sim** — falta o link |
| Skill **renomeada ou removida** | **sim** — sobra link órfão |

Se nada disso aconteceu, o comando é um no-op barato: diga isso e pare.

## Passos

### 1. Localizar o clone

`$ARK_HOME` é o caminho absoluto da pasta `.claude/` do clone, gravado no bloco `env`
de `~/.claude/settings.json` pelo instalador.

```bash
echo "$ARK_HOME"
```

Vazio significa que a instalação global nunca foi feita nesta máquina. **Não adivinhe
o caminho** e não prossiga: aponte a seção
[Instalação global](../../../README.md#instalação-global-sem-copiar-claude-por-projeto)
do README e pare.

### 2. Puxar o clone

```bash
git -C "$ARK_HOME/.." status --porcelain
git -C "$ARK_HOME/.." pull --ff-only
```

Com a árvore suja, **não faça stash nem commit**: mostre o que está pendente e
pergunte se é para seguir sem puxar (os links locais continuam válidos — só não vem
novidade do remoto). Se o `--ff-only` recusar, o clone divergiu: reporte e pare, isso
é decisão de quem escreveu os commits.

### 3. Refazer os links

Escolha pelo sistema, não por preferência. No Windows use `powershell`; só troque
por `pwsh` se o PowerShell 7 estiver instalado:

```powershell
powershell -File "$env:ARK_HOME\scripts\install-global.ps1"
```
```bash
bash "$ARK_HOME/scripts/install-global.sh"
```

Rode primeiro com `-DryRun` / `--dry-run` **se** o passo 2 trouxe commits: assim o
diff aparece antes de qualquer escrita. Sem commits novos, vá direto.

O instalador é idempotente e conservador — pasta real de mesmo nome em
`~/.claude/skills` é pulada com aviso, e só links que apontam para dentro do clone
são podados. Um `PULADO:` no output não é erro do sync: é uma skill de outra origem
ocupando o nome, e quem resolve é o usuário.

### 4. Fechar

Reporte em uma linha: quantos links entraram, quantos órfãos saíram, e o nome de cada
skill nova ou removida — não o output cru do script.

Termine avisando que **skill nova só aparece na próxima sessão**: o Claude Code lê
`~/.claude/skills` na inicialização. Skill já linkada e apenas *editada* vale na hora,
sem reiniciar.

## Limites

- Não escreve dentro de nenhum projeto. Para isso existe o `/update-claude`.
- Não faz commit nem push no clone do ARK. Se você alterou uma skill e quer publicar,
  isso é `/commit` + `/open-pr` de dentro do clone.
- Não mexe nas *rules* de projeto nem em `settings.local.json` de lugar nenhum.
