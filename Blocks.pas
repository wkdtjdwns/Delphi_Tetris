unit Blocks;

interface

uses Windows, SysUtils, Graphics, Types, Math, Dialogs, MMSystem;

{ 폼 크기 및 블록 설정 (상수) }
const
  { 필드 사이즈 }
  TETRIS_GROUND_X_NUM = 10; // 가로 칸 수
  TETRIS_GROUND_Y_NUM = 20; // 세로 칸 수

  { 대형 화면 (30px) }
  TETRIS_GROUND_BLOCK_WIDTH_N  = 30;   // 블록 너비
  TETRIS_GROUND_BLOCK_HEIGHT_N = 30;   // 블록 높이

  { 소형 화면 (20px) }
  TETRIS_GROUND_BLOCK_WIDTH_S  = 20;   // 블록 너비
  TETRIS_GROUND_BLOCK_HEIGHT_S = 20;   // 블록 높이

  { 배경 설정 }
  TETRIS_GROUND_COLOR : TColor = clBlack; // 배경 색상

  { 블록 설정 }
  TETRIX_ONEBLOCK_WIDTH  = 4;  // 블록 하나의 폭 (4 x 4)
  TETRIX_ONEBLOCK_HEIGHT = 4;  // 블록 하나의 높이

  { 블록 배열 인덱스 }
  TETRIS_LEFTOFBLOCK   = 0;
  TETRIS_RIGHTOFBLOCK  = (TETRIX_ONEBLOCK_WIDTH - 1);
  TETRIS_BOTTOMOFBLOCK = (TETRIX_ONEBLOCK_HEIGHT - 1);

  { 빈 블록 및 채워진 블록 }
  TETRIS_VOIDBLOCK = $00;
  TETRIS_FULLBLOCK = $02;

  { 레벨 관련 상수 }
  TETRIS_LEVEL_INC_COUNT = 40;
  TETRIS_LEVEL_MIN       = 1;
  TETRIS_LEVEL_MAX       = 10;

  { 블록 시작 위치 }
  TETRIS_START_POS_Y = 2;

type
  { 열거형 변수 }

  // 블록 이동 결과
  TTetrisProcResult = (TProcResult_No_Error, TProcResult_Lied_Block, TProcResult_End_Game);

  // 블록 종류
  TMatrixEnum = (MatrixEnum_I, MatrixEnum_L, MatrixEnum_IL, MatrixEnum_R, MatrixEnum_O, MatrixEnum_Z, MatrixEnum_IZ);

  // 블록 회전 각도
  TMatrixAngle = (MatrixAngle1, MatrixAngle2, MatrixAngle3, MatrixAngle4);

  // 블록 방향 및 동작
  TMatrixSide = (MatrixLeft, MatrixRight, MatrixBottom{, MatrixTop}, MatrixRotate, MatrixDropDown);

  { 움직이는 블록 정보 }
  TMatrixBlock = record
    FType: TMatrixEnum;
    FAngle: TMatrixAngle;
    FPoistion: TPoint;
  end;

  { 이미 쌓인 블록 정보 }
  TLiedBlock = record
    Color: TColor;
    Value: integer;
  end;

  TTetris = class
  private
    FScreenRect: TRect;
    FLiedBlocks: array[0..(TETRIS_GROUND_Y_NUM-1), 0..(TETRIS_GROUND_X_NUM-1)] of TLiedBlock;
    FMatrixBlock: TMatrixBlock;
    FSemaphore: THandle;
    FLevel: integer;
    FDropBlockCnt: integer;
    FScore: integer;
    FPlaying: Boolean;
    FBlockWidth: integer;
    FBlockHeight: integer;
    FBrokenBlockCnt: integer;

    { 내부 함수 - 게임 로직 검사 및 처리 }
    function CheckLevel(AMatrixBlock: TMatrixBlock; MatrixSide : TMatrixSide) : integer;
    function CheckOntheSide(AMatrixSide: TMatrixSide): Boolean;
    function CheckAngle(AMatrixBlock: TMatrixBlock; AMatrixAngle : TMatrixAngle): Boolean;
    function CheckMixed(AMatrixBlock: TMatrixBlock; AMatrixSide : TMatrixSide; ROption : Boolean): Boolean;
    procedure MixBlocks(AMatrixBlock: TMatrixBlock);
    procedure DrawLiedBlock(ACanvas: TCanvas);
    procedure DrawMoveBlock(ACanvas: TCanvas);
    procedure DrawInfo(ACanvas: TCanvas);
    procedure DrawAskNewGame(ACanvas: TCanvas);
    function CalTopBlockPosition(): integer;
  protected
  public
    constructor Create(MonitorWidth: integer);
    destructor Destroy(); override;

    function Process(AMatrixSide: TMatrixSide): TTetrisProcResult;
    function Move(Key: Word): TTetrisProcResult;
    procedure Draw(Canvas: TCanvas);
    procedure New();
    function MakeNewBlock(): Boolean;
    procedure BrokeBlocks();
    procedure ArrangeBlocks();
  published
    property MatrixBlock: TMatrixBlock read FMatrixBlock write FMatrixBlock;
    property Level: integer read FLevel write FLevel;
    property ScreenRect: TRect read FScreenRect;
    property DropBlockCnt: integer read FDropBlockCnt;
    property Score: integer read FScore;
    property Playing: Boolean read FPlaying write FPlaying;
    property BlockWidth: integer read FBlockWidth write FBlockWidth;
    property BlockHeight: integer read FBlockHeight write FBlockHeight;
    property BrokenBlockCnt: integer read FBrokenBlockCnt write FBrokenBlockCnt;
  end;

