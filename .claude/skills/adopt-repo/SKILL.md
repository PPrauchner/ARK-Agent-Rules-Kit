---
name: adopt-repo
description: Adota um repositório no ARK — cria o .claude/ enxuto que a Instalação global espera (rules do projeto e settings.local.json), preenche CLAUDE.md, CONTEXT.md e docs/agents, e migra projetos que ainda carregam a cópia antiga do kit inteiro. Deriva do código o que o código sabe responder e grelha o resto. Use when adopting an existing repository into the ARK, when CLAUDE.md/CONTEXT.md are missing or empty, or when a repo still has the whole .claude/ kit copied inside it.
---

# Adopt Repo

O ARK vive no perfil do usuário: skills, comandos e hooks são links para o clone
(`$ARK_HOME`) e valem em qualquer diretório. O que **não** pode morar no perfil é o
que descreve um repositório — e é isso que esta skill cria.

**Princípio central:** o repositório responde sozinho a stack, comandos e estrutura —
derive isso e apenas confirme. O grill é gasto onde o código é mudo: o código mostra
`class Chapter`, mas não diz se você chama aquilo de "capítulo" ou "episódio", nem por
que aquela decisão foi tomada.

## Regras invioláveis

1. **Nunca sobrescreva.** O que já existe é verdade; acrescente apenas o que falta.
   Rodar duas vezes não pode duplicar seção nem reescrever texto do usuário.
2. **Contradição vai para o grill, não para o seu palpite.** Se o `CLAUDE.md` diz
   `pnpm` e o repo tem `package-lock.json`, pergunte qual vale — não escolha.
3. **Nada de escrever antes de confirmar.** Cada artefato é apresentado antes de ir
   para o disco. Na migração isso vale em dobro: nenhum arquivo é apagado sem a lista
   aparecer primeiro.

## Pré-requisito: `$ARK_HOME`

A skill copia arquivos do clone do ARK. Sem ele, não há de onde copiar:

```bash
echo "$ARK_HOME"
```

