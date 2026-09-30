# Grill — `/review-pr` em PR próprio e convenções por linguagem

Início: 2026-09-30 19:24

Duas mudanças propostas:

1. O `/review-pr` oferece aprovar / solicitar mudanças mesmo quando quem revisa é o
   autor do PR — o GitHub não deixa. Deve detectar isso e oferecer só comentar o
   veredito.
2. Hoje o clone só traz `python-conventions.md`. Adicionar por padrão Java,
   JavaScript, TypeScript, HTML, CSS, C++, C (e sugestões).

## `/review-pr` em PR próprio

Detecção (derivada do código, sem pergunta): o passo 1 já busca `author`; comparar
`author.login` com `gh api user --jq .login`.

**P1:** Com PR próprio e `OPEN`, qual o formato da ação do passo 7 — menu de duas
opções (comentar / nada) ou pergunta direta s/n?
**R:** s/n — "Publico o veredito como comentário no PR?". Melhor para quem revisa
muito PR próprio, desde que não infle o comando.

**P2:** No PR próprio, a linha `**Veredito:** APROVAR / SOLICITAR MUDANÇAS / COMENTAR`
vira comentário do autor dizendo "APROVAR". Manter (a), trocar só no PR próprio (b),
ou trocar para todos por termos de estado do PR (c)?
**R:** (c) — `PRONTO PARA MERGE / PRECISA DE MUDANÇAS / COM RESSALVAS` para todos. O
veredito descreve o PR; a ação é decidida no passo 7. Um vocabulário só.

## Convenções por linguagem

**P3:** `code-conventions.md` (importado em todo projeto) fixa `snake_case` para
variáveis/funções — contradiz Java/JS/TS (`camelCase`). Tirar o naming do genérico
e levar para cada arquivo de linguagem (a), ou manter e deixar a linguagem
sobrescrever (b)?
**R:** (a). Naming de identificador sai do `code-conventions.md` (fica só "nomes
descritivos, sem abreviação opaca") e vai para cada `<linguagem>-conventions.md`;
`python-conventions.md` ganha a seção de naming.

**P4:** Granularidade — um arquivo por linguagem, ou agrupar JS×TS / C×C++ / HTML×CSS?
**R:** Um por linguagem: `java`, `javascript`, `typescript`, `c`, `cpp`, `html`,
`css` — mesmo formato do `python-conventions.md`.

**P5:** Além da lista, acrescentar quais? Sugestão: Shell (Bash) e SQL; C#/Go/Rust/
Kotlin ficam para quando um projeto pedir (a `adopt-repo` já semeia sob demanda);
PowerShell não (um script só no ARK, armadilhas já no `CLAUDE.md` global).
**R:** Aceito — Shell e SQL entram. Total: nove arquivos novos.

**P6:** Profundidade e guia de estilo. Esqueleto do Python (documentação / tipagem /
naming, + armadilhas quando houver erro clássico), 60–90 linhas, conforme tabela
proposta. Nomear guia (Google Java Style etc.) ou não?
**R:** Tabela aceita; **sem nomear guia**. Onde a linguagem não tem consenso (naming
C++, BEM no CSS): "siga o que o projeto já usa; em projeto novo, X".

**P7:** Default "em projeto novo" onde não há consenso: C++ e CSS.
**R:** C++ — `snake_case` para funções/variáveis, `PascalCase` para tipos,
`UPPER_SNAKE` para constantes (perto da stdlib e igual ao C), sem sufixo `_`. CSS —
kebab-case como regra, BEM quando houver componente com variações.

**P8:** Como a `adopt-repo` escolhe o que copiar, com projeto multi-linguagem?
**R:** Copia toda linguagem com código mantido (exclui vendorizado/gerado); pergunta
quando a linguagem é marginal (ex.: 1 script solto), sem limiar numérico fixo;
relatório final lista copiados / perguntados / pulados; linguagem sem arquivo no
clone segue o fluxo atual (escrever no projeto, oferecer semear no `$ARK_HOME`).

## Resultado

- `/review-pr`: detecção de autor (`author.login` × `gh api user`); PR próprio e
  `OPEN` → pergunta s/n para publicar o veredito como comentário; veredito passa a
  `PRONTO PARA MERGE / PRECISA DE MUDANÇAS / COM RESSALVAS` para todos.
- `code-conventions.md`: naming de identificador sai; fica "nomes descritivos".
- `rules/`: nove arquivos novos (`java`, `javascript`, `typescript`, `c`, `cpp`,
  `html`, `css`, `shell`, `sql`) + seção de naming no `python-conventions.md`.
- `adopt-repo` passo 7: cópia multi-linguagem com pergunta para o marginal.
- Sem ADR: nenhuma das decisões é difícil de reverter. Sem termo novo no glossário.
- Release: alterações de skill/comando existente → PATCH (rules entram na release da
  `adopt-repo`).

## Issues

Publicadas via `/to-issues`: #1 (veredito como estado), #4 (PR próprio, bloqueada
por #1), #2 (naming sai do genérico), #5–#9 (Java; JS+TS; C+C++; HTML+CSS;
Shell+SQL — bloqueadas por #2), #3 (`adopt-repo` multi-linguagem).

## Retomada — regra do veredito (lacuna da #1)

2026-09-30. A #1 trocou os rótulos, mas o comando só dizia "qualquer BLOQUEADOR →
PRECISA DE MUDANÇAS"; faltava quando é PRONTO PARA MERGE × COM RESSALVAS.

**P9:** Sem BLOQUEADOR, o que separa PRONTO PARA MERGE de COM RESSALVAS?
**R:** O pior achado decide. DESVIO → COM RESSALVAS; só MENOR ou nada → PRONTO PARA
MERGE. MENOR não pesa — senão quase nenhum PR ficaria pronto.

**P10:** E o CI que não é verde nem vermelho?
**R:** Pendente limita a COM RESSALVAS (não afirmar o que o portão ainda não
confirmou). Sem CI não pesa — o veredito já registra, e rebaixaria para sempre todo
PR de repo sem CI.

**P11:** DoD inferida do PR (sem issue) pesa?
**R:** Não. Já está registrada no veredito; falta de issue, se for problema no repo,
entra como DESVIO e conta pela P9.

Sem ADR, sem termo novo no glossário. Aplicado no passo 6 do `/review-pr`.
