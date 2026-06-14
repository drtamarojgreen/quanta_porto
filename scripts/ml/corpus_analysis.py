import numpy as np
import re
import math
import json
import argparse
import logging
import csv
from collections import Counter
import spacy

# Professional Logging Configuration
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

nlp = spacy.load("en_core_web_sm", disable=["ner", "parser"])

class GraphMetrics:
    """Pure mathematical graph metrics implemented on weighted adjacency matrices."""
    @staticmethod
    def eigen_centrality(model, target_indices, weights):
        """Measures global influence of target nodes adjusted by node weights."""
        v = model.get_weighted_eigen_vector(weights)
        if not target_indices: return 0.0
        return float(np.sum(v[target_indices]))

    @staticmethod
    def degree_centrality(model, target_indices, weights):
        """Measures local connectivity adjusted by node weights."""
        if not target_indices: return 0.0
        weighted_matrix = model.matrix * weights[:, np.newaxis]
        degrees = np.sum(weighted_matrix[target_indices, :], axis=1)
        return float(np.mean(degrees))

    @staticmethod
    def clustering_coefficient(model, target_indices):
        """Measures local cohesion (triadic closure)."""
        if not target_indices: return 0.0
        A = (model.matrix > 0).astype(float) # Use binary for simple CC
        A2 = np.dot(A, A)
        A3 = np.dot(A2, A)
        degrees = np.sum(A, axis=1)
        coeffs = []
        for i in target_indices:
            denom = degrees[i] * (degrees[i] - 1)
            coeffs.append(A3[i, i] / denom if denom > 1 else 0.0)
        return float(np.mean(coeffs))

    @staticmethod
    def associative_strength(model, target_indices):
        """Measures average association strength (e.g., PPMI)."""
        if not target_indices: return 0.0
        return float(np.mean(model.matrix[target_indices, :]))

    @staticmethod
    def graph_density(model):
        """Item 97: Graph density."""
        n = model.n
        if n < 2: return 0.0
        edges = np.count_nonzero(model.matrix)
        return edges / (n * (n - 1))

class GraphModel:
    """Mathematical engine for graph topology operations."""
    def __init__(self, matrix, vocab, word_to_idx):
        self.matrix = matrix
        self.vocab = vocab
        self.word_to_idx = word_to_idx
        self.n = len(vocab)
        self._weighted_eigen_vecs = {}

    def compute_ppmi(self, threshold=0.0):
        """Transforms counts into PPMI with optional pruning threshold."""
        total_sum = np.sum(self.matrix)
        row_sums = np.sum(self.matrix, axis=1)
        col_sums = np.sum(self.matrix, axis=0)
        # Avoid division by zero
        outer = np.outer(row_sums, col_sums)
        pmi = np.log2((self.matrix * total_sum) / (outer + 1e-10) + 1e-10)
        ppmi = np.maximum(0, pmi)
        if threshold > 0:
            ppmi[ppmi < threshold] = 0
        return ppmi

    def get_weighted_eigen_vector(self, weights, iterations=50):
        """Calculates the principal eigenvector adjusted by node weights."""
        w_hash = hash(tuple(weights))
        if w_hash in self._weighted_eigen_vecs:
            return self._weighted_eigen_vecs[w_hash]
        
        weighted_matrix = self.matrix * weights[:, np.newaxis]
        v = np.ones(self.n) / self.n
        for _ in range(iterations):
            v_new = np.dot(weighted_matrix, v)
            norm = np.linalg.norm(v_new)
            if norm == 0: break
            v = v_new / norm
        
        self._weighted_eigen_vecs[w_hash] = v
        return v

