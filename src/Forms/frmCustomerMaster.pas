unit frmCustomerMaster;

{==============================================================================
  DieVix – Rotary Die & Keyline Manager
  Customer Master Form
==============================================================================}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Grids,
  Vcl.ExtCtrls, System.Generics.Collections, System.UITypes,
  DieVix.Domain, DieVix.MasterDataService;

type
  TfrmCustomerMaster = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblSearch: TLabel;
    edtSearch: TEdit;
    chkActiveOnly: TCheckBox;
    btnRefresh: TButton;
    gridCustomers: TStringGrid;
    pnlEdit: TPanel;
    lblCode: TLabel;
    edtCode: TEdit;
    lblName: TLabel;
    edtName: TEdit;
    lblContact: TLabel;
    edtContact: TEdit;
    lblPhone: TLabel;
    edtPhone: TEdit;
    lblEmail: TLabel;
    edtEmail: TEdit;
    lblCity: TLabel;
    edtCity: TEdit;
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
    procedure gridCustomersSelectCell(Sender: TObject; ACol, ARow: Longint; var CanSelect: Boolean);
    procedure btnNewClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  private
    FService: TMasterDataService;
    FCustomerList: TList<TCustomer>;
    FCurrentID: Integer;
    procedure InitGrid;
    procedure LoadData;
    procedure ClearForm;
  public
    property Service: TMasterDataService read FService write FService;
  end;

var
  FormCustomerMaster: TfrmCustomerMaster;

implementation

{$R *.dfm}

procedure TfrmCustomerMaster.FormCreate(Sender: TObject);
begin
  FCustomerList := TList<TCustomer>.Create;
  if not Assigned(FService) then
    FService := TMasterDataService.Create;
  InitGrid;
  ClearForm;
  LoadData;
end;

procedure TfrmCustomerMaster.FormDestroy(Sender: TObject);
begin
  FCustomerList.Free;
end;

procedure TfrmCustomerMaster.InitGrid;
begin
  gridCustomers.ColCount := 7;
  gridCustomers.RowCount := 2;
  gridCustomers.FixedRows := 1;
  gridCustomers.FixedCols := 0;

  gridCustomers.Cells[0, 0] := 'Code';
  gridCustomers.Cells[1, 0] := 'Customer Name';
  gridCustomers.Cells[2, 0] := 'Contact Person';
  gridCustomers.Cells[3, 0] := 'Phone';
  gridCustomers.Cells[4, 0] := 'Email';
  gridCustomers.Cells[5, 0] := 'City';
  gridCustomers.Cells[6, 0] := 'Status';

  gridCustomers.ColWidths[0] := 80;
  gridCustomers.ColWidths[1] := 180;
  gridCustomers.ColWidths[2] := 120;
  gridCustomers.ColWidths[3] := 110;
  gridCustomers.ColWidths[4] := 140;
  gridCustomers.ColWidths[5] := 90;
  gridCustomers.ColWidths[6] := 70;
end;

procedure TfrmCustomerMaster.LoadData;
var
  List: TList<TCustomer>;
  C: TCustomer;
  Row: Integer;
  Search: string;
begin
  FCustomerList.Clear;
  List := FService.GetAllCustomers(chkActiveOnly.Checked);
  try
    Search := Trim(edtSearch.Text).ToLower;
    for C in List do
    begin
      if (Search = '') or
         (C.Code.ToLower.Contains(Search)) or
         (C.Name.ToLower.Contains(Search)) or
         (C.ContactPerson.ToLower.Contains(Search)) or
         (C.City.ToLower.Contains(Search)) then
      begin
        FCustomerList.Add(C);
      end;
    end;
  finally
    List.Free;
  end;

  if FCustomerList.Count = 0 then
  begin
    gridCustomers.RowCount := 2;
    gridCustomers.Rows[1].Clear;
    Exit;
  end;

  gridCustomers.RowCount := FCustomerList.Count + 1;
  for Row := 0 to FCustomerList.Count - 1 do
  begin
    C := FCustomerList[Row];
    gridCustomers.Cells[0, Row + 1] := C.Code;
    gridCustomers.Cells[1, Row + 1] := C.Name;
    gridCustomers.Cells[2, Row + 1] := C.ContactPerson;
    gridCustomers.Cells[3, Row + 1] := C.Phone;
    gridCustomers.Cells[4, Row + 1] := C.Email;
    gridCustomers.Cells[5, Row + 1] := C.City;
    if C.IsActive then
      gridCustomers.Cells[6, Row + 1] := 'Active'
    else
      gridCustomers.Cells[6, Row + 1] := 'Inactive';
  end;
