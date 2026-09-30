# Convenções de Código — Java

> Complementa [`code-conventions.md`](./code-conventions.md). Só se aplica a
> projetos Java.

---

## Javadoc

Dois níveis:

**1. Classe / interface** — todo tipo público tem Javadoc dizendo o que ele
representa ou orquestra:
```java
/**
 * Orchestrates the execution steps of a process.
 */
public class Pipeline { ... }
```

**2. Método** — obrigatório nos métodos públicos com ≥ 2 parâmetros ou retorno não
óbvio. `@param` para cada parâmetro, `@return` quando não for `void`, `@throws`
para toda exceção que o chamador deva tratar:
```java
/**
 * Processes an item according to the given options.
 *
 * @param item the input item to process
 * @param options options that control the processing
 * @return the processing result
 * @throws InvalidItemException if the item fails validation
 */
public Result processItem(Item item, Options options) { ... }
```

Getter, setter e override trivial dispensam Javadoc — repetir o nome não informa.

---

## Tipagem

- **Genéricos sempre parametrizados** — nunca o tipo cru (`List`, `Map`): ele
  desliga a checagem do compilador.
- Declarar pela interface, instanciar pela implementação: `List<Order>`, não
  `ArrayList<Order>`, em campo, parâmetro e retorno.
- `var` só quando o tipo está visível no lado direito da atribuição.
- **`Optional` só em retorno** — nunca em campo, parâmetro ou coleção. Ele sinaliza
  "pode não haver resultado"; num parâmetro, só troca um `null` por outro.
- Retornar coleção vazia, não `null`.

```java
// ✅ correto
public Optional<Order> findOrder(String orderId) { ... }
public List<Order> loadOrders(Path sourcePath) { ... }

// ❌ errado
public List loadOrders(Path sourcePath) { ... }        // tipo cru
public void publish(Optional<Target> target) { ... }   // Optional em parâmetro
```

---

## Naming

- Variáveis, parâmetros e métodos em `camelCase`.
- Classes, interfaces, enums e records em `PascalCase`.
- Constantes (`static final` imutável) em `UPPER_SNAKE_CASE`.
- Pacotes em minúsculas, sem separador: `com.example.orderpipeline`.

```java
package com.example.orderpipeline;

public class OrderPipeline {
    private static final int MAX_RETRIES = 3;

    public List<Order> loadOrders(Path sourcePath) { ... }
}
```
