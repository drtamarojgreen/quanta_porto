import numpy as np
import pandas as pd
from scripts.ml.features import extract_all_interpretable_features

def test_batch_ef_features():
    texts = [
        "This is a sentence. However, it has a discourse marker.",
        "The boy who lived is here.", # Relative clause
        "A very simple one."
    ]

    feats, names = extract_all_interpretable_features(texts)
    df = pd.DataFrame(feats, columns=names)

    print("Batch E&F features extracted:")
    target_cols = ["AvgDepTreeDepth", "AvgDepDistance", "SubordinateRatio", "DiscourseMarkerDensity"]
    print(df[target_cols])

    # Text 1 has discourse marker 'However'
    assert df.loc[0, "DiscourseMarkerDensity"] > 0

    # Text 2 has relative clause
    assert df.loc[1, "SubordinateRatio"] > 0

    # AvgDepTreeDepth should be greater than 0
    assert df.loc[0, "AvgDepTreeDepth"] > 0

    print("Batch E&F verification: PASSED")

if __name__ == "__main__":
    test_batch_ef_features()
