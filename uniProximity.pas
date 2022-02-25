unit uniProximity;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Generics.Collections,
  FMX.Objects,
  FMX.Types,
  FMX.Layouts,
  FMX.Controls,
  FMX.StdCtrls;


type
  THexField = class;

  THexFieldList = TList<THexField>;
  THexFields = array of array of THexField;

  TPLayer = (Human, Computer);

  TProximity = class(TRectangle)
  private
    fHexFields: THexFields;
    fNext: THexField;
    fCurrent: TPLayer;
    procedure HexFieldClick(Sender: TObject);
    function GetNeighbours(aHexField: THexField): THexFieldList;
  public
    constructor Create(AOwner: TComponent; aParent: TScaledLayout; aRectBottom: TRectangle; aX, aY, aDebug: Integer); reintroduce;
    destructor Destroy; override;
  end;

  THexFieldStatus = ( none,
                      empty,
                      red,
                      blue,
                      debug  );

  THexField = class(TCustomPath)
  private
    fTxt: TText;
    fPoints: Integer;//    fDebug: TRectangle;
    fHexFieldStatus: THexFieldStatus;
    fX, fY: Integer;
    procedure SetHexFieldStatus(const Value: THexFieldStatus);
    procedure AddPoint;
    procedure SetPoints(const Value: Integer);
  protected
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    property HexFieldStatus: THexFieldStatus read fHexFieldStatus write SetHexFieldStatus;
    property Points: Integer read fPoints write SetPoints;
    procedure RandomPoints;
  end;

implementation

uses
  System.UIConsts,
  System.Math,
  FMX.Graphics;



{ TProximity }

constructor TProximity.Create(AOwner: TComponent; aParent: TScaledLayout; aRectBottom: TRectangle; aX, aY, aDebug: Integer);
var
  x, y, _viertel, _halbe, _overlaps: Integer;
  w, h, w2, th, px, py: Single;
const
 coStrokeThickness = 1;
begin
  inherited create(AOwner);
  Fill.Kind := TBrushKind.None;
  Stroke.Kind := TBrushKind.None;
  Align := TAlignLayout.Client;
  Parent := aParent;

  aX := EnsureRange(aX, 1, 30);
  aY := EnsureRange(aY, 2, 30);

  SetLength(fHexFields, aX, aY);

  // wieviele viertel haben die Hexagons insgesamt?
  _viertel := aX*2*4;
  // wieviele viertel überlappen:
  _overlaps := aX*2-1;
  // minus die viertel die überlappen
  _viertel := _viertel - _overlaps;

  // w ist jetzt so groß dass alle hexis reinpassen
  w := aParent.OriginalWidth / _viertel*4;
  w2 := w / 2;

  // In the flat orientation, a hexagon has width w = 2 * size and height h = sqrt(3) * size. The sqrt(3) comes from sin(60°).
  h := Sqrt(3) * w2;

  // wenn es aber zu hoch wird:
  th := (h*aY) - (aY-1)*(h/2);
  if th > aParent.OriginalHeight then
  begin
    // wieviele halbe haben die Hexagons insgesamt?
    _halbe := aY*2;
    // wieviele halbe überlappen:
    _overlaps := aY-1;
    // minus die halbe die überlappen
    _halbe := _halbe - _overlaps;

    h := aParent.OriginalHeight / _halbe*2;
    w := h / Sqrt(3) * 2;
    w2 := w / 2;
  end;

  aParent.BeginUpdate;
  for x := Low(fHexFields) to High(fHexFields) do
  begin
    for y := Low(fHexFields[x]) to High(fHexFields[x]) do
    begin
      if y mod 2 = 0 then
      begin
        px := x * (w + w2) - (2 * x * coStrokeThickness);
        py := y * (h/2 - coStrokeThickness);
      end else
      begin
        px := x * (w + w2) + (w/4*3 - coStrokeThickness) - (2 * x * coStrokeThickness);
        py := y * (h/2 - coStrokeThickness);
      end;

      fHexFields[x, y] := THexField.Create(Self);
      fHexFields[x, y].fX := x;
      fHexFields[x, y].fY := y;
//      fHexFields[x, y].fTxt.Text := x.ToString + ',' + y.ToString;
      fHexFields[x, y].Width := w;
      fHexFields[x, y].Height := h;
      fHexFields[x, y].Position.X := px;
      fHexFields[x, y].Position.Y := py;
      fHexFields[x, y].HitTest := True;
      fHexFields[x, y].OnClick := HexFieldClick;
      fHexFields[x, y].Parent := Self;
    end;
  end;
  aParent.EndUpdate;

  //
  fNext := THexField.Create(aRectBottom);
  fNext.RandomPoints;
  fNext.Height := aRectBottom.Height - 10;
  fNext.Width  := fNext.Height / Sqrt(3) * 2;//  fNext.Position.X := ;//  fNext.Position.Y := ;
  fNext.HitTest := False;  //fNext.OnClick := HexFieldClick;
  fNext.Align := TAlignLayout.Center;
  fNext.Parent := aRectBottom;
  fNext.HexFieldStatus := THexFieldStatus.red;

  fCurrent := TPLayer.Human;
end;

destructor TProximity.Destroy;
begin

  inherited;
end;

procedure TProximity.HexFieldClick(Sender: TObject);
var
  clicked, hf: THexField;
  _neighbours: TList<THexField>;
