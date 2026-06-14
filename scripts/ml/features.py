import spacy
from collections import Counter
import numpy as np
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
from sklearn.feature_extraction.text import TfidfVectorizer
from scipy.stats import skew, kurtosis
import textstat
import re
from sentence_transformers import SentenceTransformer
from langdetect import detect, DetectorFactory
import html
from markdown import markdown

DetectorFactory.seed = 42
nlp = spacy.load("en_core_web_sm")
analyzer = SentimentIntensityAnalyzer()
model_st = None

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
        # Item 121, 125, 126: Preprocessing
        clean_texts = [self._clean_text(t) for t in texts]

        all_feats = []
        all_names = []
        for group in self._registry.values():
            feats = group["func"](clean_texts)
            all_feats.append(feats)
            all_names.extend(group["names"])
        return np.hstack(all_feats), all_names

    def _clean_text(self, text):
        """Items 121, 125, 126: Markdown and HTML cleaning."""
        # Unescape HTML entities
        text = html.unescape(text)
        # Remove HTML tags if any
        text = re.sub(r'<[^>]*>', '', text)
        # Simple Markdown removal (not full parsing for speed)
        text = re.sub(r'#+\s+', '', text)
        text = re.sub(r'[*_]{1,3}', '', text)
        text = re.sub(r'\[([^\]]+)\]\([^\)]+\)', r'\1', text)
        return text.strip()

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

        pos_counts = Counter([t.pos_ for t in doc])
        total = sum(pos_counts.values())
        noun = pos_counts.get("NOUN", 0) / total if total > 0 else 0
        verb = pos_counts.get("VERB", 0) / total if total > 0 else 0
        adj = pos_counts.get("ADJ", 0) / total if total > 0 else 0
        adv = pos_counts.get("ADV", 0) / total if total > 0 else 0
        pron = pos_counts.get("PRON", 0) / total if total > 0 else 0
        adp = pos_counts.get("ADP", 0) / total if total > 0 else 0
        conj = pos_counts.get("CONJ", 0) / total if total > 0 else 0

        func_words = {"the","a","an","in","on","at","to","for","of","with",
                      "and","or","but","if","because","that","this","it","he","she",
                      "they","we","you","is","are","was","were","be","been","have","has",
                      "do","does","did","will","would","can","could","may","might","shall"}
        func_count = sum(1 for t in words if t in func_words)
        func_ratio = func_count / len(words) if words else 0

        feats.append([ttr, hapax, avg_word_len, sent_len_mean, sent_len_std,
                      noun, verb, adj, adv, pron, adp, conj, func_ratio])
    return np.array(feats)

def multilingual_features(texts):
    feats = []
    for text in texts:
        try:
            lang = detect(text)
            is_en = 1.0 if lang == 'en' else 0.0
        except:
            is_en = 0.0
        feats.append([is_en])
    return np.array(feats)

def detection_signals_features(texts):
    feats = []
    prefaces = {"as an ai", "i cannot", "it is important to note", "in summary", "certainly"}
    for text in texts:
        text_lower = text.lower()
        residue_count = sum(1 for p in prefaces if p in text_lower)
        feats.append([residue_count / (len(text.split()) + 1)])
    return np.array(feats)

def advanced_pos_features(texts):
    feats = []
    for doc in nlp.pipe(texts, batch_size=256):
        N = len(doc)
        pos_counts = Counter([t.pos_ for t in doc])
        total = sum(pos_counts.values())
        propn = pos_counts.get("PROPN", 0) / total if total > 0 else 0
        num = pos_counts.get("NUM", 0) / total if total > 0 else 0
        aux = pos_counts.get("AUX", 0) / total if total > 0 else 0
        part = pos_counts.get("PART", 0) / total if total > 0 else 0
        first_person = sum(1 for t in doc if t.morph.get("Person") == ["1"]) / N if N else 0
        modals = {"must", "should", "could", "might", "would", "may", "can", "will"}
        modal_ratio = sum(1 for t in doc if t.text.lower() in modals) / N if N else 0
        negations = sum(1 for t in doc if t.dep_ == "neg") / N if N else 0
        feats.append([propn, num, aux, part, first_person, modal_ratio, negations])
    return np.array(feats)

def discourse_features(texts):
    feats = []
    contrast_markers = {"however", "but", "yet", "although", "though", "nevertheless", "nonetheless"}
    sequence_markers = {"first", "second", "then", "next", "finally", "lastly"}
    for doc in nlp.pipe(texts, batch_size=256):
        N = len(doc)
        text = doc.text.lower()
        contrast_count = sum(1 for m in contrast_markers if m in text) / N if N else 0
        sequence_count = sum(1 for m in sequence_markers if m in text) / N if N else 0
        list_like = len(re.findall(r'^\s*[-*•\d+.]\s+', doc.text, re.M)) / len(list(doc.sents)) if list(doc.sents) else 0
        feats.append([contrast_count, sequence_count, list_like])
    return np.array(feats)

def semantic_transformer_features(texts):
    global model_st
    if model_st is None:
        model_st = SentenceTransformer('all-MiniLM-L6-v2')
    embeddings = model_st.encode(texts)
    return np.hstack([np.mean(embeddings, axis=1, keepdims=True), np.std(embeddings, axis=1, keepdims=True)])

def grounding_factual_features(texts):
    feats = []
    for doc in nlp.pipe(texts, batch_size=256):
        N = len(list(doc.sents))
        if not N:
            feats.append([0]*4); continue
        person = len([e for e in doc.ents if e.label_ == "PERSON"]) / N
        org = len([e for e in doc.ents if e.label_ == "ORG"]) / N
        gpe = len([e for e in doc.ents if e.label_ == "GPE"]) / N
        facts = len(doc.ents) + sum(1 for t in doc if t.like_num)
        fact_density = facts / N
        feats.append([person, org, gpe, fact_density])
    return np.array(feats)

