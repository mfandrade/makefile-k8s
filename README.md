# kubernetes-project

Projeto template que fornece a estrutura básica para facilitar a implantação
de aplicações no cluster Kubernetes.

[![pipeline
status](https://gitlab.trt8.jus.br/trt8/kubernetes-project/badges/master/pipeline.svg)](https://gitlab.trt8.jus.br/trt8/kubernetes-project/commits/master)

# O que é este projeto?

```
.
├── app.ini       # arquivo principal com parâmetros do projeto
├── Dockerfile    # arquivo Dockerfile para geração da imagem
├── assets/       # local padrão de artefatos para cópia
├── src/          # código-fonte da aplicação
│   └── env       # variáveis de ambiente usadas pela imagem
├── makefile      # arquivo makefile
└── yaml/         # arquivos yaml onde os parâmetros do projeto serão interpolados
```

Além de prover uma estrutura básica para uma maior organização da
estrutura dos projetos, também visa facilitar a execução de tarefas comuns para
implantação do projeto no cluster Kubernetes, diminuindo a propensão a erros e
tornando mais fácil e estruturado o fluxo de trabalho.


-------------------------------------------------------------------------------
# Fluxo de trabalho

Para novos projetos:

1. [Crie um repositório para seu projeto neste Gitlab](#crie-um-repositório-para-seu-projeto-neste-gitlab);
1. [Clone o repositório criado para sua estação de trabalho](#clone-o-repositório-criado-para-sua-estação-de-trabalho);
1. [Crie a estrutura mínima padrão em sua cópia de trabalho](#crie-a-estrutura-mínima-padrão-em-sua-cópia-de-trabalho);
1. [Informe os parâmetros de seu projeto no arquivo app.ini](#informe-os-parâmetros-de-seu-projeto-no-arquivo-app.ini);
1. [Ponha os códigos-fontes na pasta raíz da aplicação](#ponha-os-códigos-fontes-na-pasta-raíz-da-sua-aplicação);
1. [Escreva o Dockerfile para a imagem da sua aplicação](#escreva-o-dockerfile-para-a-imagem-da-sua-aplicação);
1. [Relacione as variáveis de ambiente utilizadas pela aplicação](#relacione-as-variáveis-de-ambiente-utilizadas-pela-aplicação);
1. [Teste a execução de sua aplicação localmente](#teste-a-execução-de-sua-aplicação-localmente);
1. [Suba sua aplicação para o repositório no Gitlab](#suba-sua-aplicação-para-o-repositório-no-gitlab).

**Resultado:** Você deve obter a imagem da sua aplicação construída e
disponibilizada no HUB local de imagens no Gitlab.


-------------------------------------------------------------------------------
## Crie um repositório para seu projeto neste Gitlab
Esta deve ser uma etapa trivial a você neste momento: essencialmente apenas
acesse este Gitlab e clique no botão verde **"New project"** no canto superior
direito ou faça fork de algum outro projeto.

Para mais informações, [consulte a documentação](https://docs.gitlab.com/ee/user/project/repository/#create-a-repository).


## Clone o repositório criado para sua estação de trabalho
Supondo que você criou um projeto chamado "my-project" dentro do grupo "group",
você pode cloná-lo para sua estação de trabalho com:
```shell
$ git clone git@gitlab.trt8.jus.br:/group/my-project.git
```

...ou com:
```shell
$ git clone https://gitlab.trt8.jus.br/group/my-project.git
```

Para mais informações, [consulte a documentação](https://docs.gitlab.com/ee/gitlab-basics/start-using-git.html#clone-a-repository)’.


## Crie a estrutura mínima padrão em sua cópia de trabalho
A estrutura mínima do projeto inclui o arquivo a pasta raíz da aplicação
`src/`, um arquivo de parâmetros do projeto `app.ini` e  uma cópia do
arquivo `makefile`:

```shell
$ cd my-project
$ mkdir src
$ echo > app.ini
$ curl -sO https://gitlab.trt8.jus.br/trt8/kubernetes-project/raw/clean/makefile
```

## Informe os parâmetros de seu projeto no arquivo app.ini
O conjunto de parâmetros de projeto na implantação padrão são:

* ENVIRONMENT
* APPLICATION
* NAMESPACE
* IMAGE\_HUB
* IMAGE\_NAME
* APP\_BACKEND\_PORT
* APP\_ENDPOINT\_PATH
* APP\_ENDPOINT\_URL

Apenas `ENVIRONMENT` é efetivamente obrigatório.  Os três últimos serão
obrigatórios para se disponibilizar a aplicação no cluster Kubernetes.

```shell
$ cat <<END > app.ini
APPLICATION = my-project
ENVIRONMENT = desenvolvimento

APP_BACKEND_PORT  = 8080
APP_ENDPOINT_URL  = my-project.trt8.jus.br
APP_ENDPOINT_PATH = /myapp

END
```

Mais informações sobre estes parâmetros abaixo na seção [Parâmetros de aplicação](#parâmetros-de-aplicação).


## Ponha os códigos-fontes na pasta raíz da aplicação;
Sem mistério.  Desenvolva sua aplicação tendo por raíz a pasta `src/` seja
apontando sua IDE para lá ou apenas copiand seus códigos-fonte para esta pasta.


## Escreva o Dockerfile para a imagem da sua aplicação
Escreva o Dockerfile para geração da imagem de sua aplicação em
`src/Dockerfile`.  São necessários conhecimentos básicos de Docker.

Não deixe de consultar a [documentação de referência para o Dockerfile](https://docs.docker.com/engine/reference/builder/#format).


## Relacione as variáveis de ambiente utilizadas pela aplicação;
Se sua aplicação utilizar variáveis de ambiente, relacione-as com os valores
adequados criando um arquivo de texto simples `src/env`.  Este arquivo deve
conter as variáveis de ambiente, uma por linha, num formato _CHAVE=valor_,
segundo mesmo formato do [arquivo .env](https://docs.docker.com/compose/environment-variables/#the-env-file)
do Docker Compose.

Valores como locais de arquivos, variáveis de bancos de dados, e outros dados
voláteis do tipo são melhores candidatos a variáveis de ambiente para constar
neste arquivo.


## Teste a execução de sua aplicação localmente;
Se sua aplicação estiver funcional e seu Dockerfile estiver sem erros, será
possivel gerar uma imagem da sua aplicação neste momento com:
```shell
$ make image
```

Para testar sua aplicação localmente, você pode fazer:
```shell
$ make docker-run
```

**NOTA:** Você pode preferir executar a aplicação em segundo plano com `make
image-start` e pará-la com `make image-stop`.

Como você talvez esteja desenvolvendo uma aplicação web, você provavelmente vai
querer passar flags para esta execução do Docker, por exemplo, para mapear a
porta principal na qual a aplicação escuta.  Faça isso incluindo o parâmetro
**RUN_FLAGS** no arquivo `app.ini` antes de executar o Docker.
```shell
$ echo 'RUN_FLAGS = -p 8080:8080' >> app.ini
$ make docker-run
```


## Suba sua aplicação para o repositório no Gitlab
Tudo pronto, disponibilize sua aplicação no Gitlab.

```shell
$ git status
On branch master
Your branch is up to date with 'origin/master'.

nothing to commit, working tree clean

$ git push origin master
```


-------------------------------------------------------------------------------
# Parâmetros de aplicação

São os parâmetros cujos valores serão interpolados nos arquivos da pasta
`yaml/`, padronizando a construção das imagens e facilitando a implantação da
aplicação no cluster Kubernetes.

* ENVIRONMENT
* APPLICATION
* NAMESPACE
* IMAGE\_HUB
* IMAGE\_NAME
* APP\_BACKEND\_PORT
* APP\_ENDPOINT\_PATH
* APP\_ENDPOINT\_URL


### ENVIRONMENT

Indica o ambiente considerado para a implantação desta aplicação.  Deve ser um
identificador, uma string tal como **homologacao** ou **producao**.  O
desenvolvedor deve ser responsável por eventualmente utilizar esta variável de
ambiente fazendo seu devido tratamento dentro da aplicação.

Na implantação padrão é utilizado juntamente com o nome da aplicação, entre
outras coisas, como label para identificar os recursos Kubernetes da aplicação.

**Opcional:** Não


### APPLICATION

Identificador da aplicação.  Nome pelo qual a aplicação (ou microsserviço) é
conhecida.

Na implantação padrão é utilizado juntamente com o ambiente da aplicação, entre
outras coisas, como label para identificar os recursos Kubernetes da aplicação.

**Opcional:** Sim
**Valor padrão:** O mesmo nome da pasta do repositório da aplicação no Gitlab.


### NAMESPACE

Nome do grupo de aplicações logicamente relacionadas ao qual esta aplicação ou
microsserviço faz parte.  Utilizado essencialmente para fins de organização.

Na implantação padrão, associa um namespace de mesmo nome para a aplicação.
Certifique-se apenas de referenciar um namespace já existente, uma vez que a
implantação padrão não cria namespaces no cluster Kubernetes.

**Opcional:** Sim
**Valor padrão:** O mesmo valor de APPLICATION.


### IMAGE\_HUB

HUB de imagens onde a imagem Docker da aplicação será disponibilizada.  Por
padrão refere-se ao HUB local, mas pode-se alterá-lo caso se queira, por
exemplo, referenciar à imagem do HUB de alguma outra regional.

**Opcional:** Sim
**Valor padrão:** "registry.trt8.jus.br"


### IMAGE\_NAME

Nome da imagem relativo a `IMAGE_HUB`.  Por padrão este valor é obtido a partir
do nome do repositório onde o projeto está versionado.  Caso necessite-se
alterar para um valor diferente, preciso que seja um valor com [nome de
imagem](https://gitlab.trt8.jus.br/trt8/kubernetes-project/container_registry)
aceito pelo registry.

**Opcional:** Sim
**Valor padrão:** O mesmo caminho do repositório no Gitlab.


### APP\_BACKEND\_PORT

Número da porta principal no qual a aplicação expõe um serviço HTTP.  É o número
da porta no qual a aplicação normalmente escuta.

Na implantação padrão, será um valor associado à porta do container e ao serviço
que o expõe para fora do cluster.

_**OBS:** Este parâmetro refere-se à porta principal da aplicação.  Arquiteturas
multi-service serão consideradas fora da implantação padrão, de forma que nesses
casos o desenvolvedor precisará definir por conta própria os demais services
Kubernetes._

**Opcional:** Sim
**Valor padrão:** N/A


### APP\_ENDPOINT\_URL

Endereço base da URL na qual a aplicação ou microsserviço será exposta.  Para o
caso de aplicações que utilizem o domínio **trt8.jus.br**, isso significa que a
aplicação será automaticamente disponibilizada em HTTPS.

Na implantação padrão, será associado à regra do recurso Ingress que expõe a
aplicação ou microsserviço.

**Opcional:** Sim
**Valor padrão:** N/A


### APP\_ENDPOINT\_PATH

Caminho da aplicação.  Refere-se à parte final da URL, após o domínio, na qual a
aplicação ou microsserviço será exposta.

Na implantação padrão, será associado à regra do recurso Ingress que expõe a
aplicação ou microsserviço.

**Opcional:** Sim
**Valor padrão:** N/A



-------------------------------------------------------------------------------
# Variáveis de ambiente (da aplicação)

Enquanto esses parâmetros de aplicação são utilizados como forma padronizada
usados para descrever e configurar a mesma quanto a geração da imagem Docker
e implantação padrão no cluster Kubernetes, a aplicação ainda pode depender de
outros dados voláteis que só façam sentido mais internamente a ela.

Por não serem suficientemente genéricos, dados desta natureza não são parâmetros
de configuração mas sim variáveis de ambiente específicos da aplicação.

Pode-se passar um conjunto de variáveis de ambiente para a aplicação por meio do
arquivo de texto `src/env`.  Este é simplesmente um arquivo de texto que
contém nomes das variáveis de ambiente e seus valores a serem repassados para o
container da aplicação.  Trata-se do mesmo [formato dos arquivos
.env](https://docs.docker.com/compose/environment-variables/#the-env-file) do
Docker Composer.  Por exemplo:

```
$ cat src/env
DB_HOST=srv-mysql
DB_NAME=myapp
DB_USER=dbuser
DB_PASS=Tribunal2019!
```

Diferente dos parâmetros de configuração, variáveis de ambiente não são
interpoladas em nenhum arquivo yaml e só são usadas na execução do container.
Portanto, já devem estar sendo esperados pela aplicação que é onde tais
variáveis serão efetivamente utilizadas.

Na implantação padrão, as variáveis de ambiente listadas no arquivo
`src/env` serão utilizadas para criar um ConfigMap Kubernetes com o mesmo
nome da aplicação e sufixo "-config" (`${APPLICATION}-config`).

_**OBS:** A implantação padrão irá colocar as variáveis de ambiente da aplicação
sempre como ConfigMap.  Atente, porém, que talvez seja mais adequado armazenar
dados sensíveis como senhas de bancos em Secrets do Kuberentes._


-------------------------------------------------------------------------------
# Versionamento

Para fins de desenvolvimento, por padrão a aplicação será empacotada numa imagem
Docker com a tag de versão **latest**, exceto se houver um arquivo `.version`,
texto simples, contendo o identificador ou número de versão desejado.  Por
exemplo:

```
$ echo '19.03' > .version
```

Ou se preferir, você também pode marcar o repositório com uma tag de versão num
formato __v*__, isto é, o identificador ou número de versão precedido de um "v".
Por exemplo:

```
$ git tag -a v1.0
```

Separar a versão da aplicação dos demais parâmetros facilita na manutenção uma
vez que se pode gerenciá-los independentemente, permitindo uma melhor gestão de
releases e de changelog.


-------------------------------------------------------------------------------
# FAQ - Dúvidas comuns

### A imagem da aplicação já existe e não quero regerá-la.  O que fazer?

Pode ser arriscado se depender de artefatos cuja origem não se tenha certeza, daí
a importância de poder gerar as imagens com facilidade.  Sempre é mais adequado
gerar e manter novas versões da imagem.

No entanto você pode definir a variável **BUILD\_IMAGE=false** no seu arquivo
`app.ini` se preferir.


### A imagem da minha aplicação foi gerada com uma tag "v1.0-dirty".  Por quê?

A que a princípio não há qualquer problema que a imagem tenha um nome como esse,
especialmente para fins de desenvolvimento.

A versão da imagem ficou marcada com o sufixo "-dirty" porque você a gerou
localmente a partir de sua cópia de trabalho do Git que não estava no estado
"clean".  Faça commit de todas suas alterações ou salve-as num stash e gere a
imagem novamente.


-------------------------------------------------------------------------------
# Sobre

Este template e makefile foram inspirados no projeto
[config-k8s-with-make](https://github.com/zikes/config-k8s-with-make) de Jason
Hutchinson.
