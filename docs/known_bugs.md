# Known Bugs

## BDD Test Runner Hangs on Features with `Background` Steps

**Date:** 2025-07-29

**Description:**

The primary BDD test runner script, `tests/bdd/enhanced_test_runner.sh`, has a bug that causes it to hang when processing `.feature` files that contain a `Background:` block.

**Symptoms:**

When running the tests via `./run_bdd_tests.sh`, the test runner will print `Processing feature: <feature_name>` and then hang indefinitely.

**Root Cause Analysis:**

The `parse_feature_file` function in `enhanced_test_runner.sh` does not correctly handle `Background` steps. It attempts to process them as regular steps but fails to associate them with a scenario, leading to an infinite loop or other hang condition within the script's logic. The script that is called by the step definition (`scripts/ethics_bias_checker.sh`) is never actually executed.

**Workaround:**

Currently, there is no workaround other than to avoid using `Background` steps in feature files. To test the features that are currently broken, one would need to duplicate the `Background` steps into each `Scenario:` block.

**Affected Files:**

*   `tests/bdd/enhanced_test_runner.sh`
*   `tests/bdd/features/ethics_bias_detection.feature` (and any other feature file using `Background`)
