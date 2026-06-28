import spacy
from collections import Counter
import numpy as np
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
from sklearn.feature_extraction.text import TfidfVectorizer
import pandas as pd
import os
from scipy.stats import hypergeom, skew, kurtosis
import textstat
import re
from sentence_transformers import SentenceTransformer
from langdetect import detect, DetectorFactory
import html
from markdown import markdown
import emoji

DetectorFactory.seed = 42
nlp = spacy.load("en_core_web_sm")
analyzer = SentimentIntensityAnalyzer()
model_st = None

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

    def _clean_text(self, text):
        text = html.unescape(text)
        text = re.sub(r'<[^>]*>', '', text)
        text = re.sub(r'#+\s+', '', text)
        text = re.sub(r'[*_]{1,3}', '', text)
        text = re.sub(r'\[([^\]]+)\]\([^\)]+\)', r'\1', text)
        return text.strip()

    def extract_all(self, texts, **kwargs):
        clean_texts = [self._clean_text(t) for t in texts]
        all_feats = []
        all_names = []
        for entry in self.features:
            if entry["group"] == "categorical":
                mapping_path = kwargs.get("mapping_path", "scripts/ml/words.csv")
                res = entry["func"](clean_texts, mapping_path=mapping_path)
            else:
                res = entry["func"](clean_texts)

            if res.ndim == 1:
                res = res.reshape(len(clean_texts), -1)

            all_feats.append(res)
            all_names.extend(entry["names"])

        return np.hstack(all_feats), all_names

registry = FeatureRegistry()

# Utility functions
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
    if len(words) < sample_size:
        return len(set(words)) / len(words) if words else 0
    from scipy.stats import hypergeom
    counts = Counter(words)
    n = len(words)
    sum_prob = 0
    for word, freq in counts.items():
        p_none = hypergeom.pmf(0, n, freq, sample_size)
        sum_prob += (1 - p_none)
    return sum_prob / sample_size

def count_syllables(word):
    word = word.lower()
    count = 0
    vowels = "aeiouy"
    if not word: return 0
    if word[0] in vowels:
        count += 1
    for index in range(1, len(word)):
        if word[index] in vowels and word[index - 1] not in vowels:
            count += 1
    if word.endswith("e"):
        count -= 1
    if count <= 0:
        count = 1
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

def flesch_reading_ease_custom(doc):
    return flesch_reading_ease(doc)

def _get_tree_depth(node):
    depth = 0
    stack = [(node, 1)]
    while stack:
        curr, d = stack.pop()
        depth = max(depth, d)
        for child in curr.children:
            stack.append((child, d + 1))
    return depth

@registry.register("stylometric", [
    "TTR", "Hapax", "AvgWordLen", "SentLenMean", "SentLenStd",
    "NounRatio", "VerbRatio", "AdjRatio", "AdvRatio", "PronRatio", "AdpRatio", "ConjRatio", "FuncWordRatio",
    "SimpsonD", "PunctNormWordLen"
])
def stylometric_features(texts):
    feats = []
    for doc in nlp.pipe(texts, batch_size=256):
        words = [t.text.lower() for t in doc if t.is_alpha]
        if not words:
            feats.append([0]*15); continue

        ttr = len(set(words)) / len(words)
        hapax = sum(1 for w in set(words) if words.count(w) == 1) / len(words)
        avg_word_len = np.mean([len(w) for w in words])
        sent_lens = [len(s) for s in doc.sents if len(s) > 0]
        sent_len_mean = np.mean(sent_lens) if sent_lens else 0
        sent_len_std = np.std(sent_lens) if sent_lens else 0
        pos_counts = Counter([t.pos_ for t in doc])
        total = sum(pos_counts.values())
        if total == 0:
            feats.append([0]*15); continue
        noun = pos_counts.get("NOUN", 0) / total
        verb = pos_counts.get("VERB", 0) / total
        adj = pos_counts.get("ADJ", 0) / total
        adv = pos_counts.get("ADV", 0) / total
        pron = pos_counts.get("PRON", 0) / total
        adp = pos_counts.get("ADP", 0) / total
        conj = pos_counts.get("CONJ", 0) / total
        func_words = {"the","a","an","in","on","at","to","for","of","with","and","or","but","if","because","that","this","it","he","she","they","we","you","is","are","was","were","be","been","have","has","do","does","did","will","would","can","could","may","might","shall"}
        func_count = sum(1 for t in words if t in func_words)
        func_ratio = func_count / len(words)
        counts = Counter(words)
        N = len(words)
        simpson_d = sum(n * (n - 1) for n in counts.values()) / (N * (N - 1)) if N > 1 else 0
        words_no_punct = [t.text for t in doc if not t.is_punct and not t.is_space]
        punct_norm_len = np.mean([len(w) for w in words_no_punct]) if words_no_punct else 0
        feats.append([ttr, hapax, avg_word_len, sent_len_mean, sent_len_std, noun, verb, adj, adv, pron, adp, conj, func_ratio, simpson_d, punct_norm_len])
    return np.array(feats)

