unit Blocks;

interface

uses Windows, SysUtils, Graphics, Types, Math, Dialogs, MMSystem;

{ �� ũ�� �� ��� ���� (���) }
const
  { �ʵ� ������ }
  TETRIS_GROUND_X_NUM = 10; // ���� ĭ ��
  TETRIS_GROUND_Y_NUM = 20; // ���� ĭ ��

  { ���� ȭ�� (30px) }
  TETRIS_GROUND_BLOCK_WIDTH_N  = 30;   // ��� �ʺ�
  TETRIS_GROUND_BLOCK_HEIGHT_N = 30;   // ��� ����

  { ���� ȭ�� (20px) }
  TETRIS_GROUND_BLOCK_WIDTH_S  = 20;   // ��� �ʺ�
  TETRIS_GROUND_BLOCK_HEIGHT_S = 20;   // ��� ����

  { ��� ���� }
  TETRIS_GROUND_COLOR : TColor = clBlack; // ��� ����

  { ��� ���� }
  TETRIX_ONEBLOCK_WIDTH  = 4;  // ��� �ϳ��� �� (4 x 4)
  TETRIX_ONEBLOCK_HEIGHT = 4;  // ��� �ϳ��� ����

  { ��� �迭 �ε��� }
  TETRIS_LEFTOFBLOCK   = 0;
  TETRIS_RIGHTOFBLOCK  = (TETRIX_ONEBLOCK_WIDTH - 1);
  TETRIS_BOTTOMOFBLOCK = (TETRIX_ONEBLOCK_HEIGHT - 1);

  { �� ��� �� ä���� ��� }
  TETRIS_VOIDBLOCK = $00;
  TETRIS_FULLBLOCK = $02;

  { ���� ���� ��� }
  TETRIS_LEVEL_INC_COUNT = 40;
  TETRIS_LEVEL_MIN       = 1;
  TETRIS_LEVEL_MAX       = 10;

  { ��� ���� ��ġ }
  TETRIS_START_POS_Y = 2;