const
  { 점수 계산용 가중치 배열 }
  TETRIS_GRADE_WEIGHT: array[1..TETRIX_ONEBLOCK_WIDTH] of double = (1, 1.5, 2, 3);
  TETRIS_LEVEL_WEIGHT: array[TETRIS_LEVEL_MIN..TETRIS_LEVEL_MAX] of double =
    (1, 1.2, 1.4, 1.6, 1.8, 2.1, 2.4, 2.8, 3.2, 3.5);

  { 각 블록들 정의 }
  BlockSpeed: array[TETRIS_LEVEL_MIN..TETRIS_LEVEL_MAX] of integer =
    (1500, 1000, 800, 700, 600, 500, 400, 300, 200, 100); // 레벨별 블록 속도

  BlockColor: array[0..Ord(MatrixEnum_IZ)] of TColor =
    ($FF0000, $00FF00, $0000FF, $FFFF00, $FF00FF, $00FFFF, $808080); // 블록별 색상

  TetrisMatrix : array[0..Ord(MatrixEnum_IZ), 0..3] of integer =
  (
    // 블록1. 'I'
    //    XXXX 1111     XXXX 1000     XXXX 1111     XXXX 1000
    //    XXXX 0000     XXXX 1000     XXXX 0000     XXXX 1000
    //    XXXX 0000     XXXX 1000     XXXX 0000     XXXX 1000
    //    XXXX 0000     XXXX 1000     XXXX 0000     XXXX 1000
    ($F000, $8888, $F000, $8888),

    // 블록2. 'L'
    //      XXXX 1000     XXXX 0100     XXXX 1110     XXXX 1100
    //      XXXX 1110     XXXX 0100     XXXX 0010     XXXX 1000
    //      XXXX 0000     XXXX 1100     XXXX 0000     XXXX 1000
    //      XXXX 0000     XXXX 0000     XXXX 0000     XXXX 0000
    ($8E00, $44C0, $E200, $C880),

    // 블록3. '_|'
    //      XXXX 0010     XXXX 1100     XXXX 1110     XXXX 1000
    //      XXXX 1110     XXXX 0100     XXXX 1000     XXXX 1000
    //      XXXX 0000     XXXX 0100     XXXX 0000     XXXX 1100
    //      XXXX 0000     XXXX 0000     XXXX 0000     XXXX 0000
    ($2E00, $C440, $E800, $88C0),

    // 블록4. 'ㅁ'
    //      XXXX 1100     XXXX 1100     XXXX 1100     XXXX 1100
    //      XXXX 1100     XXXX 1100     XXXX 1100     XXXX 1100
    //      XXXX 0000     XXXX 0000     XXXX 0000     XXXX 0000
    //      XXXX 0000     XXXX 0000     XXXX 0000     XXXX 0000
    ($CC00, $CC00, $CC00, $CC00),

    // 블록5. 'ㅗ'
    //      XXXX 0100     XXXX 0100     XXXX 1110     XXXX 1000
    //      XXXX 1110     XXXX 1100     XXXX 0100     XXXX 1100
    //      XXXX 0000     XXXX 0100     XXXX 0000     XXXX 1000
    //      XXXX 0000     XXXX 0000     XXXX 0000     XXXX 0000
    ($4E00, $4C40, $E400, $8C80),

    // 블록6. '-|_'
    //      XXXX 1100     XXXX 0100     XXXX 1100     XXXX 0100
    //      XXXX 0110     XXXX 1100     XXXX 0110     XXXX 1100
    //      XXXX 0000     XXXX 1000     XXXX 0000     XXXX 1000
    //      XXXX 0000     XXXX 0000     XXXX 0000     XXXX 0000
    ($C600, $4C80, $C600, $4C80),

    // 블록7. '_|-'
    //      XXXX 0110     XXXX 1000     XXXX 0110     XXXX 1000
    //      XXXX 1100     XXXX 1100     XXXX 1100     XXXX 1100
    //      XXXX 0000     XXXX 0100     XXXX 0000     XXXX 0100
    //      XXXX 0000     XXXX 0000     XXXX 0000     XXXX 0000
    ($6C00, $8C40, $6C00, $8C40)
  );

