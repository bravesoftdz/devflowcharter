{
   Copyright (C) 2006 The devFlowcharter project.
   The initial author of this file is Michal Domagala.

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
}



unit PageControl_Form;

interface

uses
   Forms, StdCtrls, ExtCtrls, Graphics, Controls, Menus, ComCtrls, SysUtils,
   Classes, Types, Windows, OmniXML, Base_Form, CommonTypes;

type

  TPageControlForm = class(TBaseForm)
    MainMenu1: TMainMenu;
    miAction: TMenuItem;
    miAdd: TMenuItem;
    miRemove: TMenuItem;
    N1: TMenuItem;
    miRemoveAll: TMenuItem;
    miImport: TMenuItem;
    miExport: TMenuItem;
    miExportAll: TMenuItem;
    pgcTabs: TPageControl;
    procedure miAddClick(Sender: TObject); virtual; abstract;
    procedure miRemoveClick(Sender: TObject);
    procedure miActionClick(Sender: TObject);
    procedure pgcTabsDrawTab(Control: TCustomTabControl;
      TabIndex: Integer; const Rect: TRect; Active: Boolean);
    procedure miExportClick(Sender: TObject);
    procedure miImportClick(Sender: TObject);
    procedure miRemoveAllClick(Sender: TObject);
    procedure pgcTabsChange(Sender: TObject); virtual;
    procedure miExportAllClick(Sender: TObject);
    procedure ExportTabsToXMLTag(const rootTag: IXMLElement);
    function ImportTabsFromXMLTag(const rootTag: IXMLElement): TErrorType; virtual; abstract;
    function GetCorrectIndex(X, Y: integer): integer;
    procedure FormDeactivate(Sender: TObject); virtual;
    procedure FormMouseWheelUp(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure FormMouseWheelDown(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure RefreshTabs; virtual;
    procedure Localize(const list: TStringList); override;
    procedure pgcTabsDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure pgcTabsDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure pgcTabsMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ResetForm; override;
  private
    procedure ScrollElements(const AValue: integer);
  public
    UpdateCodeEditor: boolean;
    { Public declarations }
    function GetVisiblePageCount: integer;
  end;

implementation

{$R *.dfm}

uses
   ApplicationCommon, XMLProcessor, TabComponent, StrUtils, Main_Form;

procedure TPageControlForm.miRemoveClick(Sender: TObject);
var
   lTabComp: TTabComponent;
begin
   if pgcTabs.ActivePage <> nil then
   begin
      lTabComp := TTabComponent(pgcTabs.ActivePage);
      pgcTabs.OwnerDraw := false;
      lTabComp.Active := false;
      GClpbrd.UndoObject.Free;
      pgcTabs.OwnerDraw := true;
      GClpbrd.UndoObject := lTabComp.OverlayObject;
      if GSettings.UpdateEditor then
         TInfra.GetEditorForm.RefreshEditorForObject(nil);
   end;
end;

procedure TPageControlForm.ResetForm;
begin
   UpdateCodeEditor := true;
   inherited ResetForm;
end;

procedure TPageControlForm.miActionClick(Sender: TObject);
begin
   miRemove.Enabled := pgcTabs.ActivePage <> nil;
   miRemoveAll.Enabled := GetVisiblePageCount > 0;
   miExport.Enabled := miRemove.Enabled;
   miExportAll.Enabled := miRemoveAll.Enabled;
end;

procedure TPageControlForm.Localize(const list: TStringList);
var
   i: integer;
begin
   inherited Localize(list);
   for i := 0 to pgcTabs.PageCount-1 do
      TTabComponent(pgcTabs.Pages[i]).Localize(list);
end;

procedure TPageControlForm.RefreshTabs;
begin
{}
end;

// function to fix getting wrong tab index in pgcTabs.OnDrawTab event when
// some tabs are not visible
function TPageControlForm.GetCorrectIndex(X, Y: integer): integer;
var
   i, c: integer;
begin
  c := pgcTabs.IndexOfTabAt(X, Y);
  i := 0;
  while i <= c do
  begin
    if not pgcTabs.Pages[i].TabVisible then
      Inc(c);
    Inc(i);
  end;
  result := c;
end;

procedure TPageControlForm.pgcTabsDrawTab(Control: TCustomTabControl;
  TabIndex: Integer; const Rect: TRect; Active: Boolean);
var
   ARect: TRect;
   lTab: TTabComponent;
begin
   TabIndex := GetCorrectIndex(Rect.Left+5, Rect.Top+5);
   if TabIndex <> -1 then
   begin
      ARect := Rect;
      ARect.Right := ARect.Right-3;
      lTab := TTabComponent(TPageControl(Control).Pages[TabIndex]);
      Control.Canvas.Font.Color := lTab.edtName.Font.Color;
      if lTab.HasInvalidElement then
         Control.Canvas.Font.Color := NOK_COLOR;
      lTab.Font.Color := Control.Canvas.Font.Color;
      Control.Canvas.TextRect(ARect, ARect.Left+5, ARect.Top+3, lTab.Caption);
   end;
end;

procedure TPageControlForm.ExportTabsToXMLTag(const rootTag: IXMLElement);
var
   i: integer;
begin
   for i:= 0 to pgcTabs.PageCount-1 do
   begin
      if pgcTabs.Pages[i].TabVisible then
         TTabComponent(pgcTabs.Pages[i]).ExportToXMLTag(rootTag);
   end;
end;

procedure TPageControlForm.miExportClick(Sender: TObject);
var
   status: TErrorType;
   lTab: TTabComponent;
begin
   if pgcTabs.ActivePage <> nil then
   begin
      lTab := TTabComponent(pgcTabs.ActivePage);
      MainForm.ExportDialog.FileName := lTab.edtName.Text;
      MainForm.ExportDialog.Filter := i18Manager.GetString('XMLFilesFilter');
      if MainForm.ExportDialog.Execute then
      begin
         status := TXMLProcessor.ExportToXMLFile(MainForm.ExportDialog.Filename, lTab.ExportToXMLTag);
         if status <> errNone then
            TInfra.ShowFormattedErrorBox('SaveError', [MainForm.ExportDialog.FileName], status);
      end;
   end;
end;

procedure TPageControlForm.miExportAllClick(Sender: TObject);
var
   status: TErrorType;
begin
   if GProject <> nil then
   begin
      MainForm.ExportDialog.FileName :=  AnsiReplaceStr(GProject.Name + ' ' + Caption, ' ', '_');
      MainForm.ExportDialog.Filter := i18Manager.GetString('XMLFilesFilter');
      if MainForm.ExportDialog.Execute then
      begin
         status := TXMLProcessor.ExportToXMLFile(MainForm.ExportDialog.Filename, ExportTabsToXMLTag);
         if status <> errNone then
            TInfra.ShowFormattedErrorBox('SaveError', [MainForm.ExportDialog.FileName], status);
      end;
   end;
end;

function TPageControlForm.GetVisiblePageCount: integer;
var
   i: integer;
begin
   result := 0;
   for i:= 0 to pgcTabs.PageCount-1 do
   begin
      if pgcTabs.Pages[i].TabVisible then
         Inc(result);
   end;
end;

procedure TPageControlForm.miImportClick(Sender: TObject);
begin
   MainForm.OpenDialog.Filename := '';
   if MainForm.OpenDialog.Execute then
   begin
      if TXMLProcessor.ImportFromXMLFile(MainForm.OpenDialog.Filename, ImportTabsFromXMLTag) <> errNone then
         TInfra.ShowFormattedErrorBox('ImportFailed', [CRLF, Gerr_text], errImport)
      else
      begin
         if GSettings.UpdateEditor then
            TInfra.GetEditorForm.RefreshEditorForObject(nil);
         GChange := 1;
      end;
   end;
end;

procedure TPageControlForm.miRemoveAllClick(Sender: TObject);
var
   i, res: integer;
begin
   res := IDYES;
   if GSettings.ConfirmRemove then
      res := TInfra.ShowQuestionBox(i18Manager.GetString('ConfirmRemove'));
   if res = IDYES then
   begin
      while GetVisiblePageCount > 0 do
      begin
         for i := 0 to pgcTabs.PageCount-1 do
         begin
            if pgcTabs.Pages[i].TabVisible then
            begin
               TTabComponent(pgcTabs.Pages[i]).OverlayObject.Free;
               break;
            end;
         end;
      end;
      GChange := 1;
      if GSettings.UpdateEditor then
         TInfra.GetEditorForm.RefreshEditorForObject(nil);
   end;
end;

procedure TPageControlForm.pgcTabsChange(Sender: TObject);
begin
   TInfra.GetEditorForm.SelectCodeRange(pgcTabs.ActivePage);
end;

procedure TPageControlForm.FormDeactivate(Sender: TObject);
begin
   if GProject <> nil then
      GProject.RefreshStatements;
end;

procedure TPageControlForm.FormMouseWheelUp(Sender: TObject;
  Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
begin
   ScrollElements(-2);
end;

procedure TPageControlForm.FormMouseWheelDown(Sender: TObject;
  Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
begin
   ScrollElements(2);
end;

procedure TPageControlForm.ScrollElements(const AValue: integer);
begin
   if (pgcTabs.ActivePage <> nil) and not TTabComponent(pgcTabs.ActivePage).HasFocusedComboBox then
      TTabComponent(pgcTabs.ActivePage).ScrollElements(AValue);
end;

procedure TPageControlForm.pgcTabsDragDrop(Sender, Source: TObject; X,
  Y: Integer);
var
   lIndex: integer;
begin
   lIndex := GetCorrectIndex(X, Y);
   if lIndex <> -1 then
   begin
      pgcTabs.Pages[lIndex].PageIndex := TTabSheet(Source).PageIndex;
      TTabSheet(Source).PageIndex := lIndex;
      RefreshTabs;
      if GSettings.UpdateEditor then
         TInfra.GetEditorForm.RefreshEditorForObject(nil);
   end;
end;

procedure TPageControlForm.pgcTabsDragOver(Sender, Source: TObject; X,
  Y: Integer; State: TDragState; var Accept: Boolean);
begin
   if not (Source is TTabSheet) then
      Accept := false;
end;

procedure TPageControlForm.pgcTabsMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
   lIndex: integer;
begin
   lIndex := GetCorrectIndex(X, Y);
   if lIndex <> -1 then
      pgcTabs.Pages[lIndex].BeginDrag(false, 3);
end;

end.
