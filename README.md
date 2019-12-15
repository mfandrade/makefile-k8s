# kubernetes-project

Projeto template que fornece a estrutura básica para facilitar a implantação
de aplicações no cluster Kubernetes.

```
.
├── app-src/		# pasta raíz da aplicação em desenvolvimento
│   ├── Dockerfile	# Dockerfile para geração da imagem
│   └── env		# variáveis de ambiente usadas pela imagem
├── app.ini		# arquivo de parâmetros da aplicação
├── makefile		# arquivo makefile com ações comuns
└── yaml/		# pasta de arquivos yaml onde os parâmetros serão usados
```

## O que é este projeto?

Além de prover uma estrutura básica para uma maior organização da
estrutura dos projetos, também visa facilitar a execução de tarefas comuns para
implantação do projeto no cluster Kubernetes, diminuindo a propensão a erros e
tornando mais fácil e estruturado o fluxo de trabalho.


## Fluxo de trabalho mínimo

Para novos projetos:

1. Disponibilize o código-fonte da aplicação dentro de app-src;
1. Inclua ali também um Dockerfile para a imagem da sua aplicação;
1. Configure os parâmetros da aplicação no arquivo app.ini;
1. Suba os arquivos para o Gitlab.

**Resultado:** Você deve obter a imagem da sua aplicação construída e
disponibilizada no HUB local de imagens no Gitlab.


# Parâmetros de aplicação 

* ENVIRONMENT
* APPLICATION
* VERSION
* PACKAGE
* YAML\_DIR
* SRC\_DIR
* IMAGE\_NAME
* IMAGE\_HUB
* BUILD\_IMAGE
* BUILD\_ARGS
* RUN\_FLAGS
* APP\_BACKEND\_PORT
* APP\_ENDPOINT\_URL
* APP\_ENDPOINT\_PATH


## ENVIRONMENT

Ambiente da aplicação.  Identificador de a qual ambiente a aplicação se refere.  Por exemplo,
`homologacao` ou `producao`.

**Obrigatório:** Sim
**Valor padrão:** Não tem


## APPLICATION

Nome da aplicação em questão.  

**Obrigatório:** Não.
**Valor padrão:** O mesmo nome da pasta onde o projeto reside.


## PACKAGE

Nome do pacote de aplicações.  Identificador para agrupar conjunto correlato de
aplicações.  

**Opcional:** Sim.
**Valor padrão:** O mesmo nome da aplicação. 
