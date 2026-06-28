import numpy as np
import pandas as pd
from scripts.ml.features import extract_all_interpretable_features

def test_batch_k_features():
    texts = [
        "As an AI, I cannot provide legal advice. It is important to note that this is just a test.", # Residue and Safety
        "The cat sat on the mat. The cat sat on the mat. The cat sat on the mat.", # Repetition and Burstiness
        "Normal unique sentence with no repetition."
    ]

    feats, names = extract_all_interpretable_features(texts)
    df = pd.DataFrame(feats, columns=names)

    print("Batch K features extracted:")
    target_cols = ["BurstinessScore", "RepetitionPenalty", "ResidueRatio", "SafetyDisclaimer"]
    print(df[target_cols])

    # Text 1 has residue and safety
    assert df.loc[0, "ResidueRatio"] > 0
    assert df.loc[0, "SafetyDisclaimer"] > 0

    # Text 2 has high repetition
    assert df.loc[1, "RepetitionPenalty"] > 0.5
    assert df.loc[1, "BurstinessScore"] > 0

    print("Batch K verification: PASSED")

if __name__ == "__main__":
    test_batch_k_features()
