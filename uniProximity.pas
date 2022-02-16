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

  THexFieldStatus = ( none,
                      empty,
                      red,
                      blue  );

  THexField = class(TCustomPath)
  private
    fTxt: TText;
    fHexFieldStatus: THexFieldStatus;
    procedure SetHexFieldStatus(const Value: THexFieldStatus);
  public
    constructor Create(AOwner: TComponent); override;
    property HexFieldStatus: THexFieldStatus read fHexFieldStatus write SetHexFieldStatus;

  end;

implementation

uses
  System.UIConsts,
  FMX.Graphics;

{ TProximity }

constructor TProximity.Create(AOwner: TComponent);
var
  x, y: Integer;
  px, py: Single;
const
 coStrokeThickness = 1;
 coSizeFull = 120;
 coSizeHalf = coSizeFull div 2;
 coSize34 = coSizeFull div 4 * 3;
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
        px := x * (coSizeFull + coSizeHalf) - (2 * x * coStrokeThickness);
        py := y * (coSizeHalf - coStrokeThickness);
      end else
      begin
      //px := x * (coSizeFull + coSizeHalf - coStrokeThickness) + (coSize34 - coStrokeThickness);
        px := x * (coSizeFull + coSizeHalf) + (coSize34 - coStrokeThickness) - (2 * x * coStrokeThickness);
        py := y * (coSizeHalf - coStrokeThickness);
      end;

      fHexFields[x, y] := THexField.Create(Self);
      fHexFields[x, y].fTxt.Text := x.ToString + ',' + y.ToString;
      fHexFields[x, y].Width := coSizeFull;
      fHexFields[x, y].Height := coSizeFull;
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

  case hf.HexFieldStatus of
    empty: hf.HexFieldStatus := THexFieldStatus.red;
    red  : hf.HexFieldStatus := THexFieldStatus.blue;
    blue : hf.HexFieldStatus := THexFieldStatus.empty;
  end;

  //hf.fTxt.Text := random(99).ToString;
end;


{ THexField }

constructor THexField.Create(AOwner: TComponent);
begin
  inherited;
  // Source: https://stackoverflow.com/questions/34417564/how-do-i-create-a-cut-out-hexagon-shape
  //Data.Data := 'M2.5,0.66 L7.5,0.66 L10,5 L7.5,9.33 L2.5,9.33 L0,5 z';
  Data.Data := 'M2.5,0 L7.5,0 L10,5 L7.5,10 L2.5,10 L0,5 z';

  Stroke.Color := claBlack;
  StrokeThickness := 2;

  Fill.Kind := TBrushKind.Gradient;

  fHexFieldStatus := THexFieldStatus.none;
  HexFieldStatus := THexFieldStatus.empty;

  fTxt := TText.Create(Self);
  fTxt.Align := TAlignLayout.Client;
  fTxt.HitTest := False;
  fTxt.TextSettings.Font.Size := fTxt.TextSettings.Font.Size + 20;
  fTxt.TextSettings.Font.Style := fTxt.TextSettings.Font.Style + [tfontstyle.fsBold];
  fTxt.TextSettings.FontColor := claBlack;
  fTxt.Parent := Self;
end;

procedure THexField.SetHexFieldStatus(const Value: THexFieldStatus);
begin
  if fHexFieldStatus <> Value then
  begin
    fHexFieldStatus := Value;

    case fHexFieldStatus of
      none:;
      empty:  begin
                Fill.Gradient.Style := TGradientStyle.Radial;
                Fill.Gradient.Points[0].Color := $FF37615C;
                Fill.Gradient.Points[0].Offset := 0;
                Fill.Gradient.Points[1].Color := $FF508E86;
                Fill.Gradient.Points[1].Offset := 1;
              end;
      red  :  begin
                Fill.Gradient.Style := TGradientStyle.Linear;

                Fill.Gradient.StartPosition.Y := 0.733153820037841800;
                Fill.Gradient.StopPosition.X  := 1.000000000000000000;
                Fill.Gradient.StopPosition.Y  := 0.266846150159835800;

                Fill.Gradient.Points[0].Color := $FFBC0000;
                Fill.Gradient.Points[0].Offset := 0.801242232322692900;
                Fill.Gradient.Points[1].Color := $FFFBD7D7;
                Fill.Gradient.Points[1].Offset := 0.953416168689727700;
              end;

      blue :  begin
                Fill.Gradient.Style := TGradientStyle.Linear;

                Fill.Gradient.StartPosition.Y := 0.733153820037841800;
                Fill.Gradient.StopPosition.X  := 1.000000000000000000;
                Fill.Gradient.StopPosition.Y  := 0.266846150159835800;

                Fill.Gradient.Points[0].Color := $FF1312C9;
                Fill.Gradient.Points[0].Offset := 0.801242232322692900;
                Fill.Gradient.Points[1].Color := $FFDCDCFC;
                Fill.Gradient.Points[1].Offset := 0.953416168689727700;
              end;
    end;

    Repaint;
  end;
end;

end.