implementation

{ 블록이 Side에 도달했는지 확인 }
function TTetris.CheckOntheSide(AMatrixSide: TMatrixSide): Boolean;
var
  i, j: Integer;
  Depth: Integer;
begin
  Result := False;

  { 블록의 가장자리 깊이 계산 }
  Depth := CheckLevel(Self.FMatrixBlock, AMatrixSide);

  case AMatrixSide of
    MatrixLeft:   // 왼쪽 끝
      if (FMatrixBlock.FPoistion.X <= 0) then
        Result := True;

    MatrixRight:  // 오른쪽 끝
      if (Depth + FMatrixBlock.FPoistion.X >= TETRIS_GROUND_X_NUM - 1) then
        Result := True;

    MatrixBottom: // 아래쪽 끝
      if (Depth + FMatrixBlock.FPoistion.Y >= TETRIS_GROUND_Y_NUM - 1) then
        Result := True;
  end;
end;

{ 블록 가장자리 깊이 계산 }
function TTetris.CheckLevel(AMatrixBlock: TMatrixBlock; MatrixSide: TMatrixSide): Integer;
var
  i, j, Mask: Integer;
  BlockInfo, temp, temp1: Integer;
begin
  BlockInfo := TetrisMatrix[Ord(AMatrixBlock.FType)][Ord(AMatrixBlock.FAngle)];

  { 회전 시 모양을 변환해야 하는 블록만 처리 }
  if (MatrixRight = MatrixSide) then
  begin
    temp := BlockInfo;
    Mask := $1111;
    BlockInfo := 0;

    for i := 0 to 3 do
    begin
      temp1 := temp and Mask;
      temp1 := temp1 shr i;

      for j := 0 to 3 do
      begin
        if (((temp1 shr (j * 4)) and $01) = 1) then
          BlockInfo := BlockInfo + ((1 shl (3 - j)) shl (i * 4));
      end;

      Mask := Mask shl 1;
    end;
  end;

  { 블록 가장 아랫부분까지 깊이 측정 }
  for i := 0 to 3 do
  begin
    if not ((BlockInfo and $0F) = $00) then
      Break;
    BlockInfo := BlockInfo shr 4;
  end;

  { 깊이 반환 }
  Result := 3 - i;
end;

{ 프로젝트 실행 }
constructor TTetris.Create(MonitorWidth: Integer);
begin
  { 화면 크기에 따라 블럭 크기 조정 }
  if (1280 <= MonitorWidth) then
  begin
    { 대형 화면 }
    FBlockWidth := TETRIS_GROUND_BLOCK_WIDTH_N;
    FBlockHeight := TETRIS_GROUND_BLOCK_HEIGHT_N;
  end
  else
  begin
    { 소형 화면 }
    FBlockWidth := TETRIS_GROUND_BLOCK_WIDTH_S;
    FBlockHeight := TETRIS_GROUND_BLOCK_HEIGHT_S;
  end;

  { 세마포어 생성 }
  FSemaphore := CreateSemaphore(nil, 1, 1, '');

  { 게임 영역 설정 }
  FScreenRect.Left := 0;
  FScreenRect.Top := 0;
  FScreenRect.Right := TETRIS_GROUND_X_NUM * FBlockWidth - 1;
  FScreenRect.Bottom := TETRIS_GROUND_Y_NUM * FBlockHeight - 1;

  { 초기화 }
  New();
  FPlaying := False;
end;

{ 프로젝트 종료 }
destructor TTetris.Destroy;
begin
  CloseHandle(FSemaphore);  // 세마포어 해제
