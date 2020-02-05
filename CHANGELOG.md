# Changelog

Todas as alterações significativas neste projeto.

## [Não-liberado]
- Desenvolvimento anterior à versão 1.0.0

## [v1.0.0] - 2019-12-16
- Primeira versão funcional. Aprovada para uso em Dezembro/2019.

## [v1.1.0] - 2019-12-17
- Adicionado parâmetro NAMESPACE como um sinônimo para PACKAGE.

## [v1.1.1] - 2019-12-18
- Corrigido parâmetro BUILD\_ARGS para permitir uso de mais de um valor.

## [v1.2.0] - 2020-01-14
- Renomeada pasta default da aplicação de app-src para apenas src.
- Corrigido teste para variável IMAGE\_NAME e ENVIRONMENT vazias.
- Adicionada variável K8S\_DEPLOY.

## [v1.3.0] - 2020-01-15
- Corrige criação do configmap e inclui image prune no clean.

## [v2.0.0] - 2020-01-21
- Alterada estrutura do projeto para maior compatibilidade com Maven.
  - Movido Dockerfile um nível acima
  - Extinguido parâmetro SRC\_DIR
- Adicionados parâmetros APPLICATION e ENVIRONMENT como variáveis de ambiente da imagem.
  - Melhorada lógica para teste do arquivo env e definição de ENV\_FLAGS
  - Adicionadas flags -e para ambos nos targets docker-run e image-start
  - Adicionado env no yaml do pod gerado
- Correção no tratamento do src/env
- Removido '@' dos comandos para serem exibidos em execução

## [v2.0.1] - 2020-01-23
- Corrigido erro no target clean

## [v2.1.0] - 2020-01-24
- Separa pasta src do Docker context.

## [v2.1.1] - 2020-01-29
- Target deploy agora falha se for configurado para false.

## [v2.2.0] - 2020-01-31
- Inclui o undeploy target.

## [v2.3.0] - 2020-02-05
- Inclui o shell target.
- Inclui o redeploy target.
- Melhora mensagem de help.


_O formato deste documento foi baseado no [Mantenha um
Changelog](https://keepachangelog.com/pt-BR/0.3.0/) e este projeto é aderente ao
[Versionamento Semântico](https://semver.org/lang/pt-BR/)_.

