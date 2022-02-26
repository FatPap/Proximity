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

  THexFieldStatus = ( none,
                      empty,
                      red,
                      blue,
                      debug  );


  TProximityClickEvt = procedure (aPlayer: TPLayer) of object;
  TProximityGameOverEvt = procedure () of object;

  TProximity = class(TRectangle)
  private
    fHexFields: THexFields;
    fNextField: THexField;
    fCurrent: TPLayer;
    fTxtRed: TText;
    fTxtBlue: TText;
    fX, fY: Integer;
    fTimer: TTimer;
    fOnClickEvt: TProximityClickEvt;
    fOnGameOverEvt: TProximityGameOverEvt;

    function CreateText(aColor: TAlphaColor; aAlign: TAlignLayout): TText;
    procedure HexFieldClick(Sender: TObject);
    procedure DoHexFieldClick(aHexField: THexField);
    procedure ComputerMove;
    function GetPoints(aHexFieldStatus: THexFieldStatus): Integer;
    function GetEmpty: Integer;
    function GetNeighbours(aHexField: THexField): THexFieldList;
    procedure fTimerTimer(Sender: TObject);
  public
    constructor Create(AOwner: TComponent; aParent: TScaledLayout; aRectBottom: TRectangle; aX, aY, aDebug: Integer); reintroduce;
    destructor Destroy; override;
    property OnClickEvt: TProximityClickEvt read fOnClickEvt write fOnClickEvt;
    property OnGameOver: TProximityGameOverEvt read fOnGameOverEvt write fOnGameOverEvt;
  end;

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
    procedure DoMouseEnter; override;
    procedure DoMouseLeave; override;
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


function CopyFieldsArray(const aFields: THexFields): THexFields;
var
  i: Integer;
begin
  SetLength(Result, Length(aFields));
  for i := 0 to High(Result) do
    Result[i] := Copy(aFields[i]);
end;



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

  fTimer := TTimer.Create(nil);
  fTimer.Enabled := False;
  fTimer.Interval := 650;
  fTimer.OnTimer := fTimerTimer;

  fX := EnsureRange(aX, 1, 30);
  fY := EnsureRange(aY, 2, 30);

  SetLength(fHexFields, fX, fY);

  // wieviele viertel haben die Hexagons insgesamt?
  _viertel := fX*2*4;
  // wieviele viertel überlappen:
  _overlaps := fX*2-1;
  // minus die viertel die überlappen
  _viertel := _viertel - _overlaps;

  // w ist jetzt so groß dass alle hexis reinpassen
  w := aParent.OriginalWidth / _viertel*4;
  w2 := w / 2;

  // In the flat orientation, a hexagon has width w = 2 * size and height h = sqrt(3) * size. The sqrt(3) comes from sin(60°).
  h := Sqrt(3) * w2;

  // wenn es aber zu hoch wird:
  th := (h*fY) - (fY-1)*(h/2);
  if th > aParent.OriginalHeight then
  begin
    // wieviele halbe haben die Hexagons insgesamt?
    _halbe := fY*2;
    // wieviele halbe überlappen:
    _overlaps := fY-1;
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
      if aDebug = 1 then
        fHexFields[x, y].fTxt.Text := x.ToString + ',' + y.ToString;
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

  // Text for red and blue player:
  fTxtRed := CreateText(claRed, TAlignLayout.Left);
  fTxtRed.Parent := aRectBottom;
  fTxtBlue := CreateText(claBlue, TAlignLayout.Right);
  fTxtBlue.Parent := aRectBottom;

  // HexField to visualize next random points
  fNextField := THexField.Create(aRectBottom);
  fNextField.RandomPoints;
  fNextField.Height := aRectBottom.Height - 10;
  fNextField.Width  := fNextField.Height / Sqrt(3) * 2;
  fNextField.HitTest := False;
  fNextField.Align := TAlignLayout.Center;
  fNextField.Parent := aRectBottom;
  fNextField.HexFieldStatus := THexFieldStatus.red;

  fCurrent := TPLayer.Human;
