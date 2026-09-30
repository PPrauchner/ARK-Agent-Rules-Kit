# Convenções de Código — SQL

> Complementa [`code-conventions.md`](./code-conventions.md). Só se aplica a
> projetos com SQL escrito à mão — migrations, views, queries.

---

## Comentários

Dois níveis:

**1. Migration** — todo arquivo de migration começa dizendo o que muda e por quê.
O nome do arquivo diz *o quê*; o comentário guarda o *porquê*, que não se recupera
lendo o schema depois:
```sql
-- Adds orders.cancelled_at so cancellations keep their date.
-- Replaces the boolean orders.cancelled, dropped in the next migration
-- once the backfill is done.
```

**2. Objeto** — tabela ou coluna cujo significado não é óbvio pelo nome leva
comentário. Onde o banco suporta, `COMMENT ON` — assim ele fica no schema, visível
para quem consulta o banco, e não só no arquivo:
```sql
COMMENT ON COLUMN orders.total_cents IS 'Order total in cents, taxes included.';
```

---

## Tipagem

- **Tipo explícito e restrito em toda coluna.** O tipo é a primeira validação:
  `numeric(12, 2)` ou inteiro em centavos para dinheiro, nunca `float`; `date` ou
  `timestamp` para data, nunca texto.
- **`NOT NULL` por padrão**; coluna nula só quando "não há valor" é um estado real.
- Restrições no banco, não só na aplicação: `PRIMARY KEY`, `FOREIGN KEY`, `UNIQUE`,
  `CHECK`. O banco é o único lugar que todo cliente respeita.
- Timestamp com fuso quando o banco distingue (`timestamptz` no PostgreSQL).

```sql
-- ✅ correto
CREATE TABLE orders (
  id           bigint PRIMARY KEY,
  customer_id  bigint NOT NULL REFERENCES customers (id),
  total_cents  bigint NOT NULL CHECK (total_cents >= 0),
  created_at   timestamptz NOT NULL
);

-- ❌ errado
CREATE TABLE Orders (id int, customer text, total float, created varchar(30));
```

---

## Naming

- Tabelas, colunas, índices e constraints em `snake_case`.
- Tabela no plural ou no singular: siga o que o projeto já usa; em projeto novo,
  plural (`orders`, `order_items`).
- Chave estrangeira como `<tabela no singular>_id`: `customer_id`.
- Palavras-chave em `UPPER CASE` (`SELECT`, `WHERE`), identificadores em minúsculas.

```sql
SELECT o.id, o.total_cents
FROM orders AS o
WHERE o.customer_id = 42;
```

---

## Armadilhas

- **Migration aplicada é imutável.** Depois que rodou em algum ambiente, editar o
  arquivo não muda aquele banco — só faz o histórico mentir e o próximo ambiente
  divergir. Correção é uma migration nova.
