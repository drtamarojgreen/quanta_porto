import numpy as np
import pandas as pd
from scripts.ml.features import extract_all_interpretable_features

def test_batch_g_features():
    texts = [
        "Perhaps it is likely that it could be true.", # Hedging
        "This is amazing! This is terrible. This is fine.", # Volatility
        "A regular factual report."
    ]

    feats, names = extract_all_interpretable_features(texts)
    df = pd.DataFrame(feats, columns=names)

    print("Batch G features extracted:")
    target_cols = ["SentVolatility", "HedgingRatio", "SubjectivityScore"]
    print(df[target_cols])

    # Text 1 has hedging: Perhaps, likely, could
    assert df.loc[0, "HedgingRatio"] > 0

    # Text 2 has volatility (mix of extreme sentiment)
    assert df.loc[1, "SentVolatility"] > 0

    print("Batch G verification: PASSED")

if __name__ == "__main__":
    test_batch_g_features()
