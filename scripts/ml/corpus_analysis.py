import numpy as np
import re
import math
import json
import argparse
import logging
import csv
from collections import Counter

# Professional Logging Configuration
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

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
        # Multiply rows by weights before summation
        weighted_matrix = model.matrix * weights[:, np.newaxis]
        degrees = np.sum(weighted_matrix[target_indices, :], axis=1)
        return float(np.mean(degrees))

    @staticmethod
    def clustering_coefficient(model, target_indices):
        """Measures local cohesion (triadic closure)."""
        if not target_indices: return 0.0
        A = model.matrix
        # Ensure A is symmetric for simple clustering coeff or handle as directed
        # Here we use the trace of A^3 which works for directed graphs as well but is interpreted differently
        A3 = np.linalg.matrix_power(A, 3)
        degrees = np.sum(A, axis=1)
        coeffs = []
        for i in target_indices:
            denom = degrees[i] * (degrees[i] - 1)
            coeffs.append(A3[i, i] / denom if denom > 0 else 0.0)
        return float(np.mean(coeffs))

    @staticmethod
    def associative_strength(model, target_indices):
        """Measures average association strength (e.g., PPMI)."""
        if not target_indices: return 0.0
        return float(np.mean(model.matrix[target_indices, :]))

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
        pmi = np.log2((self.matrix * total_sum) / (np.outer(row_sums, col_sums) + 1e-10) + 1e-10)
        ppmi = np.maximum(0, pmi)
        if threshold > 0:
            ppmi[ppmi < threshold] = 0
        return ppmi

    def get_weighted_eigen_vector(self, weights, iterations=50):
        """Calculates the principal eigenvector adjusted by node weights."""
        w_hash = hash(tuple(weights))
        if w_hash in self._weighted_eigen_vecs:
            return self._weighted_eigen_vecs[w_hash]
        
        # Weighted transition matrix: v_new = (A * W)v
        weighted_matrix = self.matrix * weights[:, np.newaxis]
        v = np.ones(self.n) / self.n
        for _ in range(iterations):
            v_new = np.dot(weighted_matrix, v)
            norm = np.linalg.norm(v_new)
            if norm == 0: break
            v = v_new / norm
        
        self._weighted_eigen_vecs[w_hash] = v
        return v

class WordCategorizer:
    """Classifies individual words based on cross-corpus topological leaning."""
    def __init__(self, human_model, llm_model, config):
        self.h_model = human_model
        self.l_model = llm_model
        self.config = config
        self.dimensions = config.get("dimensions", [])

    def classify_word_lean(self, word, threshold=0.1):
        h_idx = self.h_model.word_to_idx.get(word)
        l_idx = self.l_model.word_to_idx.get(word)

        h_eigen = self.h_model.get_weighted_eigen_vector(np.ones(self.h_model.n))[h_idx] if h_idx is not None else 0.0
        l_eigen = self.l_model.get_weighted_eigen_vector(np.ones(self.l_model.n))[l_idx] if l_idx is not None else 0.0

        denom = h_eigen + l_eigen
        if denom == 0: return "Unknown"

        lean = (h_eigen - l_eigen) / denom
        if lean > threshold: return "Human-leaning"
        if lean < -threshold: return "LLM-leaning"
        return "Balanced"

    def assign_to_dimension(self, word):
        """Assigns a word to the dimension it has the strongest associative strength with."""
        # Check if word is already a core node in any dimension
        for dim in self.dimensions:
            if word in dim.get("nodes", []):
                return dim["name"]

        # Otherwise, calculate mean associative strength with dimension core nodes
        best_dim = "General"
        max_strength = -1.0

        # We use whichever model the word is present in, prioritising human for ground truth
        model = self.h_model if word in self.h_model.word_to_idx else self.l_model
        if word not in model.word_to_idx: return "Out-of-Vocab"

        w_idx = model.word_to_idx[word]
        for dim in self.dimensions:
            core_nodes = dim.get("nodes", [])
            indices = [model.word_to_idx[n] for n in core_nodes if n in model.word_to_idx]
            if not indices: continue

            strength = np.mean(model.matrix[w_idx, indices])
            if strength > max_strength:
                max_strength = strength
                best_dim = dim["name"]

        return best_dim

