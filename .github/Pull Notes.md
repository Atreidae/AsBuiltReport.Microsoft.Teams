



# Testing code and replication of ABR code and data
Having picked this module up after a 2 year hiatus, I became accutley aware of how dodgy my test environment was
I was also VERY aware of the strain I was placing on the M365 tenants I was testing against

As such, I've built a fair amount of code to support "Offline" testing of the module. Especially as pulling a Teams tenant config can take quite some time

To ensure compatability with the ABR project and to not change the parameters for Invoke-AsBuiltReport I've built a few functions that replicate ABR.Core functionaility to setup the environment based on a users ABR.Core and ABR.Module config files rather than adding an -USeOfflineData and -SaveOfflineData to the Invoke-AsBuiltReport.Microsoft.Teams fucntion.

All of these functions and sample data have been placed in the /Dev folder and are not imported or exported in the built PowerShell module but I have still tried to keep it tidy and documented incase someone else wants to contribute.

# Offline Exports for secure environments
I was tempted to move some of this to the module itself. Mainly to allow consultants to run an export in a protected environment, download the config cache and then build the real report on their machine.

This is because I've personally had plenty of customers who only allow PowerShell access to their tenants from their secure network, and wont allow PowerShell module installs there. This feature at least allows them to download the github repo and run an environment export assuming they allow unsigned code.

# Sample Tenant Data
Again, another thing I found after having to pick up the code after a long time, there was nothing I could build my code against without bashing the M365 service but more importantly for contributors, they might not have access to an M365 dev tenant they can export. So I've run some offline exports and included them in the samples folder.

If a new cmdlet comes out that you need to document, use the cmdlet and pipe it to Export-AbrCsOfflineVariable
