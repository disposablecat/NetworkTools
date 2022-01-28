#-----------------------------------------------------------[Functions]------------------------------------------------------------

function Test-ConnectionFast{
<#
.SYNOPSIS
    Pings a host or hosts
.DESCRIPTION
    Quickly pings a hosts or host. Test if a host up much more quickly than Test-Connection, especially if the host is unreachable. 
.PARAMETER ComputerName
    Parameter description
.PARAMETER Timeout
    Parameter description
.NOTES
    Version:        1.0
    Author:         disposablecat
    Purpose/Change: Initial script development
.EXAMPLE
    Example of how to use this cmdlet
.EXAMPLE
    Another example of how to use this cmdlet
#>
    [CmdletBinding()]
    [OutputType([int])]
    
    #Define parameters
    Param
    (
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [string[]]$ComputerName,

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [int]$Timeout = 50
    )

    Begin
    {
        #Will execute first. Will execute one time only. Use for one time actions
        $PingResponseBase = New-Object PSObject; 
        $PingResponseBase | Add-Member -type Noteproperty -name ComputerName -Value $Null
        $PingResponseBase | Add-Member -type Noteproperty -name IP -Value $Null;
        $PingResponseBase | Add-Member -type Noteproperty -name RTT -Value $Null
        $PingResponseBase | Add-Member -type Noteproperty -name Result -Value $Null;
        $Pings = New-Object System.Collections.ArrayList
        $Results = New-Object System.Collections.Generic.List[System.Object]
    }
    Process
    {
        Write-Verbose "Starting pings tasks."
        ForEach($Computer in $ComputerName)
        {
            Try
            {
                Write-Verbose "Starting ping of $Computer."
                [void]$Pings.Add((New-Object Net.NetworkInformation.Ping).SendPingAsync($Computer, $Timeout))
                $PingResponse = $PingResponseBase | Select *
                $PingResponse.ComputerName = $Computer
                [void]$Results.Add($PingResponse)

            }
            Catch
            {
                #Catch any error.
                Write-Verbose “Exception Caught: $($_.Exception.Message)”
            }
        }
    }
    End
    {
        Write-Verbose "Waiting for ping tasks to complete."
        Try
        {
            [void][Threading.Tasks.Task]::WaitAll($Pings)
        }
        Catch [System.Management.Automation.MethodInvocationException]
        {
            #Catch any error.
            Write-Verbose “Exception Caught: Could not lookup one or more hosts. See results for No such host is known message.”
        }
        $i = 0
        ForEach($Ping in $Pings)
        {
            if($Ping.IsFaulted)
            {
                $Results[$i].IP = $null
                $Results[$i].RTT = $null
                $Results[$i].Result = [string]$Ping.Exception.InnerException.InnerException.Message
            }
            else
            {
                $Results[$i].IP = $Ping.Result.Address.ToString()
                $Results[$i].RTT = $Ping.Result.RoundtripTime
                $Results[$i].Result = $Ping.Result.Status 
            }
            $i++
        }
        return $Results

    }
}