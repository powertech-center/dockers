/* hello.c — C dependency for Rust cc crate test */
#include <stdint.h>

int32_t add_from_c(int32_t a, int32_t b) {
    return a + b;
}
