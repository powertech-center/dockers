/* nostdlib.c — minimal program that compiles without standard library
   Used to test -nostdlib flag handling in linker wrappers. */

void _start(void) {
    /* Infinite loop — no libc, no exit() */
    for (;;) {}
}
