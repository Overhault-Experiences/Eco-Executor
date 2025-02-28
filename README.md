# Eco Executor🍃
This is a plugin made for developers to pentest or debug their game in studio. This plugin almost replicates executor API and the UI was inspired by the KRNL executor (which now has been shutdown)
Also, the executor uses an API called eAPI (a xAPI but it has been modified to fit perfectly with the level 5 identity since xAPI replicates executor functions and made it work with level 2 identity scripts)

## Features📦
 - Eco Executor UI and Syntax Highlighting
![Screenshot 2025-02-08 141832](https://github.com/user-attachments/assets/470db849-a2c2-46fc-80b9-4f6b8dfb0740)
 - Client Sided Execution
![Screenshot 2025-02-08 141911](https://github.com/user-attachments/assets/f190bb58-f4f4-4f1a-b0a6-06cafa2cb8af)
- Configurable Execution (Client | Studio)
 ![Screenshot 2025-03-01 062326](https://github.com/user-attachments/assets/e6001d4b-4ff4-4241-84da-d8486baac9ea)
 - Script Tab Support
![Screenshot 2025-02-08 142006](https://github.com/user-attachments/assets/6b1798c4-23d0-46d7-9528-b64b8ff612fe)
 - Syntax Error Highlighting
![Screenshot 2025-02-08 142043](https://github.com/user-attachments/assets/f3fceeaa-fb4e-4321-971b-4cec6cc45fda)
 - Hovering the red number will show the syntax error message
![Screenshot 2025-02-08 142558](https://github.com/user-attachments/assets/fdc61f76-7a62-4a23-bae9-ceab2f1b37ba)
 - File System
![Screenshot 2025-02-08 142117](https://github.com/user-attachments/assets/57ddef28-e00a-4438-9e52-569b266060d4)
 - File Store
![Screenshot 2025-02-15 115032](https://github.com/user-attachments/assets/406926e6-86b5-4909-bcd8-714bd657a011)
 - Custom Console for Eco Executor
![Screenshot 2025-02-08 142349](https://github.com/user-attachments/assets/4a7c906d-d7df-418b-a74d-71522ab37f95)
- Eco Executor Documentation (unfinished)
![Screenshot 2025-02-08 142510](https://github.com/user-attachments/assets/ec3c2426-61ed-4254-a3b8-c8e40fb18360)

## Installation📥
Go to [releases](https://github.com/Overhault-Experiences/Eco-Executor/releases) and download the rbxmx file in the latest release.
Insert the rbxmx file into the game and 'save it as local plugin'. There should be a toolbar in the plugins tab (click to config the Eco Executor)
Make sure that in the security settings (game settings at security section) the Enable Studio Access to API Services and Enable Http requests has been enabled, otherwise some functions may not work!

## Warning⚠️
Running in an unpublished game will make some executor functions non-functional/unusable.

## Additional Infoℹ️
### Comment directives
 - `--!noSyntaxCheck`: (Eco Executor's script editor) No error highlights
 - `--!nameFile FileName`: (Save to FileStore) Useful to save a script named properly to file store
 - `--!overwriteFile FileName`: (Save to FileStore) Useful in overwriting an already saved script in file store (so you don't need to delete it and save it again)

# Credits🔷
 - [SQLanguage - xAPI](https://github.com/3skue/xAPI4/) - For executor functions
 - [HeyWhatsHisFace - Converter Module](https://devforum.roblox.com/t/converter-module-instance-%E2%86%94-table-save-instances-to-datastores-and-more/1820480) -- For saveinstance() support
 - [NiceBuild1 - Syntax Highlighter](https://devforum.roblox.com/t/realtime-richtext-lua-syntax-highlighting/2500399?u=experience_member) -- For real time syntax highlighting (also it has been modified)
