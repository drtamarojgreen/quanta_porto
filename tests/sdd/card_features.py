import sys
import os
import numpy as np
from sorrel_runner import Is, Results, Situation, SorrelRunner, dispatch

# Add scripts/ml to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../scripts/ml')))

from features import extract_all_interpretable_features

@Is
@Situation("Default")
@Results(feature_dim=36, nan_count=0)
def card_features():
    texts = [
        "This is a short human sentence.",
        "A much longer sentence that should contain more tokens and different POS tags for the feature extractor to process correctly.",
        "The cat sat on the mat. The dog jumped over the log.",
        "It was a dark and stormy night; the wind was howling through the trees."
    ]

    features, names = extract_all_interpretable_features(texts)

    return {
        "feature_dim": features.shape[1],
        "nan_count": np.isnan(features).sum(),
        "passive_ratio_mean": np.mean(features[:, 13]),
        "ttr_mean": np.mean(features[:, 0])
    }

if __name__ == "__main__":
    runner = SorrelRunner()
    dispatch(runner)
