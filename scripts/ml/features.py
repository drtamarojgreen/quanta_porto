import spacy
from collections import Counter
import numpy as np
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
from sklearn.feature_extraction.text import TfidfVectorizer
from scipy.stats import skew, kurtosis
import textstat

nlp = spacy.load("en_core_web_sm")
analyzer = SentimentIntensityAnalyzer()

class FeatureRegistry:
    """Item 131: Feature Registry for modular management."""
    def __init__(self):
        self._registry = {}

    def register(self, group_name, func, feature_names):
        """Register a feature extraction function."""
        self._registry[group_name] = {
            "func": func,
            "names": feature_names
        }

    def extract_all(self, texts):
        """Item 132: Return feature names alongside arrays."""
        all_feats = []
        all_names = []
        for group in self._registry.values():
            feats = group["func"](texts)
            all_feats.append(feats)
            all_names.extend(group["names"])
        return np.hstack(all_feats), all_names

def stylometric_features(texts):
    feats = []
    for doc in nlp.pipe(texts, batch_size=256):
        words = [t.text.lower() for t in doc if t.is_alpha and not t.is_punct]
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
        func_count = sum(1 for t in words if t in func_words)
        func_ratio = func_count / len(words) if words else 0

        feats.append([ttr, hapax, avg_word_len, sent_len_mean, sent_len_std,
                      noun, verb, adj, adv, pron, adp, conj, func_ratio])
    return np.array(feats)

def advanced_pos_features(texts):
    """Item 31: Granular POS."""
    feats = []
    for doc in nlp.pipe(texts, batch_size=256):
        pos_counts = Counter([t.pos_ for t in doc])
        total = sum(pos_counts.values())
        propn = pos_counts.get("PROPN", 0) / total if total > 0 else 0
        num = pos_counts.get("NUM", 0) / total if total > 0 else 0
        aux = pos_counts.get("AUX", 0) / total if total > 0 else 0
        part = pos_counts.get("PART", 0) / total if total > 0 else 0
        feats.append([propn, num, aux, part])
    return np.array(feats)

def _get_tree_depth(node):
    if not list(node.children):
        return 1
    return 1 + max(_get_tree_depth(child) for child in node.children)

def advanced_syntax_features(texts):
    """Items 43, 45: Tree depth and subordination."""
    feats = []
    for doc in nlp.pipe(texts, batch_size=256):
        depths = []
        sub_clauses = 0
        total_tokens = len(doc)

        for sent in doc.sents:
            # Tree depth
            depths.append(_get_tree_depth(sent.root))

            # Subordination (sconj or advcl)
            for token in sent:
                if token.dep_ in ["advcl", "relcl", "ccomp", "xcomp"]:
                    sub_clauses += 1

        avg_depth = np.mean(depths) if depths else 0
        sub_ratio = sub_clauses / total_tokens if total_tokens > 0 else 0
        feats.append([avg_depth, sub_ratio])
    return np.array(feats)

def advanced_lexical_features(texts, window_size=50):
    """Item 1: Moving-Window TTR (MATTR)."""
    feats = []
    for doc in nlp.pipe(texts, batch_size=256):
        words = [t.text.lower() for t in doc if t.is_alpha and not t.is_punct]
        if len(words) < window_size:
            mattr = len(set(words)) / len(words) if words else 0
        else:
            ttrs = []
            for i in range(len(words) - window_size + 1):
                window = words[i:i+window_size]
                ttrs.append(len(set(window)) / window_size)
            mattr = np.mean(ttrs)
        feats.append([mattr])
    return np.array(feats)

def rhythm_readability_features(texts):
    """Items 21, 22, 27, 61: Readability and pacing with batched parsing."""
    feats = []
    for doc in nlp.pipe(texts, batch_size=256):
        text = doc.text
        sent_lens = [len(s) for s in doc.sents if len(s) > 0]
        if not sent_lens:
            feats.append([0, 0, 0, 0, 0])
            continue

        med_sent_len = np.median(sent_lens)
        skew_sent_len = skew(sent_lens) if len(sent_lens) > 2 else 0
        kurt_sent_len = kurtosis(sent_lens) if len(sent_lens) > 2 else 0

        flesch_ease = textstat.flesch_reading_ease(text)
        flesch_grade = textstat.flesch_kincaid_grade(text)

        feats.append([med_sent_len, skew_sent_len, kurt_sent_len, flesch_ease, flesch_grade])
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

# Initialize registry and register features
registry = FeatureRegistry()
registry.register("stylometric", stylometric_features, [
    "TTR", "Hapax", "AvgWordLen", "SentLenMean", "SentLenStd",
    "NounRatio", "VerbRatio", "AdjRatio", "AdvRatio", "PronRatio", "AdpRatio", "ConjRatio", "FuncWordRatio"
])
registry.register("advanced_pos", advanced_pos_features, ["PropnRatio", "NumRatio", "AuxRatio", "PartRatio"])
registry.register("advanced_syntax", advanced_syntax_features, ["AvgTreeDepth", "SubordinateRatio"])
registry.register("advanced_lexical", advanced_lexical_features, ["MATTR"])
registry.register("rhythm_readability", rhythm_readability_features, [
    "MedSentLen", "SkewSentLen", "KurtSentLen", "FleschEase", "FleschGrade"
])
registry.register("passive", passive_voice_ratio, ["PassiveRatio"])
registry.register("sentiment", sentiment_features, [
    "SentCompoundMean", "SentCompoundStd", "SentPosMean", "SentPosStd",
    "SentNegMean", "SentNegStd", "SentNeuMean", "SentNeuStd"
])
registry.register("entity", entity_density, ["EntDensity", "NounDiversity"])

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
    """Refactored to use FeatureRegistry."""
    return registry.extract_all(texts)