end;

{ 블록 그리기 }
procedure TTetris.Draw(Canvas: TCanvas);
var
  Bitmap: TBitmap;
begin
  { 이중 버퍼링 -> 화면 깜빡임 방지 }
  Bitmap := TBitmap.Create;

  try
    { 비트맵 크기 설정 }
    Bitmap.Width := FScreenRect.Right - FScreenRect.Left;
    Bitmap.Height := FScreenRect.Bottom - FScreenRect.Top;

    { 배경 색상 채우기 }
    Bitmap.Canvas.Brush.Color := TETRIS_GROUND_COLOR;
    Bitmap.Canvas.FillRect(FScreenRect);

    if (FPlaying) then
    begin
      { 블럭 및 정보 그리기 }
      DrawLiedBlock(Bitmap.Canvas); // 고정된 블록 (쌓인 블록)
      DrawMoveBlock(Bitmap.Canvas); // 이동 중인 블록
      DrawInfo(Bitmap.Canvas);      // 점수 정보
    end
    else
    begin
      { 게임 재시작 여부 묻기 }
      DrawAskNewGame(Bitmap.Canvas);
      DrawInfo(Bitmap.Canvas);
    end;

    { 출력 }
    Canvas.Draw(0, 0, Bitmap);

  finally
    Bitmap.Free;
  end;
end;

{ 블록 이동 처리 }
function TTetris.Move(Key: Word): TTetrisProcResult;
var
  TProcResult: TTetrisProcResult;
begin
  { 키보드 입력에 따라 처리 }
  case Key of
    VK_LEFT:   // 왼쪽 화살표
      Result := Process(MatrixLeft);

    VK_RIGHT:  // 오른쪽 화살표
      Result := Process(MatrixRight);

    VK_DOWN:   // 아래 화살표
      Result := Process(MatrixBottom);

    VK_UP:     // 위쪽 화살표
      Result := Process(MatrixRotate);

    VK_SPACE:  // 스페이스바
      Result := Process(MatrixDropDown);
  end;
end;

{ 새로운 블록 생성 }
function TTetris.MakeNewBlock(): Boolean;
var
  AMatrixBlock: TMatrixBlock;
begin
  Inc(FDropBlockCnt);

  { 일정수 블록이 떨어지면 레벨 증가 }
  if (DropBlockCnt mod TETRIS_LEVEL_INC_COUNT = 0) then
    Inc(FLevel);

  { 새로운 블록 생성 }
  AMatrixBlock.FType := TMatrixEnum(Random(Ord(MatrixEnum_IZ) + 1));
  AMatrixBlock.FAngle := MatrixAngle1;
  AMatrixBlock.FPoistion.X := (TETRIS_GROUND_X_NUM div 2) - 2;
  AMatrixBlock.FPoistion.Y := TETRIS_START_POS_Y;

  { 블록이 겹쳐서 생성됨 -> 게임 종료 }
  Result := true;
  if (TETRIS_START_POS_Y + CheckLevel(AMatrixBlock, MatrixBottom) >= CalTopBlockPosition()) then
  begin
    FPlaying := false;
    Result := false;
  end
  else
    FMatrixBlock := AMatrixBlock;
end;

{ 게임 초기화 }
procedure TTetris.New;
var
  i, j: integer;
begin
  { 게임 전체 초기화 }
  for i := 0 to TETRIS_GROUND_Y_NUM - 1 do
    for j := 0 to TETRIS_GROUND_X_NUM - 1 do
    begin
      FLiedBlocks[i][j].Value := TETRIS_VOIDBLOCK;
      FLiedBlocks[i][j].Color := TETRIS_GROUND_COLOR;
    end;

  FLevel := 1;
  FBrokenBlockCnt := 0;
  FDropBlockCnt := 0;
  FScore := 0;
  Randomize();
  MakeNewBlock();
end;

{ 블록 회전 및 이동 }
function TTetris.Process(AMatrixSide: TMatrixSide): TTetrisProcResult;
var
  i, height: integer;
  MatrixAngle: TMatrixAngle;
  bProblem: Boolean;