@registry.register("advanced_lexical", ["MATTR", "CTTR", "YulesK", "MTLD", "HDD", "RootTTR", "CorrectedTTR", "ContentTTR", "FuncTTR", "RareWordRatio", "FillerWordRatio"])
def advanced_lexical_features(texts, window_size=50):
    feats = []
    for doc in nlp.pipe(texts, batch_size=256):
        words = [t.text.lower() for t in doc if t.is_alpha]
        N = len(words)
        if N == 0:
            feats.append([0]*11); continue
        mattr = calculate_mattr(words, window_size)
        cttr = len(set(words)) / np.sqrt(2 * N)
        yules_k = calculate_yules_k(words)
        mtld = calculate_mtld(words)
        hdd = calculate_hdd(words)
        root_ttr = len(set(words)) / np.sqrt(N)
        corrected_ttr = cttr
        content_pos = {"NOUN", "VERB", "ADJ", "ADV"}
        content_words = [t.text.lower() for t in doc if t.pos_ in content_pos]
        func_words_list = [t.text.lower() for t in doc if t.pos_ not in content_pos and not t.is_punct and not t.is_space]
        content_ttr = len(set(content_words)) / len(content_words) if content_words else 0
        func_ttr = len(set(func_words_list)) / len(func_words_list) if func_words_list else 0
        rare_word_ratio = sum(1 for w in set(words) if words.count(w) == 1) / N
        fillers = {"important", "various", "significant", "many", "actually", "basically", "very", "really"}
        filler_ratio = sum(1 for w in words if w in fillers) / N
        feats.append([mattr, cttr, yules_k, mtld, hdd, root_ttr, corrected_ttr, content_ttr, func_ttr, rare_word_ratio, filler_ratio])
    return np.array(feats)

@registry.register("morphology_casing", ["InflectVar", "TitleCase", "AllCaps", "Contractions", "NumRatio", "DateRatio", "EmojiRatio", "SymbolRatio", "TypoRatio", "ElongatedRatio", "NumericRatio"])
def morphology_casing_features(texts):
    feats = []
    for doc in nlp.pipe(texts, batch_size=256):
        N = len(doc)
        if N == 0:
            feats.append([0]*11); continue
        words = [t.text.lower() for t in doc if t.is_alpha]
        lemmas = set(t.lemma_ for t in doc if t.is_alpha)
        surface = set(t.text.lower() for t in doc if t.is_alpha)
        inflect_var = len(lemmas) / len(surface) if surface else 1.0
        title_case = sum(1 for t in doc if t.text.istitle()) / N
        all_caps = sum(1 for t in doc if t.text.isupper() and len(t.text) > 1) / N
        contractions = sum(1 for t in doc if "'" in t.text or t.text.lower().endswith("n't")) / N
        nums = sum(1 for t in doc if t.like_num or t.pos_ == "NUM") / N
        dates = sum(1 for t in doc if t.ent_type_ == "DATE") / N
        emoji_count = emoji.emoji_count(doc.text) / N
        symbol_count = sum(1 for t in doc if t.pos_ == "SYM") / N
        vowels = set("aeiouy")
        typo_count = sum(1 for w in words if len(w) > 3 and not any(c in vowels for c in w.lower()))
        typo_ratio = typo_count / len(words) if words else 0
        elongated_pattern = re.compile(r"(.)\1{2,}")
        elongated_ratio = sum(1 for w in words if elongated_pattern.search(w)) / len(words) if words else 0
        feats.append([inflect_var, title_case, all_caps, contractions, nums, dates, emoji_count, symbol_count, typo_ratio, elongated_ratio, nums])
    return np.array(feats)

