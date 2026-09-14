# Instalação global como único modelo de reuso

Até a `v4.1.0` o ARK tinha dois modelos de reuso: o **Modelo de cópia** (a pasta
`.claude/` inteira colada dentro do Projeto adotado, atualizada pelo
`/update-claude`) e a **Instalação global** (skills, comandos e hooks ligados ao
perfil do usuário, atualizados pelo `/sync-global`). **Decidimos ficar só com a
Instalação global:** o `/update-claude` sai, e o `adopt-repo` passa a criar — e, em
projeto legado, a enxugar — um `.claude/` que contém apenas o que descreve aquele
repositório: `rules/` e `settings.local.json`.

## Por quê

Os dois modelos resolvem o mesmo problema, mas só um deles paga o custo de existir.
No Modelo de cópia, cada Projeto adotado carrega uma fotografia do kit que envelhece
sozinha, e reconciliar essa fotografia com a Versão vigente é um problema difícil o
bastante para ter gerado o [ADR 0001](./0001-nao-inferir-a-versao-de-origem.md): sem
Marcador de origem não dá para distinguir "o Template mudou isto" de "o projeto
customizou isto", e a heurística óbvia para descobrir erra com aparência de prova.

A Instalação global dissolve o problema em vez de resolvê-lo. Os links apontam para
o clone, então `git pull` já atualiza tudo: skill alterada vale na próxima sessão,
sem comando nenhum. Só skill nova, renomeada ou removida precisa de `/sync-global`,
e aí a operação é refazer link — não reconciliar conteúdo. Não existe versão do kit
"dentro" do projeto para divergir da Versão vigente, porque não existe kit dentro do
projeto.

O que sobra no repositório é o que **não** pode morar no perfil do usuário, porque
descreve um repositório e não uma pessoa: as restrições daquele projeto, a
calibragem de trabalho daquele projeto, as convenções da linguagem daquele projeto e
as permissões com os caminhos daquela máquina.

## Consequências

- O `/update-claude` é removido. O `adopt-repo` absorve o caminho de saída: num repo
  com `.claude/` do Modelo de cópia, ele **enxuga** — apaga de `skills/`, `commands/`,
  `hooks/` e `scripts/` apenas as pastas cujo nome existe hoje no `$ARK_HOME` (essas
  vêm do perfil, a cópia é redundante), preserva `rules/` e `settings.local.json`, e
  **lista** o que não existe no ARK sem apagar — pode ser skill própria do projeto ou
  resto de layout aposentado, e distinguir os dois não é trabalho de heurística.
- O [ADR 0001](./0001-nao-inferir-a-versao-de-origem.md) fica **superado**: a decisão
  continua correta, mas o comando que ela governava deixa de existir. O princípio
  sobrevive na migração — nada é apagado por inferência sobre ausência de arquivo.
- **Versão vigente**, **Marcador de origem** e **Órfão** perdem função operacional:
  eram o vocabulário da reconciliação. Ficam no glossário como história da linhagem,
  não como conceitos vivos.
- O ARK passa a exigir instalação global para funcionar. Sem `$ARK_HOME`, o
  `adopt-repo` não tem de onde copiar as rules e para, apontando o README — o mesmo
  que o `/sync-global` já fazia.
- Quem clonar um Projeto adotado numa máquina sem ARK instalado vê o `CLAUDE.md`, o
  `CONTEXT.md` e as rules, mas nenhuma skill. O repositório não é mais
  auto-suficiente, e isso é deliberado.
