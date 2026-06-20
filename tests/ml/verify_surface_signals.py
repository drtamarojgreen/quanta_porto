import numpy as np
import pandas as pd
from scripts.ml.features import extract_all_interpretable_features

def test_batch_b_features():
    texts = [
        "This is a test with 123 numbers and some elongated sooo words.",
        "Running runners ran fast.",
        "zxcvb mnbvc" # likely typos
    ]

    feats, names = extract_all_interpretable_features(texts)
    df = pd.DataFrame(feats, columns=names)

    print("Batch B features extracted:")
    print(df[["InflectionalVariety", "LemmaSurfaceRatio", "TypoRatio", "ElongatedRatio", "NumericRatio"]])

    # Text 1 has numeric and elongated
    assert df.loc[0, "NumericRatio"] > 0
    assert df.loc[0, "ElongatedRatio"] > 0

    # Text 2 has inflectional variety (Running, runners, ran all map to run)
    assert df.loc[1, "InflectionalVariety"] > 1.0

    # Text 3 has typos
    assert df.loc[2, "TypoRatio"] > 0

    print("Batch B verification: PASSED")

if __name__ == "__main__":
    test_batch_b_features()