@registry.register("rhythm_readability", ["MedSentLen", "SkewSentLen", "KurtSentLen", "FleschEase", "FleschGrade", "StartDiversity", "ParaCount", "AvgParaLen", "ShortSentRatio", "LongSentRatio", "SMOG", "GunningFog", "ColemanLiau", "ARI", "QuestionRatio", "SentLenMedian", "SentLenSkew", "SentStartDiversity"])
def rhythm_readability_features(texts):
    feats = []
    for doc in nlp.pipe(texts, batch_size=256):
        text = doc.text
        sents = [s for s in doc.sents if len(s) > 0]
        sent_lens = [len([t for t in s if not t.is_punct]) for s in sents]
        if not sent_lens:
            feats.append([0]*18); continue
        med_sent_len = np.median(sent_lens)
        skew_sent_len = skew(sent_lens) if len(sent_lens) > 2 else 0
        kurt_sent_len = kurtosis(sent_lens) if len(sent_lens) > 2 else 0
        flesch_ease = flesch_reading_ease(doc)
        flesch_grade = textstat.flesch_kincaid_grade(text)
        starts = [s[0].text.lower() for s in sents if len(s) > 0]
        start_div = len(set(starts)) / len(starts) if starts else 0
        paras = [p for p in text.split('\n\n') if p.strip()]
        para_count = len(paras)
        avg_para_len = np.mean([len(p.split()) for p in paras]) if paras else 0
        short_sent_ratio = sum(1 for l in sent_lens if l < 10) / len(sent_lens)
        long_sent_ratio = sum(1 for l in sent_lens if l > 30) / len(sent_lens)
        smog = textstat.smog_index(text)
        gunning_fog = textstat.gunning_fog(text)
        coleman_liau = textstat.coleman_liau_index(text)
        ari = textstat.automated_readability_index(text)
        question_ratio = sum(1 for s in sents if s.text.strip().endswith("?")) / len(sents)
        feats.append([med_sent_len, skew_sent_len, kurt_sent_len, flesch_ease, flesch_grade, start_div, para_count, avg_para_len, short_sent_ratio, long_sent_ratio, smog, gunning_fog, coleman_liau, ari, question_ratio, med_sent_len, skew_sent_len, start_div])
    return np.array(feats)

@registry.register("advanced_syntax", ["AvgTreeDepth", "SubordinateRatio", "AvgDepDist", "PassiveRatio", "AvgDepTreeDepth", "AvgDepDistance"])
def advanced_syntax_features(texts):
    feats = []
    for doc in nlp.pipe(texts, batch_size=256):
        depths = []
        sub_clauses = 0
        total_dist = 0
        dep_links = 0
        passive = 0
        total_verbs = sum(1 for t in doc if t.pos_ == "VERB")
        for sent in doc.sents:
            depths.append(_get_tree_depth(sent.root))
            for token in sent:
                if token.dep_ in ["advcl", "relcl", "ccomp", "xcomp", "acl"]:
                    sub_clauses += 1
                if token.head != token:
                    total_dist += abs(token.i - token.head.i)
                    dep_links += 1
                if token.dep_ in ("nsubjpass", "auxpass", "agent"):
                    passive += 1
        avg_depth = np.mean(depths) if depths else 0
        sub_ratio = sub_clauses / len(list(doc.sents)) if list(doc.sents) else 0
        avg_dep_dist = total_dist / dep_links if dep_links > 0 else 0
        passive_ratio = passive / total_verbs if total_verbs > 0 else 0
        feats.append([avg_depth, sub_ratio, avg_dep_dist, passive_ratio, avg_depth, avg_dep_dist])
    return np.array(feats)

@registry.register("advanced_pos", ["PropnRatio", "NumRatio_POS", "AuxRatio", "PartRatio", "FirstPersonRatio", "ModalRatio", "NegationRatio", "DetRatio", "InterjRatio", "POSEntropy", "SecondPersonRatio", "ThirdPersonRatio"])
def advanced_pos_features(texts):
    feats = []
    for doc in nlp.pipe(texts, batch_size=256):
        pos_counts = Counter([t.pos_ for t in doc])
        total = sum(pos_counts.values())
        if total == 0:
            feats.append([0]*12); continue
        propn = pos_counts.get("PROPN", 0) / total
        num = pos_counts.get("NUM", 0) / total
        aux = pos_counts.get("AUX", 0) / total
        part = pos_counts.get("PART", 0) / total
        det = pos_counts.get("DET", 0) / total
        interj = pos_counts.get("INTJ", 0) / total
        first_person_words = {"i", "me", "my", "mine", "we", "us", "our", "ours"}
        second_person_words = {"you", "your", "yours"}
        third_person_words = {"he", "him", "his", "she", "her", "hers", "it", "its", "they", "them", "their", "theirs"}
        first_count = sum(1 for t in doc if t.text.lower() in first_person_words) / total
        second_count = sum(1 for t in doc if t.text.lower() in second_person_words) / total
        third_count = sum(1 for t in doc if t.text.lower() in third_person_words) / total
        modals = {"must", "should", "could", "might", "would", "may", "can", "will"}
        modal_ratio = sum(1 for t in doc if t.text.lower() in modals) / total
        negations = sum(1 for t in doc if t.dep_ == "neg" or t.text.lower().endswith("n't")) / total
        probs = [c / total for c in pos_counts.values()]
        pos_entropy = -sum(p * np.log2(p) for p in probs)
        feats.append([propn, num, aux, part, first_count, modal_ratio, negations, det, interj, pos_entropy, second_count, third_count])
    return np.array(feats)

