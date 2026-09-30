# Convenções de Código — C++

> Complementa [`code-conventions.md`](./code-conventions.md). Só se aplica a
> projetos C++. Projeto em C usa `c-conventions.md`.

---

## Doxygen

Dois níveis:

**1. Classe** — todo tipo público tem um bloco dizendo o que ele representa ou
orquestra:
```cpp
/**
 * @brief Orchestrates the execution steps of a process.
 */
class Pipeline { ... };
```

**2. Função / método** — obrigatório nos públicos com ≥ 2 parâmetros ou retorno não
óbvio. O comentário mora **no header**; `@param` para cada parâmetro, `@return`
quando não for `void`, `@throws` para toda exceção que o chamador deva tratar:
```cpp
/**
 * @brief Processes an item according to the given options.
 *
 * @param item the input item to process
 * @param options options that control the processing
 * @return the processing result
 * @throws InvalidItemError if the item fails validation
 */
Result process_item(const Item& item, const Options& options);
```

---

## Tipagem

- **`const&` para parâmetro que não é copiado nem modificado** — evita a cópia sem
  abrir mão da garantia de só-leitura. Tipos pequenos (`int`, ponteiro,
  `std::string_view`) vão por valor.
- **`const` por padrão** em variável local e em método que não altera o objeto.
- **`auto` com moderação** — quando o tipo está visível à direita ou é ilegível
  (iteradores, lambdas). Não para esconder o tipo de retorno de uma função.
- Sem cast estilo C; `static_cast` e afins deixam a intenção explícita.

```cpp
// ✅ correto
std::vector<Order> load_orders(const std::filesystem::path& source_path);
auto it = orders.find(order_id);

// ❌ errado
std::vector<Order> load_orders(std::filesystem::path source_path);  // cópia à toa
auto total = compute_total(orders);                                  // tipo escondido
```

---

## Naming

C++ não tem consenso: siga o que o projeto já usa; em projeto novo:

- Variáveis, parâmetros, funções e métodos em `snake_case` (como a biblioteca
  padrão).
- Classes, structs, enums e aliases de tipo em `PascalCase`.
- Constantes (`constexpr`, `static const`) em `UPPER_SNAKE_CASE`.
- Membros sem sufixo `_` nem prefixo `m_` — `this->` desambigua quando precisar.

```cpp
constexpr int MAX_RETRIES = 3;

class OrderPipeline {
public:
    std::vector<Order> load_orders(const std::filesystem::path& source_path);
private:
    std::vector<Step> steps;
};
```

---

## Armadilhas

- **RAII: todo recurso tem um dono com destrutor.** Memória, arquivo, lock, socket
  — quem adquire é um objeto, e o destrutor libera, inclusive quando uma exceção
  sai no meio.
- **Sem `new`/`delete` crus.** Usar `std::make_unique` (dono único) ou
  `std::make_shared` (dono compartilhado); ponteiro cru só observa, nunca é dono.
