# Development Guide – AsBuiltReport.Microsoft.Teams

This document outlines the development environment, tools, and workflows used to build and maintain this PowerShell module. It complements the user-facing `README.md` and is intended for contributors or future maintainers.

Please keep in mind, this project is part of the [AsBuiltReport](https://www.asbuiltreport.com/) project maintained by [Tim Carman](https://github.com/tpcarman). Dont forget to follow the advice in [AsBuiltReport.Core CONTRIBUTING.md](https://github.com/AsBuiltReport/AsBuiltReport.Core?tab=contributing-ov-file)

---


## 📒 Code Editor
As much as I used to love ISESteriods, the world has moved on. So, similar to AsBuiltReport.Core, we highly encourage you use the multi-platform code editor [Visual Studio Code (VS Code)](https://code.visualstudio.com/docs) when developing code for AsBuiltReport.Microsoft.Teams.


## 🧰 Environment Requirements

- **Operating System**: Windows 10/11 or Server 2019+
- **PowerShell Version**: 7.x (Core) recommended; 5.1 supported with caveats
- **Execution Policy**: `RemoteSigned` or `Bypass` for local development
- **Editor**: Visual Studio Code with PowerShell extension
  - Reccomended: [PowerShellProTools](https://marketplace.visualstudio.com/items?itemName=ironmansoftware.powershellprotools) by IronMan Software. It's free now so there's really no excuse not to.
  - Optional: GitHub Copilot for code suggestions
  - Optional: PSScriptAnalyzer for linting


---

## 📦 Required Modules

Install the following modules before development:

```powershell
Install-Module -Name AsBuiltReport.Core -Scope CurrentUser
Install-Module -Name Microsoft.Graph -Scope CurrentUser
Install-Module -Name MicrosoftTeams -Scope CurrentUser
```
⚠️ Note: Specific versions may be required for compatibility. See RequiredModules in the .psd1 file

## 🧪 Testing & Validation

### Internal Testing
Your best place to start is by updating the settings in `./Dev/Test-AbrReport.ps1` to suit your environment and then running it to;
* Run through all the *.PS1 files in `./Src` and check that they sucsessfully import into the PowerShell environment
* Test for and import all the required PowerShell modules
* Run the report using settings defined in `Test-AbrReport.ps1` using the data in `./Samples`

### Sample Test Data
Running `AsBuiltReport.Microsoft.Teams` to pull data can be an extremely time consuming process, especially if you are pulling data from a live M365 tenant.
We've provided some sanitized real world sample data in `./Dev/Samples` which `Test-AbrReport.ps1` will use by default.
You CAN point the testing to a production tenant, but we reccomend only doing this in the later stages of testing.

⚠️ Note: If you are adding a function that is not covered in the test data, please consider exporting the data from your test tenant and using offline cache instead. We dont want Microsoft thinking our tools are a burden!

Additionally, if you are adding a feature that requires additional sample data, please include relevant sanitized sample data in `./Dev/Samples`

### Creating Sample Data
Dont like the included sample data? create your own!
This can be used for development or in the case of high security environments to export the data for processing on a less locked down machine

WARNING: THERE IS NO ENCRYPTION ON THE EXPORTED DATA, HANDLE IT LIKE YOU WOULD ANY OTHER PRIVILEGED INFORMATION!
ENSURE ANY SAMPLE DATA UPLOADED TO THIS PROJECT IS SANTIZED BEFORE RAISING A PULL REQUEST INCLUDING FLATTENING YOUR COMMIT HISTORY

TODO: Add the code for exporting



### Testing Before Build (todo)
- Pester Tests: (To be added)
Consider adding unit tests for key functions in /Tests

### 🛠️ Build & Packaging (todo)
 Module structure follows standard layout:
/AsBuiltReport.Microsoft.Teams/
  ├── AsBuiltReport.Microsoft.Teams.psd1
  ├── AsBuiltReport.Microsoft.Teams.psm1
  ├── Src/
  │    ├── Public/
  │    └── Private/
  ├── Dev/
  │    ├── Samples/
  ├── Docs/
  └── Docs/

- To build for release:
- Update version in .psd1
- Validate manifest with Test-ModuleManifest
- Package using Publish-Module (if pushing to PSGallery)

🧙‍♂️ Gotchas & Notes
• 	Microsoft Graph module may conflict with older Teams cmdlets—test in isolation
• 	JSON config files must be UTF-8 encoded without BOM
• 	Some Graph permissions require admin consent—see

📚 References

AsBuiltReport Framework https://github.com/AsBuiltReport/AsBuiltReport

Microsoft Graph PowerShell SDK   https://learn.microsoft.com/en-us/powershell/microsoftgraph/

Microsoft Teams PowerShell Module https://learn.microsoft.com/en-us/powershell/module/teams/

🧠 Contributor Notes

If you're contributing:

Fork the repo and submit PRs from feature branches

Include test cases or sample output where possible

Document any new config options in /Docs
