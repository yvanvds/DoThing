# Recurring tasks

Use the Sonarqube MCP to check for coverage and find the most important things to improve upon.

Use the Sonarqube MCP to check for duplications and fix those.

Write sensible tests for the code we just implemented.

Review copilot-instructions.md and see if we can improve it based on what we are doing.

# feature implementation

## General interface
If the internet connection is bad, logging in to smartschool fails. This means messages are not retrieved on startup. We should add something to retry the login.

## Message composer



## AI chat


## Outlook
Downloading attachements seems to fail


## Issues

If the app crashes or errors, we should be able to gather important information. And have a panel that shows it so that a user is able to copy that and paste it into a github issue. If we organize this right, it might make debugging easier. But we need to keep in mind that we will post the issue into github copilot. So the information should be structured in a way that is most relevant for github, not for a human debugger. (But it should still be readable).