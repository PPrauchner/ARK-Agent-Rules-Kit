# Não inferir a versão de origem de um Projeto adotado

> **Superado pelo [ADR 0003](./0003-instalacao-global-como-unico-modelo.md).** O
> `/update-claude`, que esta decisão governava, foi removido junto com o Modelo de
> cópia. O princípio continua valendo onde ainda há o que decidir: a migração feita
> pelo `adopt-repo` não apaga nada por inferência sobre arquivo ausente.

O `/update-claude` precisa saber de qual Versão vigente o projeto partiu para
distinguir "o Template mudou isto" de "o projeto customizou isto". Como nenhum
repositório tinha Marcador de origem quando o comando foi criado, a saída óbvia
seria inferir a base comparando o `.claude/` do projeto com cada tag e ficar com a
que mais se parece. **Decidimos não fazer isso:** sem Marcador, a base é
declaradamente desconhecida e o comando só afirma o que enxerga diretamente — que
um arquivo existe no projeto e não existe na Versão vigente.

## Por quê

A inferência foi tentada e produziu uma conclusão errada com aparência de prova.
O SAGA tem 15 skills byte-a-byte idênticas à `v1.0.0`, o que sugere fortemente que
ele veio dali. Daí seguiria que o SAGA "apagou `rules/python-conventions.md` de
propósito", já que a `v1.0.0` tem esse arquivo e o SAGA não — logo, não reinstalar.

Está errado. O SAGA vem da [Linhagem pré-tag (`v0.0.1`)](../../CONTEXT.md), anterior
a este repositório, em que o conteúdo Python vivia dentro do `code-conventions.md`;
o `python-conventions.md` foi extraído dele depois. O SAGA nunca teve esse arquivo,
e o comportamento correto é justamente instalá-lo. As skills não mudaram entre
`v0.0.1` e `v1.0.0`, então casá-las não prova nada sobre a origem.

O problema não é a taxa de acerto: é que o erro chega ao usuário como um motivo
verificável na lista de confirmação ("existia na sua versão e você removeu"), e ele
confirma confiando nela. Uma heurística que erra assim é pior que não ter
heurística nenhuma — sem ela, o pior caso é reinstalar um arquivo que o usuário
apaga de novo.

## Consequências

- A **primeira** execução em cada repositório é assimétrica: instala tudo que falta
  do Template e só pergunta sobre Órfãos. Não existe "você removeu isto" nessa
  passada.
- Da **segunda** em diante o Marcador dá a base real e a pergunta nos dois sentidos
  passa a ser legítima. O valor do Marcador não é registrar a versão — é habilitar
  essa afirmação.
- Projetos da Linhagem pré-tag nunca terão base retroativa. Eles ganham uma no
  primeiro update e seguem dali.
