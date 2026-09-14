# Convenções de Código

> Genérico do ARK, igual em todo projeto. Importado a partir do clone pela
> [Instalação global](../../README.md#instalação-global), então melhoria feita aqui
> vale em toda sessão sem reinstalar nada.
>
> O que é **deste** projeto não mora aqui: restrições em
> [`project-constraints.md`](./project-constraints.md), calibragem de trabalho em
> [`work-calibration.md`](./work-calibration.md), modelo de domínio em `CONTEXT.md`,
> decisões e porquês em `docs/adr/`.

---

## Idioma

- **Código** (módulos, identificadores, docstrings) em **inglês**.
- **Documentação** (ADRs, `CONTEXT.md`, README, log) em **português**.
- O glossário em `CONTEXT.md` faz a ponte entre o termo de domínio (pt-BR) e o
  identificador no código (inglês).

---

## Convenções por linguagem

As regras específicas de cada linguagem vivem em arquivos separados, para não
assumir uma stack que o projeto não usa. Ao contrário deste arquivo, elas são
**copiadas** para `.claude/rules/` do projeto pela skill `adopt-repo` — só a da
linguagem que o projeto de fato usa:

- **Python** → `python-conventions.md`
- Outras linguagens: a `adopt-repo` cria `<linguagem>-conventions.md` no mesmo
  espírito (documentação, tipagem, naming).

---

## Clean Code

- Funções com responsabilidade única — se o nome precisar de "e"/"ou", dividir.
- Nomes descritivos: sem abreviações opacas (`nd` → `node`, `sz` → `size`).
- Constantes em `UPPER_SNAKE_CASE`; variáveis e funções em `snake_case`; classes em
  `PascalCase`.
- Comentários explicam *por quê*, não *o quê*.
- Ver também [`karpathy-principles.md`](./karpathy-principles.md) (simplicidade
  primeiro, mudanças cirúrgicas, execução orientada a metas).