type
  { ������ ���� }

  // ��� �̵� ���
  TTetrisProcResult = (TProcResult_No_Error, TProcResult_Lied_Block, TProcResult_End_Game);

  // ��� ����
  TMatrixEnum = (MatrixEnum_I, MatrixEnum_L, MatrixEnum_IL, MatrixEnum_R, MatrixEnum_O, MatrixEnum_Z, MatrixEnum_IZ);

  // ��� ȸ�� ����
  TMatrixAngle = (MatrixAngle1, MatrixAngle2, MatrixAngle3, MatrixAngle4);

  // ��� ���� �� ����
  TMatrixSide = (MatrixLeft, MatrixRight, MatrixBottom{, MatrixTop}, MatrixRotate, MatrixDropDown);

  { �����̴� ��� ���� }
  TMatrixBlock = record
    FType: TMatrixEnum;
    FAngle: TMatrixAngle;
    FPoistion: TPoint;
  end;

  { �̹� ���� ��� ���� }
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

    { ���� �Լ� - ���� ���� �˻� �� ó�� }
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
  { ���� ���� ����ġ �迭 }
  TETRIS_GRADE_WEIGHT: array[1..TETRIX_ONEBLOCK_WIDTH] of double = (1, 1.5, 2, 3);
  TETRIS_LEVEL_WEIGHT: array[TETRIS_LEVEL_MIN..TETRIS_LEVEL_MAX] of double =
    (1, 1.2, 1.4, 1.6, 1.8, 2.1, 2.4, 2.8, 3.2, 3.5);

  { �� ��ϵ� ���� }
  BlockSpeed: array[TETRIS_LEVEL_MIN..TETRIS_LEVEL_MAX] of integer =
    (1500, 1000, 800, 700, 600, 500, 400, 300, 200, 100); // ������ ��� �ӵ�

  BlockColor: array[0..Ord(MatrixEnum_IZ)] of TColor =
    ($FF0000, $00FF00, $0000FF, $FFFF00, $FF00FF, $00FFFF, $808080); // ��Ϻ� ����

  TetrisMatrix : array[0..Ord(MatrixEnum_IZ), 0..3] of integer =
  (
    // ���1. 'I'
    //    XXXX 1111     XXXX 1000     XXXX 1111     XXXX 1000
    //    XXXX 0000     XXXX 1000     XXXX 0000     XXXX 1000
    //    XXXX 0000     XXXX 1000     XXXX 0000     XXXX 1000
    //    XXXX 0000     XXXX 1000     XXXX 0000     XXXX 1000
    ($F000, $8888, $F000, $8888),

    // ���2. 'L'
    //      XXXX 1000     XXXX 0100     XXXX 1110     XXXX 1100
    //      XXXX 1110     XXXX 0100     XXXX 0010     XXXX 1000
    //      XXXX 0000     XXXX 1100     XXXX 0000     XXXX 1000
    //      XXXX 0000     XXXX 0000     XXXX 0000     XXXX 0000
    ($8E00, $44C0, $E200, $C880),

    // ���3. '_|'
    //      XXXX 0010     XXXX 1100     XXXX 1110     XXXX 1000
    //      XXXX 1110     XXXX 0100     XXXX 1000     XXXX 1000
    //      XXXX 0000     XXXX 0100     XXXX 0000     XXXX 1100
    //      XXXX 0000     XXXX 0000     XXXX 0000     XXXX 0000
    ($2E00, $C440, $E800, $88C0),

    // ���4. '��'
    //      XXXX 1100     XXXX 1100     XXXX 1100     XXXX 1100
    //      XXXX 1100     XXXX 1100     XXXX 1100     XXXX 1100
    //      XXXX 0000     XXXX 0000     XXXX 0000     XXXX 0000
    //      XXXX 0000     XXXX 0000     XXXX 0000     XXXX 0000
    ($CC00, $CC00, $CC00, $CC00),

    // ���5. '��'
    //      XXXX 0100     XXXX 0100     XXXX 1110     XXXX 1000
    //      XXXX 1110     XXXX 1100     XXXX 0100     XXXX 1100
    //      XXXX 0000     XXXX 0100     XXXX 0000     XXXX 1000
    //      XXXX 0000     XXXX 0000     XXXX 0000     XXXX 0000
    ($4E00, $4C40, $E400, $8C80),

    // ���6. '-|_'
    //      XXXX 1100     XXXX 0100     XXXX 1100     XXXX 0100
    //      XXXX 0110     XXXX 1100     XXXX 0110     XXXX 1100
    //      XXXX 0000     XXXX 1000     XXXX 0000     XXXX 1000
    //      XXXX 0000     XXXX 0000     XXXX 0000     XXXX 0000
    ($C600, $4C80, $C600, $4C80),

    // ���7. '_|-'
    //      XXXX 0110     XXXX 1000     XXXX 0110     XXXX 1000
    //      XXXX 1100     XXXX 1100     XXXX 1100     XXXX 1100
    //      XXXX 0000     XXXX 0100     XXXX 0000     XXXX 0100
    //      XXXX 0000     XXXX 0000     XXXX 0000     XXXX 0000
    ($6C00, $8C40, $6C00, $8C40)
  );

implementation

{ ����� Side�� �����ߴ��� Ȯ�� }
function TTetris.CheckOntheSide(AMatrixSide: TMatrixSide): Boolean;
var
  i, j: Integer;
  Depth: Integer;
begin
  Result := False;

  { ����� �����ڸ� ���� ��� }
  Depth := CheckLevel(Self.FMatrixBlock, AMatrixSide);

  case AMatrixSide of
    MatrixLeft:   // ���� ��
      if (FMatrixBlock.FPoistion.X <= 0) then
        Result := True;

    MatrixRight:  // ������ ��
      if (Depth + FMatrixBlock.FPoistion.X >= TETRIS_GROUND_X_NUM - 1) then
        Result := True;

    MatrixBottom: // �Ʒ��� ��
      if (Depth + FMatrixBlock.FPoistion.Y >= TETRIS_GROUND_Y_NUM - 1) then
        Result := True;
  end;
end;

{ ��� �����ڸ� ���� ��� }
function TTetris.CheckLevel(AMatrixBlock: TMatrixBlock; MatrixSide: TMatrixSide): Integer;
var
  i, j, Mask: Integer;
  BlockInfo, temp, temp1: Integer;
begin
  BlockInfo := TetrisMatrix[Ord(AMatrixBlock.FType)][Ord(AMatrixBlock.FAngle)];

  { ȸ�� �� ����� ��ȯ�ؾ� �ϴ� ��ϸ� ó�� }
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

  { ��� ���� �Ʒ��κб��� ���� ���� }
  for i := 0 to 3 do
  begin
    if not ((BlockInfo and $0F) = $00) then
      Break;
    BlockInfo := BlockInfo shr 4;
  end;

  { ���� ��ȯ }
  Result := 3 - i;