begin
  { 멀티스레드 충돌 방지 (세마포어 사용) }
  WaitForSingleObject(FSemaphore, INFINITE);

  bProblem := false;
  Result := TProcResult_No_Error;

  { 블록 회전 시도 }
  if (MatrixRotate = AMatrixSide) then
  begin
    { 블록 회전이 가능한지 검사 }
    MatrixAngle := FMatrixBlock.FAngle;
    bProblem := NOT CheckAngle(FMatrixBlock, MatrixAngle);
  end

  { 하드 드롭 }
  else if (MatrixDropDown = AMatrixSide) then
  begin
    AMatrixSide := MatrixBottom;
    bProblem := true;

    for i := MatrixBlock.FPoistion.Y to TETRIS_GROUND_Y_NUM - 1 do
    begin
      { 바닥에 닿거나 다른 블록과 충돌하는 지 검사 }
      if ((CheckOntheSide(AMatrixSide) = true) OR (CheckMixed(FMatrixBlock, AMatrixSide, false) = true)) then
      begin
        FMatrixBlock.FPoistion.Y := MatrixBlock.FPoistion.Y;
        break;
      end
      else
        Inc(FMatrixBlock.FPoistion.Y);
    end;
  end
  else
  begin
    { 좌우 또는 아래 방향 이동 }
    if ((CheckOntheSide(AMatrixSide) = true) OR (CheckMixed(FMatrixBlock, AMatrixSide, false) = true)) then
      bProblem := true;
  end;

  { 문제 발생 시 }
  if bProblem then
  begin
    if (MatrixBottom = AMatrixSide) then
    begin
      { 블록 위치 = 시작 위치 -> 게임 오버 }
      if (TETRIS_START_POS_Y + CheckLevel(FMatrixBlock, MatrixBottom) >= CalTopBlockPosition()) then
      begin
        FPlaying := false;
        Result := TProcResult_End_Game;
      end
      else
      begin
        { 아니면 블록 고정 -> 쌓인 블록화 }
        MixBlocks(FMatrixBlock);
        Result := TProcResult_Lied_Block;
      end;
    end;
  end
  else
  begin
    { 아무 문제가 없으면 위치 또는 각도 변경 }
    case AMatrixSide of
      MatrixLeft:   Dec(FMatrixBlock.FPoistion.X);
      MatrixRight:  Inc(FMatrixBlock.FPoistion.X);
      MatrixBottom: Inc(FMatrixBlock.FPoistion.Y);
      MatrixRotate:
        if (FMatrixBlock.FAngle = MatrixAngle4) then
          FMatrixBlock.FAngle := MatrixAngle1
        else
          Inc(FMatrixBlock.FAngle);
    end;
  end;

  ReleaseSemaphore(FSemaphore, 1, nil);
end;

{ 현재 블록 고정 -> 쌓인 블록화 }
procedure TTetris.MixBlocks(AMatrixBlock: TMatrixBlock);
var
  i, j: integer;
  val, val1, mask: integer;
begin
  { 현재 블록 정보 (4x4 -> 32비트 정수) }
  val := TetrisMatrix[Ord(AMatrixBlock.FType)][Ord(AMatrixBlock.FAngle)];

  { 4x4 블록 세로 줄 하나씩 처리 }
  for i := 0 to TETRIX_ONEBLOCK_HEIGHT - 1 do
  begin
    val1 := val shr (TETRIX_ONEBLOCK_WIDTH * ((TETRIX_ONEBLOCK_WIDTH - 1) - i));
    mask := $08;

    { 4x4 블록 가로 줄 하나씩 처리 }
    for j := 0 to TETRIX_ONEBLOCK_WIDTH - 1 do
    begin
      if ((val1 AND mask) <> 0) then
      begin
        FLiedBlocks[AMatrixBlock.FPoistion.Y + i][AMatrixBlock.FPoistion.X + j].Value := TETRIS_FULLBLOCK;
        FLiedBlocks[AMatrixBlock.FPoistion.Y + i][AMatrixBlock.FPoistion.X + j].Color := BlockColor[Ord(AMatrixBlock.FType)];
      end;
      mask := mask shr 1;
    end;
  end;
end;

{ 블록 회전 가능 여부 확인 }
function TTetris.CheckAngle(AMatrixBlock : TMatrixBlock; AMatrixAngle : TMatrixAngle): Boolean;
var
  Value : integer;
  Depth : integer;
  i, j : integer;
