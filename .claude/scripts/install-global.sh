#!/usr/bin/env bash
#
# Instala o ARK globalmente em ~/.claude (Linux/macOS).
# Equivalente do install-global.ps1; ver ./README.md.
#
#   bash .claude/scripts/install-global.sh              # instala
#   bash .claude/scripts/install-global.sh --dry-run    # mostra sem escrever
#   bash .claude/scripts/install-global.sh --uninstall  # desfaz
#
# Diferente do link-skills.sh, que só liga skills/: este liga também commands/,
# registra os hooks, grava ARK_HOME e os toggles, e importa as rules genéricas.
set -euo pipefail

DRY_RUN=0
UNINSTALL=0
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)     DRY_RUN=1 ;;
    --uninstall)   UNINSTALL=1 ;;
    --claude-home) CLAUDE_HOME="$2"; shift ;;
    -h|--help)     sed -n '3,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "opção desconhecida: $1" >&2; exit 2 ;;
  esac
  shift
done

# O script mora em .claude/scripts/, então .. é a própria pasta .claude.
ARK_HOME_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT="$(cd "$ARK_HOME_DIR/.." && pwd)"
[ -d "$ARK_HOME_DIR/skills" ] || { echo "erro: não encontrei $ARK_HOME_DIR/skills" >&2; exit 1; }

SKILLS_DIR="$CLAUDE_HOME/skills"
SETTINGS="$CLAUDE_HOME/settings.json"
CLAUDE_MD="$CLAUDE_HOME/CLAUDE.md"

command -v python3 >/dev/null 2>&1 || {
  echo "erro: python3 é necessário para mesclar o settings.json sem apagar o que já está lá." >&2
  exit 1
}

say()  { printf '  %s\n' "$*"; }
head_() { printf '\n%s\n' "$*"; }
run()  { if [ "$DRY_RUN" = 1 ]; then say "[dry-run] $*"; else "$@"; fi; }

# --- inventário: toda pasta com SKILL.md, em skills/ e em commands/ ---------
ark_skill_dirs() {
  for sub in skills commands; do
    [ -d "$ARK_HOME_DIR/$sub" ] || continue
    find "$ARK_HOME_DIR/$sub" -mindepth 2 -maxdepth 2 -name SKILL.md -print0 |
      while IFS= read -r -d '' f; do dirname "$f"; done
  done
}

