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

--- 
I would instruct claude code later on to review the database part of the code. I can just delete the current database, because we are in early stages of development. So It's not problem if edits are destructive.

table message_participants:
Drop the entire table and just request these details when we open a message detail. It will cost a bit more data, but it's less cumbersome.

table contact_identities:
id: keep (primary key)
contact_id: keep (foreign key)
source: keep (smartschool or outlook for now)
external_id: should be email adress or smartschool userID -> the smartschool one is tricky.
Smartschool only gives us a sender name when we retrieve the message list. We can user use 
MessagesService.searchRecipients with this name to get the id for this user. We could also NOT do that, but then we cannot create a unified inbox because we cannot add the sender to contacts.
display_name_snapshot -> display_name
avatar_url_snapshot -> avatar_url
raw_payload_json -> should not be needed. Mostly null or contains info we already have.
last_seen_at: are we interested in this? We can occasionally purge contacts with nothing attached to them later.
last_enriched_at: allways NULL
created_at: do we need this?
updated_at: do we need this?

table contacts:
id: keep (primary key)
display_name: keep. We need to display a name for the contact. But it is used wrong sometimes. When we parse a sent message from the sent_items box in smartschool, we only get one string with all the recipients. We need to adjust for that: split on comma's, and again figure out the smartschool user id.
primary_avatar_url: drop. We can just request it from contact_identities and see if one of those entries has an avatar set up.
kind: drop - never used
is_stub: probably not needed? The value is always 1.
created_at: do we need this?
updated_at: do we need this?

table messages:
id: keep (primary key)
source: keep (outlook or smartschool)
external_id: keep (id on outlook or smartschool)
mailbox: keep (inbox or sent) We need this if we want to move the message or delete it.
subject: keep

Not sure about body_raw, body_text and body_format. We can just retrieve that when we open the message details. Originally we stored it so that we later on can search in messages. But we can just store the content in message_fts_content if we retrieve for the first time and be done with it. (it wont change afterwards)

sent_at: is always null (sent messages also have a time for recieved at)
received_at: keep 
remotely_updated_at: drop (is always null)
is_read: keep
is_archived: keep
is_deleted: is used, but should we not delete the message entry in this case?
has_attachments: keep

detail_fetched_at: drop if we don't store details
header_fingerprint: keep for now (and query copilot later about use)
raw_header_json: keep for now (and query copilot later about use)
raw_detail_json: keep for now (and query copilot later about use)
created_at: do we need this?
updated_at: do we need this?
account_key, conversation_key and parent_external_id are always null. That said, it would be good if messages are assigned to a contact on retrieval. Right now, assigning to a contact is done when we open the messages list and not stored. The assigned contact should be the sender, or the recipient if the sender is the current user.
Not sure what to do if we sent the message with multiple recipients though. If it's only a few, we might just assign the message to more than one contact (but that requires a separate table, because of many to many relationship). But we don't want to do that if the message is sent to like a hundred people.

The idea about conversations looks interesting. But probably not feasable. Smartschool does not keep track of that kind of information. The smartschool inbox is just one long linear list with messages. And sent items are in another folder. There is no common id, even replies are not tied to an original message. So ordening them by contact and date seems the best we can do here.

table provider_accounts is empty. It will be used for adding more mailboxes later on, perhaps. Leave it alone for now i guess.

