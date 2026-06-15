import sys
import os
import numpy as np
from sorrel_runner import Is, Results, Situation, SorrelRunner, dispatch

# Add scripts/ml to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../scripts/ml')))

from features import extract_all_interpretable_features

@Is
@Situation("Default")
@Results(nan_count=0, inf_count=0, feature_dim=71)
def card_robustness_verify():
    texts = ["", "...", "the " * 1000]
    feats, _ = extract_all_interpretable_features(texts)

    return {
        "nan_count": np.isnan(feats).sum(),
        "inf_count": np.isinf(feats).sum(),
        "rows_processed": feats.shape[0],
        "feature_dim": feats.shape[1],
        "ttr_long": feats[2, 0]
    }

if __name__ == "__main__":
    runner = SorrelRunner()
    dispatch(runner)
