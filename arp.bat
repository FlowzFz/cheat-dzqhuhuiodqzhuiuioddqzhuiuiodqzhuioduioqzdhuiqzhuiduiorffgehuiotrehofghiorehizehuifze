@echo off
SETLOCAL ENABLEDELAYEDEXPANSION
SETLOCAL ENABLEEXTENSIONS

::Generate and implement a random MAC address
FOR /F "tokens=1" %%a IN ('wmic nic where physicaladapter^=true get deviceid ^| findstr [0-9]') DO (
    CALL :MAC
    FOR %%b IN (0 00 000) DO (
        REG QUERY HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002bE10318}\%%b%%a >NUL 2>NUL && REG ADD HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002bE10318}\%%b%%a /v NetworkAddress /t REG_SZ /d !MAC! /f >NUL 2>NUL
    )
)

::Disable power saving mode for network adapters
FOR /F "tokens=1" %%a IN ('wmic nic where physicaladapter^=true get deviceid ^| findstr [0-9]') DO (
    FOR %%b IN (0 00 000) DO (
        REG QUERY HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002bE10318}\%%b%%a >NUL 2>NUL && REG ADD HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002bE10318}\%%b%%a /v PnPCapabilities /t REG_DWORD /d 24 /f >NUL 2>NUL
    )
)

::Reset NIC adapters
FOR /F "tokens=2 delims=, skip=2" %%a IN ('"wmic nic where (netconnectionid like '%%') get netconnectionid,netconnectionstatus /format:csv"') DO (
    netsh interface set interface name="%%a" disable >NUL 2>NUL
    netsh interface set interface name="%%a" enable >NUL 2>NUL
)

::ARP Spoofing Script
netsh interface ipv6 uninstall >NUL 2>NUL
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=no >NUL 2>NUL
netsh int tcp set global autotuninglevel=normal >NUL 2>NUL
netsh interface set interface "Microsoft Network Adapter Multiplexor Protocol" admin=disabled >NUL 2>NUL
sc config lltdsvc start=disabled >NUL 2>NUL
netsh advfirewall firewall set rule group="Network Discovery" new enable=no >NUL 2>NUL
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" /v DisabledComponents /t REG_DWORD /d 0xFFFFFFFF /f >NUL 2>NUL
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v EEE /f >NUL 2>NUL
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /v NetworkAddress /f >NUL 2>NUL
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v ArpOffload /f >NUL 2>NUL
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpAckFrequency /f >NUL 2>NUL
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpChecksumOffloadIPv4 /f >NUL 2>NUL
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v LargeSendOffloadv2IPv6 /f >NUL 2>NUL
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpChecksumOffloadIPv6 /f >NUL 2>NUL
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v UdpChecksumOffloadIPv6 /f >NUL 2>NUL
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" /v DisabledComponents /t REG_DWORD /d 0xFFFFFFFF /f >NUL 2>NUL
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v EEE /t REG_DWORD /d 0 /f >NUL 2>NUL
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /v NetworkAddress /t REG_SZ /d "" /f >NUL 2>NUL
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v ArpOffload /t REG_DWORD /d 0 /f >NUL 2>NUL
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpAckFrequency /t REG_DWORD /d 1 /f >NUL 2>NUL
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpChecksumOffloadIPv4 /t REG_DWORD /d 0 /f >NUL 2>NUL
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v LargeSendOffloadv2IPv6 /t REG_DWORD /d 0 /f >NUL 2>NUL
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpChecksumOffloadIPv6 /t REG_DWORD /d 0 /f >NUL 2>NUL
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v UdpChecksumOffloadIPv6 /t REG_DWORD /d 0 /f >NUL 2>NUL

::random binary data
set "RANDOM_DNS="
set "RANDOM_SEARCHLIST="
set "RANDOM_DUID="

for /l %%i in (1,1,14) do call :generateRandomByte RANDOM_DNS
for /l %%i in (1,1,14) do call :generateRandomByte RANDOM_SEARCHLIST
for /l %%i in (1,1,14) do call :generateRandomByte RANDOM_DUID

:: set random binary
set KEY_NAME=HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters
set VALUE_NAME_DNS=Dhcpv6DNSServers
set VALUE_NAME_SEARCHLIST=Dhcpv6DomainSearchList
set VALUE_NAME_DUID=Dhcpv6DUID
reg add "%KEY_NAME%" /v "%VALUE_NAME_DNS%" /t REG_BINARY /d !RANDOM_DNS! /f >NUL 2>NUL
reg add "%KEY_NAME%" /v "%VALUE_NAME_SEARCHLIST%" /t REG_BINARY /d !RANDOM_SEARCHLIST! /f >NUL 2>NUL
reg add "%KEY_NAME%" /v "%VALUE_NAME_DUID%" /t REG_BINARY /d !RANDOM_DUID! /f >NUL 2>NUL

arp -d >NUL 2>NUL
ipconfig /flushdns >NUL 2>NUL
ipconfig /registerdns >NUL 2>NUL
ipconfig /release >NUL 2>NUL
ipconfig /renew >NUL 2>NUL
netsh winsock reset >NUL 2>NUL

:MAC
::Generates semi-random MAC address
SET COUNT=0
SET GEN=ABCDEF0123456789
SET GEN2=26AE
SET MAC=
:MACLOOP
SET /a COUNT+=1
SET RND=%random%
SET /A RND=RND%%16
SET RNDGEN=!GEN:~%RND%,1!
SET /A RND2=RND%%4
SET RNDGEN2=!GEN2:~%RND2%,1!
IF "!COUNT!" EQU "2" (SET MAC=!MAC!!RNDGEN2!) ELSE (SET MAC=!MAC!!RNDGEN!)
IF !COUNT! LEQ 11 GOTO MACLOOP
exit /b

:generateRandomByte
set /a "byte=!random! %% 256"
set "hexValue=00!byte!"
set "hexValue=!hexValue:~-2!"
set "%1=!%1!!hexValue!"
exit /b