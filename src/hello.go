package main

import (
    "fmt"
    "os"
    "time"
)


func say_hello(name string) {

    if len(name) == 0 {
        name = "World"
    }
    fmt.Printf("Hello, %v!\n", name)
}


func main() {

    times := 5
    for i := 0; i < times; i++ {

        say_hello(os.Getenv("GREETINGS_TO"))
        time.Sleep(time.Second)
    }
}

