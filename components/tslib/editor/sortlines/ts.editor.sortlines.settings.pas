{
  Copyright (C) 2013 Tim Sinaeve tim.sinaeve@gmail.com

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

unit ts.Editor.SortLines.Settings;

{$MODE Delphi}

interface

uses
  Classes, SysUtils;

const
  DEFAULT_WIDTH = 360;

type
  TSortDirection = (
    sdAscending,
    sdDescending
  );

type
  TSortLinesSettings = class(TPersistent)
  strict private
    FSortDirection : TSortDirection;
    FWidth         : Integer;

  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;

    procedure AssignTo(Dest: TPersistent); override;
    procedure Assign(Source: TPersistent); override;

  published
    property SortDirection: TSortDirection
      read FSortDirection write FSortDirection default sdAscending;

    property Width: Integer
      read FWidth write FWidth default DEFAULT_WIDTH;
  end;

implementation

{ TSortLinesSettings }

{$region 'construction and destruction' /fold}
procedure TSortLinesSettings.AfterConstruction;
begin
  inherited AfterConstruction;
  FWidth := DEFAULT_WIDTH;
end;

procedure TSortLinesSettings.BeforeDestruction;
begin
  inherited BeforeDestruction;
end;
{$endregion}

{$region 'public methods' /fold}
procedure TSortLinesSettings.AssignTo(Dest: TPersistent);
var
  S: TSortLinesSettings;
begin
  if Dest is TSortLinesSettings then
  begin
    S := TSortLinesSettings(Dest);
    S.Width := Width;
  end
  else
    inherited AssignTo(Dest);
end;

procedure TSortLinesSettings.Assign(Source: TPersistent);
var
  S : TSortLinesSettings;
begin
  if Source is TSortLinesSettings then
  begin
    S := TSortLinesSettings(Source);
    Width := S.Width;
    SortDirection :=  S.SortDirection;
  end
  else
    inherited Assign(Source);
end;
{$endregion}

end.