def sentiment_emotion_features(texts):
    feats = []
    hedging_markers = {"perhaps", "likely", "possibly", "maybe", "probably", "clearly", "undoubtedly"}
    for doc in nlp.pipe(texts, batch_size=256):
        sents = [s.text for s in doc.sents]
        scores = [analyzer.polarity_scores(s) for s in sents]
        if not scores:
            feats.append([0, 0, 0, 0, 0, 0, 0, 0, 0])
            continue
        compound = [s['compound'] for s in scores]
        pos = [s['pos'] for s in scores]
        neg = [s['neg'] for s in scores]
        neu = [s['neu'] for s in scores]
        hedging = sum(1 for t in doc if t.text.lower() in hedging_markers) / len(doc) if len(doc) else 0
        feats.append([np.mean(compound), np.std(compound),
                      np.mean(pos), np.std(pos),
                      np.mean(neg), np.std(neg),
                      np.mean(neu), np.std(neu),
                      hedging])
    return np.array(feats)

def advanced_lexical_features(texts, window_size=50):
    feats = []
    for doc in nlp.pipe(texts, batch_size=256):
        words = [t.text.lower() for t in doc if t.is_alpha and not t.is_punct]
        N = len(words)
        if N == 0:
            feats.append([0]*4); continue
        if N < window_size:
            mattr = len(set(words)) / N
        else:
            ttrs = []
            for i in range(N - window_size + 1):
                window = words[i:i+window_size]
                ttrs.append(len(set(window)) / window_size)
            mattr = np.mean(ttrs)
        cttr = len(set(words)) / np.sqrt(2 * N)
        m1 = N
        m2 = sum(f**2 for f in Counter(words).values())
        yules_k = 10000 * (m2 - m1) / (m1**2) if m1 > 1 else 0
        mtld = N / (len(set(words)) + 1e-10)
        feats.append([mattr, cttr, yules_k, mtld])
    return np.array(feats)

def morphology_casing_features(texts):
    feats = []
    for doc in nlp.pipe(texts, batch_size=256):
        N = len(doc)
        if N == 0:
            feats.append([0]*6); continue
        lemmas = set(t.lemma_ for t in doc if t.is_alpha)
        surface = set(t.text.lower() for t in doc if t.is_alpha)
        inflect_var = len(lemmas) / len(surface) if surface else 0
        title_case = sum(1 for t in doc if t.text.istitle()) / N
        all_caps = sum(1 for t in doc if t.text.isupper()) / N
        contractions = sum(1 for t in doc if "'" in t.text) / N
        nums = sum(1 for t in doc if t.like_num) / N
        dates = sum(1 for t in doc if t.ent_type_ == "DATE") / N
        feats.append([inflect_var, title_case, all_caps, contractions, nums, dates])
    return np.array(feats)

def rhythm_readability_features(texts):
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

def _get_tree_depth(node):
    if not list(node.children):
        return 1
    return 1 + max(_get_tree_depth(child) for child in node.children)

def advanced_syntax_features(texts):
    feats = []
    for doc in nlp.pipe(texts, batch_size=256):
        depths = []
        sub_clauses = 0
        total_tokens = len(doc)
        for sent in doc.sents:
            depths.append(_get_tree_depth(sent.root))
            for token in sent:
                if token.dep_ in ["advcl", "relcl", "ccomp", "xcomp"]:
                    sub_clauses += 1
        avg_depth = np.mean(depths) if depths else 0
        sub_ratio = sub_clauses / total_tokens if total_tokens > 0 else 0
        feats.append([avg_depth, sub_ratio])
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
registry.register("advanced_lexical", advanced_lexical_features, ["MATTR", "CTTR", "YulesK", "MTLD"])
registry.register("morphology_casing", morphology_casing_features, ["InflectVar", "TitleCase", "AllCaps", "Contractions", "NumRatio", "DateRatio"])
registry.register("advanced_pos", advanced_pos_features, ["PropnRatio", "NumRatio_POS", "AuxRatio", "PartRatio", "FirstPersonRatio", "ModalRatio", "NegationRatio"])
registry.register("advanced_syntax", advanced_syntax_features, ["AvgTreeDepth", "SubordinateRatio"])
registry.register("discourse", discourse_features, ["ContrastRatio", "SequenceRatio", "ListDensity"])
registry.register("rhythm_readability", rhythm_readability_features, [
    "MedSentLen", "SkewSentLen", "KurtSentLen", "FleschEase", "FleschGrade"
])
registry.register("passive", passive_voice_ratio, ["PassiveRatio"])
registry.register("sentiment_emotion", sentiment_emotion_features, [
    "SentCompoundMean", "SentCompoundStd", "SentPosMean", "SentPosStd",
    "SentNegMean", "SentNegStd", "SentNeuMean", "SentNeuStd", "HedgingRatio"
])
registry.register("semantic", semantic_transformer_features, ["EmbedMean", "EmbedStd"])
registry.register("grounding", grounding_factual_features, ["PersonDensity", "OrgDensity", "GpeDensity", "FactDensity"])
registry.register("multilingual", multilingual_features, ["IsEnglish"])
registry.register("detection", detection_signals_features, ["ResidueRatio"])
registry.register("entity_legacy", entity_density, ["EntDensity_Legacy", "NounDiversity_Legacy"])

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
    return registry.extract_all(texts)
