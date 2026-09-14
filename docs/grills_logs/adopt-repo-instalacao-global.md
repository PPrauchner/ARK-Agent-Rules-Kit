# Grill — `adopt-repo` sob a Instalação global

**Início:** 2026-09-13

Objetivo declarado pelo usuário: reavaliar o `adopt-repo` agora que skills e comandos
são instalados no perfil (`~/.claude/`), o que torna desnecessária uma pasta `.claude/`
no repositório adotado. **Premissa fixada de partida:** o comando será invocado a
partir de repositórios **sem** `.claude/`.

A sessão extrapolou o `adopt-repo`: ao resolver onde mora o conhecimento de projeto,
caiu na pergunta de para que ainda serve o Modelo de cópia — e terminou removendo o
`/update-claude` ([ADR 0003](../adr/0003-instalacao-global-como-unico-modelo.md)).

## Diagnóstico inicial (recon, antes da primeira pergunta)

| # | Achado | Onde |
|---|---|---|
| 1 | No modo global **nenhuma rule viaja** a não ser `karpathy-principles.md`, que o instalador importa por `@caminho` no `~/.claude/CLAUDE.md`. `code-conventions.md`, `python-conventions.md` e `work-calibration.md` não entram em contexto nenhum | `install-global.ps1` |
| 2 | O README já decidiu o oposto da premissa do usuário: a seção "O que continua sendo do projeto" lista `rules/*` e `settings.local.json` como criados projeto a projeto, o que pressupõe um `.claude/` no repo-alvo | `README.md:221-234` |
| 3 | O passo 6 manda "invoque a skill `setup-matt-pocock-skills`" e diz que **não é opcional** — mas ela tem `disable-model-invocation: true` e não é invocável pela tool `Skill` | `adopt-repo/SKILL.md` passo 6 |
| 4 | O recon faz `grep "<preencher>" .claude/rules/code-conventions.md` e `ls .claude/rules/` sem prever que a pasta não exista — em repo sem `.claude/` isso vira pergunta ao usuário sobre ausência esperada | `adopt-repo/RECON.md` §1 |
| 5 | Fora do escopo, mas achado: das 23 entradas em `~/.claude/skills`, só 8 são links para o clone. As outras 15 (incluindo `grill-with-docs`, `tdd`, `triage`, `setup-matt-pocock-skills`) são **pastas reais de 07/jul**, puladas pelo instalador com `PULADO:`. A máquina roda cópias velhas | `~/.claude/skills` |

## Perguntas e respostas

**1. Num repo sem `.claude/`, onde mora o conhecimento específico do projeto?**
Recomendado: tudo dentro do `CLAUDE.md`, sem pasta nenhuma.
→ **Resposta:** "o objetivo é o comando criar a pasta `.claude`, ainda viveria em
`rules/`". O `adopt-repo` deixa de assumir a pasta colada e passa a **semeá-la** a
partir do `$ARK_HOME`.

**2. O que entra no `.claude/` que ele cria?**
→ **Só `rules/` + `settings.local.json`.** Nada de `skills/`, `commands/`, `hooks/`,
`scripts/` — esses vêm do perfil, e uma cópia só envelheceria.

**3. Quais arquivos de `rules/`?**
→ **`code-conventions` + `work-calibration` + `<linguagem>-conventions`.** Karpathy
fica de fora: já é importado globalmente, copiar duplicaria o texto no contexto.
(Verificado no recon: o harness carrega `.claude/rules/*.md` sozinho como *project
instructions* — basta o arquivo existir, sem import.)

**4. E quando o repo já tem `.claude/` (Modelo de cópia)?**
→ **Ramifica:** sem `.claude/` semeia; com `.claude/` segue o fluxo de hoje. Um só
comando cobre os dois. *(Revisto na pergunta 8: o ramo legado virou migração.)*

**5. Como o glossário nomeia os dois modelos?**
Conflito levantado pelo agente: `CONTEXT.md` definia **Projeto adotado** como
"repositório que já tem a pasta `.claude/` **copiada**", definição que a nova premissa
contradiz.
→ **Modelo de cópia × Instalação global**, com "Projeto adotado" virando guarda-chuva.
Escrito no `CONTEXT.md` na hora.

**6. Como resolver o passo `docs/agents/` sem conseguir invocar a skill?**
→ **Ler e seguir** `$ARK_HOME/skills/setup-matt-pocock-skills/SKILL.md` dentro da
própria sessão. Não mexe no frontmatter dela nem duplica conteúdo.

