import sys
import os
import numpy as np

# Add scripts/ml to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../scripts/ml')))

from evaluate_explain import evaluate_hybrid_system

def test_evaluate_explain():
    y_true = [0, 1, 0, 1]
    y_pred = [0, 1, 1, 1]
    exp_needed = [False, False, True, False]

    # Just verify it runs without error as it mostly prints
    evaluate_hybrid_system(y_true, y_pred, exp_needed)

    # Check for expected side effects if any were planned (like saving plots)
    # The original explain_interpretable_model saves 'shap_summary.png'
    # but evaluate_hybrid_system just prints.

    print("evaluation_completed = 1")
    sys.exit(0)

if __name__ == "__main__":
    try:
        test_evaluate_explain()
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
