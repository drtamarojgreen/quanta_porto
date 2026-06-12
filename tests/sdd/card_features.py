import sys
import os
import numpy as np

# Add scripts/ml to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../scripts/ml')))

from features import extract_all_interpretable_features

def test_features():
    texts = [
        "This is a short human sentence.",
        "A much longer sentence that should contain more tokens and different POS tags for the feature extractor to process correctly.",
        "The cat sat on the mat. The dog jumped over the log.",
        "It was a dark and stormy night; the wind was howling through the trees."
    ]

    features = extract_all_interpretable_features(texts)

    # Numeric evidence
    feature_dim = features.shape[1]
    nan_count = np.isnan(features).sum()
    passive_ratio_mean = np.mean(features[:, 13])

    print(f"feature_dim = {feature_dim}")
    print(f"nan_count = {nan_count}")
    print(f"passive_ratio_mean = {passive_ratio_mean:.4f}")

    # Validation
    assert feature_dim == 24, f"Expected 24 features, got {feature_dim}"
    assert nan_count == 0, f"Detected {nan_count} NaNs in features"

    # Verify some values are non-zero (assuming the text provides some signal)
    # TTR is at index 0
    ttr_mean = np.mean(features[:, 0])
    print(f"ttr_mean = {ttr_mean:.4f}")
    assert ttr_mean > 0, "TTR mean should be > 0"

if __name__ == "__main__":
    try:
        test_features()
        sys.exit(0)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
