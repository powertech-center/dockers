#!/bin/sh
# Generic atomics must work at the compiler's default CPU baseline.
. "$(dirname "$0")/helpers.sh"

echo "=== baseline atomic runtime ==="

cat > "$WORKDIR/atomics.c" <<'EOF'
#include <stdatomic.h>
#include <stdint.h>
struct value { uint64_t words[3]; };
int main(void) {
    struct value zero = {{0, 0, 0}}, next = {{1, 2, 3}};
    _Atomic(struct value) value = zero;
    atomic_store(&value, next);
    struct value old = atomic_exchange(&value, zero);
    if (old.words[0] != 1 || old.words[1] != 2 || old.words[2] != 3) return 1;
    return !atomic_compare_exchange_strong(&value, &zero, next);
}
EOF

for target in $(filter_targets $LINUX_TARGETS $WINDOWS_GNU_TARGETS); do
    for language in c cpp; do
        case "$language" in
            c) wrapper="clang-$target"; source="$WORKDIR/atomics.c"; flags="-std=c11"; widths="24-byte" ;;
            cpp) wrapper="clang++-$target"; source="$SRCDIR/atomics.cpp"; flags="-std=c++17 -pthread"; widths="16/24-byte" ;;
        esac
        # Static C++ executables also run when the host uses the other Linux libc.
        case "$target/$language" in *-linux-*/cpp) flags="$flags -static" ;; esac
        output="$WORKDIR/atomics-$target-$language$(exe_ext "$target")"
        desc="$target: $language $widths atomic runtime"
        if ! compile_and_link "$wrapper" "$source" -o "$output" $flags; then
            test_fail "$desc" "$LINK_STDERR"
            continue
        fi
        test_pass "$desc links"
        case "$target/$language" in
            "$(uname -m)"-linux-*/cpp)
                if "$output"; then
                    test_pass "$desc runs"
                else
                    test_fail "$desc runs" "exit code $?"
                fi
                ;;
        esac
    done
done

test_summary
