# Convenções de Código — C

> Complementa [`code-conventions.md`](./code-conventions.md). Só se aplica a
> projetos C. Projeto em C++ usa `cpp-conventions.md`.

---

## Doxygen

Dois níveis:

**1. Arquivo** — todo `.h` e `.c` começa com um bloco dizendo o que ele faz:
```c
/**
 * @file
 * @brief Loads and validates orders from the source file.
 */
```

**2. Função** — obrigatório nas públicas (declaradas no `.h`) com ≥ 2 parâmetros ou
retorno não óbvio. O comentário mora **no header**, que é o contrato; `@param` para
cada parâmetro, `@return` quando não for `void`, e o que cada código de erro
significa:
```c
/**
 * @brief Processes an item according to the given options.
 *
 * @param item the input item to process
 * @param options options that control the processing
 * @return 0 on success, -1 if the item fails validation
 */
int process_item(const struct item *item, const struct options *options);
```

---

## Tipagem

- **`const` em todo ponteiro que a função não modifica.** É a única forma de a
  assinatura dizer "só leio" — e o compilador passa a cobrar.
- **Tipos de tamanho fixo** (`<stdint.h>`: `int32_t`, `uint8_t`, `uint64_t`) quando
  o tamanho importa — formato em disco, protocolo, bits. `int` e `long` mudam de
  tamanho entre plataformas.
- `size_t` para tamanhos e índices; `bool` de `<stdbool.h>` para verdadeiro/falso,
  não `int`.
- Evitar `void *` fora de interfaces genéricas — ele desliga a checagem de tipo.

```c
// ✅ correto
uint32_t checksum(const uint8_t *data, size_t length);

// ❌ errado
unsigned long checksum(char *data, int length);  // tamanho incerto, sem const
```

---

## Naming

- Variáveis, parâmetros e funções em `snake_case`.
- `struct`, `enum` e `typedef` em `snake_case` — siga o que o projeto já usa quanto
  ao sufixo `_t` (reservado pelo POSIX); em projeto novo, sem `_t`.
- Macros e constantes (`#define`, valores de `enum`) em `UPPER_SNAKE_CASE`.
- Funções públicas levam o prefixo do módulo (`order_load`, `order_free`) — C não
  tem namespace.

```c
#define MAX_RETRIES 3

struct order_pipeline { ... };

int order_load(const char *source_path, struct order **orders, size_t *count);
```

---

## Armadilhas

- **Documentar quem é dono da memória.** Toda função que devolve ou recebe ponteiro
  diz, no Doxygen, quem libera — e com qual função. Sem isso, o chamador adivinha, e
  o erro vira vazamento ou *double free*:
  ```c
  /** @return a new order; the caller owns it and must release it with order_free(). */
  struct order *order_create(const char *id);
  ```
