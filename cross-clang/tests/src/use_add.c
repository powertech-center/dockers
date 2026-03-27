/* use_add.c — calls add() from add.c, used for testing direct linker invocation */
#include <stdio.h>

extern int add(int a, int b);

int main(void) {
    printf("%d\n", add(1, 2));
    return 0;
}
