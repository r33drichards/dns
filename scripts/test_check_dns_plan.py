import unittest

from check_dns_plan import check


def record(actions, before=None, after=None, resource_type="aws_route53_record"):
    return {"resource_changes": [{
        "address": "test.record", "type": resource_type, "mode": "managed",
        "change": {"actions": actions, "before": before, "after": after},
    }]}


class DNSPlanBoundary(unittest.TestCase):
    def test_update_authorized_zone(self):
        value = {"zone_id": "Z08951152DD6LNOZOXRJZ"}
        self.assertEqual(check(record(["update"], value, value)), [])

    def test_reject_cross_zone_replacement(self):
        self.assertTrue(check(record(["delete", "create"],
            {"zone_id": "Z08951152DD6LNOZOXRJZ"}, {"zone_id": "ZOTHER"})))

    def test_reject_unknown_zone(self):
        self.assertTrue(check(record(["create"], after={})))

    def test_reject_non_dns_mutation(self):
        self.assertTrue(check(record(["update"], resource_type="aws_cloudfront_distribution")))

    def test_allow_non_dns_noop(self):
        self.assertEqual(check(record(["no-op"], resource_type="aws_cloudfront_distribution")), [])

    def test_authorized_deletion(self):
        self.assertEqual(check(record(["delete"], before={"zone_id": "Z07438401E30ZEQ6KJPLG"})), [])


if __name__ == "__main__":
    unittest.main()
