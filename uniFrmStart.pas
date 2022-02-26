unit uniFrmStart;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  uniProximity, FMX.Objects, FMX.Layouts, FMX.Edit, FMX.Effects,
  Bass;

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
    chkbxDebug: TCheckBox;
    procedure btnNewGameClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure nmbxXYChangeTrackings(Sender: TObject);
  private
    fProximity: TProximity;
    // bass
    sams: array[0..128] of HSAMPLE;
    samc: Integer;
    procedure BassInit;
    procedure BassFree;
    procedure AddSample(aFilename: string);
    procedure ShowError(msg: string);
    procedure PlaySample(aPlayer: TPLayer);
    procedure PlayGameOver;
  public
  end;

var
  frmStart: TfrmStart;

implementation

{$R *.fmx}

uses
  Winapi.Windows,
  FMX.Platform.Win,
  uniToolsIST_XE6,
  System.Rtti, System.TypInfo;


procedure TfrmStart.FormCreate(Sender: TObject);
begin
  BassInit;
  fProximity := nil;
  designerLayout.Visible := False;
  slGame.OriginalWidth := slGame.Width;
  slGame.OriginalHeight := slGame.Height;
  btnNewGameClick(nil);
end;

procedure TfrmStart.FormDestroy(Sender: TObject);
begin
  BassFree;
end;

procedure TfrmStart.nmbxXYChangeTrackings(Sender: TObject);
begin
  btnNewGameClick(nil);
end;

procedure TfrmStart.btnNewGameClick(Sender: TObject);
begin
  if Assigned(fProximity) then
    FreeAndNil(fProximity);

  fProximity := TProximity.Create(frmStart, slGame, rectBottom, Trunc(nmbxX.Value), Trunc(nmbxY.Value), chkbxDebug.IsChecked.ToInteger);
  fProximity.OnClickEvt := PlaySample;
  fProximity.OnGameOver := PlayGameOver;
end;


procedure TfrmStart.ShowError(msg: string);
begin
  ShowMessage(msg);
end;


procedure TfrmStart.BassInit;
//var
//  Info: BASS_DEVICEINFO;
//  device: Cardinal;
//  devicefound: Boolean;
begin
  samc := 0;		// sample count
  // check the correct BASS was loaded
  if (HIWORD(BASS_GetVersion) <> BASSVERSION) then
  begin
    MessageBox(0,'An incorrect version of BASS.DLL was loaded',nil,MB_ICONERROR);
    Halt;
  end;

  // Initialize audio - default device, 44100hz, stereo, 16 bits

  // if not BASS_Init(-1, 44100, 0, FmxHandleToHWND(self.Handle), nil) then
  if not BASS_Init(-1, 44100, 0, WindowHandleToPlatform(self.Handle).Wnd, nil) then
    ShowMessage('Error initializing audio!');

//  device := BASS_GetDevice;
//  devicefound := BASS_GetDeviceInfo(device, Info);

  //
  AddSample(ExePath + 'Sounds\BigBombMouseEnter1.wav');
  AddSample(ExePath + 'Sounds\BigBombMouseEnter2.wav');

//  btnMusicPlay1Click(Self);
end;

procedure TfrmStart.BassFree;
var
  a: Integer;
begin
  //BASS (It's not actually necessary to free the streams, musics and samples because they are automatically freed by BASS_Free.)
  // Free samples
  if samc > 0 then
    for a := 0 to samc - 1 do
      BASS_SampleFree(sams[a]);
  BASS_Free();  // Close bass
end;

procedure TfrmStart.AddSample(aFilename: string);
var
  f: PChar;
begin
	if not FileExists(aFilename) then
  begin
    ShowMessage('File not found: ' + aFilename);
    Exit;
  end;

	f := PChar(aFilename);
	sams[samc] := BASS_SampleLoad(FALSE, f, 0, 0, 3, BASS_SAMPLE_OVER_POS {$IFDEF UNICODE} or BASS_UNICODE {$ENDIF});
	if sams[samc] <> 0 then
	begin
		//ListBox2.Items.Add(OpenDialog3.FileName);
		Inc(samc);
	end else
  begin
		ShowError('Error loading sample!');
  end;
end;


procedure TfrmStart.PlaySample(aPlayer: TPLayer);
var
	i: Integer;
  ch: HCHANNEL;
begin
	i := 0; // ListBox2.ItemIndex;

  // Play the sample at default rate, volume=50%, random pan position
	if i >= 0 then
  begin
    ch := BASS_SampleGetChannel(sams[i], 0);
    case aPlayer of
      // BASS_ATTRIB_PAN | 1 (full left) to +1 (full right), 0 = centre.
      Human   : begin
                  BASS_ChannelSetAttribute(ch, BASS_ATTRIB_PAN, -0.2);
                  BASS_ChannelSetAttribute(ch, BASS_ATTRIB_FREQ, Random(2000)+7000);
                end;
      Computer: begin
                  BASS_ChannelSetAttribute(ch, BASS_ATTRIB_PAN, +0.2);
                  BASS_ChannelSetAttribute(ch, BASS_ATTRIB_FREQ, Random(2000)+9000);
                end;
    end;
    BASS_ChannelSetAttribute(ch, BASS_ATTRIB_VOL, 0.3);

		if not BASS_ChannelPlay(ch, False) then
			ShowError('Error playing sample!');
  end;
end;

procedure TfrmStart.PlayGameOver();
var
	i: Integer;
  ch: HCHANNEL;
begin
	i := 1; // ListBox2.ItemIndex;

  // Play the sample at default rate, volume=50%, random pan position
	if i >= 0 then
  begin
    ch := BASS_SampleGetChannel(sams[i], 0);
    BASS_ChannelSetAttribute(ch, BASS_ATTRIB_PAN, 0);
    BASS_ChannelSetAttribute(ch, BASS_ATTRIB_VOL, 0.5);

		if not BASS_ChannelPlay(ch, False) then
			ShowError('Error playing sample!');
  end;
end;

end.
