import numpy as np
import pandas as pd
from scripts.ml.features import extract_all_interpretable_features

def test_batch_d_features():
    texts = [
        "I am writing a test for myself and we are happy.", # First person
        "You should check your work.", # Second person
        "He said that she loved them and it was good.", # Third person
        "This is not a failure. I won't quit. Never!", # Negation
    ]

    feats, names = extract_all_interpretable_features(texts)
    df = pd.DataFrame(feats, columns=names)

    print("Batch D features extracted:")
    target_cols = ["FirstPersonRatio", "SecondPersonRatio", "ThirdPersonRatio", "NegationRatio", "POSEntropy"]
    print(df[target_cols])

    # Text 1: I, myself, we
    assert df.loc[0, "FirstPersonRatio"] > 0

    # Text 2: You, your
    assert df.loc[1, "SecondPersonRatio"] > 0

    # Text 3: He, she, them, it
    assert df.loc[2, "ThirdPersonRatio"] > 0

    # Text 4: not, won't, Never
    assert df.loc[3, "NegationRatio"] > 0

    print("Batch D verification: PASSED")

if __name__ == "__main__":
    test_batch_d_features()
