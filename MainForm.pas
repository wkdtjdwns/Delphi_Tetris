unit MainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Blocks, ExtCtrls, MMSystem;

type
  { Ÿ�̸� ��� ���� ���� }
  TTimerWaitStatus = (
    TimerWaitStatus_BrokeBlocks,    // ��� �ı� ����
    TimerWaitStatus_ArrangeBlocs,   // ��� ���� ���� (�� ���´� ���� �ڵ忡�� �� ����)
    TimerWaitStatus_MakeNewBlock    // �� ��� ���� ����
  );

  TMain = class(TForm)
    TimerMain: TTimer;      // ���� ���� ���� Ÿ�̸�
    Background: TPanel;     // ���� ��� �г�
    TimerWait: TTimer;      // ��� ó���� Ÿ�̸�

    // �̺�Ʈ �ڵ鷯
    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TimerMainTimer(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure TimerWaitTimer(Sender: TObject);

  private
    procedure PlaySoundEffect(const path: string);
    procedure PlayBGMRepeat(const FileName: string);
    procedure StopBGM;
  public
    procedure ProcessTetrisProcResult(ProcResult: TTetrisProcResult);
  end;

var
  Main: TMain;                              // ���� �� �ν��Ͻ�
  Tetris: TTetris;                          // ��Ʈ���� ���� ��ü
  TimerWaitStatus: TTimerWaitStatus;       // Ÿ�̸� ��� ����
  soundCnt: integer;                        // ���� ��� Ƚ��

implementation

{$R *.dfm}

{ BGM �ݺ� ��� }
procedure TMain.PlayBGMRepeat(const FileName: string);
begin
  mciSendString('close bgm', nil, 0, 0);
  mciSendString(PChar('open "' + FileName + '" alias bgm'), nil, 0, 0);
  mciSendString('play bgm repeat', nil, 0, 0);
end;

{ BGM ���� }
procedure TMain.StopBGM;
begin
  mciSendString('stop bgm', nil, 0, 0);
  mciSendString('close bgm', nil, 0, 0);
end;

{ ȿ���� ��� }
procedure TMain.PlaySoundEffect(const path: string);
begin
  sndPlaySound(PChar(path), SND_ASYNC or SND_NODEFAULT);
end;

{ �� ���� }
procedure TMain.FormCreate(Sender: TObject);
begin
  { ��Ʈ���� ��ü ���� }
  Tetris := TTetris.Create(Screen.Width);

  { �� ũ�� ���� }
  Main.ClientWidth := TETRIS_GROUND_X_NUM * Tetris.BlockWidth;
  Main.ClientHeight := TETRIS_GROUND_Y_NUM * Tetris.BlockHeight;

  { �� ��ġ ���� (���߾�) }
  Main.Left := (Screen.Width - Main.Width) div 2;
  Main.Top := (Screen.Height - Main.Height) div 2;

  { ������ ���� }
  Background.Top := 0;
  Background.Left := 0;
  Background.Width := Main.ClientWidth - 1;
  Background.Height := Main.ClientHeight - 1;

  { Ÿ�̸� �ʱ�ȭ }
  TimerWait.Enabled := false;
  TimerMain.Interval := 1;
  TimerMain.Enabled := true;

  { BGM ���� �ݺ� ��� ���� }
  PlayBGMRepeat(ExtractFilePath(Application.ExeName) + 'Sound\BGM.mp3');
end;

{ ���� ȭ�� �׸��� }
procedure TMain.FormPaint(Sender: TObject);
var
  Canvas: TCanvas;
begin
  Canvas := TCanvas.Create;
  try
    { ĵ���� ���� }
    Canvas.Handle := GetDC(Background.Handle);

    { ��Ʈ���� ȭ�� �׸��� }
    Tetris.Draw(Canvas);
  finally
    Canvas.Free;
  end;
end;

{ �� �Ҹ� }
procedure TMain.FormDestroy(Sender: TObject);
begin
  { BGM ���� }
  StopBGM;

  { �޸� ���� }
  Tetris.Free;
end;

{ ���� Ÿ�̸� �̺�Ʈ }
procedure TMain.TimerMainTimer(Sender: TObject);
var
  ProcResult: TTetrisProcResult;
begin
  { ���� ���� �� }
  if (Tetris.Playing) then
  begin
    { ����� �Ʒ��� �̵� }
    ProcResult := Tetris.Process(MatrixBottom);

    { ȭ�� �ٽ� �׸��� }
    Invalidate;

    { ó�� ����� ���� �ļ� �۾� }
    ProcessTetrisProcResult(ProcResult);

    { ������ ���� �ӵ� ���� }
    TimerMain.Interval := BlockSpeed[Tetris.Level];
  end
  else
  begin
    { ���� ���� ���¿����� ȭ���� ���� }
    Invalidate;
  end;
end;

{ Ű���� �Է� ó�� }
procedure TMain.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  ProcResult: TTetrisProcResult;
begin
  { ���� ���� ���� }
  if (Tetris.Playing = false) then
  begin
    { 'Y'Ű: �� ���� ���� }
    if (Ord('Y') = Key) then
    begin
      Tetris.New;
      Tetris.Playing := true;
      TimerMain.Enabled := true;
      TimerMain.Interval := 10;
    end

    { 'N'Ű: ���� ���� }
    else if (Ord('N') = Key) then
      Main.Close;
  end

  { ���� ���� �� }
  else
  begin
    if (TimerMain.Enabled) then
    begin
      { ��� �̵� ó�� + ȭ�� ���� }
      ProcResult := Tetris.Move(Key);
      ProcessTetrisProcResult(ProcResult);
      Invalidate;
    end;
  end;
end;

{ ó�� ����� ���� �ļ� ó�� }
procedure TMain.ProcessTetrisProcResult(ProcResult: TTetrisProcResult);
begin
  case ProcResult of
    { ���� X -> �۾� X }
    TProcResult_No_Error:
      ;

    { ����� �ٴڿ� ���� }
    TProcResult_Lied_Block:
    begin
      TimerMain.Enabled := false;                       // ���� Ÿ�̸� ����
      TimerWait.Enabled := true;                        // ��� Ÿ�̸� ����
      TimerWait.Interval := 10;                         // ��� Ÿ�̸� ���� 10ms
      TimerWaitStatus := TimerWaitStatus_BrokeBlocks;   // ��� �ı� ���·� ����
    end;

    { ���� ���� }
    TProcResult_End_Game:
    begin
      TimerWait.Enabled := false;   // ��� Ÿ�̸� ����
      TimerMain.Enabled := false;   // ���� Ÿ�̸� ����
    end;
  end;
end;

{ ��� Ÿ�̸� �̺�Ʈ }
procedure TMain.TimerWaitTimer(Sender: TObject);
begin
  case TimerWaitStatus of
    TimerWaitStatus_BrokeBlocks:
    begin
      { �ϼ��� �ٸ�ŭ ��� �ı� }
      Tetris.BrokeBlocks();

      { �ı��� ��� ����ŭ ���� ��� �غ� }
      soundCnt := Tetris.BrokenBlockCnt;
      if soundCnt <> 0 then
      begin
        { ȿ���� ��� }
        PlaySoundEffect(ExtractFilePath(Application.ExeName) + 'Sound\LineClear.mp3');
        Dec(soundCnt);
      end;

      { ��ϵ� �Ʒ��� ���� }
      Tetris.ArrangeBlocks();

      { �� ��� ���� �ܰ�� ���� }
      TimerWaitStatus := TimerWaitStatus_MakeNewBlock;

      { ȭ�� ���� + ��� }
      Invalidate;
      TimerWait.Interval := 50;
    end;

    { �� ��� ���� }
    TimerWaitStatus_MakeNewBlock:
    begin
      { ���ο� ��� ���� �õ� }
      if (Tetris.MakeNewBlock()) then
      begin
        { ���� ���� -> ���� �簳 }
        Invalidate;

        { ��� �ӵ� ���� }
        TimerMain.Interval := BlockSpeed[Tetris.Level];

        { Ÿ�̸� ���� }
        TimerWait.Enabled := false;
        TimerMain.Enabled := true;
      end
      else
      begin
        { ���� ���� -> ���� ���� }
        Invalidate;

        { Ÿ�̸� ���� }
        TimerWait.Enabled := false;
        TimerMain.Enabled := false;
      end;
    end;
  end;
end;

end.

