# ARK — Agent Rules Kit

Template reutilizável da pasta `.claude/` — convenções, skills e comandos
compartilhados entre projetos, para não reconstruir tudo do zero a cada
repositório novo. A arca que carrega o mesmo processo de repositório em
repositório.

## Modelo de reuso

**Cópia com atualização sob demanda.** Cada projeto copia esta pasta `.claude/`
uma vez e diverge livremente dali. Nada se propaga sozinho: quando quiser trazer
uma versão nova, rode `/update-claude` dentro do projeto — ele aplica o que mudou
aqui e preserva o que o projeto customizou (ver
[Como atualizar](#como-atualizar-um-projeto-que-já-copiou)).

## O que tem aqui

- **`.claude/rules/`** — convenções de base, carregadas em toda sessão:
  - `karpathy-principles.md` — princípios de comportamento (simplicidade,
    mudanças cirúrgicas, execução orientada a metas).
  - `code-conventions.md` — convenções gerais (idioma, clean code) + a seção
    **"Restrições deste projeto"**, que cada projeto preenche do zero (idealmente
    na sessão da skill `grill-with-docs`).
  - `python-conventions.md` — docstrings e type hints, só relevante para
    projetos Python. Para outras stacks, criar `<linguagem>-conventions.md`
    equivalente.
  - `work-calibration.md` — como **este** projeto divide trabalho: limiares de
    quebra de issue e o que conta como camada num commit. Também preenchido do
    zero por cada projeto; lido pelo `/start-issue` e pelo `/commit`.
- **`.claude/skills/`** — skills reutilizáveis, de `tdd` e `diagnose` a `grill-me`
  e `handoff` — lista completa em [`skills/README.md`](.claude/skills/README.md).
- **`.claude/commands/`** — comandos de workflow encadeados num pipeline:
  `/start-issue` → `/tdd` → `/commit` → `/open-pr` → `/review-pr`, com `/afk-queue`
  orquestrando o trecho `start-issue → commit` para uma fila inteira de issues.
  Começando de um tronco (`main`, `dev`, …), a entrada do pipeline cria a branch de
  trabalho sozinha — ver o toggle [`AUTO_BRANCH`](#toggles).
  Fora do pipeline, `/update-claude` e `/sync-global`. Detalhes em
  [`commands/README.md`](.claude/commands/README.md).
- **`.claude/hooks/`** — o que roda sozinho em eventos da sessão (lembrete de commit
  ao encerrar, log das sessões de grill) — ver
  [`hooks/README.md`](.claude/hooks/README.md).
- **`.claude/scripts/`** — utilitários chamados pelos comandos ou na mão (sync do
  board, criação da branch de trabalho, symlinks das skills) — ver
  [`scripts/README.md`](.claude/scripts/README.md).
- **`.claude/settings.json`** — settings versionadas: registro dos hooks e os
  [toggles](#toggles). `settings.local.json.example` é o template do
  `settings.local.json` de cada máquina/projeto, que nunca é commitado.

## Pré-requisitos

- **[`gh`](https://cli.github.com/) autenticado** (`gh auth login`) — o pipeline de
  PR depende dele: `/open-pr`, `/review-pr` e a movimentação de board. As skills de
  issue (`/start-issue`, `/afk-queue`, `triage`, `to-issues`, `to-prd`) leem o tracker
  de `docs/agents/issue-tracker.md` e funcionam também com GitLab (`glab`) ou markdown
  local; sem esse arquivo, assumem GitHub.
- **bash** — hooks e scripts são `.sh`. No Windows, o Git Bash que vem com o Git
  resolve. Atenção ao fim de linha: `.sh` gravado com CRLF não roda (`\r: command
  not found`).
- **Board do GitHub Projects (v2)** — *opcional*. Sem ele o `board-move.sh` só avisa
  no stderr e segue; nada no pipeline quebra.

## Como usar num projeto novo

1. Copie a pasta `.claude/` inteira para a raiz do projeto.
2. Copie `.claude/settings.local.json.example` para `.claude/settings.local.json`
   e ajuste paths/permissões para aquele projeto.
3. Preencha "Restrições deste projeto" em `.claude/rules/code-conventions.md`.
4. Mantenha `python-conventions.md` se o projeto for Python; senão, crie o
   módulo de linguagem equivalente e remova o que não se aplica.
5. Revise os [toggles](#toggles) — eles chegam **ligados**.

## Como usar num projeto que já existe

Rode a skill **`adopt-repo`**. Ela faz recon do repositório, deriva o `CLAUDE.md` do
que o código já responde (stack, comandos, estrutura) e usa uma sessão de
`grill-with-docs` para o que o código não sabe dizer — o glossário de domínio do
`CONTEXT.md` e as restrições do projeto. Nunca sobrescreve o que já existe: completa
apenas o que falta e leva contradições para o grill.

## Como atualizar um projeto que já copiou

Rode o comando **`/update-claude`** dentro do projeto, sem argumentos. Ele traz o
`.claude/` para a versão vigente (a tag mais recente daqui) e preserva o que é do
projeto:

- **sobrescreve** skills, comandos, hooks, scripts e o `karpathy-principles.md`;
- **não toca** no `rules/code-conventions.md` — é ali que mora o modelo de domínio
  que o projeto escreveu;
- **acrescenta ao** `settings.json` só as chaves que faltam, mantendo os hooks
  próprios do projeto (sem isso os hooks novos nunca rodam — hook só existe se
  estiver registrado ali; os toggles, esses, já valem `on` quando a chave falta);
- pergunta **uma vez**, numa lista pré-marcada com o motivo de cada sugestão, sobre
  arquivos do projeto que sumiram da versão nova;
- grava `.claude/.template.json` com a versão aplicada, para o próximo update saber
  de onde partiu.

Se o repositório versiona o `.claude/`, ele fecha com um commit atômico só desses
caminhos — nunca faz push.

Num repositório que ainda não tem template instalado, `/update-claude` oferece o
`adopt-repo` como passo opcional antes de instalar.

## Toggles

Comportamentos que chegam **ligados** ao copiar a pasta. Desligam-se com `off`
(ou `0`/`false`/`no`) no bloco `env` de `.claude/settings.json`:

| Chave | Efeito quando `off` |
|-------|---------------------|
| `BOARD_SYNC` | Issues não são movidas no board por `/start-issue` e `/open-pr`. |
| `PR_REVIEW_PARALLEL` | `/review-pr` avalia a conformidade de todas as issues inline, sem subagentes. |
| `GRILL_LOG` | Sessões de grill não são registradas em `docs/grills_logs/`. |
| `AUTO_BRANCH` | `/start-issue` e `/afk-queue` não criam branch: implementam na branch em checkout, mesmo que seja o tronco. |

Além deles, a [instalação global](#instalação-global-sem-copiar-claude-por-projeto)
grava `ARK_HOME` no mesmo bloco — o caminho absoluto desta pasta `.claude/`, usado
pelos comandos para achar `scripts/` de dentro de qualquer projeto.

## Arquivos gerados

Aparecem dentro de `.claude/` conforme você usa o template — nenhum precisa ser
criado à mão:

| Arquivo | Quem cria | Versionar? |
|---------|-----------|------------|
| `settings.local.json` | você, a partir do `.example` | **não** — tem caminhos da sua máquina |
| `current-issue` | `/start-issue` | **não** — estado da sessão |
| `board.env` | `board-move.sh` (cache dos IDs do board) | **não** — específico do repositório |
| `.template.json` | já vem na cópia (tag da release); `/update-claude` reescreve | **sim** — sem ele o próximo update não sabe de onde partiu |

Os três primeiros já estão em `.claude/.gitignore`, que viaja junto na cópia.

## Versões

Cada versão é uma tag anotada com uma [Release](https://github.com/PPrauchner/ARK-Agent-Rules-Kit/releases)
descrevendo o que mudou e por quê. A numeração é um **odômetro, não semver**:

- **MAJOR** — skill ou comando novo (capacidade nova).
- **PATCH** — alteração de skill ou comando existente.
- **MINOR** — só transbordo do PATCH quando ele passaria de 9.

Não há breaking change a sinalizar: quem consome é o `/update-claude`, e ele preserva
o que o projeto customizou independentemente do número. Para saber qual versão um
projeto carrega, veja o `.claude/.template.json` dele.

## Instalação global (sem copiar `.claude/` por projeto)

Alternativa ao [modelo de cópia](#modelo-de-reuso): em vez de colar a pasta em cada
repositório, o kit inteiro fica ligado ao seu perfil de usuário e vale em qualquer
diretório — inclusive fora de repositório Git.

### Passo a passo

**1. Clone onde ele vai morar.** Os links apontam para este caminho, então escolha um
lugar definitivo (mover o clone depois quebra tudo e pede uma reinstalação):

```bash
git clone https://github.com/PPrauchner/ARK-Agent-Rules-Kit.git ~/ark
cd ~/ark
```

**2. Rode o instalador da sua plataforma:**

```bash
bash .claude/scripts/install-global.sh              # Linux/macOS
```
```powershell
powershell -File .\.claude\scripts\install-global.ps1   # Windows
```

Os dois aceitam `--dry-run`/`-DryRun` (mostra sem escrever) e
`--uninstall`/`-Uninstall` (desfaz tudo, sem tocar no clone). São idempotentes: rodar
duas vezes não duplica nada.

**3. Reinicie o `claude`** e confira com `/help` — devem aparecer `/tdd`, `/commit`,
`/start-issue`, `/grill-me` e companhia, em qualquer diretório.

> **Pré-requisitos além dos [gerais](#pré-requisitos):** `python3` no Linux/macOS
> (para mesclar o `settings.json` sem apagar o que já está lá) e PowerShell 5.1+ no
> Windows — o que já vem com o sistema serve, e o executável dele é `powershell`;
> `pwsh` só existe se você tiver instalado o PowerShell 7 à parte. Lá o script tenta *symlink* e cai para *junction* se o Modo Desenvolvedor
> estiver desligado — junction não exige administrador, então **não é preciso abrir o
> terminal como admin**.

### O que o instalador faz

1. **Skills e comandos** viram links em `~/.claude/skills/`. Os dois vão para o
   mesmo lugar de propósito: `~/.claude/commands/` só registra arquivos `.md`
   soltos, e os comandos daqui são pastas com `SKILL.md`. Como skill pessoal
   continuam sendo chamados por `/commit`, `/start-issue`, `/review-pr`, …
2. **Hooks** são registrados em `~/.claude/settings.json` com caminho absoluto.
3. **`ARK_HOME`** e os [toggles](#toggles) vão para o bloco `env` global.
4. **`karpathy-principles.md`** é importado por `@caminho` no `~/.claude/CLAUDE.md`
   — no Windows um import evita o symlink de arquivo, que exige privilégio.

Nenhum arquivo é copiado, e nada é apagado sem aviso: pasta real de mesmo nome em
`~/.claude/skills` é pulada, e só links que apontam para dentro do clone são
removidos — skill sua de outra origem fica intacta.

### Como atualizar

Rode **`/sync-global`** de qualquer lugar. Ele puxa o clone e refaz os links, trazendo
skill nova e podando a que foi renomeada ou removida. O equivalente na mão é
`git pull` no clone + o instalador de novo.

Na maior parte das vezes nem isso é necessário — os links apontam para os arquivos do
clone, então alteração em skill existente já vale sozinha:

| Você… | Precisa de `/sync-global`? |
|-------|----------------------------|
| edita uma skill existente | **não** — o link aponta para o arquivo, vale na próxima sessão |
| dá `git pull` com skills alteradas | **não**, mesmo motivo |
| adiciona skill ou comando novo | **sim** — falta o link |
| renomeia ou remove uma skill | **sim** — sobra link órfão |

O `/update-claude` **não** faz esse trabalho e nem deve: por decisão dele, nunca
escreve fora do repositório. Os dois são pares de modelos diferentes — `/update-claude`
atualiza o `.claude/` de um projeto que copiou, `/sync-global` atualiza os links no
perfil do usuário.

### O que continua sendo do projeto

A instalação global cobre o que é genérico. O que descreve **um** repositório não
pode morar no perfil do usuário, e continua sendo criado projeto a projeto — pela
skill `adopt-repo` ou pela `setup-matt-pocock-skills`:

| Artefato | Por quê |
|----------|---------|
| `CLAUDE.md`, `CONTEXT.md` | stack, comandos, glossário de domínio |
| `docs/agents/` (`issue-tracker.md`, `domain.md`, `triage-labels.md`) | onde ficam as issues deste repo e com que vocabulário |
| `rules/code-conventions.md` → "Restrições deste projeto" | preenchido do zero por projeto |
| `rules/work-calibration.md` | limiar de quebra de issue **deste** projeto |
| `rules/<linguagem>-conventions.md` | depende da stack |
| `.claude/settings.local.json` | permissões com caminhos da máquina |
| `.claude/current-issue`, `.claude/board.env` | estado de sessão / cache do board |

Os scripts chamados pelos comandos resolvem por `${ARK_HOME:-.claude}`: com a
instalação global apontam para o clone; numa cópia local antiga, para o `.claude/`
do projeto. Os dois modelos convivem.

## Manutenção deste repositório

O template usa as próprias skills em si mesmo, e a documentação da raiz **não** é
copiada para os projetos:

- [`CONTEXT.md`](./CONTEXT.md) — glossário do domínio deste repositório, que é a
  própria distribuição (Template, Projeto adotado, Versão vigente, Semente, Órfão).
- [`docs/adr/`](./docs/adr/) — decisões de arquitetura e seus porquês.
- [`docs/grills_logs/`](./docs/grills_logs/) — as sessões de grill que geraram essas
  decisões, pergunta a pergunta.
- [`docs/release-policy.md`](./docs/release-policy.md) — régua de bump, unidade de
  release e o procedimento de corte.

Um hook local (`scripts/readme-drift.sh`, não versionado, registrado no
`settings.local.json`) barra o `git tag -a` enquanto houver skill, comando, script,
hook, rule, toggle ou artefato gerado sem linha no README correspondente.

## Créditos

Boa parte das skills em `.claude/skills/` vem de
[**mattpocock/skills**](https://github.com/mattpocock/skills), de Matt Pocock,
publicado sob MIT. A rule `karpathy-principles.md` é uma tradução do `CLAUDE.md`
de [**multica-ai/andrej-karpathy-skills**](https://github.com/multica-ai/andrej-karpathy-skills).
Os comandos de workflow, as demais rules, os hooks, os scripts e a skill
`adopt-repo` foram escritos aqui.

A fronteira exata entre um e outro está em [`NOTICE.md`](./NOTICE.md).

## Licença

[MIT](./LICENSE) — copie, modifique e redistribua à vontade, mantendo o aviso de
copyright.
