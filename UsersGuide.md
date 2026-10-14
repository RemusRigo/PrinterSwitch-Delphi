# PrinterSwitch: User's Guide



## Downloads & Runtimes

Download the latest release from the [Releases page](https://github.com/RemusRigo/PrinterSwitch-Delphi/releases).

|Folder|Architecture|Required Runtime|
|-|-|-|
|`Win32`|32-bit|none (native Windows app)|
|`Win64`|64-bit|none (native Windows app)|

> On 64-bit Windows, use **Win64**.



## Install

PrinterSwitch is portable: there is no installer.

1. Copy `PrinterSwitch.exe` to a permanent folder, for example `D:\My Apps\PrinterSwitch\`.
2. Double-click `PrinterSwitch.exe`. A printer icon appears in the system tray.
3. Optional: to start it with Windows, press **Win+R**, type `shell:startup`, and put a shortcut to `PrinterSwitch.exe` in that folder.

On start, PrinterSwitch turns off **Let Windows manage my default printer**
(`HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows`, `LegacyDefaultPrinterMode` = 1),
otherwise Windows would change the default printer by itself.



## Usage

Click the tray icon to open the menu:

|Menu|Description|
|-|-|
|*printer names*|All installed printers; the default printer is marked. Click a printer to make it the default|
|**About**|Version information|
|**Exit**|Close PrinterSwitch|



## Uninstall

1. Click the tray icon → **Exit**.
2. Delete the shortcut from `shell:startup` (if you created one) and `PrinterSwitch.exe`.
3. Optional: turn **Let Windows manage my default printer** back on in **Settings → Bluetooth & devices → Printers & scanners**.