class CorpusProcessor:
    """Handles tokenization and graph model construction."""
    def __init__(self):
        self.re_token = re.compile(r'\b\w+\b')

    def tokenize(self, text):
        return self.re_token.findall(text.lower())

    def build_model(self, tokens, window_size=5, weight_type="ppmi", threshold=0.0):
        vocab = sorted(list(set(tokens)))
        word_to_idx = {word: i for i, word in enumerate(vocab)}
        n = len(vocab)
        matrix = np.zeros((n, n), dtype=np.float64)
        for i, target in enumerate(tokens):
            t_idx = word_to_idx[target]
            start, end = max(0, i - window_size), min(len(tokens), i + window_size + 1)
            for j in range(start, end):
                if i != j: matrix[t_idx, word_to_idx[tokens[j]]] += 1
        
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
        return features

def main():
    parser = argparse.ArgumentParser(description="Triple-Graph & Ontology Comparative Analysis Engine")
    parser.add_argument("--human", type=str, help="Path to Human Corpus")
    parser.add_argument("--llm", type=str, help="Path to LLM Corpus")
    parser.add_argument("--ontology", type=str, help="Path to Reference Ontology Corpus")
    parser.add_argument("--config", type=str, required=True, help="Path to dimensions.json configuration")
    parser.add_argument("--output", type=str, default="triple_comparison.csv", help="Path to output report (CSV)")
    parser.add_argument("--compare_words", type=str, help="Path to word-level comparison report (CSV)")
    parser.add_argument("--window", type=int, default=5, help="Co-occurrence window size")
    parser.add_argument("--ont_threshold", type=float, default=1.0, help="PPMI threshold for ontology induction (pruning)")
    
    args = parser.parse_args()
    engine = ComparativeTopologyEngine(args.config)
    processor = CorpusProcessor()
    
    all_results = {}
    models = {}
    
    # Process each source if present
    sources = [("human", args.human), ("llm", args.llm), ("ont", args.ontology)]
    for prefix_base, path in sources:
        if not path: continue
        prefix = f"{prefix_base}_"
        try:
            with open(path, 'r', encoding='utf-8') as f:
                text = f.read()
            tokens = processor.tokenize(text)
            if not tokens: continue
            
            # Ontology induction uses a stricter pruning threshold
            threshold = args.ont_threshold if prefix_base == "ont" else 0.0
            model = processor.build_model(tokens, args.window, threshold=threshold)
            models[prefix_base] = model
            
            all_results.update(engine.analyze(model, prefix))
            logger.info(f"Processed graph: {prefix_base}")
        except Exception as e:
            logger.error(f"Error processing {path}: {e}")

    if not all_results:
        logger.error("No metrics extracted.")
        return

    # Write global comparative report
    with open(args.output, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=sorted(all_results.keys()))
        writer.writeheader()
        writer.writerow(all_results)
    logger.info(f"Comparative report saved to {args.output}")

    # Word-level categorical classification
    if args.compare_words and "human" in models and "llm" in models:
        categorizer = WordCategorizer(models["human"], models["llm"], engine.config)
        union_vocab = sorted(list(set(models["human"].vocab) | set(models["llm"].vocab)))

        word_results = []
        for word in union_vocab:
            lean = categorizer.classify_word_lean(word)
            dimension = categorizer.assign_to_dimension(word)
            word_results.append({
                "word": word,
                "lean": lean,
                "dimension": dimension
            })

        with open(args.compare_words, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=["word", "lean", "dimension"])
            writer.writeheader()
            writer.writerows(word_results)
        logger.info(f"Word-level comparison saved to {args.compare_words}")

if __name__ == "__main__":
    main()
