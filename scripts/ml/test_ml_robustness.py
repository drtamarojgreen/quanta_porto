import pytest
import numpy as np
from hypothesis import given, strategies as st
import sys
import os

# Add scripts/ml to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../scripts/ml')))

from features import extract_all_interpretable_features

def test_extract_all_interpretable_features_basic():
    texts = ["The quick brown fox jumps over the lazy dog.", "Hello world!"]
    feats, names = extract_all_interpretable_features(texts)
    assert feats.shape[0] == 2
    assert len(names) == feats.shape[1]
    assert "MATTR" in names
    assert "FleschEase" in names
    assert "AvgTreeDepth" in names

@given(st.text())
def test_extract_all_interpretable_features_robustness(t):
    # Item 183, 184: Ensure no crashes and no NaNs
    try:
        feats, names = extract_all_interpretable_features([t])
        assert not np.any(np.isnan(feats))
        assert not np.any(np.isinf(feats))
    except Exception as e:
        pytest.fail(f"Crashed with input {repr(t)}: {e}")

def test_mattr_known_values():
    from features import advanced_lexical_features
    # If window_size=50 and text is short, it should be same as TTR
    text = ["word " * 10]
    feats = advanced_lexical_features(text, window_size=50)
    assert feats[0, 0] == 0.1 # 1 unique / 10 total

def test_readability_known_values():
    from features import rhythm_readability_features
    text = ["The cat sat on the mat."]
    feats = rhythm_readability_features(text)
    # flesch ease for simple sentence should be high
    assert feats[0, 3] > 100

if __name__ == "__main__":
    pytest.main([__file__])