# Links em ~/.claude/skills que apontam para dentro deste clone — base da poda e
# do --uninstall. Skill de outra origem nunca entra nesta lista.
ark_links() {
  [ -d "$SKILLS_DIR" ] || return 0
  for l in "$SKILLS_DIR"/*; do
    [ -L "$l" ] || continue
    tgt="$(readlink "$l")"
    case "$tgt" in "$ARK_HOME_DIR"/*) printf '%s\n' "$l" ;; esac
  done
}

# --- settings.json ----------------------------------------------------------
# Mesclagem em python: preserva chaves e hooks que não são do ARK. Identificamos
# os nossos hooks pelo nome do .sh, não por marcador no comando.
merge_settings() {  # $1 = install|uninstall
  local mode="$1"
  [ "$DRY_RUN" = 1 ] && { say "[dry-run] gravaria $SETTINGS"; return 0; }
  ARK_MODE="$mode" ARK_HOOKS="$ARK_HOME_DIR/hooks" ARK_ENV="$ARK_HOME_DIR" \
  ARK_SETTINGS="$SETTINGS" python3 - <<'PY'
import json, os, pathlib

mode  = os.environ['ARK_MODE']
hooks = os.environ['ARK_HOOKS']
path  = pathlib.Path(os.environ['ARK_SETTINGS'])
KEYS  = ['ARK_HOME', 'GRILL_LOG', 'BOARD_SYNC', 'PR_REVIEW_PARALLEL', 'AUTO_BRANCH']
OURS  = ('stop-commit-reminder.sh', 'grill-log.sh')

data = {}
if path.exists() and path.read_text(encoding='utf-8').strip():
    data = json.loads(path.read_text(encoding='utf-8'))

# tira sempre os nossos hooks; reinstala depois se for o caso (idempotência)
for event in list(data.get('hooks', {})):
    kept = []
    for group in data['hooks'][event]:
        inner = [h for h in group.get('hooks', [])
                 if not any(o in str(h.get('command', '')) for o in OURS)]
        if inner:
            group['hooks'] = inner
            kept.append(group)
    if kept:
        data['hooks'][event] = kept
    else:
        del data['hooks'][event]
if 'hooks' in data and not data['hooks']:
    del data['hooks']

if mode == 'uninstall':
    for k in KEYS:
        data.get('env', {}).pop(k, None)
    if 'env' in data and not data['env']:
        del data['env']
else:
    env = data.setdefault('env', {})
    env['ARK_HOME'] = os.environ['ARK_ENV']
    for k in KEYS[1:]:
        env[k] = 'on'
    h = data.setdefault('hooks', {})
    h.setdefault('Stop', []).append(
        {'hooks': [{'type': 'command', 'command': f'bash "{hooks}/stop-commit-reminder.sh"'}]})
    h.setdefault('UserPromptExpansion', []).append(
        {'matcher': 'grill-(me|with-docs)',
         'hooks': [{'type': 'command', 'command': f'bash "{hooks}/grill-log.sh"'}]})

path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
PY
}

# --- CLAUDE.md --------------------------------------------------------------
# As rules genéricas do ARK entram por import, não por cópia: melhoria no clone vale
# em toda sessão, e o .claude/ do projeto só guarda o que descreve o projeto.
ARK_RULE_IMPORTS="karpathy-principles.md code-conventions.md"

rules_import() {  # $1 = install|uninstall
  local rule line tmp missing=0
  if [ "$1" = uninstall ]; then
    [ -f "$CLAUDE_MD" ] || return 0
    grep -q '^<!-- ARK -->$' "$CLAUDE_MD" || return 0
    [ "$DRY_RUN" = 1 ] && { say "[dry-run] removeria os imports do CLAUDE.md"; return 0; }
    tmp="$(mktemp)"
    grep -v -e "^@$ARK_HOME_DIR/rules/" -e '^<!-- ARK -->$' "$CLAUDE_MD" > "$tmp"
    mv "$tmp" "$CLAUDE_MD"
    say "imports removidos"
    return 0
  fi
  for rule in $ARK_RULE_IMPORTS; do
    line="@$ARK_HOME_DIR/rules/$rule"
    if [ ! -f "$CLAUDE_MD" ] || ! grep -qxF "$line" "$CLAUDE_MD"; then missing=1; fi
  done
  [ "$missing" = 0 ] && { say "imports já presentes"; return 0; }
  [ "$DRY_RUN" = 1 ] && { say "[dry-run] acrescentaria os imports ao CLAUDE.md"; return 0; }
  mkdir -p "$CLAUDE_HOME"
  # Reescreve o bloco inteiro: assim uma rule nova entra numa reinstalação sem
  # duplicar as que já estavam lá.
  if [ -f "$CLAUDE_MD" ]; then
    tmp="$(mktemp)"
    grep -v -e "^@$ARK_HOME_DIR/rules/" -e '^<!-- ARK -->$' "$CLAUDE_MD" > "$tmp"
    mv "$tmp" "$CLAUDE_MD"
  fi
  printf '<!-- ARK -->\n' >> "$CLAUDE_MD"
  for rule in $ARK_RULE_IMPORTS; do
    printf '@%s/rules/%s\n' "$ARK_HOME_DIR" "$rule" >> "$CLAUDE_MD"
  done
  say "imports das rules genéricas atualizados ($ARK_RULE_IMPORTS)"
}

# ============================================================== execução

printf '\nARK -> %s\n' "$CLAUDE_HOME"
printf 'clone: %s\n' "$REPO_ROOT"
[ "$DRY_RUN" = 1 ] && printf '(dry-run: nada será escrito)\n'

if [ "$UNINSTALL" = 1 ]; then
  head_ "Removendo links"
  while IFS= read -r l; do
    [ -n "$l" ] || continue
    say "removendo $(basename "$l")"
    run rm -f "$l"
  done <<< "$(ark_links)"

  head_ "Limpando settings.json e CLAUDE.md"
  merge_settings uninstall
  rules_import uninstall
  printf '\nDesinstalado. O clone em %s não foi tocado.\n' "$REPO_ROOT"
  exit 0
fi

run mkdir -p "$SKILLS_DIR"

head_ "Skills e comandos"
created=0; skipped=0
while IFS= read -r src; do
  [ -n "$src" ] || continue
  name="$(basename "$src")"
  target="$SKILLS_DIR/$name"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    # Pasta real idêntica ao clone é cópia redundante de instalação antiga: trocar
    # por link não perde nada. Qualquer diferença faz a pasta ser respeitada.
    if diff -rq "$target" "$src" >/dev/null 2>&1; then
      if [ "$DRY_RUN" = 1 ]; then
        say "trocaria por link $name (cópia idêntica ao clone)"
      else
        rm -rf "$target"
        say "cópia idêntica trocada por link: $name"
      fi
    else
      echo "  PULADO: $target existe como pasta real e diferente do clone." >&2
      skipped=$((skipped + 1))
      continue
    fi
  fi
  run ln -sfn "$src" "$target"
  say "$name"
  created=$((created + 1))
done <<< "$(ark_skill_dirs)"

# Poda: skill renomeada ou removida do ARK deixaria um link apontando para o vazio,
# e o Claude Code reclamaria dela em toda sessão.
pruned=0
while IFS= read -r l; do
  [ -n "$l" ] || continue
  [ -e "$l" ] && continue          # -e segue o link: existe = alvo vivo
  say "removendo órfão $(basename "$l")"
  run rm -f "$l"
  pruned=$((pruned + 1))
done <<< "$(ark_links)"

head_ "settings.json"
merge_settings install
say "env: ARK_HOME + 4 toggles"
say "hooks: Stop + UserPromptExpansion (caminho absoluto)"

head_ "CLAUDE.md"
rules_import install

printf '\nPronto: %s link(s), %s órfão(s) removido(s), %s pulado(s).\n' "$created" "$pruned" "$skipped"
printf 'Skill alterada: nada a fazer, o link já aponta para o clone.\n'
printf 'Skill nova, renomeada ou removida: git pull e /sync-global (ou rode este script).\n'
