import requests
import threading
import time
import os
from statistics import mean

# --- Configuration ---
ALB_DNS_FILE = "alb_dns_name.txt"
RAMP_UP_SECONDS = 60      # Duration to ramp up (edit as needed)
PEAK_SECONDS = 120        # Duration to sustain peak traffic
RAMP_DOWN_SECONDS = 60    # Duration to ramp down
PEAK_RPS = 20             # Peak requests per second (edit as needed for your infra)
# ----------------------

def get_alb_dns():
    with open(ALB_DNS_FILE, "r") as f:
        # Remove extra quotes or whitespace if present
        dns = f.read().strip().replace('"', '')
        # Remove possible Terraform output label
        if dns.startswith('alb_dns_name ='):
            dns = dns.split('=')[1].strip()
        return dns

def send_requests(rps, duration_sec, endpoint):
    stats = []
    def worker():
        for _ in range(int(rps * duration_sec)):
            start = time.time()
            try:
                r = requests.get(endpoint, timeout=2)
                stats.append(r.elapsed.total_seconds())
            except Exception as e:
                stats.append(None)
            sleep_time = 1.0 / rps
            time.sleep(max(sleep_time - (time.time() - start), 0))
    thread = threading.Thread(target=worker)
    thread.start()
    thread.join()
    successes = [s for s in stats if s is not None]
    print(f"RPS: {rps}, Duration: {duration_sec}s, Successes: {len(successes)}, Avg Latency: {mean(successes) if successes else 'N/A'}s, Errors: {stats.count(None)}")

def ramp_phase(start_rps, end_rps, seconds, endpoint):
    print(f"Ramping from {start_rps} to {end_rps} RPS over {seconds}s...")
    steps = 10
    for i in range(steps):
        rps = start_rps + (end_rps - start_rps) * (i / (steps - 1))
        send_requests(rps, seconds / steps, endpoint)

def main():
    alb_dns = get_alb_dns()
    endpoint = f"http://{alb_dns}/"
    print(f"Using ALB endpoint: {endpoint}")

    # Ramp up
    ramp_phase(2, PEAK_RPS, RAMP_UP_SECONDS, endpoint)
    # Peak
    print("Sustaining peak load...")
    send_requests(PEAK_RPS, PEAK_SECONDS, endpoint)
    # Ramp down
    ramp_phase(PEAK_RPS, 2, RAMP_DOWN_SECONDS, endpoint)
    print("Traffic simulation complete.")

if __name__ == "__main__":
    main()