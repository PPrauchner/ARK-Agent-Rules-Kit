# Convenções de Código — Python

> Complementa [`code-conventions.md`](./code-conventions.md). Só se aplica a
> projetos Python.

---

## Docstrings (Google Style)

Três níveis:

**1. Módulo** — todo `.py` começa com um bloco descritivo:
```python
"""
One-line summary of what the module does.

Responsibilities:
- First responsibility of the module.
- Second responsibility of the module.
"""
```

**2. Função / método** — obrigatório quando há ≥ 2 parâmetros ou o retorno não é
óbvio:
```python
def process_item(item: Item, options: Options) -> Result:
    """Processes an item according to the given options.

    Args:
        item: The input item to process.
        options: Options that control the processing.

    Returns:
        The processing result.
    """
```

**3. Classe** — docstring na classe e nos métodos públicos não-triviais:
```python
class Pipeline:
    """Orchestrates the execution steps of a process.

    Attributes:
        steps: Steps in execution order.
    """
```

---

## Type Hints

- **Todo parâmetro e retorno** de função/método devem ser tipados — sem exceção.
- Sintaxe nativa Python 3.10+: `X | None` em vez de `Optional[X]`; `list[int]` em
  vez de `List[int]`.
- Para forward references (ex.: um tipo que referencia a si mesmo), adicionar
  `from __future__ import annotations` no topo.
- Evitar `Any` — ele encobre erros.

```python
# ✅ correto
def process(item: Item) -> Result: ...
def publish(resource: Resource, target: str) -> bool: ...

# ❌ errado
def process(item):          # sem anotações
def publish(...) -> Any:    # Any encobre erros
```

---

## Naming

- Variáveis e funções em `snake_case`.
- Classes em `PascalCase`.
- Constantes em `UPPER_SNAKE_CASE`.

```python
MAX_RETRIES = 3

class OrderPipeline: ...

def load_orders(source_path: str) -> list[Order]: ...
```
