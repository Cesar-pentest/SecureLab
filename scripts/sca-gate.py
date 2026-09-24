import json
import sys

if len(sys.argv) != 2:
    print("Usage: python3 sca-gate.py <result.json>")
    sys.exit(2)

result_file = sys.argv[1]

with open(result_file) as f:
    data = json.load(f)

blocking_severities = {"Critical", "High"}

for project in data.get("projects", []):
    for framework in project.get("frameworks", []):
        for package in framework.get("topLevelPackages", []):
            for vulnerability in package.get("vulnerabilities", []):
                severity = vulnerability.get("severity")

                if severity in blocking_severities:
                    print(
                        f"SCA GATE FAILED: "
                        f"{package['id']} "
                        f"({severity})"
                    )
                    sys.exit(1)

print("SCA GATE PASSED")
