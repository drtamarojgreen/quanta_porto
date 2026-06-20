import spacy
from collections import Counter
import numpy as np
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
from sklearn.feature_extraction.text import TfidfVectorizer
import pandas as pd
import os
from scipy.stats import hypergeom, skew, kurtosis
import textstat

nlp = spacy.load("en_core_web_sm")
analyzer = SentimentIntensityAnalyzer()

class FeatureRegistry:
    """Central registry for feature extraction functions and metadata."""
    def __init__(self):
        self.features = []
        self.groups = {}

    def register(self, group_name, feature_names):
        def decorator(func):
            self.features.append({
                "group": group_name,
                "names": feature_names,
                "func": func
            })
            if group_name not in self.groups:
                self.groups[group_name] = []
            self.groups[group_name].extend(feature_names)
            return func
        return decorator

    def get_all_names(self):
        all_names = []
        for feat in self.features:
            all_names.extend(feat["names"])
        return all_names

registry = FeatureRegistry()

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

def calculate_hdd(words, sample_size=42):
    """Hypergeometric Distribution D (HD-D). Simplified approximation."""
    if len(words) < sample_size:
        return len(set(words)) / len(words) if words else 0
    counts = Counter(words)
    n = len(words)
    sum_prob = 0
    for word, freq in counts.items():
        # Probability that this word appears at least once in a sample of sample_size
        # 1 - P(none in sample)
        p_none = hypergeom.pmf(0, n, freq, sample_size)
        sum_prob += (1 - p_none)
    return sum_prob / sample_size

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

