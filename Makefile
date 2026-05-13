CXX = g++
CXXFLAGS = -std=c++17 -Wall -Wextra -Iinterface

TARGET = porto_manager
SRCS = interface/porto_manager.cpp interface/Config.cpp
OBJS = $(SRCS:.cpp=.o)

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CXX) $(CXXFLAGS) -o $(TARGET) $(OBJS)

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -f $(OBJS) $(TARGET)

.PHONY: all clean