begin

  {
    현재 회전 상태가 마지막 각도 -> 처음 각도로 변경
    아니면 -> 다음 각도로 변경
  }
  if (AMatrixAngle = MatrixAngle4) then
    AMatrixAngle := MatrixAngle1
  else
    Inc(AMatrixAngle);

  { 회전 상태를 임시로 설정 }
  AMatrixBlock.FAngle := AMatrixAngle;

  Result := true;

  { 회전시킨 블록 모양 가져오기 }
  Value := TetrisMatrix[Ord(AMatrixBlock.FType)][Ord(AMatrixBlock.FAngle)];

  { 회전했을 때 벽을 넘는지 확인 (넘으면 회전 불가) }
  Depth := CheckLevel(AMatrixBlock, MatrixRight);
  if ((Depth + AMatrixBlock.FPoistion.X) > (TETRIS_GROUND_X_NUM - 1)) then
  begin
    Result := false;
    Exit;
  end;

  { 회전 후 아래로 내려갔을 때 바닥을 넘는지 확인 (넘으면 회전 불가) }
  Depth := CheckLevel(AMatrixBlock, MatrixBottom);
  if ((Depth + AMatrixBlock.FPoistion.Y) > (TETRIS_GROUND_Y_NUM - 1)) then
  begin
    Result := false;
    Exit;
  end;

  { 회전 했을 때 주변에 쌓여있는 블록과 충돌하는 지 검사 (충돌하면 회전 불가) }
  if ((CheckMixed(AMatrixBlock, MatrixBottom, true)) OR
      (CheckMixed(AMatrixBlock, MatrixLeft, true)) OR
      (CheckMixed(AMatrixBlock, MatrixRight, true)) ) then
    Result := false;

end;

{ 회전 시 주변 블록과 충돌하는지 검사 }
function TTetris.CheckMixed(AMatrixBlock: TMatrixBlock; AMatrixSide : TMatrixSide; ROption : Boolean): Boolean;
var
  i, j : integer;
  val, val1, mask : integer;
  RotateOffset : array[0..2] of integer;
begin

  Result := false;

  { 현재 블록 비트맵 값 추출 }
  val := TetrisMatrix[Ord(AMatrixBlock.FType)][Ord(AMatrixBlock.FAngle)];

  { 회전 중 X }
  if (ROption = false) then
  begin
    { 좌(-1), 우(+1), 아래(+1)로 이동할 오프셋 }
    RotateOffset[0] := -1;
    RotateOffset[1] := 1;
    RotateOffset[2] := 1;
  end

  { 회전 중 }
  else
  begin
    { 이동 없이 현재 위치에서만 검사 }
    RotateOffset[0] := 0;
    RotateOffset[1] := 0;
    RotateOffset[2] := 0;
  end;

  { 4x4 블록 세로 줄 하나씩 처리 }
  for i := 0 to TETRIX_ONEBLOCK_HEIGHT - 1 do
  begin

    { i번째 비트 정보 추출 }
    val1 := val shr (TETRIX_ONEBLOCK_WIDTH * ((TETRIX_ONEBLOCK_WIDTH-1) - i));
    mask := $08;

    { 4x4 블록 가로 줄 하나씩 처리 }
    for j := 0 to TETRIX_ONEBLOCK_WIDTH - 1 do
    begin
      { 해당 위치에 블록 존재 -> 출돌 여부 검사 }
      if ((val1 AND mask) <> 0) then
      begin
        case AMatrixSide of
        MatrixLeft:   // 왼쪽 이동
          if (TETRIS_FULLBLOCK = FLiedBlocks[AMatrixBlock.FPoistion.Y + i ][AMatrixBlock.FPoistion.X + j + RotateOffset[0]].Value) then
          begin
            Result := true;
            Exit;
          end;

        MatrixRight:  // 오른쪽 이동
          if (TETRIS_FULLBLOCK = FLiedBlocks[AMatrixBlock.FPoistion.Y + i ][AMatrixBlock.FPoistion.X + j + RotateOffset[1]].Value) then
          begin
            Result := true;
            Exit;
          end;

        MatrixBottom: // 아래쪽 이동
          if (TETRIS_FULLBLOCK = FLiedBlocks[AMatrixBlock.FPoistion.Y + i + RotateOffset[2]][AMatrixBlock.FPoistion.X + j].Value) then
          begin
            Result := true;
            Exit;
          end;
        end;
      end;

      { 다음 비트 검사 }
      mask := mask shr 1;
    end
  end;
end;

{ 점수 출력 }
procedure TTetris.DrawInfo(ACanvas: TCanvas);
var
  str : string;
