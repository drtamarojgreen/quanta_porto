import shap
import matplotlib.pyplot as plt
from sklearn.metrics import classification_report, confusion_matrix
import numpy as np

def explain_interpretable_model(model, X_test, feature_names):
    explainer = shap.TreeExplainer(model)
    shap_values = explainer.shap_values(X_test)
    
    # Summary plot
    shap.summary_plot(shap_values[1], X_test, feature_names=feature_names, show=False)
    plt.savefig('shap_summary.png')
    print("SHAP summary plot saved to shap_summary.png")

def evaluate_hybrid_system(y_true, y_pred, explanation_needed):
    print("Hybrid System Evaluation:")
    print(classification_report(y_true, y_pred))
    
    fallback_count = sum(explanation_needed)
    total = len(explanation_needed)
    print(f"Fallback to Interpretable Model: {fallback_count}/{total} ({fallback_count/total:.2%})")

def ablation_study(train_fn, X_train, y_train, X_test, y_test, feature_names):
    # Example: remove sentiment features (indices 14 to 21 based on features.py)
    # This is highly dependent on the final feature vector structure
    pass
