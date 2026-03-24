package main

/*
#include <stdio.h>
#include <stdlib.h>

void hello_from_c(void) {
    printf("Hello from C via CGO\n");
}
*/
import "C"

import "fmt"

func main() {
	C.hello_from_c()
	fmt.Println("Hello from Go")
}
