extern "C" {
    fn add_from_c(a: i32, b: i32) -> i32;
}

fn main() {
    let result = unsafe { add_from_c(2, 3) };
    println!("2 + 3 = {}", result);
}
