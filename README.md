# Ken's Bicep Stuff

This repo is a collection of Bicep experiments that I'm doing as I start to work with the language.  

Some of it works, some of it doesn't and all of it is 100% as-is if you want to try it.

## Contents

* `joindomain-module.bicep` is a module that calls the extension to join a VM to AD.  This one works if you feed it the parameters correctly.
* `storageaccount.bicep` is a basic bicep file to create a storage account, very similar to the one used in the [Bicep tutorial](https://github.com/Azure/bicep/blob/main/docs/tutorial/01-simple-template.md).
* `subscriptionId.bicep` is a very simple bicep file that tests referencing an existing resource by creating the resource reference with the existing tag and outputting the subcription ID for the resource.
* `UbuntuVM-SSH.bicep` and `UbuntiVM-parameters.json` are a bicep file and its associated parameters file to create an Ubuntu VM with Azure that is configured for SSH-only authentication.  The SSH public key and other secrets are included via key vault references. Working.
* `Win2019-domainjoined.bicep` and `Win2019-domainjoined-parameters.json` are a work in progress to create a VM that is domain joined by using the joindomain module mentioned above.  Currently not working.
* `Win2019VM.bicep` and `Win2019-parametdrs.json` deploy a basic Windows Server 2019 VM without domain join.  Working.
* `WVDsessionHostVM.bicep` and `WVDSessionHostVM-parameters.json` deploy a VM with Windows 10 EVD.  This is a WIP with the goal of creating a bicep file that creates a WVD session host and adds it to a specifed host pool.


