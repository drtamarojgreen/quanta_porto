#include <iostream>
#include <map>
#include <string>
#include <vector>
#include "util/fact_utils.h"
#include "MLPipelineClass.h"

int main(int argc, char** argv) {
    auto facts = Sorrel::Sdd::Util::FactReader::readFacts("facts/ml_environment.facts");
    if (facts.empty()) {
        std::cerr << "Error: Could not read facts from facts/ml_environment.facts" << std::endl;
        return 1;
    }

    if (argc < 2) {
        ml_data_prep_verification(facts);
        ml_feature_extraction_verification(facts);
        ml_pipeline_training_verification(facts);
        ml_corpus_analysis_verification(facts);
        ml_evaluate_explain_verification(facts);
        ml_robustness_verification(facts);
        return 0;
    }

    std::string cardName = argv[1];
    if (cardName == "data_prep") ml_data_prep_verification(facts);
    else if (cardName == "features") ml_feature_extraction_verification(facts);
    else if (cardName == "pipeline") ml_pipeline_training_verification(facts);
    else if (cardName == "corpus") ml_corpus_analysis_verification(facts);
    else if (cardName == "evaluate") ml_evaluate_explain_verification(facts);
    else if (cardName == "robustness") ml_robustness_verification(facts);
    else {
        std::cerr << "Unknown logical card: " << cardName << std::endl;
        return 1;
    }

    return 0;
}
