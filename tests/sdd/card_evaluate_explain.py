import sys
import os
import numpy as np
from sorrel_runner import Is, Results, Situation, SorrelRunner, dispatch

# Add scripts/ml to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../scripts/ml')))

from evaluate_explain import evaluate_hybrid_system

@Is
@Situation("Default")
@Results(evaluation_completed=1)
def card_evaluate_explain():
    y_true = [0, 1, 0, 1]
    y_pred = [0, 1, 1, 1]
    exp_needed = [False, False, True, False]

    # Just verify it runs without error as it mostly prints
    evaluate_hybrid_system(y_true, y_pred, exp_needed)

    print("evaluation_completed = 1")

if __name__ == "__main__":
    runner = SorrelRunner()
    dispatch(runner)
