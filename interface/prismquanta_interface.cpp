// quantaporto_interface.cpp
// QuantaPorto - Offline Autonomous LLM Scheduler with Logging
// This C++ application acts as a high-level task scheduler for the QuantaPorto framework.
// It operates in a continuous loop, polling for tasks, checking for timeouts, and
// executing the LLM pipeline via shell scripts.

#include <iostream>
#include <fstream>
#include <filesystem>
#include <chrono>
#include <thread>
#include <cstdlib> // For std::system
#include <ctime>   // For std::ctime
#include <map>
#include <vector>
#include <string> // For std::string
#include <map>

namespace fs = std::filesystem;

// --- Configuration ---
// All paths are relative to the project root directory where the executable is run.

// A map to hold the configuration values
std::map<std::string, std::string> config;

// Function to load configuration from a file
void load_config(const std::string& filename) {
    std::ifstream file(filename);
    if (!file.is_open()) {
        std::cerr << "Error: Could not open config file: " << filename << std::endl;
        return;
    }

    std::string line;
    while (std::getline(file, line)) {
        // Skip comments and empty lines
        if (line.empty() || line[0] == '#') {
            continue;
        }

        // Find the position of the equals sign
        size_t equals_pos = line.find('=');
        if (equals_pos != std::string::npos) {
            // Extract key and value
            std::string key = line.substr(0, equals_pos);
            std::string value = line.substr(equals_pos + 1);

            // Trim leading/trailing whitespace from key and value
            key.erase(0, key.find_first_not_of(" \t\n\r\f\v"));
            key.erase(key.find_last_not_of(" \t\n\r\f\v") + 1);
            value.erase(0, value.find_first_not_of(" \t\n\r\f\v"));
            value.erase(value.find_last_not_of(" \t\n\r\f\v") + 1);

            // Store in the config map
            config[key] = value;
        }
    }

    file.close();
}

// --- Utility Functions ---

/**
 * @brief Writes a log entry to the LOG_FILE with a timestamp.
 *        Creates the log directory if it doesn't exist.
 * @param entry The string message to log.
 */
void write_log(const std::string& entry) {
    // Ensure the log directory exists before attempting to write.
    fs::path log_path(LOG_FILE);
    if (!fs::exists(log_path.parent_path())) {
        fs::create_directories(log_path.parent_path());
    }

    std::ofstream log(LOG_FILE, std::ios_base::app);
    auto now = std::chrono::system_clock::to_time_t(std::chrono::system_clock::now());
    // std::ctime adds a newline, so we remove it to keep the format clean.
    std::string time_str = std::ctime(&now);
    time_str.pop_back();
    log << "[" << time_str << "] " << entry << "\n";
}

/**
 * @brief Loads task priorities from the PRIORITY_FILE.
 * @note This function's logic assumes a 'task_name priority_level' format in the file,
 *       which does not match the current content of priorities.txt. This needs revision
 *       to align with the project's goals for scheduling.
 * @return A map of task names to their integer priority.
 */
std::map<std::string, int> load_priorities() {
    write_log("Loading priorities from " + PRIORITY_FILE + "...");
    std::map<std::string, int> priorities;
    std::ifstream in(PRIORITY_FILE);
    if (!in) {
        write_log("ERROR: Could not open priority file: " + PRIORITY_FILE);
        return priorities;
    }
    std::string task;
    int priority;
    // WARNING: This parsing logic is incompatible with the current `priorities.txt` format.
    while (in >> task >> priority) {
        priorities[task] = priority;
    }
    write_log("Loaded " + std::to_string(priorities.size()) + " priority items.");
    return priorities;
}

/**
 * @brief Loads behavioral rules from the RULES_FILE.
 * @note This function reads a plain text file line-by-line. It must be updated
 *       to parse the XML structure of rules.xml using a proper XML library.
 * @return A vector of strings, where each string is a line from the file.
 */
std::vector<std::string> load_rules() {
    write_log("Loading rules from " + RULES_FILE + "...");
    std::vector<std::string> rules;
    std::ifstream in(RULES_FILE);
    if (!in) {
        write_log("ERROR: Could not open rules file: " + RULES_FILE);
        return rules;
    }
    std::string line;
    // WARNING: This parsing logic is incorrect for an XML file.
    while (std::getline(in, line)) {
        rules.push_back(line);
    }
    write_log("Loaded " + std::to_string(rules.size()) + " rules.");
    return rules;
}

/**
 * @brief Checks if the system is currently in a timeout period.
 *        A timeout is active if the TIMEOUT_MARKER file exists and is recent.
 * @return True if in timeout, false otherwise.
 */
bool in_timeout() {
    if (!fs::exists(TIMEOUT_MARKER)) return false;

    auto last_modified = fs::last_write_time(TIMEOUT_MARKER);
    auto now = fs::file_time_type::clock::now();
    auto diff = std::chrono::duration_cast<std::chrono::seconds>(now - last_modified).count();

    bool timed_out = diff < TIMEOUT_DURATION_SEC;
    if (timed_out) {
        write_log("Timeout marker active. Skipping task execution.");
    } else {
        // If timeout has expired, remove the marker file.
        fs::remove(TIMEOUT_MARKER);
        write_log("Timeout expired. Removing marker file.");
    }
    return timed_out;
}

/**
 * @brief Creates or updates the timeout marker file to the current time.
 */
void set_timeout() {
    std::ofstream out(TIMEOUT_MARKER);
    out << "timeout";
    write_log("Timeout marker updated.");
}

/**
 * @brief Executes the main LLM pipeline script.
 * @note This is a placeholder implementation. The system call should be updated to
 *       dynamically select a task and chain the `generate_prompt.sh` and `run_llm.sh`
 *       scripts as per the project plan.
 */
void run_pipeline() {
    write_log("Running pipeline script...");
    // TODO: Replace this with a dynamic command.
    // Example of a future, more dynamic command:
    // std::string command = "echo 'Document content...' | ./scripts/generate_prompt.sh summarize-quantaporto | ./scripts/run_llm.sh";
    int status = std::system(("bash scripts/run_task.sh " + PROMPT_FILE).c_str());
    if (status != 0) {
        write_log("Pipeline execution failed. Exit code: " + std::to_string(status));
        set_timeout();
    } else {
        write_log("Pipeline executed successfully.");
    }
}

int main() {
    // Load the configuration from the environment file
    load_config("config/environment.txt");

    // Get the configuration values from the map
    const std::string LOG_FILE = config["LOG_FILE"];
    const std::string PROMPT_FILE = config["PROMPT_FILE"];
    const std::string TIMEOUT_MARKER = config["TIMEOUT_MARKER"];
    const std::string RULES_FILE = config["RULES_FILE"];
    const std::string PRIORITY_FILE = config["PRIORITY_FILE"];
    const int POLL_INTERVAL_SEC = std::stoi(config["POLL_INTERVAL_SEC"]);
    const int TIMEOUT_DURATION_SEC = std::stoi(config["TIMEOUT_DURATION_SEC"]);

    std::cout << "QuantaPorto Task Manager Initialized.\n";
    write_log("Interface startup initiated.");

    // NOTE: The loaded rules and priorities are not currently used in the main loop.
    auto rules = load_rules();
    auto priorities = load_priorities();

    while (true) {
        write_log("Polling loop triggered.");

        if (in_timeout()) {
            write_log("System is in timeout. Awaiting next poll...");
        } else {
            run_pipeline();
        }

        std::this_thread::sleep_for(std::chrono::seconds(POLL_INTERVAL_SEC));
    }

    return 0;
}
