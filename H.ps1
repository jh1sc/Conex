Add-Type -AssemblyName  Microsoft.VisualBasic, PresentationCore, PresentationFramework, System.Drawing, System.Windows.Forms, WindowsBase, WindowsFormsIntegration, System; Add-Type -TypeDefinition 'namespace Windows.Native{using System;using System.ComponentModel;using System.IO;using System.Runtime.InteropServices;public class Kernel32{public const uint FILE_SHARE_READ = 1;public const uint FILE_SHARE_WRITE = 2;public const uint GENERIC_READ = 0x80000000;public const uint GENERIC_WRITE = 0x40000000;public static readonly IntPtr INVALID_HANDLE_VALUE = new IntPtr(-1);public const int STD_ERROR_HANDLE = -12;public const int STD_INPUT_HANDLE = -10;public const int STD_OUTPUT_HANDLE = -11;[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]public class CONSOLE_FONT_INFOEX{private int cbSize;public CONSOLE_FONT_INFOEX(){this.cbSize = Marshal.SizeOf(typeof(CONSOLE_FONT_INFOEX));}public int FontIndex;public short FontWidth;public short FontHeight;public int FontFamily;public int FontWeight;[MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]public string FaceName;}public class Handles{public static readonly IntPtr StdIn = GetStdHandle(STD_INPUT_HANDLE);public static readonly IntPtr StdOut = GetStdHandle(STD_OUTPUT_HANDLE);public static readonly IntPtr StdErr = GetStdHandle(STD_ERROR_HANDLE);}[DllImport("kernel32.dll", SetLastError=true)]public static extern bool CloseHandle(IntPtr hHandle);[DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]public static extern IntPtr CreateFile([MarshalAs(UnmanagedType.LPTStr)] string filename,uint access,uint share,IntPtr securityAttributes, [MarshalAs(UnmanagedType.U4)] FileMode creationDisposition,uint flagsAndAttributes,IntPtr templateFile);[DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]public static extern bool GetCurrentConsoleFontEx(IntPtr hConsoleOutput, bool bMaximumWindow, [In, Out] CONSOLE_FONT_INFOEX lpConsoleCurrentFont);[DllImport("kernel32.dll", SetLastError=true)]public static extern IntPtr GetStdHandle(int nStdHandle);[DllImport("kernel32.dll", SetLastError=true)]public static extern bool SetCurrentConsoleFontEx(IntPtr ConsoleOutput, bool MaximumWindow,[In, Out] CONSOLE_FONT_INFOEX ConsoleCurrentFontEx);public static IntPtr CreateFile(string fileName, uint fileAccess, uint fileShare, FileMode creationDisposition){IntPtr hFile = CreateFile(fileName, fileAccess, fileShare, IntPtr.Zero, creationDisposition, 0U, IntPtr.Zero);if (hFile == INVALID_HANDLE_VALUE){throw new Win32Exception();}return hFile;}public static CONSOLE_FONT_INFOEX GetCurrentConsoleFontEx(){IntPtr hFile = IntPtr.Zero;try{hFile = CreateFile("CONOUT$", GENERIC_READ,FILE_SHARE_READ | FILE_SHARE_WRITE, FileMode.Open);return GetCurrentConsoleFontEx(hFile);}finally{CloseHandle(hFile);}}public static void SetCurrentConsoleFontEx(CONSOLE_FONT_INFOEX cfi){IntPtr hFile = IntPtr.Zero;try{hFile = CreateFile("CONOUT$", GENERIC_READ | GENERIC_WRITE,FILE_SHARE_READ | FILE_SHARE_WRITE, FileMode.Open);SetCurrentConsoleFontEx(hFile, false, cfi);}finally{CloseHandle(hFile);}}public static CONSOLE_FONT_INFOEX GetCurrentConsoleFontEx(IntPtr outputHandle){CONSOLE_FONT_INFOEX cfi = new CONSOLE_FONT_INFOEX();if (!GetCurrentConsoleFontEx(outputHandle, false, cfi)){throw new Win32Exception();}return cfi;}}}'; $F = [Windows.Native.Kernel32]::GetCurrentConsoleFontEx(); $F.FontIndex = 0; $F.FontWidth = 8; $F.FontHeight = 8; $F.FontFamily = 48; $F.FontWeight = 100; $F.FaceName = "Terminal"; [Windows.Native.Kernel32]::SetCurrentConsoleFontEx($F)
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

#Binding Selection
$BindingIP = ((Get-NetIPAddress | Where-Object { $_.AddressState -eq "Preferred" -and $_.ValidLifetime -lt "24:00:00" }).IPAddress)
if ($BindingIP.length -gt 1) {
    $i = 0; $BindingIP | % { write-host "$($i)": "$($BindingIP[$($i)])"; $i++ }
    $inp = Read-Host Which IpAddress; $BindingIP = $BindingIP[$inp]
}

(GAC).IPv4Address
$sendip = Read-Host "IPADDRESS"


#Ping Sender
function Send {
    param (
        [ipaddress]$IP,
        [string]$text
    )
    $sc = [System.Net.NetworkInformation.Ping]::new()
    $PingOptions = [System.Net.NetworkInformation.PingOptions]::new()
    $PingOptions.DontFragment = $true
    $sc.Send([ipaddress]$IP, "20", (([text.encoding]::ASCII).GetBytes($text + "~")), $PingOptions)
    return ($text + "~")
} 

#Ping receiver
function Receive {
    param (
        [ipaddress]$BindingIP,
        [int]$TimeOut = 20
    )
    $pRs = [System.Net.Sockets.Socket]::new([Net.Sockets.AddressFamily]::InterNetwork, [Net.Sockets.SocketType]::Raw, [Net.Sockets.ProtocolType]::Icmp)
    $pRs.bind([system.net.IPEndPoint]::new([system.net.IPAddress]::Parse($BindingIP), 0))
    $pRs.IOControl([Net.Sockets.IOControlCode]::ReceiveAll, [BitConverter]::GetBytes(1), $null)
    $buffer = new-object byte[] $pRs.ReceiveBufferSize | out-null
    $pRs.ReceiveTimeout = $TimeOut
    $pRs.Receive($buffer) | out-null
    $FeedBack = ([System.Text.Encoding]::ASCII.GetString($buffer[28..255]))
    $FeedBack = ($FeedBack.Substring(0, ($FeedBack.IndexOf("~"))))
    write-host $FeedBack
}

function Spk {
    param ([string]$text)
        $words = $text.Split(' ')

        $quotedWords = foreach ($word in $words) {
            '"{0}"' -f $word
        }
        $joinedWords = $quotedWords -join '+'

    $a = '$s = new-object -com wscript.shell;1..100 | % {$s.SendKeys([char]175)};start-sleep 0.5;Add-Type -AssemblyName System.Speech;$ss = New-Object System.Speech.Synthesis.SpeechSynthesizer;$ss.Speak(replace)'
    $a = $a -replace "replace", $joinedWords
    return $a
}


while (1) {
    $inp = Read-Host "Send"
    if ($inp -eq "Speak") {
        $spk = Read-Host "What do you want to say?"
        Send $sendip (Spk $spk)
    }
    else {
        Send $sendip $inp
    }
}




