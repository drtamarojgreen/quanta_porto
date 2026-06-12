import sys
import os
import json
import numpy as np

# Add scripts/ml to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../scripts/ml')))

from corpus_analysis import CorpusProcessor, ComparativeTopologyEngine, GraphModel

def test_corpus_analysis():
    # Setup mock config
    config = {
        "node_weights": {
            "test": 2.0,
            "data": 1.5
        },
        "dimensions": [
            {
                "name": "Centrality",
                "nodes": ["test", "data"],
                "metric": "eigen_centrality"
            },
            {
                "name": "Connectivity",
                "nodes": ["test"],
                "metric": "degree_centrality"
            }
        ]
    }
    config_path = "test_config.json"
    with open(config_path, "w") as f:
        json.dump(config, f)

    try:
        processor = CorpusProcessor()
        text = "This is a test. Data is important for a test. Test data is here."
        tokens = processor.tokenize(text)

        model = processor.build_model(tokens, window_size=2)

        engine = ComparativeTopologyEngine(config_path)
        results = engine.analyze(model, prefix="test_")

        # Numeric evidence
        eigen_val = results.get("test_Centrality", 0)
        degree_val = results.get("test_Connectivity", 0)

        print(f"eigen_centrality_value = {eigen_val:.4f}")
        print(f"degree_centrality_value = {degree_val:.4f}")

        # Validation
        assert eigen_val > 0, "Eigen centrality should be non-zero"
        assert degree_val > 0, "Degree centrality should be non-zero"

    finally:
        if os.path.exists(config_path):
            os.remove(config_path)

if __name__ == "__main__":
    try:
        test_corpus_analysis()
        sys.exit(0)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
