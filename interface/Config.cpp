#include "Config.h"
#include <fstream>
#include <iostream>

Config::Config() = default;

bool Config::load(const std::string& configFile) {
    std::ifstream file(configFile);
    if (!file.is_open()) {
        std::cerr << "Error: Could not open config file: " << configFile << std::endl;
        return false;
    }

    std::string line;
    while (std::getline(file, line)) {
        // Skip comments and empty lines
        if (line.empty() || line[0] == '#') {
            continue;
        }

        const auto equals_pos = line.find('=');
        if (equals_pos != std::string::npos) {
            std::string key = line.substr(0, equals_pos);
            std::string value = line.substr(equals_pos + 1);

            // Trim leading/trailing whitespace
            const auto str_trim = [](std::string& s) {
                s.erase(0, s.find_first_not_of(" \t\n\r\f\v"));
                s.erase(s.find_last_not_of(" \t\n\r\f\v") + 1);
            };

            str_trim(key);
            str_trim(value);

            if (!key.empty()) {
                m_values[key] = value;
            }
        }
    }
    return true;
}

std::optional<std::string> Config::getString(const std::string& key) const {
    if (auto it = m_values.find(key); it != m_values.end()) {
        return it->second;
    }
    return std::nullopt;
}

std::optional<int> Config::getInt(const std::string& key) const {
    auto valueStr = getString(key);
    if (!valueStr) {
        return std::nullopt;
    }
    try {
        return std::stoi(*valueStr);
    } catch (const std::invalid_argument& ia) {
        std::cerr << "Warning: Invalid integer format for key '" << key << "': " << *valueStr << std::endl;
        return std::nullopt;
    } catch (const std::out_of_range& oor) {
        std::cerr << "Warning: Integer value out of range for key '" << key << "': " << *valueStr << std::endl;
        return std::nullopt;
    }
}