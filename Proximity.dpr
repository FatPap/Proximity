program Proximity;

uses
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  FMX.Forms,
  uniFrmStart in 'uniFrmStart.pas' {frmStart},
  uniProximity in 'uniProximity.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.CreateForm(TfrmStart, frmStart);
  Application.Run;
end.