@registry.register("stylometric", [
    "TTR", "Hapax", "AvgWordLen", "SentLenMean", "SentLenStd",
    "NounRatio", "VerbRatio", "AdjRatio", "AdvRatio", "PronRatio", "AdpRatio", "ConjRatio", "FuncWordRatio",
    "MATTR", "MTLD", "YulesK", "CapRatio", "ContractionFreq", "FleschEase",
    "HDD", "RootTTR", "CorrectedTTR", "ContentTTR", "FuncTTR", "RareWordRatio", "FillerWordRatio",
    "InflectionalVariety", "LemmaSurfaceRatio", "PunctNormWordLen", "TypoRatio", "ElongatedRatio", "NumericRatio",
    "SentLenMedian", "SentLenSkew", "SentLenKurt", "ShortSentRatio", "LongSentRatio",
    "SMOG", "GunningFog", "ColemanLiau", "ARI", "SentStartDiversity", "QuestionRatio",
    "DetRatio", "AuxRatio", "PartRatio", "PropnRatio", "InterjRatio", "POSEntropy",
    "FirstPersonRatio", "SecondPersonRatio", "ThirdPersonRatio", "NegationRatio"
])
def stylometric_features(texts):
    feats = []
    for doc in nlp.pipe(texts, batch_size=256):
        tokens = [t.text.lower() for t in doc if t.is_alpha]
        words = [t.text.lower() for t in doc if not t.is_punct and not t.is_space]
        if not words:
            feats.append([0]*53); continue
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
        det = pos_counts.get("DET", 0) / total if total > 0 else 0
        aux = pos_counts.get("AUX", 0) / total if total > 0 else 0
        part = pos_counts.get("PART", 0) / total if total > 0 else 0
        propn = pos_counts.get("PROPN", 0) / total if total > 0 else 0
        interj = pos_counts.get("INTJ", 0) / total if total > 0 else 0

        # POS Entropy (D.34)
        probs = [c / total for c in pos_counts.values()]
        pos_entropy = -sum(p * np.log2(p) for p in probs) if probs else 0

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
        hdd = calculate_hdd(words)
        root_ttr = len(set(words)) / np.sqrt(len(words)) if words else 0
        corrected_ttr = len(set(words)) / np.sqrt(2 * len(words)) if words else 0

        content_pos = {"NOUN", "VERB", "ADJ", "ADV"}
        content_words = [t.text.lower() for t in doc if t.pos_ in content_pos]
        func_words_list = [t.text.lower() for t in doc if t.pos_ not in content_pos and not t.is_punct and not t.is_space]

        content_ttr = len(set(content_words)) / len(content_words) if content_words else 0
        func_ttr = len(set(func_words_list)) / len(func_words_list) if func_words_list else 0

        # Rare word ratio (A.7) - approximation using hapax for now or we could use a word freq model
        rare_word_ratio = hapax # simplified

        # Filler words (A.8)
        fillers = {"important", "various", "significant", "many", "actually", "basically", "very", "really"}
        filler_count = sum(1 for w in words if w in fillers)
        filler_ratio = filler_count / len(words) if words else 0

        # Batch B Features
        # Inflectional variety (B.11)
        lemmas = [t.lemma_ for t in doc if t.is_alpha]
        inflectional_variety = len(set(words)) / len(set(lemmas)) if set(lemmas) else 1.0

        # Lemma-surface ratio (B.12)
        lemma_surface_ratio = len(set(lemmas)) / len(words) if words else 0

        # Punct-normalized word length (B.14)
        punct_norm_word_len = np.mean([len(w) for w in words]) if words else 0

        # Typo detection (B.16) - simple heuristic: words with no vowels or weird consonant clusters
        vowels = set("aeiou")
        def is_typo_heuristic(w):
            if len(w) > 3 and not any(c in vowels for c in w.lower()): return True
            return False
        typo_count = sum(1 for w in words if is_typo_heuristic(w))
        typo_ratio = typo_count / len(words) if words else 0

        # Elongated words (B.17) e.g. sooo
        import re
        elongated_pattern = re.compile(r"(.)\1{2,}") # 3 or more repeated characters
        elongated_count = sum(1 for w in words if elongated_pattern.search(w))
        elongated_ratio = elongated_count / len(words) if words else 0

        # Numeric profiles (B.19)
        num_count = sum(1 for t in doc if t.like_num or t.pos_ == "NUM")
        numeric_ratio = num_count / len(doc) if len(doc) > 0 else 0

        # Batch C Features
        sent_lens = [len([t for t in s if not t.is_punct]) for s in doc.sents if len(s) > 0]
        sent_len_median = np.median(sent_lens) if sent_lens else 0
        sent_len_skew = skew(sent_lens) if len(sent_lens) > 2 else 0
        sent_len_kurt = kurtosis(sent_lens) if len(sent_lens) > 2 else 0

        short_sent_count = sum(1 for l in sent_lens if l < 10)
        long_sent_count = sum(1 for l in sent_lens if l > 30)
        short_sent_ratio = short_sent_count / len(sent_lens) if sent_lens else 0
        long_sent_ratio = long_sent_count / len(sent_lens) if sent_lens else 0

        raw_text = doc.text
        smog = textstat.smog_index(raw_text)
        gunning_fog = textstat.gunning_fog(raw_text)
        coleman_liau = textstat.coleman_liau_index(raw_text)
        ari = textstat.automated_readability_index(raw_text)

        sent_starts = [s[0].text.lower() for s in doc.sents if len(s) > 0]
        sent_start_diversity = len(set(sent_starts)) / len(sent_starts) if sent_starts else 0

        question_count = sum(1 for s in doc.sents if s.text.strip().endswith("?"))
        question_ratio = question_count / len(list(doc.sents)) if list(doc.sents) else 0

        # Pronoun subtypes (D.35)
        first_person = {"i", "me", "my", "mine", "we", "us", "our", "ours"}
        second_person = {"you", "your", "yours"}
        third_person = {"he", "him", "his", "she", "her", "hers", "it", "its", "they", "them", "their", "theirs"}

        pronouns = [t.text.lower() for t in doc if t.pos_ == "PRON"]
        first_count = sum(1 for p in pronouns if p in first_person)
        second_count = sum(1 for p in pronouns if p in second_person)
        third_count = sum(1 for p in pronouns if p in third_person)

        first_ratio = first_count / total if total > 0 else 0
        second_ratio = second_count / total if total > 0 else 0
        third_ratio = third_count / total if total > 0 else 0

        # Negation frequency (D.38)
        negations = {"no", "not", "none", "neither", "never", "nobody", "nowhere", "nothing"}
        # also check for tokens with dep 'neg' or ending in n't
        neg_count = sum(1 for t in doc if t.text.lower() in negations or t.dep_ == "neg" or t.text.lower().endswith("n't"))
        neg_ratio = neg_count / total if total > 0 else 0

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
                      mattr, mtld, yules_k, cap_ratio, contraction_freq, flesch_score,
                      hdd, root_ttr, corrected_ttr, content_ttr, func_ttr, rare_word_ratio, filler_ratio,
                      inflectional_variety, lemma_surface_ratio, punct_norm_word_len, typo_ratio, elongated_ratio, numeric_ratio,
                      sent_len_median, sent_len_skew, sent_len_kurt, short_sent_ratio, long_sent_ratio,
                      smog, gunning_fog, coleman_liau, ari, sent_start_diversity, question_ratio,
                      det, aux, part, propn, interj, pos_entropy,
                      first_ratio, second_ratio, third_ratio, neg_ratio])
    return np.array(feats)