end;

{ ������Ʈ ���� }
constructor TTetris.Create(MonitorWidth: Integer);
begin
  { ȭ�� ũ�⿡ ���� �� ũ�� ���� }
  if (1280 <= MonitorWidth) then
  begin
    { ���� ȭ�� }
    FBlockWidth := TETRIS_GROUND_BLOCK_WIDTH_N;
    FBlockHeight := TETRIS_GROUND_BLOCK_HEIGHT_N;
  end
  else
  begin
    { ���� ȭ�� }
    FBlockWidth := TETRIS_GROUND_BLOCK_WIDTH_S;
    FBlockHeight := TETRIS_GROUND_BLOCK_HEIGHT_S;
  end;

  { �������� ���� }
  FSemaphore := CreateSemaphore(nil, 1, 1, '');

  { ���� ���� ���� }
  FScreenRect.Left := 0;
  FScreenRect.Top := 0;
  FScreenRect.Right := TETRIS_GROUND_X_NUM * FBlockWidth - 1;
  FScreenRect.Bottom := TETRIS_GROUND_Y_NUM * FBlockHeight - 1;

  { �ʱ�ȭ }
  New();
  FPlaying := False;
end;

{ ������Ʈ ���� }
destructor TTetris.Destroy;
begin
  CloseHandle(FSemaphore);  // �������� ����
end;

{ ��� �׸��� }
procedure TTetris.Draw(Canvas: TCanvas);
var
  Bitmap: TBitmap;
begin
  { ���� ���۸� -> ȭ�� ������ ���� }
  Bitmap := TBitmap.Create;

  try
    { ��Ʈ�� ũ�� ���� }
    Bitmap.Width := FScreenRect.Right - FScreenRect.Left;
    Bitmap.Height := FScreenRect.Bottom - FScreenRect.Top;

    { ��� ���� ä��� }
    Bitmap.Canvas.Brush.Color := TETRIS_GROUND_COLOR;
    Bitmap.Canvas.FillRect(FScreenRect);

    if (FPlaying) then
    begin
      { �� �� ���� �׸��� }
      DrawLiedBlock(Bitmap.Canvas); // ������ ��� (���� ���)
      DrawMoveBlock(Bitmap.Canvas); // �̵� ���� ���
      DrawInfo(Bitmap.Canvas);      // ���� ����
    end
    else
    begin
      { ���� ����� ���� ���� }
      DrawAskNewGame(Bitmap.Canvas);
      DrawInfo(Bitmap.Canvas);
    end;

    { ��� }
    Canvas.Draw(0, 0, Bitmap);

  finally
    Bitmap.Free;
  end;
end;

{ ��� �̵� ó�� }
function TTetris.Move(Key: Word): TTetrisProcResult;
var
  TProcResult: TTetrisProcResult;
begin
  { Ű���� �Է¿� ���� ó�� }
  case Key of
    VK_LEFT:   // ���� ȭ��ǥ
      Result := Process(MatrixLeft);

    VK_RIGHT:  // ������ ȭ��ǥ
      Result := Process(MatrixRight);

    VK_DOWN:   // �Ʒ� ȭ��ǥ
      Result := Process(MatrixBottom);

    VK_UP:     // ���� ȭ��ǥ
      Result := Process(MatrixRotate);

    VK_SPACE:  // �����̽���
      Result := Process(MatrixDropDown);
  end;
end;

{ ���ο� ��� ���� }
function TTetris.MakeNewBlock(): Boolean;
var
  AMatrixBlock: TMatrixBlock;
begin
  Inc(FDropBlockCnt);

  { ������ ����� �������� ���� ���� }
  if (DropBlockCnt mod TETRIS_LEVEL_INC_COUNT = 0) then
    Inc(FLevel);

  { ���ο� ��� ���� }
  AMatrixBlock.FType := TMatrixEnum(Random(Ord(MatrixEnum_IZ) + 1));
  AMatrixBlock.FAngle := MatrixAngle1;
  AMatrixBlock.FPoistion.X := (TETRIS_GROUND_X_NUM div 2) - 2;
  AMatrixBlock.FPoistion.Y := TETRIS_START_POS_Y;

  { ����� ���ļ� ������ -> ���� ���� }
  Result := true;
  if (TETRIS_START_POS_Y + CheckLevel(AMatrixBlock, MatrixBottom) >= CalTopBlockPosition()) then
  begin
    FPlaying := false;
    Result := false;
  end
  else
    FMatrixBlock := AMatrixBlock;
