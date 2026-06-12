import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import accuracy_score, f1_score, roc_auc_score
from datasets import Dataset
from transformers import AutoTokenizer, AutoModelForSequenceClassification, Trainer, TrainingArguments
import torch
from scipy.special import softmax
import shap
import joblib
import os
from features import extract_all_interpretable_features, get_tfidf_features

def train_interpretable_model(X_train, y_train, X_test, y_test, feature_names):
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)

    rf = RandomForestClassifier(n_estimators=200, max_depth=10, class_weight='balanced', random_state=42)
    rf.fit(X_train_scaled, y_train)

    y_pred = rf.predict(X_test_scaled)
    probs = rf.predict_proba(X_test_scaled)[:, 1]

    print(f"Interpretable Model Accuracy: {accuracy_score(y_test, y_pred)}")
    print(f"Interpretable Model F1: {f1_score(y_test, y_pred)}")

    return rf, scaler

def train_transformer_model(train_texts, train_labels, test_texts, test_labels, model_name="roberta-base"):
    tokenizer = AutoTokenizer.from_pretrained(model_name)
    
    def tokenize_function(examples):
        return tokenizer(examples["text"], truncation=True, padding="max_length", max_length=256)

    train_ds = Dataset.from_dict({"text": train_texts, "label": train_labels})
    test_ds = Dataset.from_dict({"text": test_texts, "label": test_labels})

    tokenized_train = train_ds.map(tokenize_function, batched=True)
    tokenized_test = test_ds.map(tokenize_function, batched=True)

    model = AutoModelForSequenceClassification.from_pretrained(model_name, num_labels=2)

    training_args = TrainingArguments(
        output_dir="./results",
        evaluation_strategy="epoch",
        save_strategy="epoch",
        learning_rate=2e-5,
        per_device_train_batch_size=16,
        per_device_eval_batch_size=32,
        num_train_epochs=3,
        weight_decay=0.01,
        logging_dir='./logs',
    )

    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=tokenized_train,
        eval_dataset=tokenized_test,
    )

    trainer.train()
    return trainer, tokenizer

def hybrid_predict(prob_neural, prob_interpretable, threshold=0.9):
    preds = []
    explanation_needed = []
    for pn, pi in zip(prob_neural, prob_interpretable):
        if pn > threshold or pn < (1 - threshold):
            preds.append(1 if pn > 0.5 else 0)
            explanation_needed.append(False)
        else:
            preds.append(1 if pi > 0.5 else 0)
            explanation_needed.append(True)
    return np.array(preds), explanation_needed

if __name__ == "__main__":
    # This is a skeleton for the training script. 
    # In a real scenario, you would load your prompt-matched data here.
    print("ML Pipeline scripts initialized. Use them to train and evaluate your models.")
