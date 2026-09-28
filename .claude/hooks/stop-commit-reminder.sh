#!/bin/bash
# Hook: Stop
# Verifica se há mudanças não commitadas ao encerrar a sessão.
# Se houver, avisa o usuário com um resumo do que está pendente.

# Resolve o repositório do PROJETO em sessão, não o do próprio script: com o hook
# registrado globalmente (~/.claude/settings.json), "$(dirname "$0")" apontaria
# sempre para o clone do ARK. CLAUDE_PROJECT_DIR vem do Claude Code; o cwd é o
# fallback para invocação manual.
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"

# O projeto pode não ser um repositório: uma pasta de trabalho que agrupa
# repositórios irmãos (o .claude/ e o CLAUDE.md ficam fora de todos eles). Nesse
# caso, confere cada subpasta de primeiro nível que for um repositório git.
REPOS=()
ROOT=$(git -C "$PROJECT_DIR" rev-parse --show-toplevel 2>/dev/null)
if [ -n "$ROOT" ]; then
    REPOS+=("$ROOT")
else
    for dir in "$PROJECT_DIR"/*/; do
        [ -e "$dir.git" ] && REPOS+=("${dir%/}")
    done
fi

[ "${#REPOS[@]}" -eq 0 ] && exit 0

# A issue ativa mora na raiz do projeto, não do repositório — mesmo resolvedor que
# o /start-issue usa para gravar.
ISSUE=$(cd "$PROJECT_DIR" && bash "$HOOK_DIR/../scripts/current-issue.sh" get 2>/dev/null)

HEADER_SHOWN=false
for repo in "${REPOS[@]}"; do
    STAGED=$(git -C "$repo" diff --cached --name-only 2>/dev/null)
    UNSTAGED=$(git -C "$repo" diff --name-only 2>/dev/null)
    UNTRACKED=$(git -C "$repo" ls-files --others --exclude-standard 2>/dev/null)

    [ -z "$STAGED$UNSTAGED$UNTRACKED" ] && continue

    if [ "$HEADER_SHOWN" = false ]; then
        echo ""
        echo "┌─────────────────────────────────────────────┐"
        echo "│  ⚠️  Mudanças não commitadas nesta sessão   │"
        echo "└─────────────────────────────────────────────┘"
        HEADER_SHOWN=true
    fi

    if [ "$repo" != "$ROOT" ]; then
        echo ""
        echo "📁 $(basename "$repo")"
    fi

    if [ -n "$STAGED" ]; then
        echo ""
        echo "📦 Staged (prontos para commit):"
        echo "$STAGED" | sed 's/^/   /'
    fi

    if [ -n "$UNSTAGED" ]; then
        echo ""
        echo "✏️  Modificados (não staged):"
        echo "$UNSTAGED" | sed 's/^/   /'
    fi

    if [ -n "$UNTRACKED" ]; then
        echo ""
        echo "🆕 Novos arquivos (untracked):"
        echo "$UNTRACKED" | sed 's/^/   /'
    fi
done

[ "$HEADER_SHOWN" = false ] && exit 0

if [ -n "$ISSUE" ]; then
    echo ""
    echo "📌 Issue ativa: #$ISSUE"
fi

echo ""
echo "💡 Considere commitar antes de encerrar:"
if [ -n "$ISSUE" ]; then
    echo "   git add -A && git commit -m \"tipo: descrição (#$ISSUE)\""
else
    echo "   git add -A && git commit -m \"tipo: descrição\""
fi
echo ""

exit 0
