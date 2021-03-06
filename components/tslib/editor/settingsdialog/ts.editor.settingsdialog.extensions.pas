{
  Copyright (C) 2013-2017 Tim Sinaeve tim.sinaeve@gmail.com

  This library is free software; you can redistribute it and/or modify it
  under the terms of the GNU Library General Public License as published by
  the Free Software Foundation; either version 2 of the License, or (at your
  option) any later version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
  FITNESS FOR A PARTICULAR PURPOSE. See the GNU Library General Public License
  for more details.

  You should have received a copy of the GNU Library General Public License
  along with this library; if not, write to the Free Software Foundation,
  Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
}

{-------------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: ExtDialog.pas

The Initial Developer of the Original Code is: AD <adsoft@nm.ru>
Copyright (c) 2005 ADSoft          
All Rights Reserved.

Alternatively, the contents of this file may be used under the terms of the
GNU General Public License Version 2 or later (the "GPL"), in which case
the provisions of the GPL are applicable instead of those above.
If you wish to allow use of your version of this file only under the terms
of the GPL and not to allow others to use your version of this file
under the MPL, indicate your decision by deleting the provisions above and
replace them with the notice and other provisions required by the GPL.
If you do not delete the provisions above, a recipient may use your version
of this file under either the MPL or the GPL.

$Id: ExtDialog.pas,v 1.1.1.1 2005/10/25 11:35:05 adsoft Exp $
-------------------------------------------------------------------------------}

unit ts.Editor.SettingsDialog.Extensions;

{$MODE Delphi}

interface

uses
  LCLIntf, LCLType, LMessages, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls, ExtCtrls, FileUtil;

//  ts.Core.FileAssociations;

type
  TdlgExt = class(TForm)
    gbExt: TGroupBox;
    lblIcon: TLabel;
    edIcon: TEdit;
    imIcon: TImage;
    lblDescr: TLabel;
    Bevel1: TBevel;
    bnOK: TButton;
    bnCancel: TButton;
    lblExt: TLabel;
    cbExt: TComboBox;
    cbDescr: TComboBox;
    //TT: TADToolTipManager;
    procedure FormShow(Sender: TObject);
    procedure imIconClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure cbExtChange(Sender: TObject);

  private
    FEditMode: boolean;
    //FAssociate: TFileAssociate;
    function GetIconName: string;
    function GetDescription: string;
    procedure SetDescription(const Value: string);
    procedure SetIconName(const Value: string);
    { Private declarations }
    procedure LoadIcon(const AName: string);
    procedure SetEditMode(const Value: boolean);
    function GetExt: string;
    procedure SetExt(const Value: string);

  public
    { Public declarations }
    property Ext: string
      read GetExt write SetExt;

    property IconName: string
      read GetIconName write SetIconName;

    property Description: string
      read GetDescription write SetDescription;

    property EditMode: boolean
      read FEditMode write SetEditMode;

    //property Associate: TFileAssociate
    //  read FAssociate write FAssociate;
  end;

implementation

uses
  {$IFDEF Windows}
  Windows, ShellApi,
  {$ENDIF}

  ts.Core.Utils;

{$R *.lfm}

{$IFDEF Windows}
function ExecuteIconDlg(const AParent: HWND; var AFilename: string; var AIconIndex: integer): boolean;
const
  cMaxPath = 255;
type
  TIconDialog = function(AWnd: HWND; szFileName: PChar; Reserved: Integer; var lpIconIndex: Integer): DWORD; stdcall;
  TIconDialogW = function(Wnd: HWND; szFileName: PWideChar; Reserved: Integer; var lpIconIndex: Integer): DWORD; stdcall;
var
  IconDialog: TIconDialog;
  IconDialogW: TIconDialogW;
  hDLL: THandle;
  Buffer: array [0..MAX_PATH] of Char;
  BufferW: array [0..MAX_PATH] of WideChar;
