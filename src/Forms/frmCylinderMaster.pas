unit frmCylinderMaster;

{==============================================================================
  DieVix - Rotary Die & Keyline Manager
  Cylinder Fleet Master Form
==============================================================================}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Grids,
  Vcl.ExtCtrls, System.Generics.Collections, System.UITypes,
  DieVix.Domain, DieVix.MasterDataService, DieVix.CalculationEngine;

type
  TfrmCylinderMaster = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblSearch: TLabel;
    edtSearch: TEdit;
    chkActiveOnly: TCheckBox;
    btnRefresh: TButton;
    gridCylinders: TStringGrid;
    pnlEdit: TPanel;
    lblTeeth: TLabel;
    edtTeeth: TEdit;
    lblPitch: TLabel;
    edtPitch: TEdit;
    lblRepeat: TLabel;
    lblRepeatDisplay: TLabel;
    chkActive: TCheckBox;
    lblNotes: TLabel;
    edtNotes: TEdit;
    btnSave: TButton;
    btnNew: TButton;
    btnDelete: TButton;
    btnClose: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
    procedure chkActiveOnlyClick(Sender: TObject);
    procedure edtSearchChange(Sender: TObject);
    procedure gridCylindersSelectCell(Sender: TObject; ACol, ARow: Longint; var CanSelect: Boolean);
    procedure edtTeethChange(Sender: TObject);
    procedure edtPitchChange(Sender: TObject);
    procedure btnNewClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  private
    FService: TMasterDataService;
    FCylinderList: TList<TCylinder>;
    FIsNew: Boolean;
    procedure InitGrid;
    procedure LoadData;
    procedure UpdateRepeatDisplay;
    procedure ClearForm;
  public
    property Service: TMasterDataService read FService write FService;
  end;

var
  FormCylinderMaster: TfrmCylinderMaster;

implementation

{$R *.dfm}

procedure TfrmCylinderMaster.FormCreate(Sender: TObject);
begin
  FCylinderList := TList<TCylinder>.Create;
  if not Assigned(FService) then
    FService := TMasterDataService.Create;
  InitGrid;
  ClearForm;
  LoadData;
end;

procedure TfrmCylinderMaster.FormDestroy(Sender: TObject);
begin
  FCylinderList.Free;
end;

procedure TfrmCylinderMaster.InitGrid;
begin
  gridCylinders.ColCount := 6;
  gridCylinders.RowCount := 2;
  gridCylinders.FixedRows := 1;
  gridCylinders.FixedCols := 0;

  gridCylinders.Cells[0, 0] := 'Teeth';
  gridCylinders.Cells[1, 0] := 'Pitch (um)';
  gridCylinders.Cells[2, 0] := 'Repeat (mm)';
  gridCylinders.Cells[3, 0] := 'Repeat (inch)';
  gridCylinders.Cells[4, 0] := 'Status';
  gridCylinders.Cells[5, 0] := 'Notes';

  gridCylinders.ColWidths[0] := 80;
  gridCylinders.ColWidths[1] := 100;
  gridCylinders.ColWidths[2] := 110;
  gridCylinders.ColWidths[3] := 100;
  gridCylinders.ColWidths[4] := 90;
  gridCylinders.ColWidths[5] := 250;
end;

procedure TfrmCylinderMaster.LoadData;
var
  List: TList<TCylinder>;
  C: TCylinder;
  Row: Integer;
  Search: string;
begin
  FCylinderList.Clear;
  List := FService.GetAllCylinders(chkActiveOnly.Checked);
  try
    Search := Trim(edtSearch.Text);
    for C in List do
    begin
      if (Search = '') or
         (IntToStr(C.Teeth).Contains(Search)) or
         (C.Notes.ToLower.Contains(Search.ToLower)) then
      begin
        FCylinderList.Add(C);
      end;
    end;
  finally
    List.Free;
  end;

  if FCylinderList.Count = 0 then
  begin
    gridCylinders.RowCount := 2;
    gridCylinders.Rows[1].Clear;
    Exit;
  end;

  gridCylinders.RowCount := FCylinderList.Count + 1;
  for Row := 0 to FCylinderList.Count - 1 do
  begin
    C := FCylinderList[Row];
    gridCylinders.Cells[0, Row + 1] := IntToStr(C.Teeth);
    gridCylinders.Cells[1, Row + 1] := IntToStr(C.PitchUm);
    gridCylinders.Cells[2, Row + 1] := FormatFloat('0.000', C.RepeatMm);
    gridCylinders.Cells[3, Row + 1] := FormatFloat('0.000"', C.RepeatInch);
    if C.IsActive then
      gridCylinders.Cells[4, Row + 1] := 'Active'
    else
      gridCylinders.Cells[4, Row + 1] := 'Inactive';
    gridCylinders.Cells[5, Row + 1] := C.Notes;
  end;
