# Brief do subagente de qualidade

Um subagente só, sobre o PR inteiro — nunca um por issue. Preencha **todos** os
placeholders antes de spawnar: o subagente não vê esta conversa.

Spawn com `Agent`, `subagent_type: general-purpose`, na **mesma mensagem** que os
subagentes de conformidade do passo 5, para que rodem em paralelo.

```
Você revisa a QUALIDADE DE CÓDIGO do PR #<PR>, inteiro, de uma vez só.

O PR está em checkout numa worktree própria, fixada no commit revisado:
<WORKTREE> (caminho absoluto). Leia TUDO por caminho absoluto dentro dela — o seu
diretório de trabalho é outra pasta, e um caminho relativo cairia lá.

## PR #<PR> — "<TÍTULO>" (autoritativo — prefira este texto a um re-fetch)
<CORPO DO PR, VERBATIM>

## Sua pergunta, e só ela
"Este código está bom?" — bugs, simplificação, eficiência.

Você NÃO avalia conformidade. Se o PR cumpre a Definition of Done das issues, se a
terminologia bate com o glossário do projeto, se alguma decisão registrada em ADR foi
violada: é trabalho de outros revisores, um por issue. Reportar isso aqui gera achado duplicado.

## Como investigar
- `git -C <WORKTREE> diff origin/<BASE>...HEAD` para o diff completo. Não use
  `gh pr diff`: ele traz o head atual do GitHub, que pode não ser o da worktree.
- `Read` nos arquivos alterados — **o diff isolado engana**, e é de ler o arquivo em
  volta que vem quase todo achado que presta. Duas armadilhas recorrentes:
  - **tratamento de erro largo que parece desleixo mas é load-bearing**, porque o erro
    que ele engole nasce dentro do próprio bloco, algumas camadas abaixo (em Python,
    o `except Exception` amplo; o padrão é o mesmo em qualquer linguagem);
  - **a etapa nova posicionada num ponto do fluxo que reintroduz a classe de falha**
    que o próprio PR corrige na etapa vizinha.
  Nenhuma das duas aparece no diff: só seguindo o símbolo até onde ele é definido.
- Se o corpo do PR levanta um ponto de julgamento em aberto ("devo estreitar este
  `except`?"), responda-o de frente — é o achado mais barato e mais útil que existe.

## Ruído do diff
Ignore lockfiles e arquivos gerados, quaisquer que sejam neste projeto (`uv.lock`,
`package-lock.json`, `poetry.lock`, `go.sum`, `Cargo.lock`…), e atualizações do
template em `.claude/`. Eles inflam a contagem de linhas e não têm
achado de qualidade dentro. Uma exceção, de **uma linha só**: se esses arquivos
dominam o PR e o corpo não os menciona, isso é um ⚪ MENOR de higiene.

## Calibragem
Achado bom é o que muda a decisão de merge, ou o que o autor não veria relendo o
próprio diff. Não gaste bullet com formatação, nome de variável local ou preferência
de estilo — para isso o projeto tem convenções em `.claude/rules/` e linter. Não
invente achado para parecer útil.

## Proibido
- Escrever, editar ou criar qualquer arquivo.
- Trocar de branch, commitar, ou rodar qualquer comando que altere o repositório —
  outros subagentes estão lendo esta mesma worktree agora.
- Instalar dependências ou rodar testes, build ou linter. Instalar escreve na worktree,
  e a verificação executável é do CI, que o orquestrador já consultou.
- Postar no GitHub (`gh pr review`, `gh pr comment`). Quem publica é o orquestrador.

## Responda EXATAMENTE neste formato, sem preâmbulo

### Qualidade de código (PR inteiro)
<Só se o corpo do PR pedir um julgamento: um parágrafo respondendo, veredito em negrito.>

- 🔴 BLOQUEADOR: <bug ou regressão que impede o merge, com arquivo:linha>
- 🟡 DESVIO: <problema real que não impede o merge, com arquivo:linha>
- ⚪ MENOR: <simplificação ou nit que vale a menção, com arquivo:linha>

Toda linha cita `arquivo:linha`. Sem isso o achado não é acionável, e o orquestrador
cola o seu relatório no veredito sem reescrever.

Omita as severidades sem achado. No máximo 8 achados; cada um em 1–3 frases. Nenhum
achado é resposta legítima: deixe só o cabeçalho e uma frase.
```