begin
  { 폰트 설정 }
  ACanvas.Font.Size := 12;
  ACanvas.Font.Color := clRed;
  ACanvas.Font.Style := [fsBold];
  ACanvas.Brush.Style := bsClear;

  { 점수 출력 }
  str := Format('%d', [FScore]);
  ACanvas.TextOut(FBlockWidth * (TETRIS_GROUND_X_NUM - 2), FBlockHeight div 2, str ); // 위치 설정
end;

{ 바닥에 쌓인 블록 그리기 }
procedure TTetris.DrawLiedBlock(ACanvas: TCanvas);
var
  i, j : integer;
  Rect : TRect;
begin
  { 게임 필드 전체 순회 }
  for i := 0 to TETRIS_GROUND_Y_NUM - 1 do
    for j := 0 to TETRIS_GROUND_X_NUM - 1 do
    begin
      { 해당 위치에 블록이 쌓여 있다면 }
      if (FLiedBlocks[i][j].Value = TETRIS_FULLBLOCK) then
      begin
        { 사각형 영역 계산 }
        Rect.Left := j * FBlockWidth;
        Rect.Right := (j+1) * FBlockWidth;
        Rect.Top := i * FBlockHeight;
        Rect.Bottom := (i+1) * FBlockHeight;

        { 블록 색 설정 + 블록 그리기 }
        ACanvas.Brush.Color := FLiedBlocks[i][j].Color;
        ACanvas.FillRect(Rect);
      end;
    end;
end;

{ 새 게임 진행 여부 질문 출력 }
procedure TTetris.DrawAskNewGame(ACanvas : TCanvas);
var
  lf : TLogFont;
  tf : TFont;
  str : string;
  fontwidth : integer;
begin
  { 블록 사이즈에 따라 폰트 너비 조정 }
  fontwidth := 4;
  if (FBlockWidth = TETRIS_GROUND_BLOCK_WIDTH_N) then
    fontwidth := 6;

  { 표시할 문자열 }
  str := 'Do you want to play Tetris?(y[YES], n[NO]';
  with ACanvas do begin
    { 폰트 설정 }
    Font.Name := 'Tahoma';
    Font.Style := Font.Style + [fsBold];
    Font.Color := clWhite;

    { 폰트 객체 생성 (폰트 핸들 직접 조정) }
    tf := TFont.Create;
    try
      tf.Assign(Font);                        // 기존 설정 복사
      GetObject(tf.Handle, sizeof(lf), @lf);  // LogFont 정보 추출

      { 글자 너비 조정 }
      lf.lfWidth := fontwidth;

      { 새로운 폰트 핸들 생성 + 폰트 적용 }
      tf.Handle := CreateFontIndirect(lf);
      Font.Assign(tf);
    finally
      tf.Free;
    end;

    { 텍스트 출력 (가운데 정렬) }
    TextOut( ((FBlockWidth * TETRIS_GROUND_X_NUM) - Length(str)*lf.lfWidth) div 2 + lf.lfWidth,
      FBlockHeight * 2,  str);
  end;

end;

{ 현재 움직이는 블록 그리기 }
procedure TTetris.DrawMoveBlock(ACanvas: TCanvas);
var
  Rect : TRect;
  val, val1, mask : integer;
  i, j : integer;
begin
  { 현재 블록의 비트맵 정보 가져옴 }
  val := TetrisMatrix[Ord(FMatrixBlock.FType)][Ord(FMatrixBlock.FAngle)];

  { 블록의 각 행 반복 }
  for i := 0 to TETRIX_ONEBLOCK_HEIGHT - 1 do
  begin
    { 현재 행의 비트 값 추출 }
    val1 := val shr (TETRIX_ONEBLOCK_WIDTH * ((TETRIX_ONEBLOCK_WIDTH-1) - i));
    mask := $08;

    { 각 열 반복 }
    for j := 0 to TETRIX_ONEBLOCK_WIDTH - 1 do
    begin
      { 해당 위치에 블록이 있을 때만 그림 }
      if ( (val1 AND mask) <> 0 ) then
      begin
        { 블록 색상 설정 }
        ACanvas.Brush.Color := BlockColor[Ord(FMatrixBlock.FType)];

        { 화면상의 좌표 계산 }
        Rect.Left := (FMatrixBlock.FPoistion.X + j) * FBlockWidth;
        Rect.Right := (FMatrixBlock.FPoistion.X + j + 1)* FBlockWidth;
        Rect.Top := (FMatrixBlock.FPoistion.Y + i) * FBlockHeight;
        Rect.Bottom := (FMatrixBlock.FPoistion.Y + i + 1) * FBlockHeight;

        { 블록 그리기 }
        ACanvas.FillRect(Rect);
      end;

      { 다음 비트로 이동 }
      mask := mask shr 1;
    end;
  end;
