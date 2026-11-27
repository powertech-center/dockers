#include <atomic>
#include <cstdint>
#include <thread>

template <unsigned N> struct alignas(N == 2 ? 16 : 8) Value {
    std::uint64_t words[N];
};

template <unsigned N> bool equal(Value<N> a, Value<N> b) {
    for (unsigned i = 0; i < N; ++i)
        if (a.words[i] != b.words[i]) return false;
    return true;
}

template <unsigned N> bool check() {
    Value<N> zero{}, one{}, two{};
    for (unsigned i = 0; i < N; ++i) {
        one.words[i] = 1;
        two.words[i] = 2;
    }
    std::atomic<Value<N>> value(zero);
    value.store(one);
    if (!equal(value.load(), one)) return false;
    if (!equal(value.exchange(two), one)) return false;
    auto expected = one;
    if (value.compare_exchange_strong(expected, zero) || !equal(expected, two)) return false;
    if (!value.compare_exchange_strong(expected, zero)) return false;

    // Concurrent CAS exercises the runtime's locks for non-native widths.
    auto increment = [&] {
        for (unsigned i = 0; i < 1000; ++i) {
            auto before = value.load();
            for (;;) {
                auto after = before;
                for (auto &word : after.words) ++word;
                if (value.compare_exchange_weak(before, after)) break;
            }
        }
    };
    std::thread first(increment), second(increment);
    first.join();
    second.join();
    auto result = value.load();
    for (auto word : result.words)
        if (word != 2000) return false;
    // Also instantiate the runtime lock-free query; no lock-free promise for wide values.
    (void)value.is_lock_free();
    return true;
}

int main() {
    std::atomic<std::uint32_t> small(1);
    std::atomic<std::uint64_t> large(2);
    if (small.fetch_add(2) != 1 || large.fetch_add(3) != 2) return 1;
    static_assert(sizeof(Value<2>) == 16 && sizeof(Value<3>) == 24, "test widths");
    return check<2>() && check<3>() ? 0 : 2;
}
