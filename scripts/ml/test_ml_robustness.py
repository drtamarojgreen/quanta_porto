import pytest
import numpy as np
from hypothesis import given, strategies as st
import sys
import os

# Add scripts/ml to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../ml')))

from features import extract_all_interpretable_features

def test_extract_all_interpretable_features_basic():
    texts = ["The quick brown fox jumps over the lazy dog.", "Hello world!"]
    feats, names = extract_all_interpretable_features(texts)
    assert feats.shape[0] == 2
    assert len(names) == feats.shape[1]

@given(st.text())
def test_extract_all_interpretable_features_robustness(t):
    try:
        feats, names = extract_all_interpretable_features([t])
        assert not np.any(np.isnan(feats))
        assert not np.any(np.isinf(feats))
    except Exception as e:
        pytest.fail(f"Crashed with input {repr(t)}: {e}")

if __name__ == "__main__":
    pytest.main([__file__])
