import sys
import os
import numpy as np
from sklearn.metrics import accuracy_score, f1_score

# Add scripts/ml to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../scripts/ml')))

from pipeline import train_interpretable_model, hybrid_predict

def test_pipeline():
    # Synthetic data for testing
    np.random.seed(42)
    n_samples = 100
    n_features = 24

    X_train = np.random.rand(n_samples, n_features)
    y_train = np.random.randint(0, 2, n_samples)

    X_test = np.random.rand(20, n_features)
    y_test = np.random.randint(0, 2, 20)

    feature_names = [f"feat_{i}" for i in range(n_features)]

    # Train
    rf, scaler = train_interpretable_model(X_train, y_train, X_test, y_test, feature_names)

    # Predict
    X_test_scaled = scaler.transform(X_test)
    prob_interpretable = rf.predict_proba(X_test_scaled)[:, 1]

    # Mock neural probabilities
    prob_neural = np.random.uniform(0, 1, 20)

    preds, exp_needed = hybrid_predict(prob_neural, prob_interpretable, threshold=0.8)

    # Numeric evidence
    acc = accuracy_score(y_test, preds)
    f1 = f1_score(y_test, preds)
    fallback_ratio = sum(exp_needed) / len(exp_needed)

    print(f"accuracy_score = {acc:.4f}")
    print(f"f1_score = {f1:.4f}")
    print(f"fallback_ratio = {fallback_ratio:.2f}")

    # Validation
    assert 0 <= acc <= 1.0
    assert 0 <= f1 <= 1.0
    assert 0 <= fallback_ratio <= 1.0

    print("exit_code = 0")

if __name__ == "__main__":
    try:
        test_pipeline()
        sys.exit(0)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
