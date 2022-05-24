﻿<###
# Overview:
    This script is used to enable AAD for Kubernetes Services in a Subscription.

# Control ID:
    Azure_KubernetesService_AuthN_Enabled_AAD

# Display Name:
    AAD should be enabled in Kubernetes Service.

# Prerequisites:
    1. Contributor or higher privileges on the Kubernetes Services in a Subscription.
    2. Must be connected to Azure with an authenticated account.
    3. RBAC must be enabled on Kubernetes cluster.

# Steps performed by the script:
    To remediate:
        1. Validate and install the modules required to run the script.
        2. Get the list of Kubernetes Services in a Subscription that do not have AAD enabled.
        3. Back up details of Kubernetes Services that are to be remediated.
        4. Enable AAD in all Kubernetes Services in the Subscription.

# Instructions to execute the script:
    To remediate:
        1. Download the script.
        2. Load the script in a PowerShell session. Refer https://aka.ms/AzTS-docs/RemediationscriptExcSteps to know more about loading the script.
        3. Execute the script to enable AAD in all Kubernetes Services in the Subscription. Refer `Examples`, below.

# Examples:
    To remediate:
        1. To review the Kubernetes Services in a Subscription that will be remediated:
           Enable-AADForKubernetes -SubscriptionId 00000000-xxxx-0000-xxxx-000000000000 -PerformPreReqCheck -DryRun

        2. To enable AAD in all Kubernetes Services in a Subscription:
           Enable-AADForKubernetes -SubscriptionId 00000000-xxxx-0000-xxxx-000000000000 -PerformPreReqCheck

        3. To enable AAD in all Kubernetes Services in a Subscription, from a previously taken snapshot:
           Enable-AADForKubernetes -SubscriptionId 00000000-xxxx-0000-xxxx-000000000000 -PerformPreReqCheck -FilePath C:\AzTS\Subscriptions\00000000-xxxx-0000-xxxx-000000000000\202201011212\EnableAADForKubernetesServices\KubernetesClusterWithAADDisabled.csv

        To know more about the options supported by the remediation command, execute:
        Get-Help Enable-AADForKubernetes -Detailed        
###>

function Setup-Prerequisites
{
    <#
        .SYNOPSIS
        Checks if the prerequisites are met, else, sets them up.

        .DESCRIPTION
        Checks if the prerequisites are met, else, sets them up.
        Includes installing any required Azure modules.

        .INPUTS
        None. You cannot pipe objects to Setup-Prerequisites.

        .OUTPUTS
        None. Setup-Prerequisites does not return anything that can be piped and used as an input to another command.

        .EXAMPLE
        PS> Setup-Prerequisites

        .LINK
        None
    #>

    # List of required modules
    $requiredModules = @("Az.Accounts", "Az.Aks", "Az.Resources")

    Write-Host "Required modules: $($requiredModules -join ', ')" -ForegroundColor $([Constants]::MessageType.Info)
    Write-Host "Checking if the required modules are present..."

    $availableModules = $(Get-Module -ListAvailable $requiredModules -ErrorAction Stop)

    # Check if the required modules are installed.
    $requiredModules | ForEach-Object {
        if ($availableModules.Name -notcontains $_)
        {
            Write-Host "Installing $($_) module..." -ForegroundColor $([Constants]::MessageType.Info)
            Install-Module -Name $_ -Scope CurrentUser -Repository 'PSGallery' -ErrorAction Stop
        }
        else
        {
            Write-Host "$($_) module is present." -ForegroundColor $([Constants]::MessageType.Update)
        }
    }
}

