#ifndef SDD_ML_PIPELINE_CLASS_H
#define SDD_ML_PIPELINE_CLASS_H
#include <map>
#include <string>

void ml_data_prep_verification(const std::map<std::string, std::string>& facts);
void ml_feature_extraction_verification(const std::map<std::string, std::string>& facts);
void ml_pipeline_training_verification(const std::map<std::string, std::string>& facts);
void ml_corpus_analysis_verification(const std::map<std::string, std::string>& facts);
void ml_evaluate_explain_verification(const std::map<std::string, std::string>& facts);
void ml_robustness_verification(const std::map<std::string, std::string>& facts);

#endif
