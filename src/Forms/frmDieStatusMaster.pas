unit frmDieStatusMaster;

{==============================================================================
  DieVix - Rotary Die & Keyline Manager
  Die Status Master Form
==============================================================================}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Grids,
  Vcl.ExtCtrls, System.Generics.Collections,
  DieVix.Domain, DieVix.MasterDataService;

type
  TfrmDieStatusMaster = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    gridStatuses: TStringGrid;
    pnlEdit: TPanel;
    lblCode: TLabel;
    edtCode: TEdit;
    lblDescription: TLabel;
    edtDescription: TEdit;
    chkUsable: TCheckBox;
    lblBadgeColor: TLabel;
    cmbBadgeColor: TComboBox;
    lblSortOrder: TLabel;
    edtSortOrder: TEdit;
    btnNew: TButton;
    btnSave: TButton;
    btnClose: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure gridStatusesSelectCell(Sender: TObject; ACol, ARow: Longint; var CanSelect: Boolean);
    procedure btnNewClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  private
    FService: TMasterDataService;
    FStatusList: TList<TDieStatus>;
    procedure InitGrid;
    procedure LoadData;
    procedure ClearForm;
  public
    property Service: TMasterDataService read FService write FService;
  end;

var
  FormDieStatusMaster: TfrmDieStatusMaster;

implementation

{$R *.dfm}

procedure TfrmDieStatusMaster.FormCreate(Sender: TObject);
begin
  FStatusList := TList<TDieStatus>.Create;
  if not Assigned(FService) then
    FService := TMasterDataService.Create;
  InitGrid;
  ClearForm;
  LoadData;
end;

procedure TfrmDieStatusMaster.FormDestroy(Sender: TObject);
begin
  FStatusList.Free;
end;

procedure TfrmDieStatusMaster.InitGrid;
begin
  gridStatuses.ColCount := 5;
  gridStatuses.RowCount := 2;
  gridStatuses.FixedRows := 1;
  gridStatuses.FixedCols := 0;

  gridStatuses.Cells[0, 0] := 'Status Code';
  gridStatuses.Cells[1, 0] := 'Display Description';
  gridStatuses.Cells[2, 0] := 'Usable on Press';
  gridStatuses.Cells[3, 0] := 'Badge Color';
  gridStatuses.Cells[4, 0] := 'Sort Order';

  gridStatuses.ColWidths[0] := 110;
  gridStatuses.ColWidths[1] := 200;
  gridStatuses.ColWidths[2] := 110;
  gridStatuses.ColWidths[3] := 100;
  gridStatuses.ColWidths[4] := 80;
end;

procedure TfrmDieStatusMaster.LoadData;
var
  List: TList<TDieStatus>;
  S: TDieStatus;
  Row: Integer;
begin
  FStatusList.Clear;
  List := FService.GetAllStatuses;
  try
    FStatusList.AddRange(List);
  finally
    List.Free;
  end;

  if FStatusList.Count = 0 then
  begin
    gridStatuses.RowCount := 2;
    gridStatuses.Rows[1].Clear;
    Exit;
  end;

  gridStatuses.RowCount := FStatusList.Count + 1;
  for Row := 0 to FStatusList.Count - 1 do
  begin
    S := FStatusList[Row];
    gridStatuses.Cells[0, Row + 1] := S.Code;
    gridStatuses.Cells[1, Row + 1] := S.Description;
    if S.IsUsable then
      gridStatuses.Cells[2, Row + 1] := 'Yes'
    else
      gridStatuses.Cells[2, Row + 1] := 'No';
    gridStatuses.Cells[3, Row + 1] := S.BadgeColor;
    gridStatuses.Cells[4, Row + 1] := IntToStr(S.SortOrder);
  end;
end;

procedure TfrmDieStatusMaster.gridStatusesSelectCell(
  Sender: TObject; ACol, ARow: Longint; var CanSelect: Boolean
);
var
  Idx: Integer;
  S: TDieStatus;
begin
  Idx := ARow - 1;
  if (Idx >= 0) and (Idx < FStatusList.Count) then
  begin
    S := FStatusList[Idx];
    edtCode.Text := S.Code;
    edtDescription.Text := S.Description;
    chkUsable.Checked := S.IsUsable;
    cmbBadgeColor.Text := S.BadgeColor;
    edtSortOrder.Text := IntToStr(S.SortOrder);
  end;
end;

procedure TfrmDieStatusMaster.ClearForm;
begin
  edtCode.Text := '';
  edtDescription.Text := '';
  chkUsable.Checked := True;
  cmbBadgeColor.ItemIndex := 0;
  edtSortOrder.Text := '10';
  if Showing and edtCode.CanFocus then
    edtCode.SetFocus;
end;

procedure TfrmDieStatusMaster.btnNewClick(Sender: TObject);
begin
  ClearForm;
end;

procedure TfrmDieStatusMaster.btnSaveClick(Sender: TObject);
var
  S: TDieStatus;
begin
  if Trim(edtCode.Text) = '' then
  begin
    ShowMessage('Please enter a Status Code.');
    if Showing and edtCode.CanFocus then
      edtCode.SetFocus;
    Exit;
  end;

  FillChar(S, SizeOf(S), 0);
  S.Code := Trim(edtCode.Text);
  S.Description := Trim(edtDescription.Text);
  S.IsUsable := chkUsable.Checked;
  S.BadgeColor := Trim(cmbBadgeColor.Text);
  S.SortOrder := StrToIntDef(Trim(edtSortOrder.Text), 10);

  try
    FService.SaveStatus(S);
    ShowMessage('Status saved successfully.');
    LoadData;
    ClearForm;
  except
    on E: Exception do
      ShowMessage('Error saving status: ' + E.Message);
  end;
end;

procedure TfrmDieStatusMaster.btnCloseClick(Sender: TObject);
begin
  Close;
end;

end.
