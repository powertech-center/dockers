#!/bin/sh
# 24-toolchain-tools.sh — Standard tools process foreign objects and Windows SDK inputs
. "$(dirname "$0")/helpers.sh"

printf 'int answer(void) { return 42; }\n' > "$WORKDIR/answer.c"
printf 'int answer(void); int main(void) { return answer() != 42; }\n' > "$WORKDIR/main.c"
printf '#include <string>\nint main() { return std::string("ok").size() != 2; }\n' > "$WORKDIR/native.cpp"
if cc --version | grep -qi clang &&
    c++ "$WORKDIR/native.cpp" -o "$WORKDIR/native" && "$WORKDIR/native"; then
    test_pass "standard native compiler names use Clang"
else
    test_fail "standard native compiler names use Clang" "native C++ compilation failed"
fi
if [ "$(printf '%s\n' _Z6answerv | c++filt)" = 'answer()' ]; then
    test_pass "standard C++ demangler"
else
    test_fail "standard C++ demangler" "unexpected demangled name"
fi
for target in $(filter_targets $ALL_TARGETS); do
    desc="${target}: standard archive, symbols, objcopy, and link"
    if stderr=$({
        cd "$WORKDIR" &&
        case "$target" in
            *-windows-msvc)
                PATH="/opt/toolchains/windows-${target%%-*}/bin:$PATH"
                export PATH
                cl /WX /c answer.c /Foanswer.o &&
                lib /nologo /out:answer.lib answer.o &&
                nm answer.lib | grep -q answer &&
                objcopy --strip-debug answer.o stripped.o &&
                cl /c main.c /Fomain.o &&
                link /out:main.exe main.o answer.lib &&
                printf '#include <windows.h>\n1 RCDATA { 1, 2, 3 }\n' > resource.rc &&
                rc /fo resource.res resource.rc &&
                cvtres /nologo /out:resource.o resource.res &&
                link /out:main.exe main.o answer.lib resource.o &&
                printf '<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0"><assemblyIdentity version="1.0.0.0" name="test" type="win32"/></assembly>\n' > input.manifest &&
                mt /nologo /manifest input.manifest /out:output.manifest &&
                test -s output.manifest ;;
            *)
                "clang-${target}" -g -c answer.c -o answer.o &&
                ar rcs answer.a answer.o && ranlib answer.a &&
                nm answer.a | grep -q answer &&
                objcopy --strip-debug answer.o stripped.o &&
                strip --strip-debug stripped.o &&
                "clang-${target}" main.c answer.a -o main ;;
        esac
    } 2>&1); then
        if llvm-readobj --file-headers "$WORKDIR/answer.o" | grep -q "^Arch: ${target%%-*}$" &&
            objdump --disassemble "$WORKDIR/answer.o" >/dev/null &&
            size "$WORKDIR/answer.o" >/dev/null &&
            strings "$WORKDIR/answer.o" | grep -q answer; then
            test_pass "$desc"
        else
            test_fail "$desc" "object inspection failed"
        fi
    else
        test_fail "$desc" "$stderr"
    fi
done
test_summary