@registry.register("syntactic", ["PassiveRatio", "AvgDepTreeDepth", "AvgDepDistance", "SubordinateRatio"])
def syntactic_features(texts):
    feats = []
    for doc in nlp.pipe(texts, batch_size=256):
        # 1. Passive voice (broadened E.41)
        passive = sum(1 for t in doc if t.dep_ in ("nsubjpass", "auxpass", "agent"))
        total_verbs = sum(1 for t in doc if t.pos_ == "VERB")
        passive_ratio = passive / total_verbs if total_verbs > 0 else 0

        # 2. Dependency tree depth (E.43)
        def get_depth(node):
            if not list(node.children): return 0
            return 1 + max(get_depth(child) for child in node.children)

        depths = [get_depth(s.root) for s in doc.sents]
        avg_depth = np.mean(depths) if depths else 0

        # 3. Average dependency distance (E.44)
        distances = []
        for t in doc:
            if t.head != t:
                distances.append(abs(t.i - t.head.i))
        avg_distance = np.mean(distances) if distances else 0

        # 4. Subordinate clause density (E.45)
        sub_count = sum(1 for t in doc if t.dep_ in ("advcl", "ccomp", "xcomp", "acl", "relcl"))
        total_sents = len(list(doc.sents))
        sub_ratio = sub_count / total_sents if total_sents > 0 else 0

        feats.append([passive_ratio, avg_depth, avg_distance, sub_ratio])
    return np.array(feats)

@registry.register("sentiment", [
    "SentCompoundMean", "SentCompoundStd", "SentPosMean", "SentPosStd",
    "SentNegMean", "SentNegStd", "SentNeuMean", "SentNeuStd",
    "SentVolatility", "HedgingDensity", "SubjectivityScore"
])
def sentiment_features(texts):
    feats = []

    # Simple hedging markers (G.67)
    hedging_words = {"perhaps", "likely", "probably", "maybe", "could", "might", "possibly", "suggests", "seems"}

    for doc in nlp.pipe(texts, batch_size=256):
        sents = [s.text for s in doc.sents]
        scores = [analyzer.polarity_scores(s) for s in sents]

        if not scores:
            feats.append([0]*11)
            continue

        compound = [s['compound'] for s in scores]
        pos = [s['pos'] for s in scores]
        neg = [s['neg'] for s in scores]
        neu = [s['neu'] for s in scores]

        # Volatility (G.65)
        volatility = np.std(compound) if len(compound) > 1 else 0

        # Hedging (G.67)
        tokens_lower = [t.text.lower() for t in doc]
        hedge_count = sum(1 for w in tokens_lower if w in hedging_words)
        hedge_density = hedge_count / len(tokens_lower) if tokens_lower else 0

        # Subjectivity (G.68) - simple proxy using ADJ/ADV ratio vs NOUN/VERB
        adj_adv = sum(1 for t in doc if t.pos_ in ("ADJ", "ADV"))
        noun_verb = sum(1 for t in doc if t.pos_ in ("NOUN", "VERB"))
        subj_score = adj_adv / (noun_verb + 1)

        feats.append([np.mean(compound), np.std(compound),
                      np.mean(pos), np.std(pos),
                      np.mean(neg), np.std(neg),
                      np.mean(neu), np.std(neu),
                      volatility, hedge_density, subj_score])
    return np.array(feats)

