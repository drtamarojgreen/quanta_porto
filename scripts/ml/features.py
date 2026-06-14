import spacy
from collections import Counter
import numpy as np
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
from sklearn.feature_extraction.text import TfidfVectorizer
import pandas as pd
import os

nlp = spacy.load("en_core_web_sm")
analyzer = SentimentIntensityAnalyzer()

def calculate_mattr(words, window_size=50):
    if len(words) < window_size:
        return len(set(words)) / len(words) if words else 0
    ttrs = []
    for i in range(len(words) - window_size + 1):
        window = words[i:i+window_size]
        ttrs.append(len(set(window)) / window_size)
    return np.mean(ttrs)

def calculate_mtld(words, threshold=0.72):
    def mtld_base(tokens):
        if not tokens: return 0
        factors = 0
        now_ttr = 1.0
        types = set()
        count = 0
        for t in tokens:
            count += 1
            types.add(t)
            now_ttr = len(types) / count
            if now_ttr < threshold:
                factors += 1
                types = set()
                count = 0
                now_ttr = 1.0
        if count > 0:
            excess = (1.0 - now_ttr) / (1.0 - threshold)
            factors += excess
        return len(tokens) / factors if factors > 0 else len(tokens)

    forward = mtld_base(words)
    backward = mtld_base(words[::-1])
    if forward > 0 and backward > 0:
        return (forward + backward) / 2
    return forward or backward

def calculate_yules_k(words):
    if not words: return 0
    n = len(words)
    counts = Counter(words)
    m1 = n
    m2 = sum(count**2 for count in counts.values())
    return 10000 * (m2 - m1) / (n**2)

def count_syllables(word):
    word = word.lower()
    count = 0
    vowels = "aeiouy"
    if word[0] in vowels:
        count += 1
    for index in range(1, len(word)):
        if word[index] in vowels and word[index - 1] not in vowels:
            count += 1
    if word.endswith("e"):
        count -= 1
    if count == 0:
        count += 1
    return count

def flesch_reading_ease(doc):
    words = [t for t in doc if not t.is_punct and not t.is_space]
    sentences = list(doc.sents)
    if not words or not sentences:
        return 0

    avg_sentence_length = len(words) / len(sentences)
    avg_syllables_per_word = sum(count_syllables(w.text) for w in words) / len(words)

    score = 206.835 - (1.015 * avg_sentence_length) - (84.6 * avg_syllables_per_word)
    return score

def stylometric_features(texts):
    feats = []
    for doc in nlp.pipe(texts, batch_size=256):
        tokens = [t.text.lower() for t in doc if t.is_alpha]
        words = [t.text.lower() for t in doc if not t.is_punct and not t.is_space]
        if not words:
            feats.append([0]*19); continue
        ttr = len(set(words)) / len(words)
        hapax = sum(1 for w in set(words) if words.count(w) == 1) / len(words)
        avg_word_len = np.mean([len(w) for w in words])
        sent_lens = [len(s) for s in doc.sents if len(s) > 0]
        sent_len_mean = np.mean(sent_lens) if sent_lens else 0
        sent_len_std = np.std(sent_lens) if sent_lens else 0

        # POS distributions (universal tags)
        pos_counts = Counter([t.pos_ for t in doc])
        total = sum(pos_counts.values())
        noun = pos_counts.get("NOUN", 0) / total if total > 0 else 0
        verb = pos_counts.get("VERB", 0) / total if total > 0 else 0
        adj = pos_counts.get("ADJ", 0) / total if total > 0 else 0
        adv = pos_counts.get("ADV", 0) / total if total > 0 else 0
        pron = pos_counts.get("PRON", 0) / total if total > 0 else 0
        adp = pos_counts.get("ADP", 0) / total if total > 0 else 0  # prepositions
        conj = pos_counts.get("CONJ", 0) / total if total > 0 else 0

        # Function word ratio
        func_words = {"the","a","an","in","on","at","to","for","of","with",
                      "and","or","but","if","because","that","this","it","he","she",
                      "they","we","you","is","are","was","were","be","been","have","has",
                      "do","does","did","will","would","can","could","may","might","shall"}
        func_count = sum(1 for t in tokens if t in func_words)
        func_ratio = func_count / len(tokens) if tokens else 0

        mattr = calculate_mattr(words)
        mtld = calculate_mtld(words)
        yules_k = calculate_yules_k(words)

        # Capitalization patterns (B.13)
        title_count = sum(1 for t in doc if t.text.istitle())
        upper_count = sum(1 for t in doc if t.text.isupper() and len(t.text) > 1)
        cap_ratio = (title_count + upper_count) / len(doc) if len(doc) > 0 else 0

        # Contraction frequency (B.15)
        # spaCy splits contractions into multiple tokens (e.g., "don't" -> ["do", "n't"])
        # We can look for tokens like "n't", "'re", "'ve", etc.
        contractions = {"n't", "'re", "'ve", "'ll", "'s", "'m", "'d"}
        contraction_count = sum(1 for t in doc if t.text.lower() in contractions)
        contraction_freq = contraction_count / len(doc) if len(doc) > 0 else 0

        # Flesch Reading Ease (C.27)
        flesch_score = flesch_reading_ease(doc)

        feats.append([ttr, hapax, avg_word_len, sent_len_mean, sent_len_std,
                      noun, verb, adj, adv, pron, adp, conj, func_ratio,
                      mattr, mtld, yules_k, cap_ratio, contraction_freq, flesch_score])
    return np.array(feats)

