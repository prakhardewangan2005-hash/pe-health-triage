import argparse, json, sys, time
from dataclasses import dataclass
from typing import Optional
import requests

@dataclass
class Result:
    ok: bool
    status: Optional[int]
    latency_ms: Optional[int]
    error: Optional[str]

def probe(url: str, timeout: float, retries: int) -> Result:
    last_err = None
    for attempt in range(retries + 1):
        t0 = time.perf_counter()
        try:
            r = requests.get(url, timeout=timeout)
            latency = int((time.perf_counter() - t0) * 1000)
            ok = 200 <= r.status_code < 400
            return Result(ok=ok, status=r.status_code, latency_ms=latency, error=None)
        except Exception as e:
            last_err = str(e)
            if attempt < retries:
                time.sleep(0.15)
    return Result(ok=False, status=None, latency_ms=None, error=last_err)

def main() -> int:
    ap = argparse.ArgumentParser(description="HTTP reachability probe (timeout + retries), automation-friendly.")
    ap.add_argument("url")
    ap.add_argument("--timeout", type=float, default=2.0)
    ap.add_argument("--retries", type=int, default=1)
    ap.add_argument("--json", dest="json_path", default=None, help="Write structured output JSON")
    args = ap.parse_args()

    res = probe(args.url, args.timeout, args.retries)
    payload = {"url": args.url, "ok": res.ok, "status": res.status, "latency_ms": res.latency_ms, "error": res.error}

    if args.json_path:
        with open(args.json_path, "w", encoding="utf-8") as f:
            json.dump(payload, f, indent=2)

    if res.ok:
        print(f"OK status={res.status} latency_ms={res.latency_ms}")
        return 0
    if res.status is not None:
        print(f"BAD status={res.status} latency_ms={res.latency_ms}")
        return 10
    print(f"FAIL error={res.error}")
    return 11

if __name__ == "__main__":
    sys.exit(main())
