import argparse, csv, json, re, sys
from collections import Counter
from pathlib import Path

PATS = [
    re.compile(r"\b(error|exception|traceback)\b", re.I),
    re.compile(r"\btimeout\b", re.I),
    re.compile(r"\b5\d{2}\b"),  # 5xx codes (access logs)
    re.compile(r"\b(connection reset|refused)\b", re.I),
]

def tail_lines(p: Path, n: int):
    lines = p.read_text(errors="ignore").splitlines()
    return lines[-n:] if n > 0 else lines

def offender_key(line: str) -> str:
    # Access-log style bucket: status + path
    m = re.search(r'"\w+\s+([^ ]+)\s+HTTP/[^"]+"\s+(\d{3})', line)
    if m:
        return f"http_{m.group(2)}:{m.group(1)[:80]}"
    # App-log style bucket: component prefix
    m2 = re.match(r"^\s*([A-Za-z0-9_.-]{3,30})[:\]]\s+", line)
    if m2:
        return f"src:{m2.group(1)}"
    # Fallback: shape-based key
    return re.sub(r"\d+", "<n>", line.strip())[:80] or "<empty>"

def main() -> int:
    ap = argparse.ArgumentParser(description="Scan last N lines, report top offenders, export CSV/JSON.")
    ap.add_argument("logfile")
    ap.add_argument("--tail", type=int, default=2000)
    ap.add_argument("--top", type=int, default=10)
    ap.add_argument("--csv", dest="csv_path", default="out/summary_logs.csv")
    ap.add_argument("--json", dest="json_path", default="out/summary_logs.json")
    args = ap.parse_args()

    p = Path(args.logfile)
    if not p.exists():
        print(f"ERROR file_not_found={p}")
        return 2

    lines = tail_lines(p, args.tail)
    matched = [ln for ln in lines if any(pt.search(ln) for pt in PATS)]
    ctr = Counter(offender_key(ln) for ln in matched)

    offenders = []
    for key, count in ctr.most_common(args.top):
        sample = next((ln for ln in matched if offender_key(ln) == key), "")[:220]
        offenders.append({"key": key, "count": count, "sample": sample})

    Path(args.csv_path).parent.mkdir(parents=True, exist_ok=True)
    with open(args.csv_path, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(["offender_key", "count", "sample_excerpt"])
        for o in offenders:
            w.writerow([o["key"], o["count"], o["sample"]])

    with open(args.json_path, "w", encoding="utf-8") as f:
        json.dump(
            {"scanned_lines": len(lines), "matched_lines": len(matched), "offenders": offenders},
            f,
            indent=2,
        )

    print(f"scanned_lines={len(lines)} matched_lines={len(matched)} top={len(offenders)}")
    for o in offenders:
        print(f"- {o['count']:>4}  {o['key']}  | {o['sample']}")

    return 0 if len(matched) == 0 else 1

if __name__ == "__main__":
    sys.exit(main())