class CorpusProcessor:
    """Handles tokenization and graph model construction."""
    def __init__(self):
        self.re_token = re.compile(r'\b\w+\b')

    def tokenize(self, text, use_lemmas=False, pos_filter=None):
        """Items 92, 93: Lemmatized nodes and POS filtering."""
        doc = nlp(text)
        tokens = []
        for t in doc:
            if t.is_stop or t.is_punct or not t.is_alpha:
                continue
            if pos_filter and t.pos_ not in pos_filter:
                continue
            tokens.append(t.lemma_.lower() if use_lemmas else t.text.lower())
        return tokens

    def build_model(self, tokens, window_size=5, weight_type="ppmi", threshold=0.0, directed=False):
        """Item 94: Directed co-occurrence graphs."""
        vocab = sorted(list(set(tokens)))
        word_to_idx = {word: i for i, word in enumerate(vocab)}
        n = len(vocab)
        matrix = np.zeros((n, n), dtype=np.float64)
        for i, target in enumerate(tokens):
            t_idx = word_to_idx[target]
            # If directed, we only look ahead
            start = i + 1
            end = min(len(tokens), i + window_size + 1)
            for j in range(start, end):
                matrix[t_idx, word_to_idx[tokens[j]]] += 1
                if not directed:
                    matrix[word_to_idx[tokens[j]], t_idx] += 1
        
        model = GraphModel(matrix, vocab, word_to_idx)
        if weight_type == "ppmi":
            model.matrix = model.compute_ppmi(threshold)
        return model

class ComparativeTopologyEngine:
    """Extracts comparative topological dimensions across graphs."""
    def __init__(self, config_path):
        with open(config_path, 'r', encoding='utf-8') as f:
            self.config = json.load(f)
        self.metrics = GraphMetrics()

    def get_weights_vector(self, vocab, word_to_idx):
        weights = np.ones(len(vocab))
        node_weights = self.config.get("node_weights", {})
        for word, weight in node_weights.items():
            if word in word_to_idx:
                weights[word_to_idx[word]] = weight
        return weights

    def analyze(self, model, prefix=""):
        weights = self.get_weights_vector(model.vocab, model.word_to_idx)
        features = {}
        for dim in self.config.get("dimensions", []):
            name = f"{prefix}{dim['name']}"
            target_nodes = dim.get("nodes", [])
            metric = dim["metric"]
            indices = [model.word_to_idx[w] for w in target_nodes if w in model.word_to_idx]
            
            if metric == "eigen_centrality":
                features[name] = self.metrics.eigen_centrality(model, indices, weights)
            elif metric == "degree_centrality":
                features[name] = self.metrics.degree_centrality(model, indices, weights)
            elif metric == "clustering_coefficient":
                features[name] = self.metrics.clustering_coefficient(model, indices)
            elif metric == "associative_strength":
                features[name] = self.metrics.associative_strength(model, indices)

        # Add global metrics
        features[f"{prefix}graph_density"] = self.metrics.graph_density(model)
        return features

def main():
    parser = argparse.ArgumentParser(description="Triple-Graph & Ontology Comparative Analysis Engine")
    parser.add_argument("--human", type=str, help="Path to Human Corpus")
    parser.add_argument("--llm", type=str, help="Path to LLM Corpus")
    parser.add_argument("--ontology", type=str, help="Path to Reference Ontology Corpus")
    parser.add_argument("--config", type=str, required=True, help="Path to dimensions.json configuration")
    parser.add_argument("--output", type=str, default="triple_comparison.csv", help="Path to output report (CSV)")
    parser.add_argument("--window", type=int, default=5, help="Co-occurrence window size")
    parser.add_argument("--ont_threshold", type=float, default=1.0, help="PPMI threshold for ontology induction (pruning)")
    parser.add_argument("--lemmatize", action="store_true", help="Use lemmatized nodes")
    parser.add_argument("--directed", action="store_true", help="Use directed graph")
    
    args = parser.parse_args()
    engine = ComparativeTopologyEngine(args.config)
    processor = CorpusProcessor()
    
    all_results = {}
    sources = [("human_", args.human), ("llm_", args.llm), ("ont_", args.ontology)]
    for prefix, path in sources:
        if not path: continue
        try:
            with open(path, 'r', encoding='utf-8') as f:
                text = f.read()
            tokens = processor.tokenize(text, use_lemmas=args.lemmatize)
            if not tokens: continue
            
            threshold = args.ont_threshold if prefix == "ont_" else 0.0
            model = processor.build_model(tokens, args.window, threshold=threshold, directed=args.directed)
            
            all_results.update(engine.analyze(model, prefix))
            logger.info(f"Processed graph: {prefix[:-1]}")
        except Exception as e:
            logger.error(f"Error processing {path}: {e}")

    if not all_results:
        logger.error("No metrics extracted.")
        return

    with open(args.output, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=sorted(all_results.keys()))
        writer.writeheader()
        writer.writerow(all_results)
    
    logger.info(f"Comparative report saved to {args.output}")

if __name__ == "__main__":
    main()
