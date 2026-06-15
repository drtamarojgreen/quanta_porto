import sys
import os
import numpy as np
from sorrel_runner import Is, Results, Situation, SorrelRunner, dispatch

# Add scripts/ml to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../scripts/ml')))

from features import extract_all_interpretable_features

@Is("spacy_model_available", 1)
@Situation("Default")
def card_features():
    texts = ["This is a short human sentence.", "The cat sat on the mat."]
    features, names = extract_all_interpretable_features(texts)

    print(f"feature_dim = {features.shape[1]}")
    print(f"nan_count = {np.isnan(features).sum()}")

if __name__ == "__main__":
    runner = SorrelRunner()
    dispatch(runner)
