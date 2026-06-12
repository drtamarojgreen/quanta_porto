import spacy
from collections import Counter
import numpy as np
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
from sklearn.feature_extraction.text import TfidfVectorizer

nlp = spacy.load("en_core_web_sm")
analyzer = SentimentIntensityAnalyzer()

def stylometric_features(texts):
    feats = []
    for doc in nlp.pipe(texts, batch_size=256):
        tokens = [t.text.lower() for t in doc if t.is_alpha]
        words = [t for t in tokens if not t.is_punct]
        if not words:
            feats.append([0]*13); continue
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

        feats.append([ttr, hapax, avg_word_len, sent_len_mean, sent_len_std,
                      noun, verb, adj, adv, pron, adp, conj, func_ratio])
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
    for text in texts:
        doc = nlp(text)
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

def extract_all_interpretable_features(texts):
    print("Extracting stylometric features...")
    sty = stylometric_features(texts)
    print("Extracting passive voice ratio...")
    pas = passive_voice_ratio(texts)
    print("Extracting sentiment features...")
    sent = sentiment_features(texts)
    print("Extracting entity density...")
    ent = entity_density(texts)
    return np.hstack([sty, pas, sent, ent])
