# hello-world

Uma aplicação hello-world tradicional ligeiramente modificada para exemplificar o uso de variáveis de ambiente por
aplicações.

## O que faz?

Esta aplicação de linha de comando escrita em [linguagem Go](https://golang.org/), ao ser executada normalmente exibe
a cada segundo, por cinco vezes, a mensagem "Hello, World!" na tela:

```shell
$ go run hello.go
Hello, World!
Hello, World!
Hello, World!
Hello, World!
Hello, World!
```

No entanto, se houver a variável de ambiente `GREETINGS_TO`, a aplicação exibirá a mensagem ao nome que nela estiver
definido ao invés de "World":

```shell
$ GREETINGS_TO=Fulano go run hello.go
Hello, Fulano!
Hello, Fulano!
Hello, Fulano!
Hello, Fulano!
Hello, Fulano!
```

## Arquivo de variáveis de ambiente

Como um padrão, para preparar sua aplicação para execução em containers, sugere-se listar todas as variáveis de
ambiente (e seus valores) que sua aplicação utiliza num arquivo de texto simples chamado `env`.

```shell
$ echo 'GREETINGS_TO=Beltrano' > env
```

**Esta medida visa:**
- definir claramente as variáveis de ambiente utilizadas pela aplicação;
- desestimular a escrita de variáveis em _hardcoded_ na aplicação;
- evitar mudança de versões da aplicação devido a meras mudanças de valores de variáveis;
- facilitar o uso repetível e execução de testes da aplicação de forma padronizada;


