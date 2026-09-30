# Convenções de Código — TypeScript

> Complementa [`code-conventions.md`](./code-conventions.md). Só se aplica a
> projetos TypeScript.

---

## TSDoc

Dois níveis:

**1. Módulo** — todo arquivo começa com um bloco dizendo o que ele faz:
```ts
/**
 * Loads and validates orders from the source file.
 *
 * @packageDocumentation
 */
```

**2. Função / classe** — obrigatório nas exportadas com ≥ 2 parâmetros ou retorno
não óbvio. `@param` para cada parâmetro, `@returns` quando houver retorno, `@throws`
para todo erro que o chamador deva tratar.

**Sem tipo no comentário** — o tipo está na assinatura. Repeti-lo no TSDoc só cria
uma segunda fonte que diverge da primeira:
```ts
/**
 * Processes an item according to the given options.
 *
 * @param item - The input item to process.
 * @param options - Options that control the processing.
 * @returns The processing result.
 * @throws {@link InvalidItemError} If the item fails validation.
 */
export function processItem(item: Item, options: Options): Result { ... }
```

---

## Tipagem

- **`"strict": true`** no `tsconfig.json`. Sem ele, `null` e `undefined` cabem em
  qualquer tipo e o compilador deixa passar o erro que ele existe para pegar.
- **Sem `any`** — ele desliga a checagem de tudo que toca. Para valor de origem
  desconhecida (JSON, `catch`, entrada externa), usar `unknown` e estreitar.
- Parâmetro e retorno de função exportada sempre anotados; dentro da função, deixar
  a inferência trabalhar.
- `as` só quando o compilador não tem como saber e você tem — nunca para calar erro.

```ts
// ✅ correto
function parseOrder(raw: unknown): Order { ... }
export function loadOrders(sourcePath: string): Promise<Order[]> { ... }

// ❌ errado
function parseOrder(raw: any) { ... }        // any desliga a checagem
const order = JSON.parse(text) as Order;     // as em vez de validar
```

---

## Naming

- Variáveis, parâmetros e funções em `camelCase`.
- Classes, interfaces, `type` e `enum` em `PascalCase` — sem prefixo `I` em
  interface.
- Constantes de módulo (valor fixo, conhecido de antemão) em `UPPER_SNAKE_CASE`.
- Nome de arquivo: siga o que o projeto já usa; em projeto novo, `kebab-case.ts`.

```ts
const MAX_RETRIES = 3;

interface Order { id: string; total: number; }

class OrderPipeline { ... }

async function loadOrders(sourcePath: string): Promise<Order[]> { ... }
```
