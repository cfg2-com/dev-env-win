<#
.SYNOPSIS
    Looks up a personal view GUID in Dataverse by view name.

.DESCRIPTION
    Resolves an entity logical name to its object type code, then queries userquery
    via the Dataverse Web API to retrieve the userqueryid for a matching personal view.

    Authentication uses the Az.Accounts PowerShell module (Connect-AzAccount -AuthScope).
    Avoids Azure CLI SSL issues behind corporate proxies. Install with:
    Install-Module -Name Az.Accounts -Scope CurrentUser

.PARAMETER ViewName
    Display name of the personal view to look up.
    Example: "My Contacts (Owner=Me)"

.PARAMETER EntityLogicalName
    Logical name of the entity the personal view targets.
    Used to resolve returnedtypecode via EntityDefinitions metadata. Default: contact

.PARAMETER Environment
    Dataverse environment URL.
    Default: https://org.crm.dynamics.com/

.EXAMPLE
    .\D365-PersonalViewGUID.ps1 -EntityLogicalName "contact" -ViewName "My Contacts (Owner=Me)"

.EXAMPLE
    .\D365-PersonalViewGUID.ps1 `
        -ViewName "My Open Cases" `
        -EntityLogicalName "incident" `
        -Environment "https://org.crm.dynamics.com/"
#>

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$EntityLogicalName,
    
    [Parameter(Mandatory = $true, Position = 1)]
    [string]$ViewName,

    [Parameter(Mandatory = $false)]
    [string]$Environment = "https://org.crm.dynamics.com/"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ─── Azure authentication (Az.Accounts) ──────────────────────────────────────

function Convert-SecureStringToPlainText {
    param([Security.SecureString]$SecureString)

    if ($PSVersionTable.PSVersion.Major -ge 7) {
        return ConvertFrom-SecureString -SecureString $SecureString -AsPlainText
    }

    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

function Get-D365AccessToken {
    param([string]$EnvironmentUrl)

    if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
        throw 'Az.Accounts PowerShell module is required. Install with: Install-Module -Name Az.Accounts -Scope CurrentUser'
    }

    Import-Module Az.Accounts -ErrorAction Stop | Out-Null

    $resource = $EnvironmentUrl.TrimEnd('/')

    foreach ($attempt in 1..2) {
        try {
            $tokenResponse = Get-AzAccessToken -ResourceUrl $resource -AsSecureString -ErrorAction Stop
            if ($null -eq $tokenResponse.Token) {
                throw 'No token returned.'
            }
            return (Convert-SecureStringToPlainText -SecureString $tokenResponse.Token).Trim()
        }
        catch {
            if ($attempt -eq 2) {
                throw "Failed to get access token for $resource. Run Connect-AzAccount -AuthScope $resource and try again. $($_.Exception.Message)"
            }

            Write-Host "Signing in to $resource with Connect-AzAccount..." -ForegroundColor Cyan
            Connect-AzAccount -AuthScope $resource -ErrorAction Stop | Out-Null
        }
    }

    throw "Failed to get access token for $resource."
}

function New-D365Headers {
    param([string]$AccessToken)

    return @{
        Authorization      = "Bearer $AccessToken"
        Accept             = 'application/json'
        'OData-Version'    = '4.0'
        'OData-MaxVersion' = '4.0'
    }
}

function Get-EntityObjectTypeCode {
    param(
        [string]$EnvironmentUrl,
        [string]$EntityLogicalName,
        [hashtable]$Headers
    )

    $baseUrl = $EnvironmentUrl.TrimEnd('/')
    $logicalName = $EntityLogicalName.Trim().ToLowerInvariant()
    $safeName = $logicalName.Replace("'", "''")
    $uri = "$baseUrl/api/data/v9.2/EntityDefinitions(LogicalName='$safeName')?`$select=LogicalName,ObjectTypeCode"

    try {
        $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $Headers -ErrorAction Stop
        return [int]$response.ObjectTypeCode
    }
    catch {
        $status = $null
        if ($_.Exception.Response) {
            $status = [int]$_.Exception.Response.StatusCode
        }
        if ($status -eq 404) {
            throw "Entity '$logicalName' was not found in $baseUrl."
        }
        throw "Failed to resolve entity '$logicalName': $($_.Exception.Message)"
    }
}

function Get-PersonalViewsByFetch {
    param(
        [string]$EnvironmentUrl,
        [string]$FetchXml,
        [hashtable]$Headers
    )

    $baseUrl = $EnvironmentUrl.TrimEnd('/')
    $encodedFetch = [Uri]::EscapeDataString($FetchXml)
    $uri = "$baseUrl/api/data/v9.2/userqueries?fetchXml=$encodedFetch"

    return (Invoke-RestMethod -Uri $uri -Method Get -Headers $Headers -ErrorAction Stop).value
}

# ─── Main ────────────────────────────────────────────────────────────────────

$viewNameTrimmed = $ViewName.Trim()
if ([string]::IsNullOrWhiteSpace($viewNameTrimmed)) {
    throw 'ViewName is required.'
}

$entityLogicalNameTrimmed = $EntityLogicalName.Trim().ToLowerInvariant()
if ([string]::IsNullOrWhiteSpace($entityLogicalNameTrimmed)) {
    throw 'EntityLogicalName is required.'
}

$environmentUrl = $Environment.TrimEnd('/') + '/'

Write-Host "Looking up personal view: $viewNameTrimmed" -ForegroundColor Cyan
Write-Host "Environment: $environmentUrl" -ForegroundColor DarkGray
Write-Host "Entity: $entityLogicalNameTrimmed" -ForegroundColor DarkGray

$accessToken = Get-D365AccessToken -EnvironmentUrl $environmentUrl
$headers = New-D365Headers -AccessToken $accessToken

$returnedTypeCode = Get-EntityObjectTypeCode -EnvironmentUrl $environmentUrl `
    -EntityLogicalName $entityLogicalNameTrimmed -Headers $headers

Write-Host "Resolved returnedtypecode: $returnedTypeCode" -ForegroundColor DarkGray

$escapedViewName = [System.Security.SecurityElement]::Escape($viewNameTrimmed)
$fetchXml = "<fetch count='50'><entity name='userquery'><attribute name='userqueryid' /><attribute name='name' /><filter type='and'><condition attribute='returnedtypecode' operator='eq' value='$returnedTypeCode' /><condition attribute='name' operator='eq' value='$escapedViewName' /></filter></entity></fetch>"

$results = @(Get-PersonalViewsByFetch -EnvironmentUrl $environmentUrl -FetchXml $fetchXml -Headers $headers)

if ($results.Count -eq 0) {
    Write-Host 'No matching personal views found.' -ForegroundColor Yellow
    exit 1
}

$results | Select-Object userqueryid, name | Format-Table -AutoSize
exit 0
