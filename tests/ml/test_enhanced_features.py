import numpy as np
from scripts.ml.features import calculate_mattr, calculate_mtld, calculate_yules_k

def test_lexical_metrics():
    # Simple repetitive text
    words_repetitive = ["apple", "banana", "apple", "banana"] * 25 # 100 words

    mattr = calculate_mattr(words_repetitive, window_size=10)
    mtld = calculate_mtld(words_repetitive)
    yules_k = calculate_yules_k(words_repetitive)

    print(f"Repetitive - MATTR: {mattr:.4f}, MTLD: {mtld:.4f}, YulesK: {yules_k:.4f}")

    assert 0 < mattr <= 1
    assert mtld > 0
    assert yules_k > 0

    # Diverse text
    words_diverse = [str(i) for i in range(100)]

    mattr_d = calculate_mattr(words_diverse, window_size=10)
    mtld_d = calculate_mtld(words_diverse)
    yules_k_d = calculate_yules_k(words_diverse)

    print(f"Diverse - MATTR: {mattr_d:.4f}, MTLD: {mtld_d:.4f}, YulesK: {yules_k_d:.4f}")

    assert mattr_d > mattr
    assert mtld_d > mtld
    assert yules_k_d < yules_k

    print("Lexical metrics verification: PASSED")

def test_morphology_rhythm_metrics():
    import spacy
    nlp = spacy.load("en_core_web_sm")

    text = "The quick brown fox jumps over the lazy dog. He doesn't like apples. I'm happy!"
    doc = nlp(text)

    from scripts.ml.features import flesch_reading_ease
    flesch = flesch_reading_ease(doc)
    print(f"Flesch Reading Ease: {flesch:.4f}")
    assert flesch > 0

    title_count = sum(1 for t in doc if t.text.istitle())
    upper_count = sum(1 for t in doc if t.text.isupper() and len(t.text) > 1)
    cap_ratio = (title_count + upper_count) / len(doc)
    print(f"Cap Ratio: {cap_ratio:.4f}")
    assert cap_ratio > 0

    contractions = {"n't", "'re", "'ve", "'ll", "'s", "'m", "'d"}
    contraction_count = sum(1 for t in doc if t.text.lower() in contractions)
    contraction_freq = contraction_count / len(doc)
    print(f"Contraction Freq: {contraction_freq:.4f}")
    assert contraction_freq > 0

    print("Morphology and rhythm metrics verification: PASSED")

if __name__ == "__main__":
    test_lexical_metrics()
    test_morphology_rhythm_metrics()
