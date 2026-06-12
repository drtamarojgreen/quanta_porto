import sys
import os
import pandas as pd

# Add scripts/ml to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../scripts/ml')))

from data_prep import balance_and_split_data

def test_data_prep():
    prompts = ["p1", "p2", "p3", "p4", "p5"]
    human_texts = ["h" + str(i) for i in range(20)]
    llm_texts = ["l" + str(i) for i in range(20)]

    human_df = pd.DataFrame({
        'prompt': [prompts[i % 5] for i in range(20)],
        'text': human_texts
    })
    llm_df = pd.DataFrame({
        'prompt': [prompts[i % 5] for i in range(20)],
        'text': llm_texts
    })

    train_df, val_df, test_df = balance_and_split_data(human_df, llm_df)

    # Numeric evidence
    train_size = len(train_df)
    val_size = len(val_df)
    test_size = len(test_df)

    total_samples = train_size + val_size + test_size
    label_0_count = (train_df['label'] == 0).sum() + (val_df['label'] == 0).sum() + (test_df['label'] == 0).sum()
    label_1_count = (train_df['label'] == 1).sum() + (val_df['label'] == 1).sum() + (test_df['label'] == 1).sum()

    label_balance_ratio = label_0_count / label_1_count if label_1_count > 0 else 0

    print(f"train_size = {train_size}")
    print(f"val_size = {val_size}")
    print(f"test_size = {test_size}")
    print(f"label_balance_ratio = {label_balance_ratio:.2f}")

    # Validation
    assert total_samples == 40, f"Expected 40 samples, got {total_samples}"
    assert label_balance_ratio == 1.0, f"Expected balanced labels, got {label_balance_ratio}"

    # Prompt leakage check
    train_prompts = set(train_df['prompt'])
    test_prompts = set(test_df['prompt'])
    overlap = train_prompts.intersection(test_prompts)
    print(f"prompt_overlap_count = {len(overlap)}")
    assert len(overlap) == 0, f"Prompt leakage detected: {overlap}"

if __name__ == "__main__":
    try:
        test_data_prep()
        sys.exit(0)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
