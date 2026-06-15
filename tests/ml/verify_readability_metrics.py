import numpy as np
import pandas as pd
from scripts.ml.features import extract_all_interpretable_features

def test_batch_c_features():
    texts = [
        "This is a short sentence. This is another short one. Is this a question?",
        "This is a significantly longer sentence that should hopefully trigger some different metrics in the readability analysis section of the script.",
        "A. B. C. D. E. F. G."
    ]

    feats, names = extract_all_interpretable_features(texts)
    df = pd.DataFrame(feats, columns=names)

    print("Batch C features extracted:")
    target_cols = ["SentLenMedian", "SentLenSkew", "SMOG", "GunningFog", "SentStartDiversity", "QuestionRatio"]
    print(df[target_cols])

    # Text 1 has a question
    assert df.loc[0, "QuestionRatio"] > 0

    # Text 3 has many identical starts "A", "B", etc. - but actually they are different tokens
    # Text 1 has "This", "This", "Is" -> diversity should be 2/3 = 0.66
    assert 0.6 < df.loc[0, "SentStartDiversity"] < 0.7

    print("Batch C verification: PASSED")

if __name__ == "__main__":
    test_batch_c_features()