end;

procedure TfrmCylinderMaster.gridCylindersSelectCell(
  Sender: TObject; ACol, ARow: Longint; var CanSelect: Boolean
);
var
  Idx: Integer;
  C: TCylinder;
begin
  Idx := ARow - 1;
  if (Idx >= 0) and (Idx < FCylinderList.Count) then
  begin
    C := FCylinderList[Idx];
    edtTeeth.Text := IntToStr(C.Teeth);
    edtTeeth.ReadOnly := True;
    edtPitch.Text := IntToStr(C.PitchUm);
    chkActive.Checked := C.IsActive;
    edtNotes.Text := C.Notes;
    FIsNew := False;
    UpdateRepeatDisplay;
  end;
end;

procedure TfrmCylinderMaster.UpdateRepeatDisplay;
var
  T, P: Integer;
  Mm, Inch: Double;
begin
  T := StrToIntDef(edtTeeth.Text, 0);
  P := StrToIntDef(edtPitch.Text, STANDARD_PITCH_UM);
  if (T > 0) and (P > 0) then
  begin
    Mm := TeethToRepeatMm(T, P);
    Inch := TeethToRepeatInch(T);
    lblRepeatDisplay.Caption := Format('%s mm (%s")', [FormatFloat('0.000', Mm), FormatFloat('0.000', Inch)]);
  end
  else
    lblRepeatDisplay.Caption := '-';
end;

procedure TfrmCylinderMaster.edtTeethChange(Sender: TObject);
begin
  UpdateRepeatDisplay;
end;

procedure TfrmCylinderMaster.edtPitchChange(Sender: TObject);
begin
  UpdateRepeatDisplay;
end;

procedure TfrmCylinderMaster.ClearForm;
begin
  FIsNew := True;
  edtTeeth.Text := '';
  edtTeeth.ReadOnly := False;
  edtPitch.Text := IntToStr(STANDARD_PITCH_UM);
  chkActive.Checked := True;
  edtNotes.Text := '';
  UpdateRepeatDisplay;
  if Showing and edtTeeth.CanFocus then
    edtTeeth.SetFocus;
end;

procedure TfrmCylinderMaster.btnNewClick(Sender: TObject);
begin
  ClearForm;
end;

procedure TfrmCylinderMaster.btnSaveClick(Sender: TObject);
var
  C: TCylinder;
  T, P: Integer;
begin
  T := StrToIntDef(Trim(edtTeeth.Text), 0);
  if T <= 0 then
  begin
    ShowMessage('Please enter a valid positive number of teeth.');
    if Showing and edtTeeth.CanFocus then
      edtTeeth.SetFocus;
    Exit;
  end;

  P := StrToIntDef(Trim(edtPitch.Text), STANDARD_PITCH_UM);
  if P <= 0 then
  begin
    ShowMessage(Format('Please enter a valid positive pitch in micrometres (default %d).', [STANDARD_PITCH_UM]));
    if Showing and edtPitch.CanFocus then
      edtPitch.SetFocus;
    Exit;
  end;

  C := TCylinder.CreateNew(T, P);
  C.IsActive := chkActive.Checked;
  C.Notes := Trim(edtNotes.Text);

  try
    FService.SaveCylinder(C, FIsNew);
    ShowMessage('Cylinder saved successfully.');
    LoadData;
    ClearForm;
  except
    on E: Exception do
      ShowMessage('Error saving cylinder: ' + E.Message);
  end;
end;

procedure TfrmCylinderMaster.btnDeleteClick(Sender: TObject);
var
  T: Integer;
begin
  T := StrToIntDef(Trim(edtTeeth.Text), 0);
  if T <= 0 then
  begin
    ShowMessage('Select a cylinder to delete.');
    Exit;
  end;

  if MessageDlg(Format('Are you sure you want to delete cylinder %dT from the fleet?', [T]),
                mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    try
      if FService.DeleteCylinder(T) then
      begin
        ShowMessage('Cylinder deleted successfully.');
        LoadData;
        ClearForm;
      end;
    except
      on E: Exception do
        ShowMessage('Cannot delete cylinder: ' + E.Message);
    end;
  end;
end;

procedure TfrmCylinderMaster.btnRefreshClick(Sender: TObject);
begin
  LoadData;
end;

procedure TfrmCylinderMaster.chkActiveOnlyClick(Sender: TObject);
begin
  LoadData;
end;

procedure TfrmCylinderMaster.edtSearchChange(Sender: TObject);
begin
  LoadData;
end;

procedure TfrmCylinderMaster.btnCloseClick(Sender: TObject);
begin
  Close;
end;

end.