**7. Como o repo enxuto se declara, para o `/update-claude` não reencher a pasta?**
O agente levantou o risco: `.claude/` só com `rules/` e sem Marcador dispara a
primeira-execução assimétrica do ADR 0001 e instala o kit inteiro. Recomendado:
`.template.json` com `"modelo": "global"`.
→ **Resposta:** "tô pensando em remover o `update-claude`, pq acredito que vai entrar
em desuso, passar a deixar apenas com a cópia global como padrão".

**8. Removendo o `/update-claude`, o que acontece com SAGA e Peak Plan?**
O agente listou o que cai junto: ADR 0001 inteiro, e os termos Versão vigente,
Marcador de origem e Órfão, que só existem por causa da reconciliação.
→ **O `adopt-repo` ganha o passo de migração.** O ramo "repo com `.claude/`" deixa de
ser "completa o que falta" e passa a **enxugar**.

**9. Na migração, o que apagar de `skills/` e `commands/` do projeto?**
→ **Só o que existe hoje no `$ARK_HOME`**, com confirmação. O que não existe lá fica e
é **listado** — pode ser skill própria do projeto ou resto de layout aposentado, e
distinguir os dois não é trabalho de heurística (princípio do ADR 0001, que sobrevive
ao comando que ele governava).

**10. O genérico do `code-conventions.md` congela em cada projeto?**
Consequência que só apareceu depois da remoção do `/update-claude`: sem ele, nada
atualiza o pedaço genérico copiado.
→ **Partir o arquivo em dois.** O genérico (Idioma, Clean Code) vira arquivo importado
globalmente, junto com o karpathy; o que é do projeto vira
`.claude/rules/project-constraints.md`, criado do zero, sem seção genérica.

**11. E as convenções de linguagem?**
→ **Copiadas no projeto**, aceitando o congelamento: convenção de linguagem quase não
muda, e o arquivo fica legível para quem abrir o repo sem ARK. A alternativa (import)
exigiria caminho absoluto de uma máquina dentro de arquivo versionado — e o agente
registrou que **não verificou** se `@import` funciona dentro de `.claude/rules/`.

## Decisões registradas

- [ADR 0003 — Instalação global como único modelo de reuso](../adr/0003-instalacao-global-como-unico-modelo.md)
- [ADR 0001](../adr/0001-nao-inferir-a-versao-de-origem.md) marcado como **superado**
  pelo 0003, com o princípio preservado na migração.
- `CONTEXT.md`: **Projeto adotado** redefinido; **Modelo de cópia** e **Instalação
  global** criados; **Versão vigente**, **Marcador de origem** e **Órfão** marcados
  como _(histórico)_; **Semente** passou a incluir `work-calibration.md`.

**12. Removendo um comando, qual o bump?**
A régua era odômetro com MAJOR para skill/comando **novo** e PATCH para alteração —
nada cobria remoção, e esta release remove o `/update-claude`.
→ **Remover também é MAJOR.** O MAJOR passa a marcar mudança no conjunto de
capacidades, uma entrando ou saindo. Escrito na `release-policy.md`.

**13. E as 15 skills que na máquina do usuário são pasta real, não link?**
Comparadas uma a uma: **byte-a-byte idênticas** ao clone — não havia versão velha
rodando, só cópias que o instalador pulava e que, por serem pastas, nunca receberiam
melhoria nenhuma.
→ **O instalador passa a trocar por link a pasta real idêntica ao clone**, sem
perguntar (por definição nada se perde), e continua pulando com aviso a que diverge.
Mesmo critério da migração do `adopt-repo`, aplicado ao perfil. O dry-run saiu de
`15 pulado(s)` para `0`.

## Pendências

- O achado nº 5 do diagnóstico virou a pergunta 13 e está resolvido no template. Na
  máquina do usuário ainda é preciso rodar o instalador uma vez para os links
  entrarem — a sessão não pôde fazer isso, porque a política de permissões barra
  escrita destrutiva fora do repositório.
- `work-calibration.md` aponta para `../commands/start-issue/complexity-guide.md` por
  caminho relativo, que não existe num projeto sem `commands/`. Correção mecânica,
  ainda não feita.
- Não foi verificado se `@import` funciona dentro de `.claude/rules/*.md`.
