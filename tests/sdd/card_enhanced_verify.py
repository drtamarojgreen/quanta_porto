import sys
import os
import numpy as np
from sorrel_runner import Is, Results, Situation, SorrelRunner, dispatch

# Add scripts/ml to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../scripts/ml')))

from features import extract_all_interpretable_features

@Is
@Situation("Default")
@Results(feature_count=71, new_features_found=4)
def card_enhanced_verify():
    texts = ["This is a test sentence.", "Another one for the registry."]
    feats, names = extract_all_interpretable_features(texts)

    expected_new = ["MATTR", "FleschEase", "PropnRatio", "AvgTreeDepth"]
    found_new = [n for n in expected_new if n in names]

    return {
        "feature_count": feats.shape[1],
        "name_count": len(names),
        "nan_count": np.isnan(feats).sum(),
        "new_features_found": len(found_new)
    }

if __name__ == "__main__":
    runner = SorrelRunner()
    dispatch(runner)
