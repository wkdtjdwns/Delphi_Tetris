unit MainForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Blocks, ExtCtrls, MMSystem;

type
  { 타이머 대기 상태 정의 }
  TTimerWaitStatus = (
    TimerWaitStatus_BrokeBlocks,    // 블록 파괴 상태
    TimerWaitStatus_ArrangeBlocs,   // 블록 정렬 상태 (이 상태는 원래 코드에선 안 쓰임)
    TimerWaitStatus_MakeNewBlock    // 새 블록 생성 상태
  );

  TMain = class(TForm)
    TimerMain: TTimer;      // 메인 게임 루프 타이머
    Background: TPanel;     // 게임 배경 패널
    TimerWait: TTimer;      // 대기 처리용 타이머

    // 이벤트 핸들러
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
  Main: TMain;                              // 메인 폼 인스턴스
  Tetris: TTetris;                          // 테트리스 게임 객체
  TimerWaitStatus: TTimerWaitStatus;       // 타이머 대기 상태
  soundCnt: integer;                        // 사운드 재생 횟수

implementation

{$R *.dfm}

{ BGM 반복 재생 }
procedure TMain.PlayBGMRepeat(const FileName: string);
begin
  mciSendString('close bgm', nil, 0, 0);
  mciSendString(PChar('open "' + FileName + '" alias bgm'), nil, 0, 0);
  mciSendString('play bgm repeat', nil, 0, 0);
end;

{ BGM 중지 }
procedure TMain.StopBGM;
begin
  mciSendString('stop bgm', nil, 0, 0);
  mciSendString('close bgm', nil, 0, 0);
end;

{ 효과음 재생 }
procedure TMain.PlaySoundEffect(const path: string);
begin
  sndPlaySound(PChar(path), SND_ASYNC or SND_NODEFAULT);
end;

{ 폼 생성 }
procedure TMain.FormCreate(Sender: TObject);
begin
  { 테트리스 객체 생성 }
  Tetris := TTetris.Create(Screen.Width);

  { 폼 크기 설정 }
  Main.ClientWidth := TETRIS_GROUND_X_NUM * Tetris.BlockWidth;
  Main.ClientHeight := TETRIS_GROUND_Y_NUM * Tetris.BlockHeight;

  { 폼 위치 설정 (정중앙) }
  Main.Left := (Screen.Width - Main.Width) div 2;
  Main.Top := (Screen.Height - Main.Height) div 2;

  { 백드라운드 설정 }
  Background.Top := 0;
  Background.Left := 0;
  Background.Width := Main.ClientWidth - 1;
  Background.Height := Main.ClientHeight - 1;

  { 타이머 초기화 }
  TimerWait.Enabled := false;
  TimerMain.Interval := 1;
  TimerMain.Enabled := true;

  { BGM 무한 반복 재생 시작 }
  PlayBGMRepeat(ExtractFilePath(Application.ExeName) + 'Sound\BGM.mp3');
end;

{ 게임 화면 그리기 }
procedure TMain.FormPaint(Sender: TObject);
var
  Canvas: TCanvas;
begin
  Canvas := TCanvas.Create;
  try
    { 캔버스 설정 }
    Canvas.Handle := GetDC(Background.Handle);

    { 테트리스 화면 그리기 }
    Tetris.Draw(Canvas);
  finally
    Canvas.Free;
  end;
end;

{ 폼 소멸 }
procedure TMain.FormDestroy(Sender: TObject);
begin
  { BGM 종료 }
  StopBGM;

  { 메모리 해제 }
  Tetris.Free;
end;

{ 메인 타이머 이벤트 }
procedure TMain.TimerMainTimer(Sender: TObject);
var
  ProcResult: TTetrisProcResult;
