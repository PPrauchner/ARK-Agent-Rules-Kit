#!/usr/bin/env bash
# Cria (ou reaproveita) a branch de trabalho quando a sessao esta no tronco.
#
# Uso:
#   bash .claude/scripts/ensure-branch.sh issue <numero> [titulo]
#   bash .claude/scripts/ensure-branch.sh afk <numero> [numero...]
#
# Imprime no stdout o nome da branch em que a sessao ficou, ou nada quando nao
# havia o que fazer (ja estava fora do tronco, ou AUTO_BRANCH=off).
#
# CONTRATO: este script FALHA quando nao consegue criar a branch (exit != 0), ao
# contrario do board-move.sh. La, seguir sem o board nao custa nada; aqui, seguir
# sem a branch despeja os commits no tronco -- exatamente o que ele existe para
# evitar. Quem chama deve parar.
#
# Desativar: AUTO_BRANCH=off no bloco "env" de .claude/settings.json.
#
# Tronco = main, master, dev, develop, development, ou a branch default do
# repositorio (lida de refs/remotes/origin/HEAD, sem rede).

set -u

warn() { printf 'ensure-branch: %s\n' "$1" >&2; }
die() { warn "$1"; exit 1; }

# --- toggle de desativacao ---
case "$(printf '%s' "${AUTO_BRANCH:-on}" | tr 'A-Z' 'a-z')" in
    off|0|false|no) exit 0 ;;
esac

[ "$#" -ge 2 ] || die "uso: ensure-branch.sh <issue|afk> <numero> [...]"
mode="$1"
shift

# --- a branch atual e um tronco? ---
current="$(git symbolic-ref --quiet --short HEAD)" || {
    warn "HEAD destacado -- nenhuma branch de tronco para proteger"
    exit 0
}

default="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
default="${default#origin/}"

is_trunk=""
case "$current" in
    main|master|dev|develop|development) is_trunk=1 ;;
esac
if [ -n "$default" ] && [ "$current" = "$default" ]; then
    is_trunk=1
fi
[ -n "$is_trunk" ] || exit 0

# --- montar o nome ---

# Transliteracao caractere a caractere: `y///` quebraria com multibyte sob
# locale C, que e o que o Git Bash costuma dar no Windows.
unaccent() {
    sed -e 's/á/a/g; s/à/a/g; s/â/a/g; s/ã/a/g; s/ä/a/g' \
        -e 's/é/e/g; s/è/e/g; s/ê/e/g; s/ë/e/g' \
        -e 's/í/i/g; s/ì/i/g; s/î/i/g; s/ï/i/g' \
        -e 's/ó/o/g; s/ò/o/g; s/ô/o/g; s/õ/o/g; s/ö/o/g' \
        -e 's/ú/u/g; s/ù/u/g; s/û/u/g; s/ü/u/g' \
        -e 's/ç/c/g; s/ñ/n/g'
}

# No maximo 4 palavras e 30 caracteres: o slug identifica a branch, nao
# descreve a issue. Quem chama passa um resumo curto; o corte aqui e so a rede
# de seguranca para quando vier o titulo inteiro.
slugify() {
    printf '%s' "$1" \
        | tr 'A-ZÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ' 'a-záàâãäéèêëíìîïóòôõöúùûüçñ' \
        | unaccent \
        | sed 's/[^a-z0-9]\{1,\}/-/g; s/^-//; s/-$//' \
        | cut -d- -f1-4 \
        | cut -c1-30 \
        | sed 's/-$//'
}

# Numeros ordenados e sem repeticao viram faixas: 1,2,3,7,20 -> 1-3_7_20.
# Hifen significa "ate"; underscore separa itens.
compact_range() {
    printf '%s\n' "$@" | sort -n -u | awk '
        function emit() {
            if (out != "") out = out "_"
            out = out (start == last ? start : start "-" last)
        }
        NR == 1 { start = last = $1; next }
        $1 == last + 1 { last = $1; next }
        { emit(); start = last = $1 }
        END { emit(); print out }
    '
}

case "$mode" in
    issue)
        number="$1"
        shift
        title="${1:-}"
        case "$number" in
            ''|*[!0-9]*) die "numero de issue invalido: '$number'" ;;
        esac
        slug="$(slugify "$title")"
        target="issue/${number}${slug:+-$slug}"
        ;;
    afk)
        for n in "$@"; do
            case "$n" in
                ''|*[!0-9]*) die "numero de issue invalido: '$n'" ;;
            esac
        done
        target="afk/$(compact_range "$@")"
        ;;
    *)
        die "modo desconhecido: '$mode' (esperado 'issue' ou 'afk')"
        ;;
esac

git check-ref-format --branch "$target" >/dev/null 2>&1 \
    || die "nome de branch invalido: '$target'"

# --- criar ou reaproveitar ---
if git show-ref --verify --quiet "refs/heads/$target"; then
    git checkout "$target" >/dev/null 2>&1 \
        || die "a branch '$target' ja existe mas o checkout falhou"
    warn "a branch '$target' ja existia -- retomando o trabalho nela"
else
    git checkout -b "$target" >/dev/null 2>&1 \
        || die "falhou ao criar a branch '$target' a partir de '$current'"
fi

printf '%s\n' "$target"
