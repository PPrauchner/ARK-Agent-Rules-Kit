# Convenções de Código — HTML

> Complementa [`code-conventions.md`](./code-conventions.md). Só se aplica a
> projetos HTML. Estilo mora em `css-conventions.md`.

---

## Comentários

HTML não tem docstring. O comentário marca **o que o markup não diz sozinho**:
de onde vem um bloco gerado, por que uma estrutura fora do comum existe:
```html
<!-- Filled by orders.js after the first fetch; keep the id stable. -->
<ul id="order-list"></ul>
```

Não comentar o óbvio (`<!-- header -->` acima de `<header>`): o elemento já diz.
Comentário HTML vai para o navegador — nada de segredo, TODO interno ou código morto.

---

## Semântica

HTML não tem tipos; o **elemento** é o tipo. Ele diz ao navegador, ao leitor de tela
e ao mecanismo de busca o que o conteúdo é:

- **Elemento semântico em vez de `div`/`span`**: `header`, `nav`, `main`, `section`,
  `article`, `aside`, `footer`. `div` só para agrupar por estilo, sem significado.
- **Ação é `button`, navegação é `a`.** `div` com `onclick` não recebe foco nem
  responde ao teclado.
- Títulos em ordem (`h1` → `h2` → `h3`), sem pular nível para ajustar tamanho —
  tamanho é CSS.
- `type` certo no `input` (`email`, `number`, `date`): validação e teclado de graça.

```html
<!-- ✅ correto -->
<nav>
  <a href="/orders">Orders</a>
</nav>
<button type="submit">Save</button>

<!-- ❌ errado -->
<div class="nav">
  <div onclick="go('/orders')">Orders</div>
</div>
<div class="button" onclick="save()">Save</div>
```

---

## Naming

- Elementos e atributos em minúsculas.
- Valores de `id`, `class` e atributos próprios (`data-*`) em `kebab-case`.
- Nome de arquivo: siga o que o projeto já usa; em projeto novo, `kebab-case.html`.

```html
<section id="order-summary" class="order-card" data-order-id="42">
```

---

## Armadilhas

- **Toda `img` tem `alt`.** Descreve a imagem quando ela informa; `alt=""` quando é
  decorativa — assim o leitor de tela pula. Sem o atributo, ele lê o nome do arquivo.
- **Todo campo de formulário tem `label` associado** (`for` apontando para o `id`).
  `placeholder` não é rótulo: some ao digitar e muitos leitores de tela o ignoram.

```html
<!-- ✅ correto -->
<img src="chart.png" alt="Orders per month, peaking in March">
<label for="email">E-mail</label>
<input id="email" type="email">

<!-- ❌ errado -->
<img src="chart.png">
<input type="email" placeholder="E-mail">
```
