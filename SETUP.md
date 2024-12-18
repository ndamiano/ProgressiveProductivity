# Setting up your local development environment

## Visual Studio Code

This project is configured to use Visual Studio Code as the primary code editor.
You can use any code editor of your choice, but the instructions in this guide will be specific to Visual Studio Code.

You can install Visual Studio Code from [here](https://code.visualstudio.com/) or use any package manager of your choice.

- For macOS users, you can use [Homebrew](https://brew.sh/) to install Visual Studio Code.

### Extensions

The following extensions are recommended for this project:

- [EditorConfig for VS Code](https://marketplace.visualstudio.com/items?itemName=EditorConfig.EditorConfig) (`editorconfig.editorconfig`)
- [Lua](https://marketplace.visualstudio.com/items?itemName=sumneko.lua) (`sumneko.lua`)
- [Factorio Modding Tool Kit (FMTK)](https://marketplace.visualstudio.com/items?itemName=justarandomgeek.factoriomod-debug) (`justarandomgeek.factoriomod-debug`)

Suggestions for these extensions are included in the `.vscode/extensions.json` file for your convenience,
to prompt you to install them when you open the project in Visual Studio Code.
Configurations for these extensions are already included in the `.vscode` directory as well.

#### Factorio Modding Tool Kit

The Factorio Modding Tool Kit (FMTK) extension is a must-have for Factorio modding.
It provides a lot of useful features, such as code completion for the Factorio API, extended tooltips, links to the Factorio API documentation, type validation and more.

To use these features, you need to have the Factorio game installed on your computer.
The extension will create the library files for you when you run the "Factorio: Select Version" command from the command palette or when you click the "Select Factorio Version" button in the status bar.
This will also update the `.vscode/settings.json` file within this project.
As these are user specific settings that will vary from user to user, they should not be included in the repository.
Please move them over to your user settings manually.

To do so, open the `.vscode/settings.json` file and look for two entries similar to these:

```json
"factorio.versions": [
    {
        "name": "Steam",
        "factorioPath": "~/Library/Application Support/Steam/steamapps/common/Factorio/factorio.app/Contents/MacOS/factorio",
        "active": true
    }
],
```

and

```json
"Lua.workspace.userThirdParty": [
    "/Users/your_user_name/Library/Application Support/Code/User/workspaceStorage/875550e0b6bbf54102d1ccdbe42cf16a/justarandomgeek.factoriomod-debug/sumneko-3rd"
],
```

Cut them out and paste them into your user settings file.
You can get to that file quickly by running the "Preferences: Open User Settings (JSON)" command from the command palette.
