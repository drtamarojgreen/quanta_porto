#ifndef PQ_DAEMON_H
#define PQ_DAEMON_H

#include <string>
#include <vector>

struct PQLTask {
    std::string id;
    std::string type;
    std::string priority;
    std::string status;
    std::string created;
    std::string description;
    std::vector<std::string> commands;
    std::vector<std::string> criteria;
    std::string notes;
};

class PQLParser {
public:
    std::vector<PQLTask> parse(const std::string& filename);
};

class PromptGenerator {
public:
    std::string generate(const PQLTask& task);
};

class LLMRunner {
public:
    std::string run(const std::string& prompt);
};

class RuleEngine {
public:
    bool evaluate(const std::string& response);
};

class ReflectionEngine {
public:
    std::string reflect(const std::string& failed_response);
};

class Scheduler {
public:
    void run();
};

#endif // PQ_DAEMON_H