end;

{ ���� �ʱ�ȭ }
procedure TTetris.New;
var
  i, j: integer;
begin
  { ���� ��ü �ʱ�ȭ }
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

{ ��� ȸ�� �� �̵� }
function TTetris.Process(AMatrixSide: TMatrixSide): TTetrisProcResult;
var
  i, height: integer;
  MatrixAngle: TMatrixAngle;
  bProblem: Boolean;
begin
  { ��Ƽ������ �浹 ���� (�������� ���) }
  WaitForSingleObject(FSemaphore, INFINITE);

  bProblem := false;
  Result := TProcResult_No_Error;

  { ��� ȸ�� �õ� }
  if (MatrixRotate = AMatrixSide) then
  begin
    { ��� ȸ���� �������� �˻� }
    MatrixAngle := FMatrixBlock.FAngle;
    bProblem := NOT CheckAngle(FMatrixBlock, MatrixAngle);
  end

  { �ϵ� ��� }
  else if (MatrixDropDown = AMatrixSide) then
  begin
    AMatrixSide := MatrixBottom;
    bProblem := true;

    for i := MatrixBlock.FPoistion.Y to TETRIS_GROUND_Y_NUM - 1 do
    begin
      { �ٴڿ� ��ų� �ٸ� ��ϰ� �浹�ϴ� �� �˻� }
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
    { �¿� �Ǵ� �Ʒ� ���� �̵� }
    if ((CheckOntheSide(AMatrixSide) = true) OR (CheckMixed(FMatrixBlock, AMatrixSide, false) = true)) then
      bProblem := true;
  end;

  { ���� �߻� �� }
  if bProblem then
  begin
    if (MatrixBottom = AMatrixSide) then
    begin
      { ��� ��ġ = ���� ��ġ -> ���� ���� }
      if (TETRIS_START_POS_Y + CheckLevel(FMatrixBlock, MatrixBottom) >= CalTopBlockPosition()) then
      begin
        FPlaying := false;
        Result := TProcResult_End_Game;
      end
      else
      begin
        { �ƴϸ� ��� ���� -> ���� ���ȭ }
        MixBlocks(FMatrixBlock);
        Result := TProcResult_Lied_Block;
      end;
    end;
  end
  else
  begin
    { �ƹ� ������ ������ ��ġ �Ǵ� ���� ���� }
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

{ ���� ��� ���� -> ���� ���ȭ }
procedure TTetris.MixBlocks(AMatrixBlock: TMatrixBlock);
var
  i, j: integer;
  val, val1, mask: integer;
begin
  { ���� ��� ���� (4x4 -> 32��Ʈ ����) }
  val := TetrisMatrix[Ord(AMatrixBlock.FType)][Ord(AMatrixBlock.FAngle)];

  { 4x4 ��� ���� �� �ϳ��� ó�� }
  for i := 0 to TETRIX_ONEBLOCK_HEIGHT - 1 do
  begin
    val1 := val shr (TETRIX_ONEBLOCK_WIDTH * ((TETRIX_ONEBLOCK_WIDTH - 1) - i));
    mask := $08;

    { 4x4 ��� ���� �� �ϳ��� ó�� }
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

{ ��� ȸ�� ���� ���� Ȯ�� }
function TTetris.CheckAngle(AMatrixBlock : TMatrixBlock; AMatrixAngle : TMatrixAngle): Boolean;
var
  Value : integer;
  Depth : integer;
  i, j : integer;
