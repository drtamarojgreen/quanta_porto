import numpy as np
import pandas as pd
from scripts.ml.features import extract_all_interpretable_features
from scripts.ml.data_prep import balance_and_split_data
from scripts.ml.pipeline import train_interpretable_model, hybrid_predict
from scripts.ml.evaluate_explain import evaluate_hybrid_system

def run_mock_test():
    print("Generating mock data...")
    prompts = ["Tell me a story about a cat.", "Explain quantum physics.", "How to bake a cake?"]
    human_texts = [
        "Once upon a time, there was a fluffy cat named Luna. She loved sleeping in the sun.",
        "Quantum physics is a fundamental theory in physics that provides a description of the physical properties of nature at the scale of atoms and subatomic particles.",
        "To bake a cake, you need flour, sugar, eggs, and butter. Mix them and bake at 350 degrees."
    ] * 10
    llm_texts = [
        "In a quaint village, a cat of exceptional fluffiness resided. Luna spent her days basking in solar warmth.",
        "Quantum mechanics is the branch of physics relating to the very small. It results in what may appear to be some very strange conclusions about the physical world.",
        "Baking a cake requires several key ingredients: flour, sugar, eggs, and fat. Combine these elements and cook in an oven."
    ] * 10
    
    human_df = pd.DataFrame({'prompt': prompts * 10, 'text': human_texts})
    llm_df = pd.DataFrame({'prompt': prompts * 10, 'text': llm_texts})
    
    print("Balancing and splitting data...")
    train_df, val_df, test_df = balance_and_split_data(human_df, llm_df)
    
    print(f"Train size: {len(train_df)}, Test size: {len(test_df)}")
    
    print("Extracting features for training...")
    X_train = extract_all_interpretable_features(train_df['text'].tolist())
    y_train = train_df['label'].tolist()
    
    print("Extracting features for testing...")
    X_test = extract_all_interpretable_features(test_df['text'].tolist())
    y_test = test_df['label'].tolist()
    
    feature_names = [
        "TTR", "Hapax", "AvgWordLen", "SentLenMean", "SentLenStd",
        "NounRatio", "VerbRatio", "AdjRatio", "AdvRatio", "PronRatio", "AdpRatio", "ConjRatio", "FuncWordRatio",
        "MATTR", "MTLD", "YulesK", "CapRatio", "ContractionFreq", "FleschEase",
        "PassiveRatio",
        "SentCompoundMean", "SentCompoundStd", "SentPosMean", "SentPosStd", "SentNegMean", "SentNegStd", "SentNeuMean", "SentNeuStd",
        "EntDensity", "NounDiversity",
        "HumanLeaningRatio", "LLMLeaningRatio", "TopDimRatio"
    ]
    
    print("Training interpretable model...")
    rf, scaler = train_interpretable_model(X_train, y_train, X_test, y_test, feature_names)
    
    # Mocking neural probabilities
    print("Mocking neural probabilities...")
    prob_neural = np.random.uniform(0, 1, len(y_test))
    prob_interpretable = rf.predict_proba(scaler.transform(X_test))[:, 1]
    
    print("Running hybrid prediction...")
    preds, exp_needed = hybrid_predict(prob_neural, prob_interpretable)
    
    evaluate_hybrid_system(y_test, preds, exp_needed)
    print("Mock test completed successfully!")

if __name__ == "__main__":
    run_mock_test()
