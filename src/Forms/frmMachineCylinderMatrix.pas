unit frmMachineCylinderMatrix;

{==============================================================================
  DieVix - Rotary Die & Keyline Manager
  Machine x Cylinder Compatibility Matrix Form
  2D cross-tab grid for managing fleet assignments transactionally.
==============================================================================}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Grids, Vcl.StdCtrls,
  Vcl.ExtCtrls, System.Generics.Collections, System.UITypes,
  DieVix.Domain, DieVix.MasterDataService;

type
  TfrmMachineCylinderMatrix = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblInstructions: TLabel;
    btnSaveMatrix: TButton;
    btnReload: TButton;
    btnClose: TButton;
    gridMatrix: TStringGrid;
    pnlBottom: TPanel;
    lblLegend: TLabel;
    btnAssignAll: TButton;
    btnUnassignAll: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure gridMatrixClick(Sender: TObject);
    procedure gridMatrixDrawCell(Sender: TObject; ACol, ARow: Longint; Rect: TRect; State: TGridDrawState);
    procedure btnSaveMatrixClick(Sender: TObject);
    procedure btnReloadClick(Sender: TObject);
    procedure btnAssignAllClick(Sender: TObject);
    procedure btnUnassignAllClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  private
    FService: TMasterDataService;
    FMachines: TList<TMachine>;
    FCylinders: TList<TCylinder>;
    // In-memory matrix representation: [Row, Col] -> Boolean
    FAssignments: array of array of Boolean;
    FModified: Boolean;
    procedure LoadMatrix;
  public
    property Service: TMasterDataService read FService write FService;
  end;

var
  FormMachineCylinderMatrix: TfrmMachineCylinderMatrix;

implementation

{$R *.dfm}

procedure TfrmMachineCylinderMatrix.FormCreate(Sender: TObject);
begin
  FMachines := TList<TMachine>.Create;
  FCylinders := TList<TCylinder>.Create;
  if not Assigned(FService) then
    FService := TMasterDataService.Create;
  LoadMatrix;
end;

procedure TfrmMachineCylinderMatrix.FormDestroy(Sender: TObject);
begin
  FMachines.Free;
  FCylinders.Free;
end;

procedure TfrmMachineCylinderMatrix.LoadMatrix;
var
  MList: TList<TMachine>;
  CList: TList<TCylinder>;
  C, R, Col: Integer;
  AssignedTeeth: TList<Integer>;
begin
  FMachines.Clear;
  FCylinders.Clear;

  MList := FService.GetAllMachines(False);
  try
    FMachines.AddRange(MList);
  finally
    MList.Free;
  end;

  CList := FService.GetAllCylinders(False);
  try
    FCylinders.AddRange(CList);
  finally
    CList.Free;
  end;

  if (FMachines.Count = 0) or (FCylinders.Count = 0) then
  begin
    gridMatrix.ColCount := 2;
    gridMatrix.RowCount := 2;
    gridMatrix.Cells[0, 0] := 'Machine';
    gridMatrix.Cells[1, 0] := 'No Cylinders';
    Exit;
  end;

  gridMatrix.ColCount := FCylinders.Count + 1;
  gridMatrix.RowCount := FMachines.Count + 1;
  gridMatrix.FixedRows := 1;
  gridMatrix.FixedCols := 1;

  gridMatrix.Cells[0, 0] := 'Machine / Press';
  gridMatrix.ColWidths[0] := 200;

  for C := 0 to FCylinders.Count - 1 do
  begin
    gridMatrix.Cells[C + 1, 0] := IntToStr(FCylinders[C].Teeth) + 'T';
    gridMatrix.ColWidths[C + 1] := 55;
  end;

  SetLength(FAssignments, FMachines.Count, FCylinders.Count);

  for R := 0 to FMachines.Count - 1 do
  begin
    gridMatrix.Cells[0, R + 1] := Format('%s (%s)', [FMachines[R].Code, FMachines[R].Name]);
    AssignedTeeth := FService.GetAssignedCylindersForMachine(FMachines[R].ID);
    try
      for Col := 0 to FCylinders.Count - 1 do
      begin
        FAssignments[R, Col] := AssignedTeeth.Contains(FCylinders[Col].Teeth);
        if FAssignments[R, Col] then
          gridMatrix.Cells[Col + 1, R + 1] := '[X]'
        else
          gridMatrix.Cells[Col + 1, R + 1] := '';
      end;
    finally
      AssignedTeeth.Free;
    end;
  end;

  FModified := False;
end;

procedure TfrmMachineCylinderMatrix.gridMatrixClick(Sender: TObject);
var
  R, C: Integer;
