import pandas as pd
import numpy as np
import subprocess
import os
from scripts.ml.features import categorical_word_features

def test_categorical_analysis():
    print("Step 1: Preparing mock data...")
    human_text = "This complex system for data analysis is very advanced."
    llm_text = "A system for data analysis often uses simple modules."

    with open("human_test.txt", "w") as f: f.write(human_text)
    with open("llm_test.txt", "w") as f: f.write(llm_text)

    print("Step 2: Running corpus_analysis.py to generate mapping...")
    subprocess.run([
        "python3", "scripts/ml/corpus_analysis.py",
        "--human", "human_test.txt",
        "--llm", "llm_test.txt",
        "--config", "scripts/ml/dimensions.json",
        "--compare_words", "tests/ml/test_words.csv"
    ], check=True)

    print("Step 3: Verifying mapping file...")
    if not os.path.exists("tests/ml/test_words.csv"):
        raise Exception("Mapping file tests/ml/test_words.csv not created!")

    df = pd.read_csv("tests/ml/test_words.csv")
    print(f"Mapping file contains {len(df)} words.")
    print(df.head())

    print("Step 4: Verifying categorical feature extraction...")
    test_texts = ["This system for data analysis is complex.", "Often uses modules."]
    feats = categorical_word_features(test_texts, mapping_path="tests/ml/test_words.csv")

    print("Extracted categorical features:")
    print(feats)

    if feats.shape != (2, 3):
        raise Exception(f"Expected shape (2, 3), got {feats.shape}")

    print("Empirical Verification of categorical analysis: PASSED")

    # Final Cleanup
    os.remove("human_test.txt")
    os.remove("llm_test.txt")
    os.remove("tests/ml/test_words.csv")
    if os.path.exists("triple_comparison.csv"): os.remove("triple_comparison.csv")

if __name__ == "__main__":
    test_categorical_analysis()