begin

  {
    ���� ȸ�� ���°� ������ ���� -> ó�� ������ ����
    �ƴϸ� -> ���� ������ ����
  }
  if (AMatrixAngle = MatrixAngle4) then
    AMatrixAngle := MatrixAngle1
  else
    Inc(AMatrixAngle);

  { ȸ�� ���¸� �ӽ÷� ���� }
  AMatrixBlock.FAngle := AMatrixAngle;

  Result := true;

  { ȸ����Ų ��� ��� �������� }
  Value := TetrisMatrix[Ord(AMatrixBlock.FType)][Ord(AMatrixBlock.FAngle)];

  { ȸ������ �� ���� �Ѵ��� Ȯ�� (������ ȸ�� �Ұ�) }
  Depth := CheckLevel(AMatrixBlock, MatrixRight);
  if ((Depth + AMatrixBlock.FPoistion.X) > (TETRIS_GROUND_X_NUM - 1)) then
  begin
    Result := false;
    Exit;
  end;

  { ȸ�� �� �Ʒ��� �������� �� �ٴ��� �Ѵ��� Ȯ�� (������ ȸ�� �Ұ�) }
  Depth := CheckLevel(AMatrixBlock, MatrixBottom);
  if ((Depth + AMatrixBlock.FPoistion.Y) > (TETRIS_GROUND_Y_NUM - 1)) then
  begin
    Result := false;
    Exit;
  end;

  { ȸ�� ���� �� �ֺ��� �׿��ִ� ��ϰ� �浹�ϴ� �� �˻� (�浹�ϸ� ȸ�� �Ұ�) }
  if ((CheckMixed(AMatrixBlock, MatrixBottom, true)) OR
      (CheckMixed(AMatrixBlock, MatrixLeft, true)) OR
      (CheckMixed(AMatrixBlock, MatrixRight, true)) ) then
    Result := false;

end;

{ ȸ�� �� �ֺ� ��ϰ� �浹�ϴ��� �˻� }
function TTetris.CheckMixed(AMatrixBlock: TMatrixBlock; AMatrixSide : TMatrixSide; ROption : Boolean): Boolean;
var
  i, j : integer;
  val, val1, mask : integer;
  RotateOffset : array[0..2] of integer;
begin

  Result := false;

  { ���� ��� ��Ʈ�� �� ���� }
  val := TetrisMatrix[Ord(AMatrixBlock.FType)][Ord(AMatrixBlock.FAngle)];

  { ȸ�� �� X }
  if (ROption = false) then
  begin
    { ��(-1), ��(+1), �Ʒ�(+1)�� �̵��� ������ }
    RotateOffset[0] := -1;
    RotateOffset[1] := 1;
    RotateOffset[2] := 1;
  end

  { ȸ�� �� }
  else
  begin
    { �̵� ���� ���� ��ġ������ �˻� }
    RotateOffset[0] := 0;
    RotateOffset[1] := 0;
    RotateOffset[2] := 0;
  end;

  { 4x4 ��� ���� �� �ϳ��� ó�� }
  for i := 0 to TETRIX_ONEBLOCK_HEIGHT - 1 do
  begin

    { i��° ��Ʈ ���� ���� }
    val1 := val shr (TETRIX_ONEBLOCK_WIDTH * ((TETRIX_ONEBLOCK_WIDTH-1) - i));
    mask := $08;

    { 4x4 ��� ���� �� �ϳ��� ó�� }
    for j := 0 to TETRIX_ONEBLOCK_WIDTH - 1 do
    begin
      { �ش� ��ġ�� ��� ���� -> �⵹ ���� �˻� }
      if ((val1 AND mask) <> 0) then
      begin
        case AMatrixSide of
        MatrixLeft:   // ���� �̵�
          if (TETRIS_FULLBLOCK = FLiedBlocks[AMatrixBlock.FPoistion.Y + i ][AMatrixBlock.FPoistion.X + j + RotateOffset[0]].Value) then
          begin
            Result := true;
            Exit;
          end;

        MatrixRight:  // ������ �̵�
          if (TETRIS_FULLBLOCK = FLiedBlocks[AMatrixBlock.FPoistion.Y + i ][AMatrixBlock.FPoistion.X + j + RotateOffset[1]].Value) then
          begin
            Result := true;
            Exit;
          end;

        MatrixBottom: // �Ʒ��� �̵�
          if (TETRIS_FULLBLOCK = FLiedBlocks[AMatrixBlock.FPoistion.Y + i + RotateOffset[2]][AMatrixBlock.FPoistion.X + j].Value) then
          begin
            Result := true;
            Exit;
          end;
        end;
      end;

      { ���� ��Ʈ �˻� }
      mask := mask shr 1;
    end
  end;
end;

{ ���� ��� }
procedure TTetris.DrawInfo(ACanvas: TCanvas);
var
  str : string;