begin
  clicked := THexField(Sender);

  case clicked.HexFieldStatus of
    empty:
    begin
      case fCurrent of
        Human   : begin
                    clicked.HexFieldStatus := THexFieldStatus.red;
                    fCurrent := TPLayer.Computer;
                    fNext.HexFieldStatus := THexFieldStatus.blue;
                  end;
        Computer: begin
                    clicked.HexFieldStatus := THexFieldStatus.blue;
                    fCurrent := TPLayer.Human;
                    fNext.HexFieldStatus := THexFieldStatus.red;
                  end;
      end;

      clicked.Points := fNext.Points;
      fNext.RandomPoints;

      // Nachbarn ermitteln:
      _neighbours := GetNeighbours(clicked);
      for hf in _neighbours do
      begin
        // eigene bekommen einen Punkt mehr:
        if hf.HexFieldStatus = clicked.HexFieldStatus then
          hf.AddPoint;
        // gegnerische bekommen eigene Farbe:
        case hf.HexFieldStatus of
          red, blue:
          begin
            if hf.HexFieldStatus <> clicked.HexFieldStatus then
              if hf.Points < clicked.Points then
                hf.HexFieldStatus := clicked.HexFieldStatus;
          end;
        end;
      end;
      _neighbours.Free;
    end;

    red  : ; // kann man nicht mehr klicken
    blue : ; // kann man nicht mehr klicken
  end;
end;

function TProximity.GetNeighbours(aHexField: THexField): THexFieldList;
var
  hx, hy: Integer;

  function IsInsideField(aX, aY: Integer): Boolean;
  begin
    Result :=
      (aX >= 0)  and
      (aX <= hx) and
      (aY >= 0)  and
      (aY <= hy);
  end;

  procedure AddIfInside(aX, aY: Integer);
  begin
    if IsInsideField(aX, aY) then
      Result.Add( fHexFields[aX, aY] );
  end;

begin
  Result := THexFieldList.Create;

  hx := High(fHexFields);
  hy := High(fHexFields[High(fHexFields)]);

  if (aHexField.fY mod 2) = 0 then
  begin
    AddIfInside(aHexField.fX-1, aHexField.fY-1);
    AddIfInside(aHexField.fX-1, aHexField.fY+1);
    AddIfInside(aHexField.fX+0, aHexField.fY-2);
    AddIfInside(aHexField.fX+0, aHexField.fY-1);
    AddIfInside(aHexField.fX+0, aHexField.fY+1);
    AddIfInside(aHexField.fX+0, aHexField.fY+2);
  end else
  begin
    AddIfInside(aHexField.fX+0, aHexField.fY-2);
    AddIfInside(aHexField.fX+0, aHexField.fY-1);
    AddIfInside(aHexField.fX+0, aHexField.fY+1);
    AddIfInside(aHexField.fX+0, aHexField.fY+2);
    AddIfInside(aHexField.fX+1, aHexField.fY-1);
    AddIfInside(aHexField.fX+1, aHexField.fY+1);
  end;
end;




{ THexField }

constructor THexField.Create(AOwner: TComponent);
begin
  inherited;
  // Source: https://stackoverflow.com/questions/34417564/how-do-i-create-a-cut-out-hexagon-shape
  //Data.Data := 'M2.5,0.66 L7.5,0.66 L10,5 L7.5,9.33 L2.5,9.33 L0,5 z';
  Data.Data := 'M10,10 M0,0 M2.5,0 L7.5,0 L10,5 L7.5,10 L2.5,10 L0,5 z';

  Stroke.Color := claBlack;
  StrokeThickness := 2;

  Fill.Kind := TBrushKind.Gradient;

  fHexFieldStatus := THexFieldStatus.none;
  HexFieldStatus := THexFieldStatus.empty;

  fTxt := TText.Create(Self);
  fTxt.Align := TAlignLayout.Client;
  fTxt.HitTest := False;
  fTxt.TextSettings.Font.Size := fTxt.TextSettings.Font.Size + 10;
  fTxt.TextSettings.Font.Style := fTxt.TextSettings.Font.Style + [tfontstyle.fsBold];
  fTxt.TextSettings.FontColor := claDarkgray;
  fTxt.TextSettings.WordWrap := False;
  fTxt.Parent := Self;

  fPoints := 0;
//  fDebug := TRectangle.Create(Self);
//  fDebug.Align := TAlignLayout.Left;
//  fDebug.Fill.Color := $DD00FF00;
  //fDebug.Parent := Self;
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
      debug : begin
                Fill.Gradient.Style := TGradientStyle.Linear;

                Fill.Gradient.StartPosition.Y := 0.733153820037841800;
                Fill.Gradient.StopPosition.X  := 1.000000000000000000;
                Fill.Gradient.StopPosition.Y  := 0.266846150159835800;

                Fill.Gradient.Points[0].Color := $FFA302A9;
                Fill.Gradient.Points[0].Offset := 0.801242232322692900;
                Fill.Gradient.Points[1].Color := $FFD00CFC;
                Fill.Gradient.Points[1].Offset := 0.953416168689727700;
              end;
    end;

    Repaint;
  end;
end;

procedure THexField.SetPoints(const Value: Integer);
var
  tmp: Integer;
begin
  tmp := EnsureRange(Value, 1, 20);
  if fPoints <> tmp then
  begin
    fPoints := tmp;
    fTxt.Text := fPoints.ToString;
  end;
end;

procedure THexField.Resize;
begin
  inherited;
//  fDebug.Width := Width / 4 * 3;
//  fDebug.Height := Height / 4 * 3;
end;

procedure THexField.AddPoint;
begin
  Points := Points + 1;
end;

procedure THexField.RandomPoints;
begin
  Points := Random(20)+1;
end;


end.
