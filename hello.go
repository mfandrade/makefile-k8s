// AUTHOR: Marcelo F Andrade <mfandrade@gmail.com>
// LICENSE: The Beer-ware License
// (C) 2022 https://about.me/mfandrade
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

    times := 10 // 10 seconds
    for i := 0; i < times; i++ {

        say_hello(os.Getenv("USERNAME"))
        time.Sleep(time.Second)
    }
}
