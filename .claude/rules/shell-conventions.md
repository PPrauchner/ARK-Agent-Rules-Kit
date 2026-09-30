# Convenções de Código — Shell

> Complementa [`code-conventions.md`](./code-conventions.md). Só se aplica a
> scripts Bash. PowerShell não entra aqui.

---

## Comentários

Dois níveis:

**1. Script** — todo script começa, logo abaixo do shebang, com um cabeçalho de uso:
o que faz, como chamar, o que cada argumento significa e o que sai:
```bash
#!/usr/bin/env bash
# Loads orders from the source file and prints the valid ones as CSV.
#
# Usage: load-orders.sh <source-path> [limit]
#   source-path  file with one order per line
#   limit        maximum number of orders to print (default: all)
# Exit: 0 on success, 1 on invalid input, 2 if the file is missing.
```

**2. Função** — comentário acima dela quando recebe argumentos ou o retorno não é
óbvio. Shell não tem assinatura: o comentário diz o que `$1`, `$2` são e o que a
função imprime ou retorna:
```bash
# Prints the total of an order line.
#   $1  order line, fields separated by ";"
# Returns 1 if the line has no total field.
order_total() { ... }
```

---

## Variáveis e argumentos

Shell não tem tipos; tudo é string. O equivalente é **declarar o escopo e nomear
os argumentos**:

- **`local` em toda variável de função** — sem ele, a variável é global e vaza para
  o resto do script.
- Dar nome aos posicionais logo no início: `local source_path="$1"`, e não `$1`
  espalhado pelo corpo.
- `readonly` para valor que não muda depois de definido.
- Lista é array (`files=(a b c)`, `"${files[@]}"`), não string separada por espaço.

```bash
# ✅ correto
load_orders() {
  local source_path="$1"
  local limit="${2:-0}"
  ...
}

# ❌ errado
load_orders() {
  path=$1          # global, sem aspas
  head -n $2 $path
}
```

---

## Naming

- Variáveis locais e funções em `snake_case`.
- **Variáveis de ambiente e constantes exportadas em `UPPER_SNAKE_CASE`** — é o que
  diz ao leitor que o valor vem de fora ou vale para os processos filhos.
- Nome de arquivo: siga o que o projeto já usa; em projeto novo, `kebab-case.sh`.

```bash
readonly MAX_RETRIES=3
export ORDER_SOURCE_DIR="${ORDER_SOURCE_DIR:-./data}"

parse_order_line() { ... }
```

---

## Armadilhas

- **`set -euo pipefail` no topo.** Sem ele, o script segue depois de um comando
  falhar, usa variável não definida como string vazia e ignora erro no meio de pipe.
- **Aspas em toda expansão**: `"$var"`, `"$@"`, `"$(cmd)"`. Sem aspas, valor com
  espaço vira vários argumentos e `*` vira lista de arquivos.
- **`[[ ]]` em vez de `[ ]`.** O `[[` não quebra com variável vazia nem com espaço,
  e aceita `&&`, `||` e `=~` sem escape.
- **GNU × BSD.** `sed -i`, `date`, `readlink -f`, `grep -P` mudam entre Linux e
  macOS. Script que roda nos dois evita essas flags ou testa qual versão tem.