begin
  R := gridMatrix.Row - 1;
  C := gridMatrix.Col - 1;
  if (R >= 0) and (R < Length(FAssignments)) and (C >= 0) and (C < Length(FAssignments[R])) then
  begin
    FAssignments[R, C] := not FAssignments[R, C];
    if FAssignments[R, C] then
      gridMatrix.Cells[C + 1, R + 1] := '[X]'
    else
      gridMatrix.Cells[C + 1, R + 1] := '';
    FModified := True;
  end;
end;

procedure TfrmMachineCylinderMatrix.gridMatrixDrawCell(
  Sender: TObject; ACol, ARow: Longint; Rect: TRect; State: TGridDrawState
);
var
  Text: string;
  IsHeader: Boolean;
  IsAssigned: Boolean;
begin
  IsHeader := (ACol = 0) or (ARow = 0);
  Text := gridMatrix.Cells[ACol, ARow];

  if IsHeader then
  begin
    gridMatrix.Canvas.Brush.Color := $00F0F0F0;
    gridMatrix.Canvas.Font.Style := [fsBold];
    gridMatrix.Canvas.Font.Color := clBlack;
  end
  else
  begin
    IsAssigned := (ACol - 1 >= 0) and (ARow - 1 >= 0) and
                  (ARow - 1 < Length(FAssignments)) and
                  (ACol - 1 < Length(FAssignments[ARow - 1])) and
                  FAssignments[ARow - 1, ACol - 1];

    if IsAssigned then
    begin
      gridMatrix.Canvas.Brush.Color := $00D5FAD5; // Soft green highlight
      gridMatrix.Canvas.Font.Color := $00006600;
      gridMatrix.Canvas.Font.Style := [fsBold];
    end
    else
    begin
      gridMatrix.Canvas.Brush.Color := clWhite;
      gridMatrix.Canvas.Font.Color := clGray;
      gridMatrix.Canvas.Font.Style := [];
    end;

    // Check if machine or cylinder is inactive
    if ((ARow - 1 >= 0) and (ARow - 1 < FMachines.Count) and not FMachines[ARow - 1].IsActive) or
       ((ACol - 1 >= 0) and (ACol - 1 < FCylinders.Count) and not FCylinders[ACol - 1].IsActive) then
    begin
      gridMatrix.Canvas.Brush.Color := $00EAEAEA; // Gray out inactive
      gridMatrix.Canvas.Font.Color := clMedGray;
    end;
  end;

  gridMatrix.Canvas.FillRect(Rect);
  InflateRect(Rect, -2, -2);
  DrawText(gridMatrix.Canvas.Handle, PChar(Text), Length(Text), Rect,
           DT_CENTER or DT_VCENTER or DT_SINGLELINE);
end;

procedure TfrmMachineCylinderMatrix.btnSaveMatrixClick(Sender: TObject);
var
  R, C: Integer;
  AssignedList: TList<Integer>;
begin
  for R := 0 to FMachines.Count - 1 do
  begin
    AssignedList := TList<Integer>.Create;
    try
      for C := 0 to FCylinders.Count - 1 do
      begin
        if FAssignments[R, C] then
          AssignedList.Add(FCylinders[C].Teeth);
      end;
      FService.SaveMachineCylinderAssignments(FMachines[R].ID, AssignedList.ToArray);
    finally
      AssignedList.Free;
    end;
  end;

  FModified := False;
  ShowMessage('Machine-Cylinder matrix saved successfully.');
  LoadMatrix;
end;

procedure TfrmMachineCylinderMatrix.btnAssignAllClick(Sender: TObject);
var
  R, C: Integer;
begin
  R := gridMatrix.Row - 1;
  if (R >= 0) and (R < Length(FAssignments)) then
  begin
    for C := 0 to FCylinders.Count - 1 do
    begin
      FAssignments[R, C] := True;
      gridMatrix.Cells[C + 1, R + 1] := '[X]';
    end;
    FModified := True;
    gridMatrix.Invalidate;
  end;
end;

procedure TfrmMachineCylinderMatrix.btnUnassignAllClick(Sender: TObject);
var
  R, C: Integer;
begin
  R := gridMatrix.Row - 1;
  if (R >= 0) and (R < Length(FAssignments)) then
  begin
    for C := 0 to FCylinders.Count - 1 do
    begin
      FAssignments[R, C] := False;
      gridMatrix.Cells[C + 1, R + 1] := '';
    end;
    FModified := True;
    gridMatrix.Invalidate;
  end;
end;

procedure TfrmMachineCylinderMatrix.btnReloadClick(Sender: TObject);
begin
  LoadMatrix;
end;

procedure TfrmMachineCylinderMatrix.btnCloseClick(Sender: TObject);
begin
  if FModified then
  begin
    if MessageDlg('You have unsaved matrix changes. Close without saving?',
                  mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
      Exit;
  end;
  Close;
end;

end.
