# Convenções de Código — JavaScript

> Complementa [`code-conventions.md`](./code-conventions.md). Só se aplica a
> projetos JavaScript. Projeto em TypeScript usa `typescript-conventions.md`.

---

## JSDoc

Dois níveis:

**1. Módulo** — todo arquivo começa com um bloco dizendo o que ele faz:
```js
/**
 * @file Loads and validates orders from the source file.
 */
```

**2. Função / classe** — obrigatório nas exportadas com ≥ 2 parâmetros ou retorno
não óbvio. `@param` para cada parâmetro, `@returns` quando houver retorno, `@throws`
para todo erro que o chamador deva tratar:
```js
/**
 * Processes an item according to the given options.
 *
 * @param {Item} item - The input item to process.
 * @param {Options} options - Options that control the processing.
 * @returns {Result} The processing result.
 * @throws {InvalidItemError} If the item fails validation.
 */
export function processItem(item, options) { ... }
```

---

## Tipagem

JavaScript não tem tipo na assinatura — **o JSDoc é a tipagem**. Por isso o tipo
entre chaves é obrigatório, não enfeite:

- Todo `@param` e `@returns` leva `{Tipo}`.
- Formas de objeto reutilizadas viram `@typedef`, em vez de `{Object}` genérico.
- Evitar `{*}` e `{any}` — encobrem erros, como o `Any` do Python.
- Valor que pode faltar declara isso: `{Order | null}`, `{string} [label]`.

```js
/**
 * @typedef {Object} Order
 * @property {string} id
 * @property {number} total
 */

// ✅ correto
/** @param {string} sourcePath @returns {Promise<Order[]>} */
// ❌ errado
/** @param sourcePath @returns {*} */
```

---

## Naming

- Variáveis, parâmetros e funções em `camelCase`.
- Classes em `PascalCase`.
- Constantes de módulo (valor fixo, conhecido de antemão) em `UPPER_SNAKE_CASE`.
- Nome de arquivo: siga o que o projeto já usa; em projeto novo, `kebab-case.js`.

```js
const MAX_RETRIES = 3;

class OrderPipeline { ... }

async function loadOrders(sourcePath) { ... }
```

---

## Armadilhas

- **`===` e `!==`, nunca `==`/`!=`.** A comparação frouxa converte tipos
  (`0 == ""` é `true`). Exceção única e explícita: `value == null`, que cobre
  `null` e `undefined` de uma vez.
- **`const` por padrão, `let` quando houver reatribuição, nunca `var`.** O `var`
  tem escopo de função e é içado (*hoisting*): vaza de blocos e de laços.
