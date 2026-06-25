import numpy as np
import pandas as pd
from scripts.ml.features import extract_all_interpretable_features

def test_batch_i_features():
    texts = [
        "Apple is located in Cupertino, California. Steve Jobs founded it in 1976.", # Entities
        "Many studies suggest that experts agree on this topic.", # Ungrounded
        "A regular sentence with no facts."
    ]

    feats, names = extract_all_interpretable_features(texts)
    df = pd.DataFrame(feats, columns=names)

    print("Batch I features extracted:")
    target_cols = ["OrgDensity", "GpeDensity", "DateRatio", "UngroundedCount", "FactDensity"]
    print(df[target_cols])

    # Text 1 has ORG (Apple), GPE (Cupertino, California), DATE (1976)
    assert df.loc[0, "OrgDensity"] > 0
    assert df.loc[0, "GpeDensity"] > 0
    assert df.loc[0, "DateRatio"] > 0
    assert df.loc[0, "FactDensity"] > 1.0

    # Text 2 has ungrounded phrases
    assert df.loc[1, "UngroundedCount"] >= 2

    print("Batch I verification: PASSED")

if __name__ == "__main__":
    test_batch_i_features()