begin
  { 게임 진행 중 }
  if (Tetris.Playing) then
  begin
    { 블록을 아래로 이동 }
    ProcResult := Tetris.Process(MatrixBottom);

    { 화면 다시 그리기 }
    Invalidate;

    { 처리 결과에 따른 후속 작업 }
    ProcessTetrisProcResult(ProcResult);

    { 레벨에 따른 속도 조정 }
    TimerMain.Interval := BlockSpeed[Tetris.Level];
  end
  else
  begin
    { 게임 정지 상태에서도 화면은 갱신 }
    Invalidate;
  end;
end;

{ 키보드 입력 처리 }
procedure TMain.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  ProcResult: TTetrisProcResult;
begin
  { 게임 정지 상태 }
  if (Tetris.Playing = false) then
  begin
    { 'Y'키: 새 게임 시작 }
    if (Ord('Y') = Key) then
    begin
      Tetris.New;
      Tetris.Playing := true;
      TimerMain.Enabled := true;
      TimerMain.Interval := 10;
    end

    { 'N'키: 게임 종료 }
    else if (Ord('N') = Key) then
      Main.Close;
  end

  { 게임 진행 중 }
  else
  begin
    if (TimerMain.Enabled) then
    begin
      { 블록 이동 처리 + 화면 갱신 }
      ProcResult := Tetris.Move(Key);
      ProcessTetrisProcResult(ProcResult);
      Invalidate;
    end;
  end;
end;

{ 처리 결과에 따른 후속 처리 }
procedure TMain.ProcessTetrisProcResult(ProcResult: TTetrisProcResult);
begin
  case ProcResult of
    { 에러 X -> 작업 X }
    TProcResult_No_Error:
      ;

    { 블록이 바닥에 닿음 }
    TProcResult_Lied_Block:
    begin
      TimerMain.Enabled := false;                       // 메인 타이머 정지
      TimerWait.Enabled := true;                        // 대기 타이머 시작
      TimerWait.Interval := 10;                         // 대기 타이머 간격 10ms
      TimerWaitStatus := TimerWaitStatus_BrokeBlocks;   // 블록 파괴 상태로 설정
    end;

    { 게임 종료 }
    TProcResult_End_Game:
    begin
      TimerWait.Enabled := false;   // 대기 타이머 정지
      TimerMain.Enabled := false;   // 메인 타이머 정지
    end;
  end;
end;

{ 대기 타이머 이벤트 }
procedure TMain.TimerWaitTimer(Sender: TObject);
begin
  case TimerWaitStatus of
    TimerWaitStatus_BrokeBlocks:
    begin
      { 완성된 줄만큼 블록 파괴 }
      Tetris.BrokeBlocks();

      { 파괴된 블록 수만큼 사운드 출력 준비 }
      soundCnt := Tetris.BrokenBlockCnt;
      if soundCnt <> 0 then
      begin
        { 효과음 재생 }
        PlaySoundEffect(ExtractFilePath(Application.ExeName) + 'Sound\LineClear.mp3');
        Dec(soundCnt);
      end;

      { 블록들 아래로 정렬 }
      Tetris.ArrangeBlocks();

      { 새 블록 생성 단계로 변경 }
      TimerWaitStatus := TimerWaitStatus_MakeNewBlock;

      { 화면 갱신 + 대기 }
      Invalidate;
      TimerWait.Interval := 50;
    end;

    { 새 블록 생성 }
    TimerWaitStatus_MakeNewBlock:
    begin
      { 새로운 블록 생성 시도 }
      if (Tetris.MakeNewBlock()) then
      begin
        { 생성 성공 -> 게임 재개 }
        Invalidate;

        { 블록 속도 설정 }
        TimerMain.Interval := BlockSpeed[Tetris.Level];

        { 타이머 설정 }
        TimerWait.Enabled := false;
        TimerMain.Enabled := true;
      end
      else
      begin
        { 생성 실패 -> 게임 오버 }
        Invalidate;

        { 타이머 설정 }
        TimerWait.Enabled := false;
        TimerMain.Enabled := false;
      end;
    end;
  end;
end;

end.