@registry.register("discourse", [
    "EntDensity", "NounDiversity", "DiscourseMarkerDensity", "TransitionDensity",
    "PersonRatio", "OrgRatio", "GpeRatio", "DateRatio", "UngroundedCount", "FactualDensity"
])
def discourse_features(texts):
    densities = []

    # Common discourse markers and transition words (F.51, F.52)
    discourse_markers = {"however", "therefore", "furthermore", "moreover", "consequently", "nevertheless", "nonetheless", "meanwhile", "instead"}
    transitions = {"first", "second", "then", "next", "finally", "finally", "in addition", "as a result", "for example", "specifically"}

    # Ungrounded quantification (I.84)
    ungrounded_phrases = {"many studies", "experts agree", "it is widely known", "some people say", "research shows", "studies suggest"}

    for doc in nlp.pipe(texts):
        entities = list(doc.ents)
        nouns = [t.lemma_ for t in doc if t.pos_ == "NOUN"]
        total_nouns = len(nouns)
        unique_nouns = len(set(nouns))
        sents = list(doc.sents)
        n_sents = len(sents)

        ent_density = len(set([e.text for e in entities])) / n_sents if n_sents else 0
        noun_diversity = unique_nouns / total_nouns if total_nouns else 0

        # F.51/52
        tokens_lower = [t.text.lower() for t in doc]
        dm_count = sum(1 for w in tokens_lower if w in discourse_markers)
        trans_count = sum(1 for w in tokens_lower if w in transitions)

        dm_density = dm_count / n_sents if n_sents else 0
        trans_density = trans_count / n_sents if n_sents else 0

        # Batch I Features (Named Entities 81, 89)
        person_count = sum(1 for e in entities if e.label_ == "PERSON")
        org_count = sum(1 for e in entities if e.label_ == "ORG")
        gpe_count = sum(1 for e in entities if e.label_ == "GPE")
        date_count = sum(1 for e in entities if e.label_ == "DATE")

        total_ents = len(entities)
        person_ratio = person_count / total_ents if total_ents > 0 else 0
        org_ratio = org_count / total_ents if total_ents > 0 else 0
        gpe_ratio = gpe_count / total_ents if total_ents > 0 else 0
        date_ratio = date_count / total_ents if total_ents > 0 else 0

        # I.84 Ungrounded
        raw_text_lower = doc.text.lower()
        ungrounded_count = sum(1 for p in ungrounded_phrases if p in raw_text_lower)

        # I.89 Factual density proxy (numbers, entities, dates per sentence)
        num_count = sum(1 for t in doc if t.like_num or t.pos_ == "NUM")
        factual_score = (total_ents + num_count) / n_sents if n_sents > 0 else 0

        densities.append([ent_density, noun_diversity, dm_density, trans_density,
                         person_ratio, org_ratio, gpe_ratio, date_ratio, ungrounded_count, factual_score])
    return np.array(densities)

@registry.register("fingerprint", ["BurstinessScore", "RepetitionPenalty", "AssistantResidue", "SafetyDisclaimer"])
def fingerprint_features(texts):
    feats = []

    # Residue markers (K.106, K.107)
    residue_phrases = {"as an ai", "i cannot", "my knowledge cutoff", "i don't have feelings", "as a large language model"}
    safety_phrases = {"important to note", "please consult", "legal advice", "medical professional", "for informational purposes"}

    for doc in nlp.pipe(texts, batch_size=256):
        # 1. Burstiness (K.102) - inter-arrival distance variance
        tokens = [t.text.lower() for t in doc if t.is_alpha]
        if not tokens:
            feats.append([0,0,0,0]); continue

        counts = Counter(tokens)
        variances = []
        for word, count in counts.items():
            if count > 2:
                indices = [i for i, x in enumerate(tokens) if x == word]
                intervals = np.diff(indices)
                variances.append(np.var(intervals))
        burstiness = np.mean(variances) if variances else 0

        # 2. Repetition Penalty (K.105) - ratio of repeated bigrams
        bigrams = [tokens[i:i+2] for i in range(len(tokens)-1)]
        if not bigrams:
            repetition = 0
        else:
            unique_bigrams = set(tuple(b) for b in bigrams)
            repetition = 1 - (len(unique_bigrams) / len(bigrams))

        # 3. Residue (K.107)
        raw_text_lower = doc.text.lower()
        residue = sum(1 for p in residue_phrases if p in raw_text_lower)

        # 4. Safety (K.106)
        safety = sum(1 for p in safety_phrases if p in raw_text_lower)

        feats.append([burstiness, repetition, residue, safety])
    return np.array(feats)

@registry.register("categorical", ["HumanLeaningRatio", "LLMLeaningRatio", "TopDimRatio"])
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
    print("Extracting features using registry...")
    all_feats = []
    all_names = []
    for entry in registry.features:
        print(f"Extracting {entry['group']} features...")
        if entry["group"] == "categorical":
            res = entry["func"](texts, mapping_path=mapping_path)
        else:
            res = entry["func"](texts)
        all_feats.append(res)
        all_names.extend(entry["names"])

    return np.hstack(all_feats), all_names
