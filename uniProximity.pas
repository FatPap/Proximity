unit uniProximity;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  FMX.Objects,
  FMX.Types,
//  FMX.Graphics,
//  FMX.Controls,
  FMX.StdCtrls;


type
  THexField = class;

  THexFields = array of array of THexField;

  TProximity = class(TRectangle)
  private
    fHexFields: THexFields;
    procedure HexFieldClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

  end;

  THexField = class(TCustomPath)
  private
    fTxt: TText;
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

uses
  System.UIConsts;

{ TProximity }

constructor TProximity.Create(AOwner: TComponent);
var
  x, y: Integer;
  px, py: Single;
  hf: THexField;
begin
  inherited;
  Align := TAlignLayout.Client;
  SetLength(fHexFields, 5, 10);

  for x := Low(fHexFields) to High(fHexFields) do
  begin
    for y := Low(fHexFields[x]) to High(fHexFields[x]) do
    begin
      if y mod 2 = 0 then
      begin
        px := x * 150;
        py := y * 50;
      end else
      begin
        px := x * 150 + 75;
        py := y * 50;
      end;

      fHexFields[x, y] := THexField.Create(Self);
      fHexFields[x, y].fTxt.Text := x.ToString + ',' + y.ToString;
      fHexFields[x, y].Width := 100;
      fHexFields[x, y].Height := 100;
      fHexFields[x, y].Position.X := px;
      fHexFields[x, y].Position.Y := py;
      fHexFields[x, y].HitTest := True;
      fHexFields[x, y].OnClick := HexFieldClick;
      fHexFields[x, y].Parent := Self;
    end;
  end;
end;

destructor TProximity.Destroy;
begin

  inherited;
end;

procedure TProximity.HexFieldClick(Sender: TObject);
var
  hf: THexField;
begin
  hf := THexField(Sender);
  hf.fTxt.Text := random(99).ToString;
end;


{ THexField }

constructor THexField.Create(AOwner: TComponent);
begin
  inherited;
  // Source: https://stackoverflow.com/questions/34417564/how-do-i-create-a-cut-out-hexagon-shape
  Data.Data := 'M2.5,0.66 L7.5,0.66 L10,5 L7.5,9.33 L2.5,9.33 L0,5 z';

  fTxt := TText.Create(Self);
  fTxt.Align := TAlignLayout.Client;
  fTxt.HitTest := False;
  fTxt.TextSettings.FontColor := claBlue;
  fTxt.Parent := Self;
end;

end.