@registry.register("discourse", ["ContrastRatio", "SequenceRatio", "ListDensity", "RepetitionBigramRatio", "DiscourseMarkerDensity", "TransitionDensity"])
def discourse_features(texts):
    feats = []
    contrast_markers = {"however", "but", "yet", "although", "though", "nevertheless", "nonetheless"}
    sequence_markers = {"first", "second", "then", "next", "finally", "lastly"}
    transitions = {"first", "second", "then", "next", "finally", "in addition", "as a result", "for example", "specifically"}
    for doc in nlp.pipe(texts, batch_size=256):
        N = len(doc)
        if N == 0:
            feats.append([0]*6); continue
        text_lower = doc.text.lower()
        contrast_count = sum(1 for m in contrast_markers if m in text_lower) / N
        sequence_count = sum(1 for m in sequence_markers if m in text_lower) / N
        list_like = len(re.findall(r'^\s*[-*•\d+.]\s+', doc.text, re.M)) / len(list(doc.sents)) if list(doc.sents) else 0
        tokens = [t.text.lower() for t in doc if t.is_alpha]
        bigrams = [(tokens[i], tokens[i+1]) for i in range(len(tokens)-1)]
        repeat_bigrams = len(bigrams) - len(set(bigrams))
        bigram_repeat_ratio = repeat_bigrams / len(bigrams) if bigrams else 0
        dm_count = sum(1 for t in doc if t.text.lower() in (contrast_markers | sequence_markers)) / len(list(doc.sents)) if list(doc.sents) else 0
        trans_count = sum(1 for t in doc if t.text.lower() in transitions) / len(list(doc.sents)) if list(doc.sents) else 0
        feats.append([contrast_count, sequence_count, list_like, bigram_repeat_ratio, dm_count, trans_count])
    return np.array(feats)

@registry.register("sentiment_emotion", ["SentCompoundMean", "SentCompoundStd", "SentPosMean", "SentPosStd", "SentNegMean", "SentNegStd", "SentNeuMean", "SentNeuStd", "HedgingRatio", "SentVolatility", "SubjectivityScore", "HedgingDensity"])
def sentiment_emotion_features(texts):
    feats = []
    hedging_markers = {"perhaps", "likely", "possibly", "maybe", "probably", "clearly", "undoubtedly", "suggests", "seems"}
    for doc in nlp.pipe(texts, batch_size=256):
        sents = [s.text for s in doc.sents]
        scores = [analyzer.polarity_scores(s) for s in sents]
        if not scores:
            feats.append([0]*12); continue
        compound = [s['compound'] for s in scores]
        pos = [s['pos'] for s in scores]
        neg = [s['neg'] for s in scores]
        neu = [s['neu'] for s in scores]
        hedging = sum(1 for t in doc if t.text.lower() in hedging_markers) / len(doc) if len(doc) else 0
        volatility = np.std(compound) if len(compound) > 1 else 0
        adj_adv = sum(1 for t in doc if t.pos_ in ("ADJ", "ADV"))
        noun_verb = sum(1 for t in doc if t.pos_ in ("NOUN", "VERB"))
        subj_score = adj_adv / (noun_verb + 1)
        feats.append([np.mean(compound), np.std(compound), np.mean(pos), np.std(pos), np.mean(neg), np.std(neg), np.mean(neu), np.std(neu), hedging, volatility, subj_score, hedging])
    return np.array(feats)

@registry.register("semantic", ["EmbedMean", "EmbedStd"])
def semantic_transformer_features(texts):
    global model_st
    if model_st is None:
        model_st = SentenceTransformer('all-MiniLM-L6-v2')
    embeddings = model_st.encode(texts)
    return np.hstack([np.mean(embeddings, axis=1, keepdims=True), np.std(embeddings, axis=1, keepdims=True)])

