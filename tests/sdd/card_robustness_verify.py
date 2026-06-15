import sys
import os
import numpy as np
from sorrel_runner import Is, Results, Situation, SorrelRunner, dispatch

# Add scripts/ml to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../scripts/ml')))

from features import extract_all_interpretable_features

@Is("spacy_model_available", 1)
@Situation("Default")
def card_robustness_verify():
    texts = ["", "...", "the " * 100]
    feats, _ = extract_all_interpretable_features(texts)
    print(f"nan_count = {np.isnan(feats).sum()}")
    print(f"feature_dim = {feats.shape[1]}")

if __name__ == "__main__":
    runner = SorrelRunner()
    dispatch(runner)
