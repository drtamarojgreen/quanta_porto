import pytest
import numpy as np
from hypothesis import given, strategies as st
import sys
import os

# Add scripts/ml to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../scripts/ml')))

from features import (
    stylometric_features,
    passive_voice_ratio,
    sentiment_features,
    entity_density,
    extract_all_interpretable_features
)

def test_stylometric_features_empty():
    texts = ["", "   ", "!!!"]
    feats = stylometric_features(texts)
    assert feats.shape == (3, 13)
    assert np.all(feats == 0)

def test_passive_voice_ratio_empty():
    texts = [""]
    feats = passive_voice_ratio(texts)
    assert feats.shape == (1, 1)
    assert feats[0, 0] == 0

def test_sentiment_features_empty():
    texts = [""]
    feats = sentiment_features(texts)
    assert feats.shape == (1, 8)
    assert np.all(feats == 0)

def test_entity_density_empty():
    texts = [""]
    feats = entity_density(texts)
    assert feats.shape == (1, 2)
    assert np.all(feats == 0)

@given(st.text())
def test_extract_all_interpretable_features_robustness(t):
    # Ensure it doesn't crash and returns no NaNs
    try:
        feats = extract_all_interpretable_features([t])
        assert feats.shape == (1, 24)
        assert not np.any(np.isnan(feats))
        assert not np.any(np.isinf(feats))
    except Exception as e:
        # Some very weird strings might cause issues in spaCy or VADER,
        # but we want to know if it's a "clean" crash.
        pytest.fail(f"Crashed with input {repr(t)}: {e}")

def test_stylometric_features_known_values():
    # Repetitive text to test TTR
    texts = ["word word word word"]
    feats = stylometric_features(texts)
    # TTR = unique words / total words = 1 / 4 = 0.25
    assert feats[0, 0] == 0.25
    # Hapax = 0 / 4 = 0
    assert feats[0, 1] == 0

if __name__ == "__main__":
    # Allow running directly
    pytest.main([__file__])
