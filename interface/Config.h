#ifndef PRISMQUANTA_CONFIG_H
#define PRISMQUANTA_CONFIG_H

#include <string>
#include <map>
#include <filesystem>
#include <optional>

namespace fs = std::filesystem;

class Config {
public:
    /**
     * @brief Default constructor for the Config object.
     */
    Config();

    /**
     * @brief Loads configuration settings from a specified file.
     * @param configFile The path to the configuration file, relative to the project root.
     * @return True if loading was successful, false otherwise.
     */
    bool load(const std::string& configFile);

    /**
     * @brief Retrieves a configuration value as a string.
     * @param key The configuration key.
     * @return An std::optional containing the value if the key exists, otherwise an empty optional.
     */
    std::optional<std::string> getString(const std::string& key) const;

    /**
     * @brief Retrieves a configuration value as an integer.
     * @param key The configuration key.
     * @return An std::optional containing the value if the key exists and is a valid integer, otherwise an empty optional.
     */
    std::optional<int> getInt(const std::string& key) const;

private:
    std::map<std::string, std::string> m_values;
};

#endif //PRISMQUANTA_CONFIG_H