end;

procedure TfrmCustomerMaster.gridCustomersSelectCell(
  Sender: TObject; ACol, ARow: Longint; var CanSelect: Boolean
);
var
  Idx: Integer;
  C: TCustomer;
begin
  Idx := ARow - 1;
  if (Idx >= 0) and (Idx < FCustomerList.Count) then
  begin
    C := FCustomerList[Idx];
    FCurrentID := C.ID;
    edtCode.Text := C.Code;
    edtName.Text := C.Name;
    edtContact.Text := C.ContactPerson;
    edtPhone.Text := C.Phone;
    edtEmail.Text := C.Email;
    edtCity.Text := C.City;
    chkActive.Checked := C.IsActive;
    edtNotes.Text := C.Notes;
  end;
end;

procedure TfrmCustomerMaster.ClearForm;
begin
  FCurrentID := 0;
  edtCode.Text := '';
  edtName.Text := '';
  edtContact.Text := '';
  edtPhone.Text := '';
  edtEmail.Text := '';
  edtCity.Text := '';
  chkActive.Checked := True;
  edtNotes.Text := '';
  if Showing and edtCode.CanFocus then
    edtCode.SetFocus;
end;

procedure TfrmCustomerMaster.btnNewClick(Sender: TObject);
begin
  ClearForm;
end;

procedure TfrmCustomerMaster.btnSaveClick(Sender: TObject);
var
  Cust: TCustomer;
begin
  if Trim(edtCode.Text) = '' then
  begin
    ShowMessage('Please enter a Customer Code.');
    if Showing and edtCode.CanFocus then
      edtCode.SetFocus;
    Exit;
  end;
  if Trim(edtName.Text) = '' then
  begin
    ShowMessage('Please enter a Customer Name.');
    if Showing and edtName.CanFocus then
      edtName.SetFocus;
    Exit;
  end;

  Cust := TCustomer.CreateNew(Trim(edtCode.Text), Trim(edtName.Text));
  Cust.ID := FCurrentID;
  Cust.ContactPerson := Trim(edtContact.Text);
  Cust.Phone := Trim(edtPhone.Text);
  Cust.Email := Trim(edtEmail.Text);
  Cust.City := Trim(edtCity.Text);
  Cust.Notes := Trim(edtNotes.Text);
  Cust.IsActive := chkActive.Checked;

  try
    FService.SaveCustomer(Cust);
    ShowMessage('Customer saved successfully.');
    LoadData;
    ClearForm;
  except
    on E: Exception do
      ShowMessage('Error saving customer: ' + E.Message);
  end;
end;

procedure TfrmCustomerMaster.btnDeleteClick(Sender: TObject);
begin
  if FCurrentID <= 0 then
  begin
    ShowMessage('Select a customer to delete.');
    Exit;
  end;

  if MessageDlg('Are you sure you want to delete this customer record?',
                mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    try
      if FService.DeleteCustomer(FCurrentID) then
      begin
        ShowMessage('Customer deleted successfully.');
        LoadData;
        ClearForm;
      end;
    except
      on E: Exception do
        ShowMessage('Cannot delete customer: ' + E.Message);
    end;
  end;
end;

procedure TfrmCustomerMaster.btnRefreshClick(Sender: TObject);
begin
  LoadData;
end;

procedure TfrmCustomerMaster.chkActiveOnlyClick(Sender: TObject);
begin
  LoadData;
end;

procedure TfrmCustomerMaster.edtSearchChange(Sender: TObject);
begin
  LoadData;
end;

procedure TfrmCustomerMaster.btnCloseClick(Sender: TObject);
begin
  Close;
end;

end.
