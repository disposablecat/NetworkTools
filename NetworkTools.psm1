function Test-Ports{
<#
.SYNOPSIS
    Test whether a TCP port or ports are open on a computer or computers
.DESCRIPTION
    Test whether a TCP port or ports are open on a computer or computers. Returns whether the port or ports are opened or closed. 
.PARAMETER ComputerName
    Specify a computer to connect to.
.PARAMETER Ports
    Specify a TCP port or ports to test
.NOTES
    Version:        1.0
    Author:         disposablecat
    Purpose/Change: Initial script development
.EXAMPLE
    Test-Ports -ComputerName server1 -ports 80
    Will return if the TCP port is open on server1, assuming it can resolve the DNS name to an IP.
.EXAMPLE
    Test-Ports -ComputerName server1 -ports 80,443,3389
    Will return if the TCP ports are open on server1, assuming it can resolve the DNS name to an IP.
.EXAMPLE
    Test-Ports -ComputerName server1,server2,10.11.107.52 -ports 80,443,3389
    Will return if the TCP ports are open on server1, server2, and 10.11.107.52, assuming it can resolve the DNS name to an IP for the first two.
    It will try the IP specify regardless.
#>
    [CmdletBinding()]
    [OutputType([System.Object])]
    
    #Define parameters
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [string[]]$ComputerName,

        # Param2 help description
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [ValidateRange(1,65535)]
        [int[]]$Ports,

        [Parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [ValidateRange(1,10000)]
        [int]$Timeout = 100
    )

    Begin
    {
        $PortsObjectBase = New-Object PSObject; 
        $PortsObjectBase | Add-Member -type Noteproperty -Name ComputerName -Value $Null
        $PortsObjectBase | Add-Member -type Noteproperty -Name IP -Value $Null
        $PortsObjectBase | Add-Member -type Noteproperty -Name Port -Value $Null
        $PortsObjectBase | Add-Member -type Noteproperty -Name Open -Value $Null
        $Results = New-Object System.Collections.Generic.List[System.Object]    
    }
    Process
    {
        ForEach ($Computer in $ComputerName)
        {
            
            try
            {
                $Resolved = [System.Net.Dns]::GetHostEntry($Computer)
                $IPAddress = $Resolved.AddressList.IPAddressToString
                $Name = $Resolved.HostName
            }
            Catch
            {
                #Catch any error.
                Write-Verbose “Exception Caught: $($_.Exception.Message)”
            }

            ForEach ($P in $Ports)
            {
                $PortsObject = $PortsObjectBase | Select *
                $PortsObject.ComputerName = $Name
                $PortsObject.IP = $IPAddress
                $PortsObject.Port = $P
                $Socket = New-Object Net.Sockets.TcpClient
                $Connect = $Socket.BeginConnect($IPAddress,$P,$Null,$Null)
                $Wait = $Connect.AsyncWaitHandle.WaitOne($Timeout,$false)
                if($Wait -eq $false)
                {
                    $Socket.Close()
                    $PortsObject.Open = $false
                    Write-Verbose "Port $P on $Computer did not respond try increasing timeout."
                }
                else
                {
                    $Socket.EndConnect($Connect) | Out-Null
                    $PortsObject.Open = $true
                }
                $Results.Add($PortsObject)
            }            
        }
        return $Results
    }
    End
    {
        #Will execute last. Will execute once. Good for cleanup. 
    }
}

