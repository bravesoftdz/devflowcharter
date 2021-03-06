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



unit Text_Block;

interface

uses
   Controls, StdCtrls, Graphics, Classes, Base_Block, SysUtils, CommonInterfaces,
   ExtCtrls, MultiLine_Block;

type

  TCornerPanel = class(TPanel)
     protected
        procedure Paint; override;
  end;

   TTextBlock = class(TMultiLineBlock)
      public
         constructor Create(const ABranch: TBranch; const ALeft, ATop, AWidth, AHeight: integer; const AId: integer = ID_INVALID); overload; override;
         constructor Create(const ABranch: TBranch; const ASource: TTextBlock); overload;
         constructor Create(const ABranch: TBranch); overload;
         procedure ChangeColor(const AColor: TColor); override;
      protected
         FCorner: TCornerPanel;
         procedure Paint; override;
         procedure OnChangeMemo(Sender: TObject); override;
         procedure MyOnCanResize(Sender: TObject; var NewWidth, NewHeight: Integer; var Resize: Boolean); override;
   end;

implementation

uses
   ApplicationCommon, StrUtils, CommonTypes;

constructor TTextBlock.Create(const ABranch: TBranch; const ALeft, ATop, AWidth, AHeight: integer; const AId: integer = ID_INVALID);
begin
   FType := blText;
   inherited Create(ABranch, ALeft, ATop, AWidth, AHeight, AId);

   FCorner := TCornerPanel.Create(Self);
   FCorner.Parent := Self;
   FCorner.Color := GSettings.RectColor;
   FCorner.BevelOuter := bvNone;
   FCorner.Ctl3D := false;
   FCorner.DoubleBuffered := true;
   FCorner.ControlStyle := FCorner.ControlStyle + [csOpaque];
   FCorner.SetBounds(Width-15, 0, 15, 15);
end;

constructor TTextBlock.Create(const ABranch: TBranch; const ASource: TTextBlock);
begin
   inherited Create(ABranch, ASource);
end;

constructor TTextBlock.Create(const ABranch: TBranch);
begin
   Create(ABranch, 0, 0, 140, 91);
end;


procedure TTextBlock.Paint;
begin
   inherited;
   if FCorner <> nil then
      FCorner.Repaint;
end;

procedure TCornerPanel.Paint;
var
   lParent: TTextBlock;
begin
   inherited;
   with Canvas do
   begin
      lParent := TTextBlock(Parent);
      Pen.Color := clBlack;
      PolyLine([Point(0, 0), Point(Width-1, Height-1), Point(0, Height-1), Point(0, 0)]);
      Brush.Color := lParent.FStatements.Color;
      FloodFill(2, Height-2, clBlack, fsBorder);
      Brush.Color := lParent.ParentBlock.Color;
      FloodFill(Width-1, 0, clBlack, fsBorder);
   end;
end;

procedure TTextBlock.MyOnCanResize(Sender: TObject; var NewWidth, NewHeight: Integer; var Resize: Boolean);
begin
   inherited MyOnCanResize(Sender, NewWidth, NewHeight, Resize);
   if HResizeInd and Resize then
      FCorner.Left := Width - 15;
end;

procedure TTextBlock.OnChangeMemo(Sender: TObject);
begin
   inherited;
   UpdateEditor(nil);
end;

procedure TTextBlock.ChangeColor(const AColor: TColor);
begin
   inherited ChangeColor(AColor);
   FStatements.Font.Color := GSettings.FontColor;
end;

end.
