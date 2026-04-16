# Recurring tasks

Use the Sonarqube MCP to check for coverage and find the most important things to improve upon.

Use the Sonarqube MCP to check for duplications and fix those.

Write sensible tests for the code we just implemented.

Review copilot-instructions.md and see if we can improve it based on what we are doing.

# feature implementation

## General interface
If the internet connection is bad, logging in to smartschool fails. This means messages are not retrieved on startup. We should add something to retry the login. Also it seems like smartschool is only tried once. And then we give up. For now I mostly succeed loggin in,  if I restart the app a few times. So most likely a few retries, maybe after waiting a few seconds. Say we try like five times before we give up. And add a command 'restart connection'.

## Message composer
Add options to forward and reply to messages. But first we need to check smartschool. See if reply and sending new mail is really something different.


## AI chat
How are we going to continue here? Just orchestration seems limited. I think it would mean we have very strict actions coupled to buttons. Like 'reply to this email' or 'what should i do today'. A less strict AI which behaves more as a bot  might be preferable. Maybe we should expose most of the app features and then some to the 

Right now we just keep continuing the same chat session. We need to be able to start a new session. Right now we have a chat button in the side bar and an open chat command. The action they are linked to doesn't do anything yet. I want a new panel that can be displayed in the context panel. Is should be displayed by clicking the chat button or dhe open chat command (rename to open chat history).

In there we can show a history of stored conversations. With the ability to reopen them and delete them. And a button to end the current conversation and start a new one. Also, on app start do not load the last conversation but start with a new chat session.

## Outlook
Downloading attachements seems to fail


## Issues

If the app crashes or errors, we should be able to gather important information. And have a panel that shows it so that a user is able to copy that and paste it into a github issue. If we organize this right, it might make debugging easier. But we need to keep in mind that we will post the issue into github copilot. So the information should be structured in a way that is most relevant for github, not for a human debugger. (But it should still be readable).