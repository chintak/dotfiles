//! Crate docs for the parity sample.
use std::collections::HashMap;
use std::fmt::{self, Display};

/// A point with a label.
#[derive(Debug, Clone, PartialEq)]
pub struct Point<'a, T> {
    pub x: T,
    name: &'a str,
}

pub enum Shape {
    Circle { radius: f64 },
    Square(f64),
    Empty,
}

pub trait Area {
    fn area(&self) -> f64;
}

const MAX_LEN: usize = 42;
static GREETING: &str = "hello\tworld\n";

macro_rules! square {
    ($x:expr) => {
        $x * $x
    };
}

impl Area for Shape {
    fn area(&self) -> f64 {
        match self {
            Shape::Circle { radius } => std::f64::consts::PI * square!(radius),
            Shape::Square(side) if *side > 0.0 => side * side,
            _ => 0.0,
        }
    }
}

impl<'a, T: Display> Point<'a, T> {
    pub fn new(x: T, name: &'a str) -> Self {
        Self { x, name }
    }

    fn describe(&self, verbose: bool) -> Result<String, fmt::Error> {
        let mut out = String::new();
        if verbose && self.name.len() < MAX_LEN {
            'outer: for c in self.name.chars() {
                if c == 'q' {
                    break 'outer;
                }
                out.push(c);
            }
        }
        let n = 3.5_f64 as u32 + 0x1F;
        let counts: HashMap<&str, i32> = HashMap::new();
        let total = counts.values().map(|v| v * 2).sum::<i32>();
        match Some(n) {
            Some(v) => println!("{}\t{v} {}", self.x, 'z'),
            None => return Err(fmt::Error),
        }
        unsafe { std::ptr::null::<u8>().is_null() };
        drop(total);
        Ok(out)
    }
}

async fn fetch(id: u64) -> Option<Vec<u8>> {
    let raw = r#"{"id": 1}"#;
    let ok = true && !false;
    if ok { Some(raw.as_bytes().to_vec()) } else { None }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_works() {
        assert_eq!(square!(3), 9);
    }
}
