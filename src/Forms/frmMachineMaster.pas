unit frmMachineMaster;

{==============================================================================
  DieVix – Rotary Die & Keyline Manager
  Machine / Press Master Form
==============================================================================}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Grids,
  Vcl.ExtCtrls, System.Generics.Collections, System.UITypes,
  DieVix.Domain, DieVix.MasterDataService;

type
  TfrmMachineMaster = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblSearch: TLabel;
    edtSearch: TEdit;
    chkActiveOnly: TCheckBox;
    btnRefresh: TButton;
    gridMachines: TStringGrid;
    pnlEdit: TPanel;
    lblCode: TLabel;
    edtCode: TEdit;
    lblName: TLabel;
    edtName: TEdit;
    lblMaxWeb: TLabel;
    edtMaxWeb: TEdit;
    lblMinWeb: TLabel;
    edtMinWeb: TEdit;
    lblMargin: TLabel;
    edtMargin: TEdit;
    lblPrintMethod: TLabel;
    edtPrintMethod: TEdit;
    chkActive: TCheckBox;
    lblNotes: TLabel;
    edtNotes: TEdit;
    btnNew: TButton;
    btnSave: TButton;
    btnDelete: TButton;
    btnClose: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
    procedure chkActiveOnlyClick(Sender: TObject);
    procedure edtSearchChange(Sender: TObject);
    procedure gridMachinesSelectCell(Sender: TObject; ACol, ARow: Longint; var CanSelect: Boolean);
    procedure btnNewClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  private
    FService: TMasterDataService;
    FMachineList: TList<TMachine>;
    FCurrentID: Integer;
    procedure InitGrid;
    procedure LoadData;
    procedure ClearForm;
  public
    property Service: TMasterDataService read FService write FService;
  end;

var
  FormMachineMaster: TfrmMachineMaster;

implementation

{$R *.dfm}

procedure TfrmMachineMaster.FormCreate(Sender: TObject);
begin
  FMachineList := TList<TMachine>.Create;
  if not Assigned(FService) then
    FService := TMasterDataService.Create;
  InitGrid;
  ClearForm;
  LoadData;
end;

procedure TfrmMachineMaster.FormDestroy(Sender: TObject);
begin
  FMachineList.Free;
end;

procedure TfrmMachineMaster.InitGrid;
begin
  gridMachines.ColCount := 7;
  gridMachines.RowCount := 2;
  gridMachines.FixedRows := 1;
  gridMachines.FixedCols := 0;

  gridMachines.Cells[0, 0] := 'Code';
  gridMachines.Cells[1, 0] := 'Machine Name';
  gridMachines.Cells[2, 0] := 'Max Web (mm)';
  gridMachines.Cells[3, 0] := 'Min Web (mm)';
  gridMachines.Cells[4, 0] := 'Margin (mm)';
  gridMachines.Cells[5, 0] := 'Print Method';
  gridMachines.Cells[6, 0] := 'Status';

  gridMachines.ColWidths[0] := 90;
  gridMachines.ColWidths[1] := 190;
  gridMachines.ColWidths[2] := 95;
  gridMachines.ColWidths[3] := 95;
  gridMachines.ColWidths[4] := 85;
  gridMachines.ColWidths[5] := 110;
  gridMachines.ColWidths[6] := 75;
end;

procedure TfrmMachineMaster.LoadData;
var
  List: TList<TMachine>;
  M: TMachine;
  Row: Integer;
  Search: string;
begin
  FMachineList.Clear;
  List := FService.GetAllMachines(chkActiveOnly.Checked);
  try
    Search := Trim(edtSearch.Text).ToLower;
    for M in List do
    begin
      if (Search = '') or
         (M.Code.ToLower.Contains(Search)) or
         (M.Name.ToLower.Contains(Search)) or
         (M.PrintMethod.ToLower.Contains(Search)) then
      begin
        FMachineList.Add(M);
      end;
    end;
  finally
    List.Free;
  end;

  if FMachineList.Count = 0 then
  begin
    gridMachines.RowCount := 2;
    gridMachines.Rows[1].Clear;
    Exit;
  end;

  gridMachines.RowCount := FMachineList.Count + 1;
  for Row := 0 to FMachineList.Count - 1 do
  begin
    M := FMachineList[Row];
    gridMachines.Cells[0, Row + 1] := M.Code;
    gridMachines.Cells[1, Row + 1] := M.Name;
    gridMachines.Cells[2, Row + 1] := FormatFloat('0.000', M.MaxWebWidthMm);
    gridMachines.Cells[3, Row + 1] := FormatFloat('0.000', M.MinWebWidthMm);
    gridMachines.Cells[4, Row + 1] := FormatFloat('0.000', M.DefaultMarginMm);
    gridMachines.Cells[5, Row + 1] := M.PrintMethod;
    if M.IsActive then
      gridMachines.Cells[6, Row + 1] := 'Active'
    else
      gridMachines.Cells[6, Row + 1] := 'Inactive';
  end;
