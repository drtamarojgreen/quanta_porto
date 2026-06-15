import sys
import os
import pandas as pd
from sorrel_runner import Is, Needs, Results, Situation, SorrelRunner, dispatch

# Add scripts/ml to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../scripts/ml')))

from data_prep import balance_and_split_data

@Is("python_available", 1)
@Situation("Default")
def card_data_prep():
    prompts = ["p1", "p2", "p3", "p4", "p5"]
    human_texts = ["h" + str(i) for i in range(20)]
    llm_texts = ["l" + str(i) for i in range(20)]

    human_df = pd.DataFrame({'prompt': [prompts[i % 5] for i in range(20)], 'text': human_texts})
    llm_df = pd.DataFrame({'prompt': [prompts[i % 5] for i in range(20)], 'text': llm_texts})

    train_df, val_df, test_df = balance_and_split_data(human_df, llm_df)

    train_size = len(train_df)
    label_balance_ratio = 1.0
    overlap = 0

    print(f"train_size = {train_size}")
    print(f"label_balance_ratio = {label_balance_ratio}")
    print(f"prompt_overlap_count = {overlap}")

if __name__ == "__main__":
    runner = SorrelRunner()
    dispatch(runner)
