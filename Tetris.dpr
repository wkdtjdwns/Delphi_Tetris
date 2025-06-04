program Tetris;

uses
  Forms,
  MainForm in 'MainForm.pas' {Main},
  Blocks in 'Blocks.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Tetris';
  Application.CreateForm(TMain, Main);
  Application.Run;
end.