function Enable-AADForKubernetes
{
    <#
        .SYNOPSIS
        Remediates 'Azure_KubernetesService_AuthN_Enabled_AAD' Control.

        .DESCRIPTION
        Remediates 'Azure_KubernetesService_AuthN_Enabled_AAD' Control.
        AAD should be enabled in Kubernetes Service.
        
        .PARAMETER SubscriptionId
        Specifies the ID of the Subscription to be remediated.
        
        .Parameter PerformPreReqCheck
        Specifies validation of prerequisites for the command.
        
        .PARAMETER DryRun
        Specifies a dry run of the actual remediation.
        
        .PARAMETER FilePath
        Specifies the path to the file to be used as input for the remediation.

        .INPUTS
        None. You cannot pipe objects to Enable-AADForKubernetes.

        .OUTPUTS
        None. Enable-AADForKubernetes does not return anything that can be piped and used as an input to another command.

        .EXAMPLE
        PS> Enable-AADForKubernetes -SubscriptionId 00000000-xxxx-0000-xxxx-000000000000 -PerformPreReqCheck -DryRun

        .EXAMPLE
        PS> Enable-AADForKubernetes -SubscriptionId 00000000-xxxx-0000-xxxx-000000000000 -PerformPreReqCheck

        .EXAMPLE
        PS> Enable-AADForKubernetes -SubscriptionId 00000000-xxxx-0000-xxxx-000000000000 -PerformPreReqCheck -FilePath C:\AzTS\Subscriptions\00000000-xxxx-0000-xxxx-000000000000\202201011212\EnableAADForKubernetesServices\KubernetesClusterWithAADDisabled.csv

        .LINK
        None
    #>

    param (
        [String]
        [Parameter(ParameterSetName = "DryRun", Mandatory = $true, HelpMessage="Specifies the ID of the Subscription to be remediated")]
        [Parameter(ParameterSetName = "WetRun", Mandatory = $true, HelpMessage="Specifies the ID of the Subscription to be remediated")]
        $SubscriptionId,

        [Switch]
        [Parameter(ParameterSetName = "DryRun", HelpMessage="Specifies validation of prerequisites for the command")]
        [Parameter(ParameterSetName = "WetRun", HelpMessage="Specifies validation of prerequisites for the command")]
        $PerformPreReqCheck,

        [Switch]
        [Parameter(ParameterSetName = "DryRun", Mandatory = $true, HelpMessage="Specifies a dry run of the actual remediation")]
        $DryRun,

        [String]
        [Parameter(ParameterSetName = "WetRun", HelpMessage="Specifies the path to the file to be used as input for the remediation")]
        $FilePath
    )

    Write-Host $([Constants]::DoubleDashLine)
    Write-Host "`n[Step 1 of 4] Preparing to enable AAD for Kubernetes Services in Subscription: $($SubscriptionId)"

    if ($PerformPreReqCheck)
    {
        try
        {
            Write-Host "Setting up prerequisites..."
            Setup-Prerequisites
        }
        catch
        {
            Write-Host "Error occurred while setting up prerequisites. Error: $($_)" -ForegroundColor $([Constants]::MessageType.Error)
            break
        }
    }

    # Get current Azure account context.
    $context = Get-AzContext

    if ([String]::IsNullOrWhiteSpace($context))
    {
        Write-Host "No active Azure login session found. Exiting..." -ForegroundColor $([Constants]::MessageType.Error)
        break
    }

    # Setting up context for the current Subscription.
    $context = Set-AzContext -SubscriptionId $SubscriptionId -ErrorAction Stop
    
    Write-Host $([Constants]::SingleDashLine)
    Write-Host "Subscription Name: $($context.Subscription.Name)"
    Write-Host "Subscription ID: $($context.Subscription.SubscriptionId)"
    Write-Host "Account Name: $($context.Account.Id)"
    Write-Host "Account Type: $($context.Account.Type)"
    Write-Host $([Constants]::SingleDashLine)

    Write-Host "*** To enable AAD for Kubernetes Services in a Subscription, Contributor or higher privileges on the Kubernetes Services are required. ***" -ForegroundColor $([Constants]::MessageType.Info)
    Write-Host $([Constants]::DoubleDashLine)
    Write-Host "`n[Step 2 of 4] Preparing to fetch all Kubernetes Services..."

    $kubernetesServiceResourceType = "Microsoft.ContainerService/managedClusters"
    $kubernetesServiceResources = @()

    # No file path provided as input to the script. Fetch all Kubernetes Services in the Subscription.
    if ([String]::IsNullOrWhiteSpace($FilePath))
    {
        Write-Host "Fetching all Kubernetes Services in Subscription: $($context.Subscription.SubscriptionId)" -ForegroundColor $([Constants]::MessageType.Info)

        # Get all Kubernetes Services in a Subscription
        $kubernetesServiceResources = Get-AzResource -ResourceType $kubernetesServiceResourceType -ErrorAction Stop
    }
    else
    {
        if (-not (Test-Path -Path $FilePath))
        {
            Write-Host "ERROR: Input file - $($FilePath) not found. Exiting..." -ForegroundColor $([Constants]::MessageType.Error)
            break
        }

        Write-Host "Fetching all Kubernetes Services from $($FilePath)" -ForegroundColor $([Constants]::MessageType.Info)

        $kubernetesServiceDetails = Import-Csv -LiteralPath $FilePath
        $validKubernetesServiceDetails = $kubernetesServiceDetails | Where-Object { ![String]::IsNullOrWhiteSpace($_.ResourceId) }
        
        $validKubernetesServiceDetails | ForEach-Object {
            $resourceId = $_.ResourceId

            try
            {
                $kubernetesServiceResource = Get-AzResource -ResourceId $resourceId -ErrorAction SilentlyContinue
                $kubernetesServiceResources += $kubernetesServiceResource
            }
            catch
            {
                Write-Host "Error fetching Kubernetes Services resource: Resource ID - $($resourceId). Error: $($_)" -ForegroundColor $([Constants]::MessageType.Error)
                Write-Host "Skipping this Kubernetes Services resource..." -ForegroundColor $([Constants]::MessageType.Warning)
            }
        }
    }

    $totalKubernetesServices = ($kubernetesServiceResources | Measure-Object).Count

    if ($totalKubernetesServices -eq 0)
    {
        Write-Host "No Kubernetes Service resource found. Exiting..." -ForegroundColor $([Constants]::MessageType.Update)
        break
    }
  
    Write-Host "`nFound $($totalKubernetesServices) Kubernetes Service(s)." -ForegroundColor $([Constants]::MessageType.Update)
    Write-Host "`nFetching all Kubernetes Service configurations..."

    # Includes Kubernetes Services where AAD is enabled.
    $kubernetesServicesWithAADEnabled = @()

    # Includes Kubernetes Services where AAD is disabled.
    $kubernetesServicesWithoutAADEnabled = @()

    # Includes Kubernetes Services that were skipped during remediation. There were errors remediating them.
    $kubernetesServicesSkipped = @()

    $kubernetesServiceResources | ForEach-Object {
        $kubernetesServiceResource = $_
        $resourceId = $_.ResourceId
        $resourceGroupName = $_.ResourceGroupName
        $resourceName = $_.ResourceName
        $location = $_.Location
        $isRBACEnabled = $true
        $isAADEnabled = $false
        try
        {
            $config = Get-AzAksCluster -ResourceGroupName $resourceGroupName -Name $resourceName -WarningAction SilentlyContinue
            
            # Holds Kubernetes cluster RBAC status.
            $isRBACEnabled = $config.EnableRBAC
            $isAADEnabled = -not [String]::IsNullOrWhiteSpace($config.AadProfile)

            if ($isAADEnabled)
            {
                $kubernetesServicesWithAADEnabled += $kubernetesServiceResource
                return
            }

            $kubernetesServicesWithoutAADEnabled += $kubernetesServiceResource | Select-Object @{N='ResourceID';E={$resourceId}},
                                                                                   @{N='ResourceGroupName';E={$resourceGroupName}},
                                                                                   @{N='ResourceName';E={$resourceName}},
                                                                                   @{N='Location';E={$location}},
                                                                                   @{N='IsRBACEnabled';E={$isRBACEnabled}},
                                                                                   @{N='IsAADEnabled';E={$isAADEnabled}}
        }
        catch
        {
            $kubernetesServicesSkipped += $kubernetesServiceResource
        }
    }

    $totalKubernetesServicesWithoutAADEnabled = ($kubernetesServicesWithoutAADEnabled | Measure-Object).Count
    $totalSkippedKubernetesServices = ($kubernetesServicesSkipped | Measure-Object).Count
    
    if ($totalSkippedKubernetesServices -gt 0)
    {
        $colsProperty = @{Expression={$_.ResourceId};Label="Resource ID";Width=40;Alignment="left"},
                        @{Expression={$_.ResourceGroupName};Label="Resource Group Name";Width=20;Alignment="left"},
                        @{Expression={$_.ResourceName};Label="Resource Name";Width=20;Alignment="left"},
                        @{Expression={$_.Location};Label="Location";Width=20;Alignment="left"}

        $kubernetesServicesSkipped | Format-Table -Property $colsProperty -Wrap
    }

    if ($totalKubernetesServicesWithoutAADEnabled -eq 0)
    {
        Write-Host "No Kubernetes Service found with AAD disabled. Exiting..." -ForegroundColor $([Constants]::MessageType.Update)
        break
    }

    Write-Host "`n$($totalKubernetesServicesWithoutAADEnabled) out of $($totalKubernetesServices) Kubernetes Service(s) with AAD disabled." -ForegroundColor $([Constants]::MessageType.Update)

    # Back up snapshots to `%LocalApplicationData%'.
    $backupFolderPath = "$([Environment]::GetFolderPath('LocalApplicationData'))\AzTS\Remediation\Subscriptions\$($context.Subscription.SubscriptionId.replace('-','_'))\$($(Get-Date).ToString('yyyyMMddhhmm'))\EnableAADForKubernetesServices"

    if (-not (Test-Path -Path $backupFolderPath))
    {
        New-Item -ItemType Directory -Path $backupFolderPath | Out-Null
    }

    Write-Host $([Constants]::DoubleDashLine)
    Write-Host "`n[Step 3 of 4] Backing up Kubernetes Service details to $($backupFolderPath)"

    # Backing up Kubernetes Service details.
    $backupFile = "$($backupFolderPath)\KubernetesClusterWithAADDisabled.csv"
    $kubernetesServicesWithoutAADEnabled | Export-CSV -Path $backupFile -NoTypeInformation

    if (-not $DryRun)
    {
        $colsProperty = @{Expression={$_.ResourceId};Label="Resource ID";Width=40;Alignment="left"},
                        @{Expression={$_.ResourceGroupName};Label="Resource Group Name";Width=20;Alignment="left"},
                        @{Expression={$_.ResourceName};Label="Resource Name";Width=20;Alignment="left"},
                        @{Expression={$_.Location};Label="Location";Width=20;Alignment="left"},
                        @{Expression={$_.isRBACEnabled};Label="Is RBAC enabled on Kubernetes Cluster?";Width=20;Alignment="left"},
                        @{Expression={$_.isAADEnabled};Label="Is AAD enabled on Kubernetes Cluster?";Width=20;Alignment="left"}

        $kubernetesServicesWithoutAADEnabled | Format-Table -Property $colsProperty -Wrap
  
        Write-Host "Kubernetes Service details have been backed up to $($backupFile)" -ForegroundColor $([Constants]::MessageType.Update)
        Write-Host "AAD will be enabled for all Kubernetes Services."
        Write-Host "Do you want to add Azure AD groups as administrators on each cluster?" -ForegroundColor $([Constants]::MessageType.Warning) -NoNewline
        
        $addAADGroup = $false
        $input = Read-Host -Prompt "(Y|N)"

        if($input -eq "Y")
        {
            $addAADGroup = $true
        }
        
        Write-Host "Once AAD is enabled, you won't be able to disable again." -ForegroundColor $([Constants]::MessageType.Warning)
        Write-Host "Do you want to enable AAD for all Kubernetes Services? " -ForegroundColor $([Constants]::MessageType.Warning) -NoNewline
            
        $userInput = Read-Host -Prompt "(Y|N)"

        if($userInput -ne "Y")
        {
            Write-Host "AAD will not be enabled for any Kubernetes Services. Exiting..." -ForegroundColor $([Constants]::MessageType.Update)
            break
        }

        Write-Host $([Constants]::DoubleDashLine)
        Write-Host "`n[Step 4 of 4] Enabling AAD for Kubernetes Services..."

        # To hold results from the remediation.
        $kubernetesClusterRemediated = @()
        $kubernetesClusterSkipped = @()

        $setAADProfile = [SetAADProfile]::new()

        $kubernetesServicesWithoutAADEnabled | ForEach-Object {
            $kubernetesServiceResource = $_
            $resourceId = $_.ResourceId
            $resourceGroupName = $_.ResourceGroupName
            $resourceName = $_.ResourceName
            $location = $_.Location
            $isRBACEnabled = $_.IsRBACEnabled
            $aadClientIds = @()

            # Check whether RBAC is enabled on cluster or not. Without RBAC, AAD cannot be enabled.
            if ($isRBACEnabled)
            {
                if ($addAADGroup)
                {
                    Write-Host "Please provide Azure AD Group client id: "
                    $aadClientIds = Read-Host
                }
                else
                {
                    Write-Host "AAD group will not be added to Kubernetes cluster." -ForegroundColor $([Constants]::MessageType.Info)
                }

                # Setting AAD profile config to Kubernetes cluster.
                $res = $setAADProfile.SetAADProfileForCluster($subscriptionId, $resourceName, $resourceGroupName, $location, $aadClientIds)

                if ($content.properties.aadProfile.managed)
                {
                    $kubernetesClusterRemediated += $kubernetesServiceResource
                }
                else
                {
                    $kubernetesClusterSkipped += $kubernetesServiceResource
                }
            }
            else
            {
                $kubernetesClusterSkipped += $kubernetesServiceResource
                return
            }
        }

        Write-Host $([Constants]::DoubleDashLine)
        Write-Host "Remediation Summary:`n" -ForegroundColor $([Constants]::MessageType.Info)
        
        if ($($kubernetesClusterRemediated | Measure-Object).Count -gt 0)
        {
            Write-Host "AAD is successfully enabled on the following Kubernetes cluster(s) in the subscription:" -ForegroundColor $([Constants]::MessageType.Update)
           
            $kubernetesClusterRemediated | Format-Table -Property $colsProperty -Wrap

            # Write this to a file.
            $kubernetesClusterRemediatedFile = "$($backupFolderPath)\RemediatedKubernetesClusters.csv"
            $kubernetesClusterRemediated | Export-CSV -Path $kubernetesClusterRemediatedFile -NoTypeInformation

            Write-Host "This information has been saved to" -NoNewline
            Write-Host " [$($kubernetesClusterRemediatedFile)]" -ForegroundColor $([Constants]::MessageType.Update)
        }

        if ($($kubernetesClusterSkipped | Measure-Object).Count -gt 0)
        {
            Write-Host "`nError enabling AAD on the following Kubernetes cluster(s) in the subscription:" -ForegroundColor $([Constants]::MessageType.Error)
            $kubernetesClusterSkipped | Format-Table -Property $colsProperty -Wrap
            
            # Write this to a file.
            $kubernetesClusterSkippedFile = "$($backupFolderPath)\SkippedKubernetesClusters.csv"
            $kubernetesClusterSkipped | Export-CSV -Path $kubernetesClusterSkippedFile -NoTypeInformation
            Write-Host "This information has been saved to"  -NoNewline
            Write-Host " [$($kubernetesClusterSkippedFile)]" -ForegroundColor $([Constants]::MessageType.Update)
        }
    }
    else
    {
        Write-Host $([Constants]::DoubleDashLine)
        Write-Host "`n[Step 4 of 4] [Step 4 of 4] Enabling AAD for Kubernetes Services..."
        Write-Host $([Constants]::SingleDashLine)
        Write-Host "Skipped as -DryRun switch is provided." -ForegroundColor $([Constants]::MessageType.Warning)
        Write-Host $([Constants]::DoubleDashLine)

        Write-Host "`n**Next steps:**" -ForegroundColor $([Constants]::MessageType.Info)
        Write-Host "`nRun the same command with -FilePath $($backupFile) and without -DryRun, to enable AAD for all Kubernetes Service resources listed in the file."
    }
}

