# Automated Pipeline

This document outlines the automated pipeline for this project.

## 1. Code Commit

When a developer commits code to the repository, a webhook triggers the CI/CD pipeline.

## 2. Build and Test

The pipeline checks out the code, builds the project, and runs all tests.

## 3. Deployment

If the build and tests are successful, the pipeline deploys the application to the staging environment.

## 4. Production Release

After successful testing in the staging environment, the release is manually promoted to production.

# Pipeline Strategy

This document outlines the strategy for a pipeline that uses a C++ console application to manage tasks based on timestamps in a text file.

## Pipeline Components

1.  **Task Scheduler**: A mechanism to schedule tasks by writing their execution times to a text file.
2.  **Timestamp File (`tasks.txt`)**: A simple text file where each line contains the timestamp and details of a task to be executed.
3.  **C++ Daemon**: A lightweight C++ console application that continuously runs in the background, monitoring `tasks.txt` for tasks to execute.

## Workflow

1.  **Task Creation**: A user or another process adds a new task to `tasks.txt`. Each line in the file will follow a specific format, e.g., `YYYY-MM-DD HH:MM:SS;task_command;task_argument`.
2.  **Daemon Polling**: The C++ daemon reads `tasks.txt` at regular intervals (e.g., every 60 seconds).
3.  **Task Execution**: For each line in the file, the daemon parses the timestamp. If the current time is greater than or equal to the task's timestamp, the daemon executes the task.
4.  **Task Completion**: Upon successful execution, the daemon removes the task's entry from `tasks.txt` to prevent re-execution.
5.  **Resumption**: If the daemon is restarted, it will read `tasks.txt` and execute any tasks that were scheduled to run during the downtime.

# C++ Daemon Design

The C++ daemon will be a lightweight, cross-platform console application with the following design:

## Core Components

1.  **Configuration Manager**: Responsible for loading configuration settings, such as the path to `tasks.txt` and the polling interval.
2.  **File Monitor**: Monitors `tasks.txt` for changes. This can be implemented using a simple polling mechanism.
3.  **Task Parser**: Parses each line of `tasks.txt` to extract the timestamp and task details.
4.  **Task Executor**: Executes the task command. This component should handle command execution in a separate process to avoid blocking the daemon.
5.  **Logger**: Logs daemon activities, such as task execution, errors, and status changes.

## Behavior

1.  **Initialization**: On startup, the daemon will:
    *   Load configuration settings.
    *   Perform an initial check of `tasks.txt` and execute any overdue tasks.
2.  **Main Loop**: The daemon will enter a loop where it:
    *   Sleeps for the configured polling interval.
    *   Wakes up and reads `tasks.txt`.
    *   For each task, it will:
        *   Parse the timestamp.
        *   If the task is due, execute it.
        *   If the task is executed successfully, remove it from the file.
3.  **Signal Handling**: The daemon should gracefully handle signals like `SIGINT` and `SIGTERM` to ensure a clean shutdown.
