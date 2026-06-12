import pandas as pd
from sklearn.model_selection import train_test_split

def balance_and_split_data(human_df, llm_df, prompt_col='prompt', text_col='text'):
    """
    Matches human and LLM texts by prompt and balances their counts.
    """
    # Group by prompt
    human_groups = human_df.groupby(prompt_col)
    llm_groups = llm_df.groupby(prompt_col)
    
    matched_data = []
    
    all_prompts = set(human_df[prompt_col]).intersection(set(llm_df[prompt_col]))
    
    for prompt in all_prompts:
        h_texts = human_groups.get_group(prompt)
        l_texts = llm_groups.get_group(prompt)
        
        min_count = min(len(h_texts), len(l_texts))
        
        h_sample = h_texts.sample(min_count, random_state=42)
        l_sample = l_texts.sample(min_count, random_state=42)
        
        h_sample['label'] = 0 # Human
        l_sample['label'] = 1 # LLM
        
        matched_data.append(h_sample)
        matched_data.append(l_sample)
        
    combined_df = pd.concat(matched_data).reset_index(drop=True)
    
    # Stratified split by prompt to avoid prompt leakage
    unique_prompts = combined_df[prompt_col].unique()
    train_prompts, test_prompts = train_test_split(unique_prompts, test_size=0.2, random_state=42)
    train_prompts, val_prompts = train_test_split(train_prompts, test_size=0.125, random_state=42) # 0.125 * 0.8 = 0.1
    
    train_df = combined_df[combined_df[prompt_col].isin(train_prompts)]
    val_df = combined_df[combined_df[prompt_col].isin(val_prompts)]
    test_df = combined_df[combined_df[prompt_col].isin(test_prompts)]
    
    return train_df, val_df, test_df