begin
  { ��Ʈ ���� }
  ACanvas.Font.Size := 12;
  ACanvas.Font.Color := clRed;
  ACanvas.Font.Style := [fsBold];
  ACanvas.Brush.Style := bsClear;

  { ���� ��� }
  str := Format('%d', [FScore]);
  ACanvas.TextOut(FBlockWidth * (TETRIS_GROUND_X_NUM - 2), FBlockHeight div 2, str ); // ��ġ ����
end;

{ �ٴڿ� ���� ��� �׸��� }
procedure TTetris.DrawLiedBlock(ACanvas: TCanvas);
var
  i, j : integer;
  Rect : TRect;
begin
  { ���� �ʵ� ��ü ��ȸ }
  for i := 0 to TETRIS_GROUND_Y_NUM - 1 do
    for j := 0 to TETRIS_GROUND_X_NUM - 1 do
    begin
      { �ش� ��ġ�� ����� �׿� �ִٸ� }
      if (FLiedBlocks[i][j].Value = TETRIS_FULLBLOCK) then
      begin
        { �簢�� ���� ��� }
        Rect.Left := j * FBlockWidth;
        Rect.Right := (j+1) * FBlockWidth;
        Rect.Top := i * FBlockHeight;
        Rect.Bottom := (i+1) * FBlockHeight;

        { ��� �� ���� + ��� �׸��� }
        ACanvas.Brush.Color := FLiedBlocks[i][j].Color;
        ACanvas.FillRect(Rect);
      end;
    end;
end;

{ �� ���� ���� ���� ���� ��� }
procedure TTetris.DrawAskNewGame(ACanvas : TCanvas);
var
  lf : TLogFont;
  tf : TFont;
  str : string;
  fontwidth : integer;
begin
  { ��� ����� ���� ��Ʈ �ʺ� ���� }
  fontwidth := 4;
  if (FBlockWidth = TETRIS_GROUND_BLOCK_WIDTH_N) then
    fontwidth := 6;

  { ǥ���� ���ڿ� }
  str := 'Do you want to play Tetris?(y[YES], n[NO]';
  with ACanvas do begin
    { ��Ʈ ���� }
    Font.Name := 'Tahoma';
    Font.Style := Font.Style + [fsBold];
    Font.Color := clWhite;

    { ��Ʈ ��ü ���� (��Ʈ �ڵ� ���� ����) }
    tf := TFont.Create;
    try
      tf.Assign(Font);                        // ���� ���� ����
      GetObject(tf.Handle, sizeof(lf), @lf);  // LogFont ���� ����

      { ���� �ʺ� ���� }
      lf.lfWidth := fontwidth;

      { ���ο� ��Ʈ �ڵ� ���� + ��Ʈ ���� }
      tf.Handle := CreateFontIndirect(lf);
      Font.Assign(tf);
    finally
      tf.Free;
    end;

    { �ؽ�Ʈ ��� (��� ����) }
    TextOut( ((FBlockWidth * TETRIS_GROUND_X_NUM) - Length(str)*lf.lfWidth) div 2 + lf.lfWidth,
      FBlockHeight * 2,  str);
  end;

end;

{ ���� �����̴� ��� �׸��� }
procedure TTetris.DrawMoveBlock(ACanvas: TCanvas);
var
  Rect : TRect;
  val, val1, mask : integer;
  i, j : integer;
begin
  { ���� ����� ��Ʈ�� ���� ������ }
  val := TetrisMatrix[Ord(FMatrixBlock.FType)][Ord(FMatrixBlock.FAngle)];

  { ����� �� �� �ݺ� }
  for i := 0 to TETRIX_ONEBLOCK_HEIGHT - 1 do
  begin
    { ���� ���� ��Ʈ �� ���� }
    val1 := val shr (TETRIX_ONEBLOCK_WIDTH * ((TETRIX_ONEBLOCK_WIDTH-1) - i));
    mask := $08;

    { �� �� �ݺ� }
    for j := 0 to TETRIX_ONEBLOCK_WIDTH - 1 do
    begin
      { �ش� ��ġ�� ����� ���� ���� �׸� }
      if ( (val1 AND mask) <> 0 ) then
      begin
        { ��� ���� ���� }
        ACanvas.Brush.Color := BlockColor[Ord(FMatrixBlock.FType)];

        { ȭ����� ��ǥ ��� }
        Rect.Left := (FMatrixBlock.FPoistion.X + j) * FBlockWidth;
        Rect.Right := (FMatrixBlock.FPoistion.X + j + 1)* FBlockWidth;
        Rect.Top := (FMatrixBlock.FPoistion.Y + i) * FBlockHeight;
        Rect.Bottom := (FMatrixBlock.FPoistion.Y + i + 1) * FBlockHeight;

        { ��� �׸��� }
        ACanvas.FillRect(Rect);
      end;

      { ���� ��Ʈ�� �̵� }
      mask := mask shr 1;
    end;
  end;
