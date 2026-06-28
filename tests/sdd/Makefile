CXX = g++
CXXFLAGS = -std=c++17 -Icpp -Icards
BIN_DIR = bin

all: $(BIN_DIR)/sorrel_test

$(BIN_DIR)/sorrel_test: cards/MLAppClass.cpp cards/MLPipelineClass.cpp
	@mkdir -p $(BIN_DIR)
	$(CXX) $(CXXFLAGS) $^ -o $@

test: all
	@./$(BIN_DIR)/sorrel_test

clean:
	rm -rf $(BIN_DIR)

.PHONY: all test clean