Vazio significa que a [Instalação global](../../../README.md#instalação-global) nunca
foi feita nesta máquina. **Não adivinhe o caminho** e não prossiga: aponte o README e
pare — a mesma decisão que o `/sync-global` já toma.

## Os dois ramos

O primeiro passo do recon é olhar se existe `.claude/` no repositório. A resposta
decide o que a skill faz:

| Ramo | Gatilho | O que faz |
|---|---|---|
| **Adoção** | sem `.claude/` — o caso normal | cria a pasta enxuta e segue para os artefatos |
| **Migração** | com `.claude/` do Modelo de cópia (tem `skills/` ou `commands/` dentro) | **enxuga** primeiro, depois segue igual |

Não existe terceiro caso: `.claude/` só com `rules/` já é o estado final, e a skill
segue direto para os artefatos, completando o que falta.

## Os artefatos

| # | Artefato | Origem |
|---|----------|--------|
| 1 | `CLAUDE.md` | derivado do recon + 1 rodada de conferência |
| 2 | `CONTEXT.md` | grill (glossário de domínio) |
| 3 | `.claude/rules/project-constraints.md` | grill |
| 4 | `.claude/rules/work-calibration.md` | grill |
| 5 | `.claude/rules/<linguagem>-conventions.md` | copiado do `$ARK_HOME` + confirmação |
| 6 | `docs/agents/*` | seguindo a `setup-matt-pocock-skills` |
| 7 | `.claude/settings.local.json` | derivado do `settings.local.json.example` |

`code-conventions.md` e `karpathy-principles.md` **não** entram na lista: são
genéricos, e o instalador global já os importa no `~/.claude/CLAUDE.md` direto do
clone. Copiá-los para o projeto congelaria uma fotografia que nada atualiza.

## Workflow

### 1. Recon

Levante o estado atual antes de perguntar qualquer coisa. Use o
[checklist de recon](./RECON.md) — ele diz o que ler por tipo de stack e o que cada
sinal significa.

Ao final você deve saber: qual ramo, linguagem(ns) e versão, gerenciador de pacotes,
comandos de dev/build/test/lint, estrutura de pastas, e **o que já existe** dos sete
artefatos.

### 2. Apresentar o mapa da adoção

Mostre em uma tabela o que encontrou e o que falta — o usuário precisa ver o tamanho
do trabalho antes de entrar num grill. Confirme a stack detectada; se você errar aqui,
tudo depois herda o erro. No ramo de migração, a tabela vem junto com as listas do
passo 3.

### 3. Migração — só no ramo legado

O projeto carrega uma cópia do kit inteiro, feita quando o ARK ainda era distribuído
por cópia. Essa cópia agora **sombreia** o que vem do perfil: skill de mesmo nome
dentro do projeto ganha da global, e é a versão velha que roda.

Separe em três listas e mostre as três antes de apagar qualquer coisa:

| Lista | Critério | Ação |
|---|---|---|
| **Redundante** | pasta em `.claude/skills/`, `commands/`, `hooks/`, `scripts/` cujo nome existe **hoje** no `$ARK_HOME` | apagar, após confirmação |
| **Do projeto** | pasta nos mesmos lugares cujo nome **não** existe no `$ARK_HOME` | **não apagar** — listar e perguntar |
| **Preservado** | `rules/`, `settings.local.json`, `current-issue`, `board.env`, `.gitignore` | não tocar |

A lista "Do projeto" é ambígua por natureza: pode ser skill escrita naquele repositório
ou resto de um layout que o ARK aposentou. Distinguir os dois não é trabalho de
heurística — é pergunta
([ADR 0001](../../../docs/adr/0001-nao-inferir-a-versao-de-origem.md)).

Depois de enxugar: se havia `.claude/rules/code-conventions.md` com a seção
"Restrições deste projeto" **preenchida**, mova esse conteúdo para
`project-constraints.md` e só então apague o arquivo antigo — o genérico dele agora vem
do clone. Seção ainda em `<preencher>` não é conteúdo: pode ir junto com o arquivo.

Remova também `.claude/.template.json`: o Marcador de origem existia para o
`/update-claude`, que não existe mais
([ADR 0003](../../../docs/adr/0003-instalacao-global-como-unico-modelo.md)).

### 4. Semear o `.claude/`

Crie o que faltar, copiando do `$ARK_HOME`:

```bash
mkdir -p .claude/rules
cp -n "$ARK_HOME/rules/project-constraints.md" .claude/rules/
cp -n "$ARK_HOME/rules/work-calibration.md"    .claude/rules/
cp -n "$ARK_HOME/.gitignore"                   .claude/
```

O `.gitignore` viaja junto porque é ele que mantém `settings.local.json` fora do git.
Sem ele, o primeiro `/commit` versiona caminhos da sua máquina.

O `-n` é a regra 1 em forma de flag: arquivo que já existe não é copiado por cima.

### 5. `CLAUDE.md` — derivar e conferir

Monte o rascunho a partir do recon: o que o projeto é, stack, comandos, estrutura de
pastas e apontadores para `CONTEXT.md` e `docs/adr/`. **Uma rodada** de conferência —
não vire isso em entrevista, o repo já respondeu.

Se `CLAUDE.md` já existir: leia, trate como verdade, e proponha **apenas** as seções
ausentes. Liste as contradições encontradas em vez de resolvê-las sozinho.

### 6. `CONTEXT.md` e restrições — grelhar

Aqui sim, invoque a skill **`grill-with-docs`**. Ela já entrevista uma pergunta por
vez, desafia termos contra o glossário e escreve o `CONTEXT.md` incrementalmente no
formato certo — não reimplemente isso.

Foque o grill no que o código não entrega:

- **Glossário:** para cada conceito central que o recon encontrou, qual é o termo de
  domínio em pt-BR e qual identificador em inglês o representa. Fronteiras entre
  conceitos parecidos (`User` × `Customer`, `Chapter` × `Episode`).
- **Restrições deste projeto:** o que **não** pode mudar — dependência que é decisão e
  não acaso, formato de persistência, exigência de reprodutibilidade, limite de
  ambiente. Escreva o resultado em `.claude/rules/project-constraints.md`,
  substituindo o `<preencher>`.
- **Calibragem de trabalho:** o recon já mostrou a estrutura de pastas — pergunte
  quantos módulos distintos costumam entrar numa mudança antes de ela virar grande
  demais, e quais pastas o projeto trata como camadas. Escreva o resultado nas duas
  seções de `.claude/rules/work-calibration.md`, substituindo os `<preencher>`.
  Deixar vazio é resposta legítima: significa que valem os defaults genéricos.
- **ADRs retroativos:** só ofereça quando a decisão for difícil de reverter,
  surpreendente sem contexto e fruto de trade-off real — os três critérios da
  `grill-with-docs`. Não documente retroativamente o que foi acaso.

### 7. Convenções da linguagem

O clone traz apenas `python-conventions.md`. Copie para `.claude/rules/` **só** o
arquivo da linguagem que o projeto usa:

```bash
cp -n "$ARK_HOME/rules/python-conventions.md" .claude/rules/
```

Se o projeto não for Python, escreva `.claude/rules/<linguagem>-conventions.md` no
mesmo espírito (documentação, tipagem, naming) — direto no projeto; ofereça semeá-lo
também no `$ARK_HOME` se for servir a outros repositórios.

Este arquivo é copiado, e não importado, de propósito: **qual** linguagem se aplica é
conhecimento do projeto, e um import exigiria o caminho absoluto da sua máquina dentro
de arquivo versionado. O preço é o conteúdo congelar — aceitável, porque convenção de
linguagem quase não muda.

### 8. `docs/agents/` — seguir a `setup-matt-pocock-skills`

Leia `$ARK_HOME/skills/setup-matt-pocock-skills/SKILL.md` e **execute aquelas
instruções nesta sessão**. Ela tem `disable-model-invocation: true` no frontmatter,
ou seja, não é invocável pela tool `Skill` — por isso seguir, e não invocar. Não
reescreva o que ela faz.

Este passo não é opcional: sem `docs/agents/issue-tracker.md` o `/afk-queue` se recusa
a rodar.

### 9. `settings.local.json`

Copie `$ARK_HOME/settings.local.json.example` para `.claude/settings.local.json` e
substitua o caminho placeholder pelo caminho real do repositório. Se o arquivo já
existir, não toque nele.

### 10. Relatório final

Uma tabela com os sete artefatos: criado / completado / já existia / pulado (e por
quê). No ramo de migração, some a contagem do que foi apagado e **repita** a lista "Do
projeto" que ficou de pé, que é decisão pendente.

Termine dizendo o que ficou pendente de decisão humana — restrição que o usuário não
soube responder na hora vale mais explícita como pendência do que preenchida com um
chute.
