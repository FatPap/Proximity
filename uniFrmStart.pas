unit uniFrmStart;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  uniProximity, FMX.Objects, FMX.Layouts, FMX.Edit;

type
  TfrmStart = class(TForm)
    panTop: TPanel;
    btnNewGame: TButton;
    designerLayout: TPanel;
    Path1: TPath;
    Path2: TPath;
    Path3: TPath;
    Path4: TPath;
    Path5: TPath;
    slGame: TScaledLayout;
    panClient: TPanel;
    NumberBox1: TNumberBox;
    NumberBoxDebug: TNumberBox;
    procedure btnNewGameClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure NumberBox1ChangeTracking(Sender: TObject);
    procedure NumberBoxDebugChangeTracking(Sender: TObject);
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
  Path1.Visible := False;
  Path2.Visible := False;
  Path3.Visible := False;
  Path4.Visible := False;
  Path5.Visible := False;

  btnNewGameClick(nil);
end;

procedure TfrmStart.FormDestroy(Sender: TObject);
begin
  //
end;

procedure TfrmStart.NumberBox1ChangeTracking(Sender: TObject);
begin
  btnNewGameClick(nil);
end;

procedure TfrmStart.NumberBoxDebugChangeTracking(Sender: TObject);
begin
  btnNewGameClick(nil);
end;

procedure TfrmStart.btnNewGameClick(Sender: TObject);
begin
  if Assigned(fProximity) then
    FreeAndNil(fProximity);

  fProximity := TProximity.Create(frmStart, slGame, Trunc(NumberBox1.Value), 4, Trunc(NumberBoxDebug.Value));
end;


end.
