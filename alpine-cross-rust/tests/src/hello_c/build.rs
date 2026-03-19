// build.rs — build script that compiles hello.c via cc crate
fn main() {
    cc::Build::new()
        .file("hello.c")
        .compile("hello_c");
}
