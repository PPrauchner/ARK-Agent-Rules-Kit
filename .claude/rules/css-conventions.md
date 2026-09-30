# Convenções de Código — CSS

> Complementa [`code-conventions.md`](./code-conventions.md). Só se aplica a
> projetos CSS. Markup mora em `html-conventions.md`.

---

## Comentários

Dois níveis:

**1. Seção** — o arquivo é dividido em blocos, cada um aberto por um comentário que
diz o que ele estiliza:
```css
/* ==========================================================================
   Order card
   ========================================================================== */
```

**2. Regra** — só quando o *porquê* não é óbvio: um valor mágico, um contorno de
bug de navegador, uma dependência de outra regra:
```css
.order-card {
  /* Leaves room for the fixed header, which is 64px tall. */
  scroll-margin-top: 4rem;
}
```

---

## Custom properties

CSS não tem tipos; o equivalente é **nomear o valor**. Cor, espaçamento e tipografia
repetidos viram custom property em `:root`, e as regras usam o nome:

- Um valor com significado (cor da marca, espaço base) tem uma fonte só.
- Tema (claro/escuro) é redefinir as propriedades, não reescrever as regras.
- Valor solto repetido em várias regras é sinal de property faltando.

```css
:root {
  --color-accent: #2563eb;
  --space-md: 1rem;
}

/* ✅ correto */
.order-card { padding: var(--space-md); border-color: var(--color-accent); }

/* ❌ errado */
.order-card { padding: 16px; border-color: #2563eb; }
```

---

## Naming

CSS não tem consenso: siga o que o projeto já usa; em projeto novo:

- Classes e custom properties em `kebab-case`.
- **BEM quando houver componente com variações**: bloco `order-card`, elemento
  `order-card__title`, modificador `order-card--highlighted`.
- Nome de arquivo em `kebab-case.css`.

```css
.order-card { ... }
.order-card__title { ... }
.order-card--highlighted { ... }
```

---

## Armadilhas

- **Sem `!important`.** Ele vence a cascata em vez de resolvê-la, e o próximo
  ajuste precisa de outro `!important`. Conflito se resolve com especificidade ou
  ordem.
- **Sem id para estilo.** Seletor de id tem especificidade alta demais para ser
  sobrescrito por classe e não se reusa. Estilo vai em classe; id fica para âncora e
  JavaScript.
