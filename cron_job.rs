use std::time::{Duration, Instant};

fn main() {
    let interval = Duration::new(60, 0); // 60 seconds
    let mut last_run = Instant::now();

    loop {
        if last_run.elapsed() >= interval {
            // Your cron job logic here
            println!("Cron job executed at: {:?}", Instant::now());
            last_run = Instant::now();
        }
    }
}