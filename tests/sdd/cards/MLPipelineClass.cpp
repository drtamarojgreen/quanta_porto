#include "MLPipelineClass.h"
#include <iostream>
#include <map>
#include <string>
#include <filesystem>
#include <fstream>
#include <cstdlib>
#include <sstream>

namespace fs = std::filesystem;

// Helper to get absolute project root
std::string get_project_root() {
    auto current = fs::current_path();
    if (current.filename() == "sdd") {
        return current.parent_path().parent_path().string();
    }
    return current.string();
}

void ml_data_prep_verification(const std::map<std::string, std::string>& facts) {
    std::string root = get_project_root();
    std::string python_cmd = "export PYTHONPATH=$PYTHONPATH:" + root + " && python3 -c \"from scripts.ml.data_prep import balance_and_split_data; import pandas as pd; h=pd.DataFrame({'prompt':[str(i) for i in range(20)],'text':['h']*20}); l=pd.DataFrame({'prompt':[str(i) for i in range(20)],'text':['l']*20}); train,v,t = balance_and_split_data(h,l); print(f'train_size = {len(train)}')\"";
    std::system(python_cmd.c_str());
}

void ml_feature_extraction_verification(const std::map<std::string, std::string>& facts) {
    std::string root = get_project_root();
    std::string cmd = "export PYTHONPATH=$PYTHONPATH:" + root + " && python3 -c \"from scripts.ml.features import extract_all_interpretable_features; feats, names = extract_all_interpretable_features(['test']); print(f'feature_dim = {len(names)}')\" 2>/dev/null";
    std::system(cmd.c_str());
}

void ml_pipeline_training_verification(const std::map<std::string, std::string>& facts) {
    std::string root = get_project_root();
    std::string cmd = "export PYTHONPATH=$PYTHONPATH:" + root + " && python3 " + root + "/tests/ml/verify_full_pipeline.py > /dev/null 2>&1";
    int res = std::system(cmd.c_str());
    std::cout << "ml_pipeline_exit_code = " << (res == 0 ? 0 : 1) << std::endl;
}

void ml_corpus_analysis_verification(const std::map<std::string, std::string>& facts) {
    std::string root = get_project_root();
    std::string python_cmd = "export PYTHONPATH=$PYTHONPATH:" + root + " && python3 -c \"from scripts.ml.corpus_analysis import GraphMetrics; print('eigen_centrality_available = 1')\"";
    std::system(python_cmd.c_str());
}

void ml_evaluate_explain_verification(const std::map<std::string, std::string>& facts) {
    std::string root = get_project_root();
    std::string cmd = "export PYTHONPATH=$PYTHONPATH:" + root + " && python3 -c \"from scripts.ml.evaluate_explain import evaluate_hybrid_system; print('evaluation_logic_available = 1')\"";
    std::system(cmd.c_str());
}

void ml_robustness_verification(const std::map<std::string, std::string>& facts) {
    std::string root = get_project_root();
    std::string cmd = "export PYTHONPATH=$PYTHONPATH:" + root + " && pytest " + root + "/scripts/ml/test_ml_robustness.py 2>/dev/null | grep 'passed' | awk '{print \"ml_robustness_tests_passed = \" $2}'";
    std::system(cmd.c_str());
}
