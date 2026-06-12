import sys
import os
import numpy as np

# Add scripts/ml to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../scripts/ml')))

from features import extract_all_interpretable_features

def verify_robustness():
    # Test cases: empty, punctuation, long repetitive
    texts = ["", "...", "the " * 1000]

    feats = extract_all_interpretable_features(texts)

    # Numeric evidence
    nan_count = np.isnan(feats).sum()
    inf_count = np.isinf(feats).sum()
    rows_processed = feats.shape[0]
    feature_dim = feats.shape[1]

    print(f"nan_count = {nan_count}")
    print(f"inf_count = {inf_count}")
    print(f"rows_processed = {rows_processed}")
    print(f"feature_dim = {feature_dim}")

    # Assertions for the runner
    if nan_count > 0 or inf_count > 0 or rows_processed != 3 or feature_dim != 24:
        sys.exit(1)

    # Check long text TTR (should be very low)
    ttr_long = feats[2, 0]
    print(f"ttr_long = {ttr_long:.4f}")
    if ttr_long > 0.1: # It should be 1/1000 = 0.001
        sys.exit(1)

    sys.exit(0)

if __name__ == "__main__":
    try:
        verify_robustness()
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
