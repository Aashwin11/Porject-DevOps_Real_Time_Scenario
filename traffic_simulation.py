import requests
import threading
import time
import os
from statistics import mean

ALB_DNS_FILE = os.getenv('ALB_DNS_FILE', 'alb_dns_name.txt')
RAMP_UP_SECONDS = 60
PEAK_SECONDS = 120
RAMP_DOWN_SECONDS = 60
PEAK_RPS = 20

def get_alb_dns():
    with open(ALB_DNS_FILE, 'r') as f:
        dns = f.read().strip()
        return dns
    
def send_requests_concurrent(rps, duration_sec, endpoint):
    stats = []
    num_threads = min(50, int(rps))  # Max 50 concurrent threads
    iterations_per_thread = int((rps * duration_sec) / num_threads)

    def worker():
        for _ in range(iterations_per_thread):
            start = time.time()
            try:
                r = requests.get(endpoint, timeout=5)
                stats.append(r.elapsed.total_seconds())
            except Exception:
                stats.append(None)
            sleep_time = 1.0 / rps
            time.sleep(max(sleep_time - (time.time() - start), 0))

    threads = [threading.Thread(target=worker) for _ in range(num_threads)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()

    successes = [s for s in stats if s is not None]
    print(f"RPS: {rps}, Duration: {duration_sec}s, Successes: {len(successes)}, "
          f"Avg Latency: {mean(successes) if successes else 'N/A'}s, Errors: {stats.count(None)}")

def ramp_phase(start_rps, end_rps, seconds, endpoint):
    print(f"Ramping from {start_rps} to {end_rps} RPS over {seconds}s...")
    steps = 10
    for i in range(steps):
        rps = start_rps + (end_rps - start_rps) * (i / (steps - 1))
        send_requests_concurrent(rps, seconds / steps, endpoint)

def main():
    ALB_DNS = get_alb_dns()
    endpoint = f"http://{ALB_DNS}/index.php"
    print(f"Using ALB endpoint: {endpoint}")

    ramp_phase(2, PEAK_RPS, RAMP_UP_SECONDS, endpoint)
    print("Sustaining peak load...")
    send_requests_concurrent(PEAK_RPS, PEAK_SECONDS, endpoint)
    ramp_phase(PEAK_RPS, 2, RAMP_DOWN_SECONDS, endpoint)
    print("Traffic simulation complete.")

if __name__ == "__main__":
    main()
