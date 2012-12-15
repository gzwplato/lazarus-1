{
  Copyright (C) 2012 Tim Sinaeve tim.sinaeve@gmail.com

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

unit Notepas_Forms_Main;

{$mode delphi}

{

procedure AssociateFileExtension(const IconPath, ProgramName, Path, Extension: string);
begin
  with TRegistry.Create do
  begin
    RootKey := HKEY_CLASSES_ROOT;
    OpenKey(ProgramName, True);
    WriteString('', ProgramName);
    if IconPath <> '' then
    begin
      OpenKey(RC_DefaultIcon, True);
      WriteString('', IconPath);
    end;
    CloseKey;
    OpenKey(ProgramName, True);
    OpenKey('shell', True);
    OpenKey('open', True);
    OpenKey('command', True);
    WriteString('', '"' + Path + '" "%1"');
    Free;
  end;
  with TRegistry.Create do
  begin
    RootKey := HKEY_CLASSES_ROOT;
    OpenKey('.' + Extension, True);
    WriteString('', ProgramName);
    Free;
  end;
  RebuildIconCache;
end;

procedure AssociateExtension(const IconPath, ProgramName, Path, Extension: string);
begin
  AssociateFileExtension(IconPath, ProgramName, Path, Extension);
end;

}


//*****************************************************************************

interface

uses
  Classes, SysUtils, Forms, Controls, ComCtrls, ActnList, ExtCtrls, Menus,
  Buttons, StdCtrls,

  LResources,

  ts_Docking, ts_Docking_Storage,
  // for debugging
  sharedloggerlcl, ipcchannel,

  SynEdit,

  ts_Editor_Interfaces;

{
  KNOWN PROBLEMS
    - Close all but current tab does not work in all cases
    - when all tabs are closed and one editor remains, the tab is still shown
    - The highlighter of the selected view does not show correctly in the
      popup menu
    - idem for the folding level
    - Fold level does not work for XML
    - encoding support needs to be implemented
    - support for alternative line endings needs to be implemented
    - auto guess highlighter (make it a setting)
    - comment selection should use comment style of the currently selected
      highlighter
    - saving loading in different encodings
    - memory management in combination with the anchor docking

  TODO
    - Dequote lines in code shaper

  IDEAS
    - surround with function for selected block (as in Notepad2)
    - duplicate lines
    - remove first/last char in selected block
    - draw tables
    - status bar builder
}

//=============================================================================

type
  TfrmMain = class(TForm)
    aclMain               : TActionList;
    actClose              : TAction;
    actAbout              : TAction;
    actCloseAllOtherPages : TAction;
    actInspect            : TAction;
    actToggleMaximized    : TAction;
    btnEncoding           : TSpeedButton;
    btnFileName           : TSpeedButton;
    btnHighlighter        : TSpeedButton;
    btnLineBreakStyle     : TSpeedButton;
    imlMain               : TImageList;
    lblHeader             : TLabel;
    mnuMain               : TMainMenu;
    pnlTop                : TPanel;
    pnlTool               : TPanel;
    pnlLineBreakStyle     : TPanel;
    pnlFileName           : TPanel;
    pnlHighlighter        : TPanel;
    pnlEncoding           : TPanel;
    pnlModified           : TPanel;
    pnlViewerCount        : TPanel;
    pnlSize               : TPanel;
    pnlPosition           : TPanel;
    pnlEditMode           : TPanel;
    pnlStatusBar          : TPanel;
    Shape1                : TShape;
    SpeedButton1          : TSpeedButton;
    splVertical           : TSplitter;
    tlbMain               : TToolBar;

    procedure actAboutExecute(Sender: TObject);
    procedure actCloseExecute(Sender: TObject);
    procedure actToggleMaximizedExecute(Sender: TObject);

    procedure ActionListExecute(AAction: TBasicAction; var Handled: Boolean);
    procedure AHSActivate(Sender: TObject);
    procedure AHSActivateSite(Sender: TObject);
    procedure AHSEnter(Sender: TObject);
    procedure AHSShow(Sender: TObject);
    procedure AHSWindowStateChange(Sender: TObject);
    procedure btnEncodingClick(Sender: TObject);
    procedure btnFileNameClick(Sender: TObject);
    procedure btnHighlighterClick(Sender: TObject);
    procedure btnLineBreakStyleClick(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of string);
    procedure FormShow(Sender: TObject);
    procedure frmMainActiveViewChange(Sender: TObject);
    procedure ScreenActiveControlChange(Sender: TObject);
    procedure ScreenActiveFormChange(Sender: TObject);
    procedure TAnchorDockPageControlChanging(Sender: TObject; var AllowChange: Boolean);
  private
    // property access methods
    function GetActions: IEditorActions;
    function GetEditor: IEditorView;
    function GetManager: IEditorManager;
    function GetMenus: IEditorMenus;
    function GetSettings: IEditorSettings;
    function GetViews: IEditorViews;

    procedure InitDebugAction(const AActionName: string);

    // event handlers
    procedure ENewFile(Sender: TObject; var AFileName: string;
      const AText: string);
    procedure EStatusChange(Sender: TObject; Changes: TSynStatusChanges);

  protected
    procedure AddDockingMenuItems;
    procedure AssignEvents;
    procedure ConfigureAvailableActions;
    procedure UpdateStatusBar;
    procedure UpdateCaptions;

  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    procedure UpdateActions; override;

    function AddEditor(const AFileName: string): IEditorView;

    property Manager: IEditorManager
      read GetManager;

    property Editor: IEditorView
      read GetEditor;

    property Actions: IEditorActions
      read GetActions;

    property Views: IEditorViews
      read GetViews;

    property Menus: IEditorMenus
      read GetMenus;

    property Settings: IEditorSettings
      read GetSettings;
  end;

var
  frmMain: TfrmMain;

//*****************************************************************************

implementation

{$R *.lfm}

uses
  StrUtils, Windows,

  SynEditTypes,

  ts_Core_Utils, ts_Core_VersionInfo,

  ts_Editor_Manager, ts_Editor_AboutDialog, ts_Editor_Helpers;

//*****************************************************************************
// construction and destruction                                          BEGIN
//*****************************************************************************

procedure TfrmMain.AfterConstruction;
var
  I : Integer;
  EV: IEditorEvents;
  V : IEditorView;
begin
  inherited AfterConstruction;
  Manager.PersistSettings := True;
  ConfigureAvailableActions;
  DockMaster.MakeDockSite(Self, [akTop, akBottom, akRight, akLeft], admrpChild);
  AddDockingMenuItems;
  AddStandardEditorToolbarButtons(tlbMain);
  AddStandardEditorMenus(mnuMain);

  if Settings.DebugMode then
  begin
    // for debugging
    Logger.Channels.Add(TIPCChannel.Create);
    Logger.MaxStackCount := 5; // more than 5 give problems when exception is raised when stackinfo is not available
    Screen.OnActiveControlChange := ScreenActiveControlChange;
    Screen.OnActiveFormChange := ScreenActiveFormChange;
    AddEditorDebugMenu(mnuMain);
  end;
  pnlViewerCount.Visible := Settings.DebugMode;

  if ParamCount > 0 then
  begin
    for I := 1 to Paramcount do
    begin
      if I = 1 then
        V := AddEditor(ParamStr(I))
      else
        AddEditor(ParamStr(I));
    end;
  end
  else
  begin
    V := AddEditor('<new>');
  end;
  EV := Manager.Events;
  Manager.OnActiveViewChange  := frmMainActiveViewChange;
  EV.OnStatusChange := EStatusChange;
  EV.OnNewFile := ENewFile;
  tlbMain.Parent := Self;
  pnlStatusBar.Parent := Self;
  pnlHighlighter.PopupMenu    := Menus.HighlighterPopupMenu;
  btnHighlighter.PopupMenu    := Menus.HighlighterPopupMenu;
  btnEncoding.PopupMenu       := Menus.EncodingPopupMenu;
  btnLineBreakStyle.PopupMenu := Menus.LineBreakStylePopupMenu;
  Manager.Actions.ActionList.OnExecute  := ActionListExecute;

  SetWindowSizeGrip(pnlStatusBar.Handle, True);
  Manager.ActiveView := V;
  DoubleBuffered := True;
end;

procedure TfrmMain.BeforeDestruction;
begin
  Settings.FormSettings.Assign(Self);
  inherited BeforeDestruction;
end;

//*****************************************************************************
// construction and destruction                                            END
//*****************************************************************************

//*****************************************************************************
// property access methods                                               BEGIN
//*****************************************************************************

function TfrmMain.GetManager: IEditorManager;
begin
  Result := EditorManager;
end;

function TfrmMain.GetActions: IEditorActions;
begin
  Result := Manager.Actions;
end;

function TfrmMain.GetEditor: IEditorView;
begin
  Result := Manager.ActiveView;
end;

function TfrmMain.GetMenus: IEditorMenus;
begin
  Result := Manager.Menus;
end;

function TfrmMain.GetSettings: IEditorSettings;
begin
  Result := Manager.Settings;
end;

function TfrmMain.GetViews: IEditorViews;
begin
  Result := Manager.Views;
end;

//*****************************************************************************
// property access methods                                                 END
//*****************************************************************************

//*****************************************************************************
// action handlers                                                       BEGIN
//*****************************************************************************

procedure TfrmMain.actToggleMaximizedExecute(Sender: TObject);
begin
  if WindowState = wsMaximized then
    WindowState := wsNormal
  else
    WindowState := wsMaximized;
end;

procedure TfrmMain.actCloseExecute(Sender: TObject);
begin
  if Settings.CloseWithESC then
    Close;
end;

procedure TfrmMain.actAboutExecute(Sender: TObject);
begin
  ShowAboutDialog;
end;

//*****************************************************************************
// action handlers                                                         END
//*****************************************************************************

//*****************************************************************************
// event handlers                                                        BEGIN
//*****************************************************************************

procedure TfrmMain.ActionListExecute(AAction: TBasicAction; var Handled: Boolean);
var
  F: TForm;
  A: TAction;
  ADHS: TAnchorDockHostSite;
begin
  /// below works!
  //if AAction.Name = 'actFindNext' then
  //begin
  //  Actions.FindReplaceDialog;
  //  DockMaster.MakeDockable(Actions.FindReplaceDialog);
  //  DockMaster.ManualDock(DockMaster.GetAnchorSite(Actions.FindReplaceDialog),Self, alRight);
  //end;
    A := TAction(AAction);
    if A.Name = 'actShapeCode' then
    begin
      pnlTool.BeginUpdateBounds;
      //F := CodeShaperForm;
      //ShowMessage(F.Name);

      F := EditorManager.ToolViews['frmCodeShaper'].Form;
      if Assigned(F) then
      begin
        lblHeader.Caption := F.Caption;
        F.BeginUpdateBounds;
        F.Parent := pnlTool;
        F.BorderStyle := bsNone;
        F.Align := alClient;
        F.Visible := A.Checked;
        F.EndUpdateBounds;
        pnlTool.EndUpdateBounds;
        pnlTool.Visible := A.Checked;
        splVertical.Visible := A.Checked;
      end
    end
    else if A.Name = 'actFind' then
    begin
      F := EditorManager.ToolViews['frmSearchForm'].Form;
      if Assigned(F) then
      begin
        pnlTool.BeginUpdateBounds;
        lblHeader.Caption := F.Caption;
        F.BeginUpdateBounds;
        F.Parent := pnlTool;
        F.BorderStyle := bsNone;
        F.Align := alClient;
        F.Visible := A.Checked;
        F.EndUpdateBounds;
        pnlTool.EndUpdateBounds;
        pnlTool.Visible := A.Checked;
        splVertical.Visible := A.Checked;
        Application.ProcessMessages;  // required to be able to set focus to this window
        if F.CanFocus then
          F.SetFocus;
      end;
    end

    else if A.Name = 'actShowPreview' then
    begin
      F := EditorManager.ToolViews['frmPreview'].Form;
      if Assigned(F) then
      begin
        pnlTool.BeginUpdateBounds;
        lblHeader.Caption := F.Caption;
        F.BeginUpdateBounds;
        F.Parent := pnlTool;
        F.BorderStyle := bsNone;
        F.Align := alClient;
        F.Visible := A.Checked;
        F.EndUpdateBounds;
        pnlTool.Visible := A.Checked;
        splVertical.Visible := A.Checked;
        pnlTool.EndUpdateBounds;
      end;
    end
    else if A.Name = 'actTestForm' then
    begin
      F := EditorManager.ToolViews['frmTest'].Form;
      if Assigned(F) then
      begin
        pnlTool.BeginUpdateBounds;
        lblHeader.Caption := F.Caption;
        F.BeginUpdateBounds;
        F.Parent := pnlTool;
        F.BorderStyle := bsNone;
        F.Align := alClient;
        F.Visible := True;
        F.EndUpdateBounds;
        pnlTool.Visible := A.Checked;
        splVertical.Visible := A.Checked;
        pnlTool.EndUpdateBounds;
      end;
    end
    else if A.Name = 'actAlignSelection' then
    begin
      F := EditorManager.ToolViews['frmAlignLines'].Form;
      if Assigned(F) then
      begin
        pnlTool.BeginUpdateBounds;
        lblHeader.Caption := F.Caption;
        F.BeginUpdateBounds;
        F.Parent := pnlTool;
        F.BorderStyle := bsNone;
        F.Align := alClient;
        F.Visible := True;
        F.EndUpdateBounds;
        pnlTool.Visible := A.Checked;
        splVertical.Visible := A.Checked;
        EditorManager.ToolViews['frmAlignLines'].UpdateView;
        pnlTool.EndUpdateBounds;
      end;
    end;
      //DockMaster.BeginUpdate;
      //DockMaster.MakeDockable(CodeShaperForm.CodeShaperForm);
      //ADHS := DockMaster.GetAnchorSite(CodeShaperForm.CodeShaperForm);
      //ADHS.BeginUpdateLayout;
      //DockMaster.ManualDock(ADHS, FToolForm, alLeft);
      //ADHS.EndUpdateLayout;
      //DockMaster.EndUpdate;
  Logger.SendCallStack('CallStack');
end;

procedure TfrmMain.AHSActivate(Sender: TObject);
begin
  Logger.Send('AHS.Activate', Sender);
end;

procedure TfrmMain.AHSActivateSite(Sender: TObject);
var
  AHS : TAnchorDockHostSite;
  C   : TControl;
begin
  AHS := TAnchorDockHostSite(Sender);
  if AHS.SiteType = adhstOneControl then
  begin
    C := DockMaster.GetControl(AHS);
    if C is IEditorView then
      (C as IEditorView).Activate;
  end;
end;

procedure TfrmMain.AHSEnter(Sender: TObject);
begin
  Logger.Send('AHS.Enter', Sender);
end;

procedure TfrmMain.AHSShow(Sender: TObject);
begin
  Logger.Send('AHS.Show', Sender);
end;

procedure TfrmMain.AHSWindowStateChange(Sender: TObject);
begin
Logger.Send('AHS.WindowStateChange', Sender);
end;

procedure TfrmMain.ENewFile(Sender: TObject; var AFileName: string;
  const AText: string);
begin
  if FileExists(AFileName) then
  begin
    AddEditor(AFileName);
  end
  else
  begin
    AddEditor('<new>').Text := AText;
    Editor.SetFocus;
  end;
end;

procedure TfrmMain.EStatusChange(Sender: TObject; Changes: TSynStatusChanges);
begin
  if scModified in Changes then
  begin
    // TODO: draw icon in tabsheet indicating that there was a change
  end;
end;

procedure TfrmMain.btnEncodingClick(Sender: TObject);
begin
  btnEncoding.PopupMenu.PopUp;
end;

procedure TfrmMain.btnFileNameClick(Sender: TObject);
begin
  ExploreFile(Editor.FileName);
end;

procedure TfrmMain.btnHighlighterClick(Sender: TObject);
begin
  btnHighlighter.PopupMenu.PopUp;
end;

procedure TfrmMain.btnLineBreakStyleClick(Sender: TObject);
begin
  btnLineBreakStyle.PopupMenu.PopUp;
end;

procedure TfrmMain.FormDropFiles(Sender: TObject;
  const FileNames: array of string);
var
  I: Integer;
  V: IEditorView;
begin
  if Assigned(Editor) then
    V := Editor;
  DisableAutoSizing;
  try
    for I := Low(FileNames) to High(FileNames) do
    begin
      if I = Low(FileNames) then
        V := AddEditor(FileNames[I])
      else
        AddEditor(FileNames[I])
    end;
  finally
    EnableAutoSizing;
  end;
  V.Activate;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  BeginAutoSizing;
  Settings.FormSettings.AssignTo(Self);
  EndAutoSizing;
end;

procedure TfrmMain.frmMainActiveViewChange(Sender: TObject);
begin
  if Assigned(Editor) then
    DockMaster.MakeVisible(Editor.Form, True);
end;

procedure TfrmMain.ScreenActiveControlChange(Sender: TObject);
begin
  if Assigned(Screen.ActiveControl) then
  begin
    if Screen.ActiveControl is TSynEdit then
      Logger.Send('EditorView', Format('%s', [Screen.ActiveControl.Parent.Name]))
    else
      Logger.Send('Screen.ActiveControl changed', Format('%s, %s', [Screen.ActiveControl.ClassName, Screen.ActiveControl.Name]));
  end;
end;

procedure TfrmMain.ScreenActiveFormChange(Sender: TObject);
begin
  if Assigned(Screen.ActiveCustomForm) then
  begin
      Logger.Send('Screen.ActiveForm changed', Format('%s, %s', [Screen.ActiveCustomForm.ClassName, Screen.ActiveCustomForm.Name]));
  end;
end;

procedure TfrmMain.TAnchorDockPageControlChanging(Sender: TObject; var AllowChange: Boolean);
begin
  Logger.Send('ControlChanging', Sender);
  (Sender as TAnchorDockPageControl).GetActiveSite.Show;
end;

//*****************************************************************************
// event handlers                                                          END
//*****************************************************************************

//*****************************************************************************
// private methods                                                       BEGIN
//*****************************************************************************

procedure TfrmMain.InitDebugAction(const AActionName: string);
begin
  Actions[AActionName].Enabled := Settings.DebugMode;
  Actions[AActionName].Visible := Settings.DebugMode;
end;

//*****************************************************************************
// private methods                                                         END
//*****************************************************************************

//*****************************************************************************
// protected methods                                                     BEGIN
//*****************************************************************************

procedure TfrmMain.AddDockingMenuItems;
var
  MI: TMenuItem;
  PPM: TPopupMenu;
begin
  PPM := DockMaster.GetPopupMenu;
  MI := TMenuItem.Create(PPM);
  MI.Action := Actions.ActionList.ActionByName('actCloseOthers');
  PPM.Items.Add(MI);
end;

procedure TfrmMain.AssignEvents;
var
  C: TComponent;
  I: Integer;
begin
  for I := 0 to DockMaster.ComponentCount - 1 do
  begin
    C := DockMaster.Components[I];
    if C is TAnchorDockPageControl then
      TAnchorDockPageControl(C).OnChanging := TAnchorDockPageControlChanging;
  end;
end;

{ Hide actions that are not (fully) implemented or supported. }

procedure TfrmMain.ConfigureAvailableActions;
begin
  // TODO: maintain a list with Available actions in the manager instance !!!
  InitDebugAction('actMonitorChanges');
  InitDebugAction('actShowActions');
  InitDebugAction('actLoadHighlighterFromFile');
  InitDebugAction('actInspect');
  InitDebugAction('actShapeCode');
  InitDebugAction('actSortSelection');
  InitDebugAction('actPrint');
  InitDebugAction('actPrintPreview');
  InitDebugAction('actPageSetup');
  InitDebugAction('actExportToWiki');
  InitDebugAction('actExportToHTML');
  InitDebugAction('actExportToRTF');
  InitDebugAction('actInsertCharacterFromMap');

  //InitDebugAction('actCopyHTMLToClipboard');
  //InitDebugAction('actCopyWikiToClipboard');
  //InitDebugAction('actCopyRTFToClipboard');
  //InitDebugAction('actCopyHTMLTextToClipboard');
  //InitDebugAction('actCopyWikiTextToClipboard');
  //InitDebugAction('actCopyRTFTextToClipboard');
end;

procedure TfrmMain.UpdateStatusBar;
begin
  pnlPosition.Caption :=
    Format('%1d:%1d / %1d | %1d', [
      Editor.CaretX,
      Editor.CaretY,
      Editor.Lines.Count,
      Editor.SelStart
    ]);

  pnlViewerCount.Caption := IntToStr(Views.Count);
  pnlSize.Caption := FormatByteText(Editor.TextSize);

  if Assigned(Editor.HighlighterItem) then
    pnlHighlighter.Caption := Editor.HighlighterItem.Description;
  if Editor.Editor.InsertMode then
    pnlEditMode.Caption := 'INS'
  else
    pnlEditMode.Caption := 'OVR';
  btnFileName.Caption := Editor.FileName;
  btnFileName.Hint := Editor.FileName;
  pnlFileName.Caption := Editor.FileName;
  pnlEncoding.Caption := UpperCase(Editor.Encoding);
  pnlLineBreakStyle.Caption := Editor.LineBreakStyle;
  pnlModified.Caption := IfThen(Editor.Modified, 'Modified', '');
  OptimizeWidth(pnlViewerCount);
  OptimizeWidth(pnlPosition);
  OptimizeWidth(pnlSize);
  OptimizeWidth(pnlHighlighter);
  OptimizeWidth(pnlEncoding);
  OptimizeWidth(pnlEditMode);
  OptimizeWidth(pnlFileName);
  OptimizeWidth(pnlLineBreakStyle);
  OptimizeWidth(pnlModified);
end;

procedure TfrmMain.UpdateCaptions;
var
  V: IEditorView;
  I: Integer;
begin
  for I := 0 to Views.Count - 1 do
  begin
    V := Views[I];
    V.Form.Caption := ExtractFileName(V.FileName);
  end;
end;

procedure TfrmMain.UpdateActions;
begin
  inherited UpdateActions;
  if Assigned(Editor) then
  begin
    UpdateStatusBar;
  end;
end;

{ Creates a new IEditorView instance for the given file. }

function TfrmMain.AddEditor(const AFileName: string): IEditorView;
var
  V: IEditorView;
  AHS: TAnchorDockHostSite;
begin
  DisableAutoSizing;
  try
    V := Views.Add('', AFileName);
    V.Form.DisableAutoSizing;
    try
      DockMaster.MakeDockable(V.Form);
      AHS := DockMaster.GetAnchorSite(V.Form);
      AHS.OnEnter := AHSEnter;
      AHS.OnShow := AHSShow;
      AHS.OnWindowStateChange := AHSWindowStateChange;
      AHS.OnActivate := AHSActivate;
      DockMaster.ManualDock(AHS, Self, alClient);
      AHS.Header.Visible := Views.Count > 1;
      AHS.Header.HeaderPosition := adlhpTop;
      AHS.OnActivateSite := AHSActivateSite;
      if FileExists(AFileName) then
      begin
        V.LoadFromFile(AFileName);
      end;
      V.OnDropFiles := FormDropFiles;
      V.Editor.PopupMenu := Menus.EditorPopupMenu;
      UpdateCaptions;
    finally
      V.Form.EnableAutoSizing;
    end;
  finally
    EnableAutoSizing;
  end;
  Result := V;
end;

//*****************************************************************************
// protected methods                                                       END
//*****************************************************************************

initialization
{$I notepas_forms_main.lrs}

end.