end;

{ �ϼ��� �� ���� + ���� ��� }
procedure TTetris.BrokeBlocks;
var
  i, j : integer;
  bClear : Boolean;
  AScore : double;
begin
  { ���ŵ� �� �� �ʱ�ȭ }
  FBrokenBlockCnt := 0;

  { �Ʒ����� ���� �� �پ� Ȯ�� }
  for i := TETRIS_GROUND_Y_NUM - 1 downto 0 do
  begin
    bClear := true;

    { ���� ���� ��� ĭ�� ���������� Ȯ�� }
    for j := 0 to TETRIS_GROUND_X_NUM - 1 do
    begin
      { ��ĭ�� �ϳ��� ������ ���� X }
      if (TETRIS_VOIDBLOCK = FLiedBlocks[i][j].Value) then
      begin
        bClear := false;
        break;
      end;
    end;

    { ���� ������ -> ���� }
    if (bClear) then
    begin
      { ���ŵ� �� �� ���� + ���� ��� }
      Inc(FBrokenBlockCnt);

      { �ش� ���� ���� ��� ��(���� ��)���� �ʱ�ȭ }
      for j := 0 to TETRIS_GROUND_X_NUM - 1 do
      begin
        FLiedBlocks[i][j].Value := TETRIS_VOIDBLOCK;
        FLiedBlocks[i][j].Color := TETRIS_GROUND_COLOR;
      end;
    end;
  end;

  { ���� ��� �� �ݾ� }
  if (FBrokenBlockCnt <> 0) then
  begin
    { �Ҽ��� �߶󳻱� ���(Round ���) ���� }
    SetRoundMode(rmTruncate);

    { ���� ��� �� �ݿ� }
    AScore := TETRIS_GRADE_WEIGHT[FBrokenBlockCnt] * TETRIS_LEVEL_WEIGHT[FLevel] * 5;
    FScore := FScore + Round(AScore);
  end;
end;

{ ���� ���� �ִ� ����� Y ��ǥ ��� }
function TTetris.CalTopBlockPosition() : integer;
var
  bClear : Boolean;
  i, j, top : integer;
begin
  bClear := true;
  top := TETRIS_GROUND_Y_NUM - 1;

  { ������ �Ʒ��� Ž���ϸ� ù ��� �߰� ��ġ ã�� }
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

    { �߰� �ϸ� ���� ����� �ִ� �� ��ȯ }
    if bClear = false then
    begin
      top := i;
      break;
    end;
  end;

  Result := top;
end;

{ ���� ����� ������ �Ʒ��� ���� }
procedure TTetris.ArrangeBlocks();
var
  i, j, i_, top, bottom : integer;
  bClear : Boolean;
label
  ProcessArrangeBlocks;
begin
  { Top ��� ��ġ ��� }
  top := CalTopBlockPosition();
  bottom := TETRIS_GROUND_Y_NUM - 1;

  { Top - 1 �ٺ��� ��� ���� }
  Dec(top);

ProcessArrangeBlocks:
  Inc(top);

  { bottom ~ top���� �� �پ� Ž�� (�Ʒ����� ����) }
  for i := bottom downto top do
  begin
    bClear := true;

    { ���� ���� ����� �� Ȯ�� }
    for j := 0 to TETRIS_GROUND_X_NUM - 1 do
    begin
      if (TETRIS_FULLBLOCK = FLiedBlocks[i][j].Value) then
      begin
        bClear := false;
        break;
      end;
    end;

    { ��� �ִ� ���̸� ���� �ִ� �ٵ��� �� ĭ�� �Ʒ��� ���� }
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

      // ���ο� bottom ���� �� �ٽ� Ž��
      bottom := i;
      goto ProcessArrangeBlocks;
    end;
  end;
end;

initialization

end.