def passive_voice_ratio(texts):
    ratios = []
    for doc in nlp.pipe(texts, batch_size=256):
        passive = 0
        total_clauses = 0
        for sent in doc.sents:
            for token in sent:
                if token.dep_ == "nsubjpass":
                    passive += 1
            total_clauses += sum(1 for t in sent if t.pos_ == "VERB")
        ratio = passive / total_clauses if total_clauses > 0 else 0
        ratios.append(ratio)
    return np.array(ratios).reshape(-1, 1)

def sentiment_features(texts):
    feats = []
    for doc in nlp.pipe(texts, batch_size=256):
        sents = [s.text for s in doc.sents]
        scores = [analyzer.polarity_scores(s) for s in sents]
        if not scores:
            feats.append([0, 0, 0, 0, 0, 0, 0, 0])
            continue
        compound = [s['compound'] for s in scores]
        pos = [s['pos'] for s in scores]
        neg = [s['neg'] for s in scores]
        neu = [s['neu'] for s in scores]
        feats.append([np.mean(compound), np.std(compound),
                      np.mean(pos), np.std(pos),
                      np.mean(neg), np.std(neg),
                      np.mean(neu), np.std(neu)])
    return np.array(feats)

def entity_density(texts):
    densities = []
    for doc in nlp.pipe(texts):
        entities = set([ent.text for ent in doc.ents])
        nouns = [t.lemma_ for t in doc if t.pos_ == "NOUN"]
        total_nouns = len(nouns)
        unique_nouns = len(set(nouns))
        n_sents = len(list(doc.sents))
        ent_density = len(entities) / n_sents if n_sents else 0
        noun_diversity = unique_nouns / total_nouns if total_nouns else 0
        densities.append([ent_density, noun_diversity])
    return np.array(densities)

def categorical_word_features(texts, mapping_path="scripts/ml/words.csv"):
    """
    Extracts features based on the categorical classification of words (leaning and dimension).
    """
    if not os.path.exists(mapping_path):
        # Fallback if no mapping exists yet
        return np.zeros((len(texts), 3))

    df = pd.read_csv(mapping_path)
    # Create fast lookup dicts
    lean_map = dict(zip(df['word'], df['lean']))
    dim_map = dict(zip(df['word'], df['dimension']))

    feats = []
    for doc in nlp.pipe(texts, batch_size=256):
        tokens = [t.text.lower() for t in doc if t.is_alpha]
        if not tokens:
            feats.append([0, 0, 0]); continue

        h_count = sum(1 for t in tokens if lean_map.get(t) == "Human-leaning")
        l_count = sum(1 for t in tokens if lean_map.get(t) == "LLM-leaning")

        h_ratio = h_count / len(tokens)
        l_ratio = l_count / len(tokens)

        # Dominant dimension (dimension with most words in this text)
        dim_counts = Counter([dim_map.get(t) for t in tokens if dim_map.get(t)])
        # We just take the count of the most frequent dimension as a simple feature
        top_dim_count = dim_counts.most_common(1)[0][1] / len(tokens) if dim_counts else 0

        feats.append([h_ratio, l_ratio, top_dim_count])

    return np.array(feats)

def get_tfidf_features(train_texts, test_texts, max_features=500):
    vec = TfidfVectorizer(
        max_features=max_features,
        stop_words='english',
        ngram_range=(1,2),
        min_df=5
    )
    train_tfidf = vec.fit_transform(train_texts)
    test_tfidf = vec.transform(test_texts)
    return train_tfidf, test_tfidf, vec

def extract_all_interpretable_features(texts, mapping_path="scripts/ml/words.csv"):
    print("Extracting stylometric features...")
    sty = stylometric_features(texts)
    print("Extracting passive voice ratio...")
    pas = passive_voice_ratio(texts)
    print("Extracting sentiment features...")
    sent = sentiment_features(texts)
    print("Extracting entity density...")
    ent = entity_density(texts)
    print("Extracting categorical word features...")
    cat = categorical_word_features(texts, mapping_path)
    return np.hstack([sty, pas, sent, ent, cat])