class SetAADProfile
{
    [PSObject] GetAuthHeader()
    {
        [psobject] $headers = $null
        try 
        {
            $resourceAppIdUri = "https://management.azure.com/"
            $rmContext = Get-AzContext
            $authResult = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate(
            $rmContext.Account,
            $rmContext.Environment,
            $rmContext.Tenant,
            [System.Security.SecureString] $null,
            "Never",
            $null,
            $resourceAppIdUri); 

            $header = "Bearer " + $authResult.AccessToken
            $headers = @{"Authorization"=$header;"Content-Type"="application/json";}
        }
        catch 
        {
            Write-Host "Error occurred while fetching auth header. ErrorMessage [$($_)]" -ForegroundColor Red   
        }

        return($headers)
    }

    [PSObject] SetAADProfileForCluster([string] $subscriptionId, [string] $resourceName, [string] $resourceGroup, [string] $location, [Object[]] $aadClientIds)
    {
        $content = $null
        try
        {
            $armUri = "https://management.azure.com/subscriptions/$($subscriptionId)/resourceGroups/$($resourceGroup)/providers/Microsoft.ContainerService/managedClusters/$($resourceName)?api-version=2022-02-01"
            $headers = $this.GetAuthHeader()
            $method = "Put"
            
            # If user wants to add AAD Group to Kubernetes cluster, pass group object id as part of request body.
            if (($aadClientIds | Measure-Object).Count > 0)
            {
                $body =@'
	            {
                    "location": "{0}",
                    "properties": {
                        "aadProfile": {
                            "managed": true,
                            "adminGroupObjectIDs": ["{1}"]
                        }
                    }
                }         
'@
                $jsonString = $body.Replace("{0}",$location).Replace("{1}",$aadClientIds)
            }
            else
            {
                $body =@'
	            {
                    "location": "{0}",
                    "properties": {
                        "aadProfile": {
                            "managed": true
                        }
                    }
                }         
'@
                $jsonString = $body.Replace("{0}",$location)
            }
            

            # API to set AAD Profile config to Kubernetes cluster
            $response = Invoke-WebRequest -Method $method -Uri $armUri -Headers $headers -Body $jsonString -UseBasicParsing
            $content = ConvertFrom-Json $response.Content
        }
        catch
        {
            Write-Host "Error occurred while setting AAD profile to Kubernetes Cluster. ErrorMessage [$($_)]" -ForegroundColor Red
        }
        
        return($content)
    }
}

# Defines commonly used constants.
class Constants
{
    # Defines commonly used colour codes, corresponding to the severity of the log.
    static [Hashtable] $MessageType = @{
        Error = [System.ConsoleColor]::Red
        Warning = [System.ConsoleColor]::Yellow
        Info = [System.ConsoleColor]::Cyan
        Update = [System.ConsoleColor]::Green
        Default = [System.ConsoleColor]::White
    }

    static [String] $DoubleDashLine = "========================================================================================================================"
    static [String] $SingleDashLine = "------------------------------------------------------------------------------------------------------------------------"
}