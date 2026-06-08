#include "Config.h"
#include <iostream>
#include <vector>
#include <string>
#include <filesystem>
#include <fstream>
#include <chrono>
#include <ctime>
#include <algorithm>
#include <cstdlib>
#include <sstream>
#include <sys/wait.h>

namespace fs = std::filesystem;

class PortoManager {
public:
    PortoManager() : m_scriptsDir("scripts"), m_logFile("logs/quantaporto.log") {}

    bool initialize(const std::string& configFile) {
        m_config.load(configFile);
        m_config.load(".quanta");

        auto scriptsDirOpt = m_config.getString("SCRIPTS_DIR");
        if (scriptsDirOpt) {
            m_scriptsDir = *scriptsDirOpt;
        }

        auto logFileOpt = m_config.getString("LOG_FILE");
        if (logFileOpt) {
            m_logFile = *logFileOpt;
        }

        if (!fs::exists(m_scriptsDir)) {
            std::cerr << "Error: Scripts directory does not exist: " << m_scriptsDir << std::endl;
            return false;
        }

        discoverScripts();

        writeLog("Porto Manager initialized. Discovered " + std::to_string(m_scripts.size()) + " scripts.");
        return true;
    }

    void writeLog(const std::string& message) {
        fs::path logPath(m_logFile);
        if (!fs::exists(logPath.parent_path())) {
            fs::create_directories(logPath.parent_path());
        }

        std::ofstream log(m_logFile, std::ios_base::app);
        if (log.is_open()) {
            auto now = std::chrono::system_clock::to_time_t(std::chrono::system_clock::now());
            std::string timeStr = std::ctime(&now);
            if (!timeStr.empty() && timeStr.back() == '\n') {
                timeStr.pop_back();
            }
            log << "[" << timeStr << "] [PortoManager] " << message << "\n";
        }
    }

    void discoverScripts() {
        m_scripts.clear();
        if (!fs::exists(m_scriptsDir)) return;

        for (const auto& entry : fs::directory_iterator(m_scriptsDir)) {
            if (entry.is_regular_file() && entry.path().extension() == ".sh") {
                auto perms = entry.status().permissions();
                if ((perms & fs::perms::owner_exec) != fs::perms::none ||
                    (perms & fs::perms::group_exec) != fs::perms::none ||
                    (perms & fs::perms::others_exec) != fs::perms::none) {
                    m_scripts.push_back(entry.path().filename().string());
                }
            }
        }
        std::sort(m_scripts.begin(), m_scripts.end());
    }

    void listScripts() {
        std::cout << "\n--- Available Porto Scripts ---\n";
        if (m_scripts.empty()) {
            std::cout << "No executable scripts found in " << m_scriptsDir << std::endl;
        } else {
            for (size_t i = 0; i < m_scripts.size(); ++i) {
                std::cout << (i + 1) << ". " << m_scripts[i] << std::endl;
            }
        }
        std::cout << "-------------------------------\n";
    }

    std::string sanitize(const std::string& input) {
        std::string sanitized;
        for (char c : input) {
            if (std::isalnum(c) || c == '_' || c == '-' || c == '.' || c == '/' || c == ' ') {
                sanitized += c;
            }
        }
        return sanitized;
    }

    bool executeScript(const std::string& scriptName, const std::string& args = "") {
        fs::path scriptPath = fs::path(m_scriptsDir) / scriptName;
        if (!fs::exists(scriptPath)) {
            std::cerr << "Error: Script not found: " << scriptPath << std::endl;
            return false;
        }

        std::string sanitizedArgs = sanitize(args);
        writeLog("Executing script: " + scriptName + (sanitizedArgs.empty() ? "" : " with sanitized args: " + sanitizedArgs));
        std::cout << "Executing: " << scriptName << " " << sanitizedArgs << " ..." << std::endl;

        std::string command = "bash " + scriptPath.string() + " " + sanitizedArgs;
        int status = std::system(command.c_str());

        int exitCode = -1;
        if (WIFEXITED(status)) {
            exitCode = WEXITSTATUS(status);
        }

        if (exitCode == 0) {
            writeLog("Script executed successfully: " + scriptName);
            std::cout << "Success: " << scriptName << " finished with exit code 0." << std::endl;
            return true;
        } else {
            writeLog("Script failed: " + scriptName + " with exit code " + std::to_string(exitCode));
            std::cerr << "Error: " << scriptName << " failed with exit code " << exitCode << std::endl;
            return false;
        }
    }

    void showHelp() {
        std::cout << "\n--- Porto Manager Help ---\n";
        std::cout << "list           : List available porto scripts\n";
        std::cout << "run <id|name> [args] : Run a script by its ID (index) or filename with optional arguments\n";
        std::cout << "help           : Show this help message\n";
        std::cout << "exit           : Exit the application\n";
        std::cout << "--------------------------\n";
    }

    void run() {
        std::cout << "Porto Manager Started. Type 'help' for commands." << std::endl;

        std::string line;
        while (true) {
            std::cout << "\nPorto Manager > ";
            if (!std::getline(std::cin, line)) break;

            std::stringstream ss(line);
            std::string cmd;
            ss >> cmd;

            if (cmd == "exit") {
                break;
            } else if (cmd == "list") {
                listScripts();
            } else if (cmd == "help") {
                showHelp();
            } else if (cmd == "run") {
                std::string target;
                ss >> target;
                if (target.empty()) {
                    std::cout << "Usage: run <id|name> [args]" << std::endl;
                    continue;
                }

                std::string args;
                std::getline(ss, args);
                if (!args.empty()) {
                    size_t first = args.find_first_not_of(" \t");
                    if (first != std::string::npos) {
                        args = args.substr(first);
                    } else {
                        args = "";
                    }
                }

                bool found = false;
                try {
                    size_t index = std::stoul(target);
                    if (index > 0 && index <= m_scripts.size()) {
                        executeScript(m_scripts[index - 1], args);
                        found = true;
                    }
                } catch (...) {}

                if (!found) {
                    auto it = std::find(m_scripts.begin(), m_scripts.end(), target);
                    if (it != m_scripts.end()) {
                        executeScript(*it, args);
                        found = true;
                    }
                }

                if (!found) {
                    std::cout << "Error: Script not found: " << target << std::endl;
                }
            } else if (!cmd.empty()) {
                std::cout << "Unknown command: " << cmd << ". Type 'help' for usage." << std::endl;
            }
        }
        std::cout << "Exiting Porto Manager." << std::endl;
    }

private:
    Config m_config;
    std::string m_scriptsDir;
    std::string m_logFile;
    std::vector<std::string> m_scripts;
};

int main() {
    PortoManager manager;
    if (manager.initialize("environment.txt")) {
        manager.run();
        return 0;
    }
    return 1;
}
