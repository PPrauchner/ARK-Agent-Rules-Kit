#!/usr/bin/env bash
# Le ou grava a issue ativa em <raiz do projeto>/.claude/current-issue.
#
# Uso:
#   bash .claude/scripts/current-issue.sh set <numero>
#   bash .claude/scripts/current-issue.sh get      # imprime o numero, ou nada
#   bash .claude/scripts/current-issue.sh path     # imprime o caminho do arquivo
#
# Por que existe: o caminho relativo ".claude/current-issue" se resolve contra o
# cwd do shell, e o cwd deriva ao longo da sessao -- basta um "cd <repo>" para o
# arquivo nascer dentro do repositorio, nao versionado mas tambem nao ignorado,
# e para o /commit ler outro arquivo que nao o gravado pelo /start-issue.
#
# Raiz do projeto, na ordem:
#   1. CLAUDE_PROJECT_DIR, quando definido (hooks);
#   2. o ancestral mais proximo do cwd com .claude/rules/ -- a pasta que a
#      adopt-repo semeia na raiz de todo projeto adotado;
#   3. o toplevel do git;
#   4. o proprio cwd.

set -u

die() { printf 'current-issue: %s\n' "$1" >&2; exit 1; }

project_root() {
    if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "$CLAUDE_PROJECT_DIR" ]; then
        printf '%s\n' "$CLAUDE_PROJECT_DIR"
        return
    fi

    dir="$PWD"
    while :; do
        if [ -d "$dir/.claude/rules" ]; then
            printf '%s\n' "$dir"
            return
        fi
        parent="$(dirname "$dir")"
        [ "$parent" = "$dir" ] && break
        dir="$parent"
    done

    git rev-parse --show-toplevel 2>/dev/null || printf '%s\n' "$PWD"
}

file="$(project_root)/.claude/current-issue"

case "${1:-}" in
    set)
        [ "$#" -eq 2 ] || die "uso: current-issue.sh set <numero>"
        mkdir -p "$(dirname "$file")" || die "nao consegui criar $(dirname "$file")"
        printf '%s\n' "$2" > "$file" || die "nao consegui gravar $file"
        printf 'current-issue -> %s (%s)\n' "$2" "$file"
        ;;
    get)
        [ -f "$file" ] && tr -d '[:space:]' < "$file"
        exit 0
        ;;
    path)
        printf '%s\n' "$file"
        ;;
    *)
        die "uso: current-issue.sh <set <numero>|get|path>"
        ;;
esac
