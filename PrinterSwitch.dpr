//--------------------------------------------------------------------------------------------------
//   Printer Switch
//      © 2026 Remus Rigo
//         v1.0 2026-05-15
// PrinterSwitch.dpr : main project
//--------------------------------------------------------------------------------------------------

program PrinterSwitch;

uses
  Vcl.Forms,
  Vcl.Menus,
  Vcl.Printers,
//  {$IFDEF DEBUG}
  Vcl.Dialogs,
//  {$ENDIF }
  Winapi.Messages,
  Winapi.ShellAPI,
  Winapi.Windows,
  Winapi.WinSpool,
  System.SysUtils, System.UITypes,
  AppData in 'Units\AppData.pas',
  User32_dll in 'API\User32_dll.pas',
  libReg in 'Lib\libReg.pas',
  wndAbout in 'Forms\wndAbout.pas' {frmAbout};

{$R *.res}

const
   CLASS_NAME = 'RemusRigoPrinterSwitchDelphi';
   TRAY_ID    = 1;

var
   msg: TMsg;
   tray: TNotifyIconData;
   mnu: TPopupMenu;
   MenuItem: TMenuItem;
   hwndTray: HWND = 0;
   wc: WNDCLASSEX;

type
   TPrinterSwitchEvents = class
      class procedure OnPrinterClick(Sender: TObject);
      class procedure OnAboutClick(Sender: TObject);
      class procedure OnExitClick(Sender: TObject);
end;

//-------------------------------------------------------------------------------------------------
// WindowProc
function WindowProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
var
   CursorPos: TPoint;
begin
   Result := 0;
   case uMsg of

      WM_TRAYICON:
      begin
         if lParam = WM_RBUTTONUP then
         begin
            GetCursorPos(CursorPos);
            SetForegroundWindow(hWnd);        // Required: fixes ghost menu
            mnu.Popup(CursorPos.X, CursorPos.Y);
            PostMessage(hWnd, WM_NULL, 0, 0); // Required: flushes the menu
         end;
      end;

      WM_DESTROY:
         PostQuitMessage(0);

      else
         Result:=DefWindowProc(hWnd, uMsg, wParam, lParam);
   end;
end;

//-------------------------------------------------------------------------------------------------
// OnPrinter
class procedure TPrinterSwitchEvents.OnPrinterClick(Sender: TObject);
var
   i: Integer;
   prn: string;
   clickedItem: TMenuItem;
begin
   clickedItem:=Sender as TMenuItem;
   prn:=StripHotkey((Sender as TMenuItem).Caption);
   if SetDefaultPrinter(PChar(prn)) then
   begin
      for i:=0 to mnu.Items.Count - 1 do
         mnu.Items[i].Checked:=False; // Uncheck all printer items,
      clickedItem.Checked:=True; // re-check the selected one
   end
   else
      raise Exception.CreateFmt('SetDefaultPrinter failed: %d', [GetLastError]);
end;

//-------------------------------------------------------------------------------------------------
// OnAbout
class procedure  TPrinterSwitchEvents.OnAboutClick(Sender: TObject);
var
   frm: TForm;
begin
   frm := TfrmAbout.Create(nil);
   try
      frm.ShowModal;
   finally
      frm.Free;
   end;
end;

//-------------------------------------------------------------------------------------------------
// OnExit
class procedure  TPrinterSwitchEvents.OnExitClick(Sender: TObject);
begin
  PostQuitMessage(0);
end;

//-------------------------------------------------------------------------------------------------
// UserManagesDefaultPrinter
procedure UserManagesDefaultPrinter;
const
  regPath : String = 'SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows';
  regKey  : String = 'LegacyDefaultPrinterMode';
begin
   if RegReadDWord(HKEY_CURRENT_USER, regPath, regKey)=0 then //  0 = Windows manages default printer
   begin
      if MessageDlg('Are you sure?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
         RegWriteDWord(HKEY_CURRENT_USER, regPath, regKey, 1); //  1 = User manages default printer
   end;
end;

//-------------------------------------------------------------------------------------------------
// BuildPrinterMenu
procedure BuildPrinterMenu;
var
  i: Integer;
  mnuItem: TMenuItem;
begin
   for i:=0 to Printer.Printers.Count - 1 do
   begin
      mnuItem:=TMenuItem.Create(mnu);
      mnuItem.Caption:=Printer.Printers[i];
      // Mark the current default printer
      if i = Printer.PrinterIndex then
         mnuItem.Checked:=True;
      mnuItem.OnClick:=TPrinterSwitchEvents.OnPrinterClick;
      mnu.Items.Add(mnuItem);
   end;

   mnuItem:= TMenuItem.Create(mnu);
   mnuItem.Caption := '-';
   mnu.Items.Add(mnuItem);

   mnuItem:=TMenuItem.Create(mnu);
   mnuItem.Caption:='&About';
   mnuItem.OnClick:= TPrinterSwitchEvents.OnAboutClick;
   mnu.Items.Add(mnuItem);

   mnuItem:=TMenuItem.Create(mnu);
   mnuItem.Caption:='E&xit';
   mnuItem.OnClick:= TPrinterSwitchEvents.OnExitClick;
   mnu.Items.Add(mnuItem);
end;

//-------------------------------------------------------------------------------------------------

begin
   Application.Initialize;
   mnu:=TPopupMenu.Create(nil);
   try
        UserManagesDefaultPrinter;
      // Build menu
      BuildPrinterMenu;

      // Register Class
      FillChar(wc, SizeOf(wc), 0);
      wc.cbSize:=SizeOf(WNDCLASSEX);
      wc.lpfnWndProc:=@WindowProc;       // Our proc, set at registration time
      wc.hInstance:=HInstance;
      wc.lpszClassName:=CLASS_NAME;
      if not (RegisterClassEx(wc) <> 0) then
         raise Exception.CreateFmt('RegisterClassEx failed: %d', [GetLastError]);

      // Create Window <> Message-only window — never shown, very clean
      hwndTray:=CreateWindowEx(0, CLASS_NAME, '', WS_OVERLAPPED, 0, 0, 0, 0, HWND_MESSAGE, 0, HInstance, nil);

      // Create Tray Icon
      FillChar(tray, SizeOf(tray), 0);
      tray.cbSize           := SizeOf(TNotifyIconData);
      tray.Wnd              := HwndTray;
      tray.uID              := TRAY_ID;
      tray.uFlags           := NIF_ICON or NIF_MESSAGE or NIF_TIP;
      tray.uCallbackMessage := WM_TRAYICON;
      tray.hIcon            := LoadIcon(HInstance, 'MAINICON');//LoadIcon(0, IDI_APPLICATION);
      StrPCopy(tray.szTip, appCaption);
      Shell_NotifyIcon(NIM_ADD, @tray);

      // loop messages
      while GetMessage(Msg, 0, 0, 0) do
      begin
         TranslateMessage(Msg);
         DispatchMessage(Msg);
      end;

      finally
         // Free all
         Shell_NotifyIcon(NIM_DELETE, @tray);
         if hwndTray <> 0 then
            DestroyWindow(HwndTray);
         UnregisterClass(CLASS_NAME, HInstance);
         mnu.Free;
     end;
end.