begin
  hDLL := GetModuleHandle('Shell32.dll');
  if hDLL = 0 then
    hDLL := LoadLibrary('Shell32.dll');
  if Win32Platform = VER_PLATFORM_WIN32_NT then
  begin
    IconDialogW := GetProcAddress(hDLL, PChar(62));
    StringToWideChar(AFilename, BufferW, SizeOf(BufferW));
    Result := IconDialogW(GetForegroundWindow, BufferW, SizeOf(BufferW), AIconIndex) = 1;
    if Result then
      AFilename := BufferW;
  end
  else
  begin
    IconDialog := GetProcAddress(hDLL, PChar(62));
    StrPCopy(Buffer, AFilename);
    Result := IconDialog(GetForegroundWindow, Buffer, SizeOf(Buffer), AIconIndex) = 1;
    if Result then
      AFilename := Buffer;
  end;
end;
{$ENDIF}

procedure TdlgExt.imIconClick(Sender: TObject);
//var
//  FN: string;
//  Index: integer;
begin
  //FN := GetPartOfStr(edIcon.Hint, 0, SExtDel);
  //Index := StrToInt(GetPartOfStr(edIcon.Hint, 1, SExtDel));
  //if not FileExistsUTF8(FN)  then
    //FN := ParamStr(0);
    //Index := 1;
  //if ExecuteIconDlg(Handle, FN, Index) then
  //;
    //LoadIcon(FN + SExtDel + IntToStr(Index));
end;

procedure TdlgExt.LoadIcon(const AName: string);
//var
//  FPath: string;
//  Index: Word;
//const
//  SExtDel = [','];
begin
  //IconName := AName;
  //FPath := AnsiDequotedStr(ExtractWord(0, AName, SExtDel), '"');
  ////FIndex := StrToIntDef(ExtractWord(1, AName, SExtDel), 0);
  ////@FIndex = 1;
  //FPath :=  ParamStr(0);
  //Index := 1;
  //imIcon.Picture.Icon.Handle := ExtractAssociatedIcon(hInstance, Pointer(FPath), Pointer(Index));
  //ExtractAssociatedIcon(hInstance, PChar(FPath), Pointer(Index));
  //if imIcon.Picture.Icon.Empty then
   // LoadIcon(ParamStr(0) + ',' + SDefIconIndex);
end;

function TdlgExt.GetIconName: string;
begin
  Result := edIcon.Hint;
end;

procedure TdlgExt.SetIconName(const Value: string);
//var
//  ShortName: string;
begin
  edIcon.Hint := Value;
  imIcon.Hint := Value;
  //ShortName := MinName(edIcon, Value);
  //edIcon.Text := ShortName;
end;

procedure TdlgExt.SetDescription(const Value: string);
begin
  cbDescr.Text := Value;
end;

function TdlgExt.GetDescription: string;
begin
  Result := cbDescr.Text;
end;

procedure TdlgExt.SetEditMode(const Value: boolean);
begin
  FEditMode := Value;
  if FEditMode then
  begin
    cbExt.Enabled := False;
    cbExt.Color := clBtnFace;
  end
  else
  begin
    cbExt.Enabled := True;
    cbExt.Color := clWindow;
  end;
end;

function TdlgExt.GetExt: string;
begin
  Result := cbExt.Text;
  if Pos('.', Result) <> 1 then
    Result := '.' + Result;
end;

procedure TdlgExt.SetExt(const Value: string);
begin
  cbExt.Text := Value;
end;

procedure TdlgExt.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
//var
//  Item: TAssociateItem;
begin
  //if (ModalResult = mrOK) and (not FEditMode) then
  //begin
  //  Item := Associate.AddItem(Ext);
  //  if Assigned(Item) then
  //  begin
  //    CanClose := True;
  //    Item.Descr := Description;
  //    Item.Icon := IconName;
  //  end
  //  else begin
  //    CanClose := False;
  //    cbExtChange(Self);
  //  end;
  //end;
end;

procedure TdlgExt.cbExtChange(Sender: TObject);
begin
  //if not FEditMode then begin
  //  TT.Items[TT.Items.IndexOf(cbExt)].Text :=
  //    Format(GetLangStr('SExtAlreadyExist'), [Ext]);
  //  TT.ShowToolTip(cbExt, Associate.IndexOf(Ext) <> -1);
    //cbDescr.Text := Associate.GetDescr(Ext);
    //LoadIcon(Associate.GetIcon(Ext));
  //end;
end;

procedure TdlgExt.FormShow(Sender: TObject);
begin
  LoadIcon(IconName);
  if FEditMode then
    cbDescr.SetFocus
  else
    cbExt.SetFocus;
end;

end.

