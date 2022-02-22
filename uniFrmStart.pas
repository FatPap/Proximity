unit uniFrmStart;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  uniProximity, FMX.Objects, FMX.Layouts, FMX.Edit, FMX.Effects;

type
  TfrmStart = class(TForm)
    rectTop: TRectangle;
    btnNewGame: TButton;
    designerLayout: TPanel;
    Path1: TPath;
    Path2: TPath;
    Path3: TPath;
    Path4: TPath;
    Path5: TPath;
    slGame: TScaledLayout;
    nmbxX: TNumberBox;
    nmbxY: TNumberBox;
    rectGame: TRectangle;
    rectBottom: TRectangle;
    Text1: TText;
    ShadowEffect1: TShadowEffect;
    procedure btnNewGameClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure nmbxXYChangeTrackings(Sender: TObject);
  private
    fProximity: TProximity;
  public
  end;

var
  frmStart: TfrmStart;

implementation

{$R *.fmx}

procedure TfrmStart.FormCreate(Sender: TObject);
begin
  fProximity := nil;
  designerLayout.Visible := False;
  slGame.OriginalWidth := slGame.Width;
  slGame.OriginalHeight := slGame.Height;
  btnNewGameClick(nil);
end;

procedure TfrmStart.FormDestroy(Sender: TObject);
begin
  //
end;

procedure TfrmStart.nmbxXYChangeTrackings(Sender: TObject);
begin
  btnNewGameClick(nil);
end;

procedure TfrmStart.btnNewGameClick(Sender: TObject);
begin
  if Assigned(fProximity) then
    FreeAndNil(fProximity);

  fProximity := TProximity.Create(frmStart, slGame, rectBottom, Trunc(nmbxX.Value), Trunc(nmbxY.Value), 0);
end;


end.
