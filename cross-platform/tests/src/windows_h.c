/* windows_h.c — test that windows.h compiles cleanly (xwin for MSVC, mingw-w64 for GNU) */
#include <windows.h>
#include <stdio.h>

int main(void) {
    DWORD val = 42;
    printf("Value: %lu\n", (unsigned long)val);
    return 0;
}
