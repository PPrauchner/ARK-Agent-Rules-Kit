# Checklist de recon

O que ler antes de perguntar qualquer coisa. Objetivo: chegar ao grill sabendo tudo
que o repositório já responde sozinho.

## 0. Qual ramo

A primeira pergunta é do disco, não do usuário:

```bash
echo "$ARK_HOME"          # vazio = sem Instalação global: pare e aponte o README
ls -d .claude 2>/dev/null
ls .claude/skills .claude/commands 2>/dev/null
```

| O que você vê | Ramo |
|---|---|
| nenhuma `.claude/` | **Adoção** — o caso normal, e o padrão desta skill |
| `.claude/` com `skills/` ou `commands/` dentro | **Migração** — cópia antiga do kit inteiro |
| `.claude/` só com `rules/` | já é o estado final — complete o que falta e siga |

**Ausência de `.claude/` não é problema a investigar.** No modelo de Instalação global
o repositório não tem por que ter essa pasta antes da adoção; é a skill que a cria. Não
gaste pergunta com isso.

## 1. O que já existe dos sete artefatos

```bash
ls CLAUDE.md AGENTS.md CONTEXT.md CONTEXT-MAP.md 2>/dev/null
ls docs/adr/ docs/agents/ 2>/dev/null
ls .claude/rules/ .claude/settings.local.json 2>/dev/null
grep -rn "<preencher>" .claude/rules/ 2>/dev/null
```

Um `CONTEXT.md` de 0 byte conta como **inexistente** — é stub, não conteúdo. O mesmo
vale para uma seção que ainda está em `<preencher>`.

No ramo de migração, some a isto a comparação que decide o que apagar:

```bash
ls "$ARK_HOME/skills" "$ARK_HOME/commands"     # o que vem do perfil
ls .claude/skills .claude/commands             # o que o projeto copiou
```

Nome presente nos dois = redundante. Nome só no projeto = **pergunta**, nunca
exclusão automática.

## 2. Stack e comandos

Leia o manifesto, não adivinhe pela extensão dos arquivos:

| Sinal no repo | Stack | Onde estão os comandos |
|---|---|---|
| `package.json` | Node/TS | campo `scripts` |
| `pnpm-lock.yaml` · `package-lock.json` · `yarn.lock` | qual gerenciador **de fato** | — |
| `pyproject.toml` · `requirements.txt` | Python | `[project.scripts]`, `[tool.*]` |
| `Cargo.toml` | Rust | `cargo build/test` |
| `go.mod` | Go | `go build ./...` |
| `docker-compose.yml` | ambiente | serviços = topologia real |
| `Makefile` · `Taskfile.yml` | qualquer | alvos = comandos canônicos |
| `.github/workflows/` | CI | **a fonte mais confiável de build/test/lint** |

O lockfile decide o gerenciador de pacotes — `package.json` não diz se é npm ou pnpm.
Quando houver mais de um lockfile, isso é uma contradição para o grill, não para você
resolver.

A linguagem detectada aqui decide qual `<linguagem>-conventions.md` é copiado do
`$ARK_HOME` no passo 7 da skill.

## 3. Domínio (matéria-prima do grill, não conclusão)

- Nomes de módulos/pastas de primeiro nível — costumam ser os conceitos centrais.
- Modelos/entidades: classes de ORM, schemas, `models/`, `entities/`, `types/`,
  migrations.
- Termos que aparecem no README em pt-BR e no código em inglês — são exatamente as
  pontes que o `CONTEXT.md` precisa registrar.

Anote os candidatos a conceito. **Não escreva glossário a partir daqui** — o código
mostra o identificador, não o termo que o usuário usa nem a fronteira entre conceitos.

## 4. Histórico

```bash
git log --oneline -30
git log --format='%an' | sort | uniq -c | sort -rn | head
ls docs/ 2>/dev/null
```

Convenção de commit em uso (o `/commit` deve segui-la, não impor a dele), se o projeto
é solo ou de time, e documentação já existente que não deve ser duplicada.

## 5. O que o recon **não** decide

Leve para o grill, sempre:

- Qual termo de domínio corresponde a cada identificador, e a fronteira entre conceitos
  parecidos.
- Por que uma dependência ou formato foi escolhido — e se é decisão ou acaso.
- O que não pode mudar no projeto.
- Qualquer contradição entre documentação existente e código.
- No ramo de migração: o que fazer com cada pasta da lista "Do projeto".