end;

destructor TProximity.Destroy;
begin
  fTimer.Free;
  inherited;
end;

function TProximity.CreateText(aColor: TAlphaColor; aAlign: TAlignLayout): TText;
begin
  // Text for red player:
  Result := TText.Create(Self);
  Result.Align := aAlign;
  Result.Width := 240;
  Result.HitTest := False;
  Result.TextSettings.Font.Size := Result.TextSettings.Font.Size + 14;
  Result.TextSettings.Font.Style := Result.TextSettings.Font.Style + [TFontStyle.fsBold];
  Result.TextSettings.FontColor := aColor;
  Result.TextSettings.WordWrap := False;
  Result.Text := '';
end;


procedure TProximity.HexFieldClick(Sender: TObject);
begin
  if fCurrent = TPLayer.Computer then
    Exit;

  DoHexFieldClick(THexField(Sender));
end;

procedure TProximity.DoHexFieldClick(aHexField: THexField);
var
  clicked, hf: THexField;
  _neighbours: TList<THexField>;
  pred, pblue: Integer;
begin
  clicked := aHexField;

  case clicked.HexFieldStatus of
    empty:
    begin
      if Assigned(fOnClickEvt) then
        fOnClickEvt(fCurrent);

      case fCurrent of
        Human   : begin
                    clicked.HexFieldStatus := THexFieldStatus.red;
                    fCurrent := TPLayer.Computer;
                    fNextField.HexFieldStatus := THexFieldStatus.blue;
                  end;
        Computer: begin
                    clicked.HexFieldStatus := THexFieldStatus.blue;
                    fCurrent := TPLayer.Human;
                    fNextField.HexFieldStatus := THexFieldStatus.red;
                  end;
      end;

      clicked.Points := fNextField.Points;
      fNextField.RandomPoints;

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

      // calc total points for red and blue:
      pred := GetPoints(THexFieldStatus.red);
      pblue := GetPoints(THexFieldStatus.blue);
      fTxtRed.Text := pred.ToString;
      fTxtBlue.Text := pblue.ToString;

      // check empty fields / winner:
      if GetEmpty = 0 then
      begin
        if pred > pblue then
        begin
          fTxtRed.Text := fTxtRed.Text + ' WINNER!';
        end else
        if pred < pblue then
        begin
          fTxtBlue.Text := fTxtBlue.Text + ' WINNER!';
        end else
        begin
          fTxtRed.Text := fTxtBlue.Text + ' DRAW';
          fTxtBlue.Text := fTxtBlue.Text + ' DRAW';
        end;

        if Assigned(fOnGameOverEvt) then
          fOnGameOverEvt();

      end else
      begin
        if fCurrent = TPLayer.Computer then
        begin
          fTimer.Enabled := True;
        end;
      end;
    end;

    red  : ; // kann man nicht mehr klicken
    blue : ; // kann man nicht mehr klicken
  end;
end;


procedure TProximity.fTimerTimer(Sender: TObject);
begin
  fTimer.Enabled := False;
  ComputerMove;
end;

procedure TProximity.ComputerMove;
var
  _HexFields: THexFields;
  hf, nb, clicked: THexField;
  x, y, yield, maxP, clickX, clickY: Integer;
  _neighbours: TList<THexField>;
  _points: array of array of Integer;
  done: Boolean;
