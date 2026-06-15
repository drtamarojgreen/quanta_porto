import sys
import os
import numpy as np
from sklearn.metrics import accuracy_score, f1_score
from sorrel_runner import Is, Results, Situation, SorrelRunner, dispatch

# Add scripts/ml to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../scripts/ml')))

from pipeline import train_interpretable_model, hybrid_predict

@Is("python_available", 1)
@Situation("Default")
def card_pipeline():
    np.random.seed(42)
    n_features = 71
    X_train = np.random.rand(100, n_features)
    y_train = np.random.randint(0, 2, 100)
    X_test = np.random.rand(20, n_features)
    y_test = np.random.randint(0, 2, 20)

    feature_names = [f"feat_{i}" for i in range(n_features)]
    rf, scaler = train_interpretable_model(X_train, y_train, X_test, y_test, feature_names)

    X_test_scaled = scaler.transform(X_test)
    prob_interpretable = rf.predict_proba(X_test_scaled)[:, 1]
    prob_neural = np.random.uniform(0, 1, 20)
    preds, exp_needed = hybrid_predict(prob_neural, prob_interpretable, threshold=0.8)

    print(f"accuracy_score = {accuracy_score(y_test, preds)}")
    print(f"exit_code = 0")

if __name__ == "__main__":
    runner = SorrelRunner()
    dispatch(runner)
