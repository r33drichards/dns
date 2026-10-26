"""Reject CI changes outside DNS records in the two existing hosted zones."""
import json
import sys

ZONES = {"Z07438401E30ZEQ6KJPLG", "Z08951152DD6LNOZOXRJZ"}


def check(plan):
    errors = []
    for change in plan.get("resource_changes", []):
        if change.get("mode") == "data":
            continue
        detail = change["change"]
        if detail["actions"] == ["no-op"]:
            continue
        if change["type"] != "aws_route53_record":
            errors.append(change["address"] + ": only DNS record changes are allowed")
            continue
        for side in ("before", "after"):
            value = detail.get(side)
            if value is not None and value.get("zone_id") not in ZONES:
                errors.append(change["address"] + ": unknown or unauthorized hosted zone")
    return errors


if __name__ == "__main__":
    with open(sys.argv[1]) as source:
        errors = check(json.load(source))
    if errors:
        raise SystemExit("\n".join(errors))
    print("Plan contains only permitted DNS record changes.")
