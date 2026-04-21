import sqlite3, os

devices = [
    ("ETHOSCOPE_007", "007c18e6355c4edc8438de9d9154c4d2"),
    ("ETHOSCOPE_008", "008dc3ad3e8049049b7d2f5bab510f57"),
    ("ETHOSCOPE_009", "009ca905dd0045729382988fcbcc853a"),
    ("ETHOSCOPE_010", "010a1a7964a744f1b461d14f5b252573"),
    ("ETHOSCOPE_011", "0112d7e7d85748dc949ac42e50fdbcc7"),
    ("ETHOSCOPE_012", "0128e0a73ce447ee9497d4c897f603d4"),
    ("ETHOSCOPE_013", "01393696187d49d2b77fa796764503c6"),
    ("ETHOSCOPE_014", "01447d17dbf0418cb425d47a1559667c"),
    ("ETHOSCOPE_015", "01555ae26bbd4d9787feadb207b20c40"),
]

BASE = "/Users/aniketsharma/Documents/Research Assistant/Ethoscope/ethoscope_data/results"
GOOD = 50000   # threshold for "good" data

def find_db(uuid, name):
    device_dir = os.path.join(BASE, uuid, name)
    for session in sorted(os.listdir(device_dir)):
        session_dir = os.path.join(device_dir, session)
        for f in os.listdir(session_dir):
            if f.endswith(".db"):
                return os.path.join(session_dir, f)
    return None

def get_counts(db_path, rois):
    conn = sqlite3.connect(db_path)
    counts = {}
    for roi in rois:
        try:
            counts[roi] = conn.execute(f"SELECT COUNT(*) FROM ROI_{roi}").fetchone()[0]
        except:
            counts[roi] = 0
    conn.close()
    return counts

TUBES = [1, 3, 12, 14]
has_fly  = {dev: [1,3,12,14] if dev != "ETHOSCOPE_012" else [1,12] for dev,_ in devices}

print(f"{'Device':<15} {'ROI_1':>10} {'ROI_3':>10} {'ROI_12':>10} {'ROI_14':>10}   Status")
print("-" * 80)

for name, uuid in devices:
    db = find_db(uuid, name)
    if not db:
        print(f"{name:<15}  DB not found")
        continue
    c = get_counts(db, TUBES)
    expected = has_fly[name]
    
    issues = []
    for t in expected:
        if c[t] < GOOD:
            issues.append(f"T{t} dead/missing ({c[t]:,})")
    
    def fmt(tube):
        val = c[tube]
        if tube not in expected:
            return f"{'(no fly)':>10}"
        marker = "⚠" if val < GOOD else " "
        return f"{val:>9,}{marker}"
    
    status = "OK" if not issues else " | ".join(issues)
    print(f"{name:<15} {fmt(1)} {fmt(3)} {fmt(12)} {fmt(14)}   {status}")

print(f"\n⚠ = fewer than {GOOD:,} rows (fly likely dead, escaped, or tracking failed)")
