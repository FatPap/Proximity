program Proximity;



{$R *.dres}

uses
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  FMX.Forms,
  uniFrmStart in 'uniFrmStart.pas' {frmStart},
  uniProximity in 'uniProximity.pas',
  bass in 'bass.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.CreateForm(TfrmStart, frmStart);
  Application.Run;
end.
