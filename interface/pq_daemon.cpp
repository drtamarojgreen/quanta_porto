#include "pq_daemon.h"
#include "Config.h"
#include <iostream>
#include <fstream>
#include <sstream>
#include <algorithm>

// --- PQL Parser ---

// Helper function to trim leading/trailing whitespace
static std::string trim(const std::string& str) {
    const std::string whitespace = " \t\n\r\f\v";
    size_t first = str.find_first_not_of(whitespace);
    if (std::string::npos == first) {
        return str;
    }
    size_t last = str.find_last_not_of(whitespace);
    return str.substr(first, (last - first + 1));
}

// Helper function to extract content from a tag
static std::string get_tag_content(const std::string& xml, const std::string& tag, size_t& pos) {
    std::string start_tag = "<" + tag + ">";
    std::string end_tag = "</" + tag + ">";
    size_t start = xml.find(start_tag, pos);
    if (start == std::string::npos) {
        return "";
    }
    start += start_tag.length();
    size_t end = xml.find(end_tag, start);
    if (end == std::string::npos) {
        return "";
    }
    pos = end + end_tag.length();
    return xml.substr(start, end - start);
}

// Helper function to extract content from all occurrences of a tag
static std::vector<std::string> get_all_tag_contents(const std::string& xml, const std::string& tag) {
    std::vector<std::string> contents;
    std::string start_tag = "<" + tag + ">";
    std::string end_tag = "</" + tag + ">";
    size_t pos = 0;
    while ((pos = xml.find(start_tag, pos)) != std::string::npos) {
        pos += start_tag.length();
        size_t end = xml.find(end_tag, pos);
        if (end == std::string::npos) {
            break;
        }
        contents.push_back(trim(xml.substr(pos, end - pos)));
        pos = end + end_tag.length();
    }
    return contents;
}


std::vector<PQLTask> PQLParser::parse(const std::string& filename) {
    std::vector<PQLTask> tasks;
    std::ifstream file(filename);
    if (!file.is_open()) {
        std::cerr << "Error: Could not open PQL file: " << filename << std::endl;
        return tasks;
    }

    std::stringstream buffer;
    buffer << file.rdbuf();
    std::string xml_content = buffer.str();

    size_t pos = 0;
    while ((pos = xml_content.find("<task", pos)) != std::string::npos) {
        size_t end_of_task_tag = xml_content.find(">", pos);
        size_t end_of_task = xml_content.find("</task>", pos);
        if (end_of_task_tag == std::string::npos || end_of_task == std::string::npos) {
            break;
        }

        std::string task_attributes = xml_content.substr(pos, end_of_task_tag - pos);
        std::string task_inner_xml = xml_content.substr(end_of_task_tag + 1, end_of_task - (end_of_task_tag + 1));

        PQLTask task;

        // Simplified attribute parsing
        std::string temp = task_attributes;
        std::replace(temp.begin(), temp.end(), '=', ' ');
        std::replace(temp.begin(), temp.end(), '"', ' ');
        std::stringstream ss(temp);
        std::string key, value;
        ss >> key; // <task
        while(ss >> key >> value) {
            if (key == "id") task.id = value;
            else if (key == "type") task.type = value;
            else if (key == "priority") task.priority = value;
            else if (key == "status") task.status = value;
            else if (key == "created") task.created = value;
        }

        size_t inner_pos = 0;
        task.description = trim(get_tag_content(task_inner_xml, "description", inner_pos));

        size_t commands_pos = 0;
        std::string commands_xml = get_tag_content(task_inner_xml, "commands", commands_pos);
        task.commands = get_all_tag_contents(commands_xml, "command");

        size_t criteria_pos = 0;
        std::string criteria_xml = get_tag_content(task_inner_xml, "criteria", criteria_pos);
        task.criteria = get_all_tag_contents(criteria_xml, "criterion");

        size_t notes_pos = 0;
        task.notes = trim(get_tag_content(task_inner_xml, "notes", notes_pos));

        tasks.push_back(task);

        pos = end_of_task + std::string("</task>").length();
    }

    return tasks;
}

// --- Prompt Generator ---

std::string PromptGenerator::generate(const PQLTask& task) {
    std::stringstream prompt;
    prompt << "Task: " << task.description << std::endl;
    prompt << "Commands:" << std::endl;
    for (const auto& cmd : task.commands) {
        prompt << "- " << cmd << std::endl;
    }
    prompt << "Criteria:" << std::endl;
    for (const auto& crit : task.criteria) {
        prompt << "- " << crit << std::endl;
    }
    return prompt.str();
}

// --- LLM Runner (Placeholder) ---

std::string LLMRunner::run(const std::string& prompt) {
    std::cout << "--- Running LLM with prompt ---" << std::endl;
    std::cout << prompt << std::endl;
    std::cout << "--- End of prompt ---" << std::endl;
    return "This is a placeholder response from the LLM.";
}

// --- Rule Engine (Placeholder) ---

bool RuleEngine::evaluate(const std::string& response) {
    std::cout << "Evaluating rules for response: " << response << std::endl;
    // In a real implementation, this would parse rules.xml and check the response.
    return true; // Placeholder, always passes.
}

// --- Reflection Engine (Placeholder) ---

std::string ReflectionEngine::reflect(const std::string& failed_response) {
    std::cout << "Reflecting on failed response: " << failed_response << std::endl;
    return "This is a new prompt after reflection.";
}

// --- Scheduler ---

void Scheduler::run() {
    PQLParser parser;
    std::vector<PQLTask> tasks = parser.parse("/app/rules/pql_sample.xml");
    if (tasks.empty()) {
        std::cout << "No tasks to process." << std::endl;
        return;
    }

    PromptGenerator prompt_generator;
    LLMRunner llm_runner;
    RuleEngine rule_engine;
    ReflectionEngine reflection_engine;

    for (const auto& task : tasks) {
        std::cout << "--- Starting task: " << task.id << " ---" << std::endl;
        std::string prompt = prompt_generator.generate(task);
        std::string response = llm_runner.run(prompt);
        if (rule_engine.evaluate(response)) {
            std::cout << "Task " << task.id << " completed successfully." << std::endl;
        } else {
            std::cout << "Task " << task.id << " failed. Reflecting..." << std::endl;
            std::string new_prompt = reflection_engine.reflect(response);
            response = llm_runner.run(new_prompt);
            // In a real implementation, we would have a retry loop here.
        }
        std::cout << "--- Finished task: " << task.id << " ---" << std::endl;
        std::cout << std::endl;
    }
}

// --- main ---

int main() {
    std::cout << "QuantaPorto Daemon Initializing..." << std::endl;

    Config config;
    if (!config.load("/app/environment.txt")) {
        std::cerr << "Failed to load 'environment.txt'. Make sure the application is run from the project root directory." << std::endl;
        return 1;
    }
    std::cout << "Configuration loaded successfully." << std::endl;

    Scheduler scheduler;
    scheduler.run();

    return 0;
}