@registry.register("grounding", ["PersonDensity", "OrgDensity", "GpeDensity", "FactDensity", "EntRecurrence", "UngroundedCount", "FactualDensity"])
def grounding_factual_features(texts):
    feats = []
    ungrounded_phrases = {"many studies", "experts agree", "it is widely known", "some people say", "research shows", "studies suggest"}
    for doc in nlp.pipe(texts, batch_size=256):
        sents = list(doc.sents)
        N = len(sents)
        if not N:
            feats.append([0]*7); continue
        person = len([e for e in doc.ents if e.label_ == "PERSON"]) / N
        org = len([e for e in doc.ents if e.label_ == "ORG"]) / N
        gpe = len([e for e in doc.ents if e.label_ == "GPE"]) / N
        facts = len(doc.ents) + sum(1 for t in doc if t.like_num)
        fact_density = facts / N
        ent_texts = [e.text.lower() for e in doc.ents]
        recurrence = (len(ent_texts) - len(set(ent_texts))) / len(ent_texts) if ent_texts else 0
        ungrounded_count = sum(1 for p in ungrounded_phrases if p in doc.text.lower())
        feats.append([person, org, gpe, fact_density, recurrence, ungrounded_count, fact_density])
    return np.array(feats)

@registry.register("multilingual", ["IsEnglish"])
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

@registry.register("detection", ["ResidueRatio", "AssistantResidue", "SafetyDisclaimer"])
def detection_signals_features(texts):
    feats = []
    prefaces = {"as an ai", "i cannot", "it is important to note", "in summary", "certainly"}
    residue_phrases = {"my knowledge cutoff", "i don't have feelings", "as a large language model"}
    safety_phrases = {"please consult", "legal advice", "medical professional", "for informational purposes"}
    for text in texts:
        text_lower = text.lower()
        res_ratio = sum(1 for p in prefaces if p in text_lower) / (len(text.split()) + 1)
        res_count = sum(1 for p in residue_phrases if p in text_lower)
        safety_count = sum(1 for p in safety_phrases if p in text_lower)
        feats.append([res_ratio, res_count, safety_count])
    return np.array(feats)

@registry.register("fingerprint", ["BurstinessScore", "RepetitionPenalty"])
def fingerprint_features(texts):
    feats = []
    for doc in nlp.pipe(texts, batch_size=256):
        tokens = [t.text.lower() for t in doc if t.is_alpha]
        if not tokens:
            feats.append([0,0]); continue
        counts = Counter(tokens)
        variances = []
        for word, count in counts.items():
            if count > 2:
                indices = [i for i, x in enumerate(tokens) if x == word]
                variances.append(np.var(np.diff(indices)))
        burstiness = np.mean(variances) if variances else 0
        bigrams = [tuple(tokens[i:i+2]) for i in range(len(tokens)-1)]
        repetition = 1 - (len(set(bigrams)) / len(bigrams)) if bigrams else 0
        feats.append([burstiness, repetition])
    return np.array(feats)

@registry.register("categorical", ["HumanLeaningRatio", "LLMLeaningRatio", "TopDimRatio"])
def categorical_word_features(texts, mapping_path="scripts/ml/words.csv"):
    if not os.path.exists(mapping_path):
        return np.zeros((len(texts), 3))
    df = pd.read_csv(mapping_path)
    lean_map = dict(zip(df['word'], df['lean']))
    dim_map = dict(zip(df['word'], df['dimension']))
    feats = []
    for doc in nlp.pipe(texts, batch_size=256):
        tokens = [t.text.lower() for t in doc if t.is_alpha]
        if not tokens:
            feats.append([0, 0, 0]); continue
        h_count = sum(1 for t in tokens if lean_map.get(t) == "Human-leaning")
        l_count = sum(1 for t in tokens if lean_map.get(t) == "LLM-leaning")
        dim_counts = Counter([dim_map.get(t) for t in tokens if dim_map.get(t)])
        top_dim_count = dim_counts.most_common(1)[0][1] / len(tokens) if dim_counts else 0
        feats.append([h_count/len(tokens), l_count/len(tokens), top_dim_count])
    return np.array(feats)

@registry.register("entity_legacy", ["EntDensity_Legacy", "NounDiversity_Legacy"])
def entity_density_legacy(texts):
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

def extract_all_interpretable_features(texts, **kwargs):
    return registry.extract_all(texts, **kwargs)

def get_tfidf_features(train_texts, test_texts, max_features=500):
    vec = TfidfVectorizer(max_features=max_features, stop_words='english', ngram_range=(1,2), min_df=5)
    train_tfidf = vec.fit_transform(train_texts)
    test_tfidf = vec.transform(test_texts)
    return train_tfidf, test_tfidf, vec
