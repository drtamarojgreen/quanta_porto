import numpy as np
import pandas as pd
from scripts.ml.features import extract_all_interpretable_features

def test_batch_a_features():
    texts = [
        "This is a very important and significant test case with various data points.",
        "A simple sentence.",
        "Repetitive Repetitive Repetitive Repetitive Repetitive"
    ]

    feats, names = extract_all_interpretable_features(texts)
    df = pd.DataFrame(feats, columns=names)

    print("Batch A features extracted:")
    print(df[["HDD", "RootTTR", "CorrectedTTR", "ContentTTR", "FuncTTR", "RareWordRatio", "FillerWordRatio"]])

    assert "HDD" in names
    assert "FillerWordRatio" in names

    # Text 1 has fillers: "very", "important", "significant", "various"
    assert df.loc[0, "FillerWordRatio"] > 0

    print("Batch A verification: PASSED")

if __name__ == "__main__":
    test_batch_a_features()
