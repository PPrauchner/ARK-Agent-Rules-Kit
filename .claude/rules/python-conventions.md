# Convenções de Código — Python

> Complementa [`code-conventions.md`](./code-conventions.md). Só se aplica a
> projetos Python.

---

## Docstrings (Google Style)

Três níveis:

**1. Módulo** — todo `.py` começa com um bloco descritivo:
```python
"""
Resumo de uma linha do que o módulo faz.

Responsabilidades:
- Primeira responsabilidade do módulo.
- Segunda responsabilidade do módulo.
"""
```

**2. Função / método** — obrigatório quando há ≥ 2 parâmetros ou o retorno não é
óbvio:
```python
def process_item(item: Item, options: Options) -> Result:
    """Processa um item de acordo com as opções fornecidas.

    Args:
        item: Item de entrada a ser processado.
        options: Opções que controlam o processamento.

    Returns:
        O resultado do processamento.
    """
```

**3. Classe** — docstring na classe e nos métodos públicos não-triviais:
```python
class Pipeline:
    """Orquestra as etapas de execução de um processo.

    Attributes:
        steps: Etapas na ordem de execução.
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