begin
//  fCurrent := TPLayer.Human;
//  Exit;

  // copy array for the following tests:
  _HexFields := CopyFieldsArray(fHexFields);

  // Punkte array Init:
  SetLength(_points, fX, fY);
  for x := Low(_points) to High(_points) do
    for y := Low(_points[x]) to High(_points[x]) do
      _points[x, y] := 0;

  // Tactic: the field that yields the most points will be clicked by the computer:
  for x := Low(_HexFields) to High(_HexFields) do
  begin
    for y := Low(_HexFields[x]) to High(_HexFields[x]) do
    begin
      hf := _HexFields[x, y];
      if hf.HexFieldStatus = THexFieldStatus.empty then
      begin
        clicked := hf;

        // Nachbarn ermitteln:
        _neighbours := GetNeighbours(clicked);
        // alle roten Nachbarn die weniger Punkte haben:
        yield := 0;
        for nb in _neighbours do
        begin
          if nb.HexFieldStatus = THexFieldStatus.red then
          begin
            if nb.Points < fNextField.Points then
            begin
              Inc(yield, nb.Points);
            end;
          end else
          if nb.HexFieldStatus = THexFieldStatus.blue then
          begin
            Inc(yield, 1);
          end;
        end;
        _neighbours.Free;

        _points[x, y] := yield;
      end;
    end;
  end;

  // das Feld dass die meißten Punkte bringt Klicken:
  maxP := 0;
  clickX := 0;
  clickY := 0;
  for x := Low(_points) to High(_points) do
  begin
    for y := Low(_points[x]) to High(_points[x]) do
    begin
      if _points[x, y] > maxP then
      begin
        maxP := _points[x, y];
        clickX := x;
        clickY := y;
      end;
    end;
  end;

  // kein Feld gefunden:
  if maxP = 0 then
  begin
    // irgend ein leeres finden:
    done := False;
    for x := Low(_HexFields) to High(_HexFields) do
    begin
      for y := Low(_HexFields[x]) to High(_HexFields[x]) do
      begin
        hf := _HexFields[x, y];
        if hf.HexFieldStatus = THexFieldStatus.empty then
        begin
          clickX := x;
          clickY := y;
          done := True;
        end;
        if done then Break;
      end;
      if done then Break;
    end;
  end;


  // Spielzug ausführen:
  DoHexFieldClick(fHexFields[clickX, clickY]);
end;

function TProximity.GetPoints(aHexFieldStatus: THexFieldStatus): Integer;
var
  x, y: Integer;
begin // Result = total points for aHexFieldStatus:
  Result := 0;
  for x := Low(fHexFields) to High(fHexFields) do
    for y := Low(fHexFields[x]) to High(fHexFields[x]) do
      if fHexFields[x, y].HexFieldStatus = aHexFieldStatus then
        Inc(Result, fHexFields[x, y].Points);
end;

function TProximity.GetEmpty: Integer;
var
  x, y: Integer;
begin // Result = total empty fields
  Result := 0;
  for x := Low(fHexFields) to High(fHexFields) do
    for y := Low(fHexFields[x]) to High(fHexFields[x]) do
      if fHexFields[x, y].HexFieldStatus = THexFieldStatus.empty then
        Inc(Result);
end;

function TProximity.GetNeighbours(aHexField: THexField): THexFieldList;

  function IsInsideField(aX, aY: Integer): Boolean;
  begin
    Result :=
      (aX >= 0)  and
      (aX < fX) and
      (aY >= 0)  and
      (aY < fY);
  end;

  procedure AddIfInside(aX, aY: Integer);
  begin
    if IsInsideField(aX, aY) then
      Result.Add( fHexFields[aX, aY] );
  end;

begin
  Result := THexFieldList.Create;

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
  inherited Create(AOwner);
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

procedure THexField.DoMouseEnter;
begin
  inherited;
  if fHexFieldStatus = THexFieldStatus.empty then
  begin
    Stroke.Color := claYellow;
    StrokeThickness := 3;
  end;
end;

procedure THexField.DoMouseLeave;
begin
  inherited;
  Stroke.Color := claBlack;
  StrokeThickness := 2;
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

                Opacity := 0.7;
                AnimateFloat('opacity', 1, 0.2);
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

                Opacity := 0.7;
                AnimateFloat('opacity', 1, 0.2);
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
