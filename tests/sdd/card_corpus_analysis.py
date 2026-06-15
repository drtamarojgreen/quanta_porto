import sys
import os
import json
import numpy as np
from sorrel_runner import Is, Results, Situation, SorrelRunner, dispatch

# Add scripts/ml to path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../scripts/ml')))

from corpus_analysis import CorpusProcessor, ComparativeTopologyEngine, GraphModel

@Is("python_available", 1)
@Situation("Default")
def card_corpus_analysis():
    config = {
        "node_weights": {"test": 2.0, "data": 1.5},
        "dimensions": [{"name": "Centrality", "nodes": ["test", "data"], "metric": "eigen_centrality"}]
    }
    config_path = "test_config.json"
    with open(config_path, "w") as f: json.dump(config, f)

    try:
        processor = CorpusProcessor()
        tokens = processor.tokenize("This is a test. Data is important.")
        model = processor.build_model(tokens, window_size=2)
        engine = ComparativeTopologyEngine(config_path)
        results = engine.analyze(model, prefix="test_")

        print(f"eigen_centrality_value = {results.get('test_Centrality', 0)}")
    finally:
        if os.path.exists(config_path): os.remove(config_path)

if __name__ == "__main__":
    runner = SorrelRunner()
    dispatch(runner)