end;

{ 완성된 줄 제거 + 점수 계산 }
procedure TTetris.BrokeBlocks;
var
  i, j : integer;
  bClear : Boolean;
  AScore : double;
begin
  { 제거된 줄 수 초기화 }
  FBrokenBlockCnt := 0;

  { 아래에서 위로 한 줄씩 확인 }
  for i := TETRIS_GROUND_Y_NUM - 1 downto 0 do
  begin
    bClear := true;

    { 현재 줄의 모든 칸이 지워졌는지 확인 }
    for j := 0 to TETRIS_GROUND_X_NUM - 1 do
    begin
      { 빈칸이 하나라도 있으면 제거 X }
      if (TETRIS_VOIDBLOCK = FLiedBlocks[i][j].Value) then
      begin
        bClear := false;
        break;
      end;
    end;

    { 줄이 가득참 -> 제거 }
    if (bClear) then
    begin
      { 제거된 줄 수 증가 + 사운드 출력 }
      Inc(FBrokenBlockCnt);

      { 해당 줄을 비우고 배경 색(검은 색)으로 초기화 }
      for j := 0 to TETRIS_GROUND_X_NUM - 1 do
      begin
        FLiedBlocks[i][j].Value := TETRIS_VOIDBLOCK;
        FLiedBlocks[i][j].Color := TETRIS_GROUND_COLOR;
      end;
    end;
  end;

  { 점수 계산 및 반양 }
  if (FBrokenBlockCnt <> 0) then
  begin
    { 소수점 잘라내기 방식(Round 방식) 설정 }
    SetRoundMode(rmTruncate);

    { 점수 계산 및 반영 }
    AScore := TETRIS_GRADE_WEIGHT[FBrokenBlockCnt] * TETRIS_LEVEL_WEIGHT[FLevel] * 5;
    FScore := FScore + Round(AScore);
  end;
end;

{ 가장 위에 있는 블록의 Y 좌표 계산 }
function TTetris.CalTopBlockPosition() : integer;
var
  bClear : Boolean;
  i, j, top : integer;
begin
  bClear := true;
  top := TETRIS_GROUND_Y_NUM - 1;

  { 위에서 아래로 탐색하며 첫 블록 발견 위치 찾기 }
  for i := 0 to TETRIS_GROUND_Y_NUM - 1 do
  begin
    for j := 0 to TETRIS_GROUND_X_NUM - 1 do
    begin
      if (TETRIS_FULLBLOCK = FLiedBlocks[i][j].Value) then
      begin
        bClear := false;
        break;
      end;
    end;

    { 발견 하면 가장 블록이 있는 줄 반환 }
    if bClear = false then
    begin
      top := i;
      break;
    end;
  end;

  Result := top;
end;

{ 위에 블록이 있으면 아래로 내림 }
procedure TTetris.ArrangeBlocks();
var
  i, j, i_, top, bottom : integer;
  bClear : Boolean;
label
  ProcessArrangeBlocks;
begin
  { Top 블록 위치 계산 }
  top := CalTopBlockPosition();
  bottom := TETRIS_GROUND_Y_NUM - 1;

  { Top - 1 줄부터 계산 시작 }
  Dec(top);

ProcessArrangeBlocks:
  Inc(top);

  { bottom ~ top까지 한 줄씩 탐색 (아래에서 위로) }
  for i := bottom downto top do
  begin
    bClear := true;

    { 현재 줄이 비었는 지 확인 }
    for j := 0 to TETRIS_GROUND_X_NUM - 1 do
    begin
      if (TETRIS_FULLBLOCK = FLiedBlocks[i][j].Value) then
      begin
        bClear := false;
        break;
      end;
    end;

    { 비어 있는 줄이면 위에 있는 줄들을 한 칸씩 아래로 내림 }
    if (bClear) then
    begin
      for i_ := i downto top do
      begin
        for j := 0 to TETRIS_GROUND_X_NUM - 1 do
        begin
          if( i_ <> 0 ) then
          begin
            FLiedBlocks[i_][j] := FLiedBlocks[i_-1][j];
          end;
        end;
      end;

      // 새로운 bottom 설정 후 다시 탐색
      bottom := i;
      goto ProcessArrangeBlocks;
    end;
  end;
end;

initialization

end.
