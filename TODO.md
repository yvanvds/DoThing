# Recurring tasks

Use the Sonarqube MCP to check for coverage and find the most important things to improve upon.

Use the Sonarqube MCP to check for duplications and fix those.

Write sensible tests for the code we just implemented.

Review copilot-instructions.md and see if we can improve it based on what we are doing.

# feature implementation

## Message composer

Add a table to the database to store messages that are not sent yet. When a message can't be sent, (probably because of a network error) we should store it in this table and have something running that retries sending them every five minutes.

Add persistence/retry tests once you implement the unsent-messages table and recovery flow.

