import sys
import os
import numpy as np
from sorrel_runner import Is, Results, Situation, SorrelRunner, dispatch

# Add scripts/ml to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../scripts/ml')))

from features import extract_all_interpretable_features

@Is
@Situation("Default")
@Results(nan_count=0, inf_count=0, feature_dim=36)
def card_robustness_verify():
    # Test cases: empty, punctuation, long repetitive
    texts = ["", "...", "the " * 1000]

    feats, _ = extract_all_interpretable_features(texts)

    # Numeric evidence
    nan_count = np.isnan(feats).sum()
    inf_count = np.isinf(feats).sum()
    rows_processed = feats.shape[0]
    feature_dim = feats.shape[1]

    print(f"nan_count = {nan_count}")
    print(f"inf_count = {inf_count}")
    print(f"rows_processed = {rows_processed}")
    print(f"feature_dim = {feature_dim}")

    # Check long text TTR (should be very low)
    ttr_long = feats[2, 0]
    print(f"ttr_long = {ttr_long:.4f}")

    if nan_count > 0 or inf_count > 0 or rows_processed != 3 or feature_dim != 36:
        raise Exception("Validation failed")
    if ttr_long > 0.1: # It should be 1/1000 = 0.001
        raise Exception("TTR too high for repetitive text")

if __name__ == "__main__":
    runner = SorrelRunner()
    dispatch(runner)