end;

procedure TfrmMachineMaster.gridMachinesSelectCell(
  Sender: TObject; ACol, ARow: Longint; var CanSelect: Boolean
);
var
  Idx: Integer;
  M: TMachine;
begin
  Idx := ARow - 1;
  if (Idx >= 0) and (Idx < FMachineList.Count) then
  begin
    M := FMachineList[Idx];
    FCurrentID := M.ID;
    edtCode.Text := M.Code;
    edtName.Text := M.Name;
    edtMaxWeb.Text := FormatFloat('0.000', M.MaxWebWidthMm);
    edtMinWeb.Text := FormatFloat('0.000', M.MinWebWidthMm);
    edtMargin.Text := FormatFloat('0.000', M.DefaultMarginMm);
    edtPrintMethod.Text := M.PrintMethod;
    chkActive.Checked := M.IsActive;
    edtNotes.Text := M.Notes;
  end;
end;

procedure TfrmMachineMaster.ClearForm;
begin
  FCurrentID := 0;
  edtCode.Text := '';
  edtName.Text := '';
  edtMaxWeb.Text := '254.000';
  edtMinWeb.Text := '50.000';
  edtMargin.Text := '5.000';
  edtPrintMethod.Text := 'Flexo';
  chkActive.Checked := True;
  edtNotes.Text := '';
  if edtCode.CanFocus then
    edtCode.SetFocus;
end;

procedure TfrmMachineMaster.btnNewClick(Sender: TObject);
begin
  ClearForm;
end;

procedure TfrmMachineMaster.btnSaveClick(Sender: TObject);
var
  M: TMachine;
begin
  if Trim(edtCode.Text) = '' then
  begin
    ShowMessage('Please enter a Machine Code.');
    edtCode.SetFocus;
    Exit;
  end;
  if Trim(edtName.Text) = '' then
  begin
    ShowMessage('Please enter a Machine Name.');
    edtName.SetFocus;
    Exit;
  end;

  FillChar(M, SizeOf(M), 0);
  M.ID := FCurrentID;
  M.Code := Trim(edtCode.Text);
  M.Name := Trim(edtName.Text);
  M.MaxWebWidthMm := StrToFloatDef(Trim(edtMaxWeb.Text), 254.0);
  M.MinWebWidthMm := StrToFloatDef(Trim(edtMinWeb.Text), 50.0);
  M.DefaultMarginMm := StrToFloatDef(Trim(edtMargin.Text), 5.0);
  M.PrintMethod := Trim(edtPrintMethod.Text);
  M.IsActive := chkActive.Checked;
  M.Notes := Trim(edtNotes.Text);

  try
    FService.SaveMachine(M);
    ShowMessage('Machine saved successfully.');
    LoadData;
    ClearForm;
  except
    on E: Exception do
      ShowMessage('Error saving machine: ' + E.Message);
  end;
end;

procedure TfrmMachineMaster.btnDeleteClick(Sender: TObject);
begin
  if FCurrentID <= 0 then
  begin
    ShowMessage('Select a machine to delete.');
    Exit;
  end;

  if MessageDlg('Are you sure you want to delete this machine? Any cylinder assignments will also be deleted.',
                mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    try
      if FService.DeleteMachine(FCurrentID) then
      begin
        ShowMessage('Machine deleted successfully.');
        LoadData;
        ClearForm;
      end;
    except
      on E: Exception do
        ShowMessage('Error deleting machine: ' + E.Message);
    end;
  end;
end;

procedure TfrmMachineMaster.btnRefreshClick(Sender: TObject);
begin
  LoadData;
end;

procedure TfrmMachineMaster.chkActiveOnlyClick(Sender: TObject);
begin
  LoadData;
end;

procedure TfrmMachineMaster.edtSearchChange(Sender: TObject);
begin
  LoadData;
end;

procedure TfrmMachineMaster.btnCloseClick(Sender: TObject);
begin
  Close;
end;

end.
