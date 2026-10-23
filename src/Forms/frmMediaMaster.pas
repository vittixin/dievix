unit frmMediaMaster;

{==============================================================================
  DieVix – Rotary Die & Keyline Manager
  Media / Substrate Master Form (Standardized Face & Liner Layers)
==============================================================================}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Grids,
  Vcl.ExtCtrls, System.Generics.Collections, System.UITypes,
  DieVix.Domain, DieVix.MasterDataService;

type
  TfrmMediaMaster = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblSearch: TLabel;
    edtSearch: TEdit;
    chkActiveOnly: TCheckBox;
    btnRefresh: TButton;
    gridMedia: TStringGrid;
    pnlEdit: TPanel;
    lblCode: TLabel;
    edtCode: TEdit;
    lblName: TLabel;
    edtName: TEdit;
    lblFace: TLabel;
    edtFace: TEdit;
    lblLiner: TLabel;
    edtLiner: TEdit;
    lblAdhesive: TLabel;
    edtAdhesive: TEdit;
    lblCaliper: TLabel;
    edtCaliper: TEdit;
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
    procedure gridMediaSelectCell(Sender: TObject; ACol, ARow: Longint; var CanSelect: Boolean);
    procedure btnNewClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  private
    FService: TMasterDataService;
    FMediaList: TList<TMedia>;
    FCurrentID: Integer;
    procedure InitGrid;
    procedure LoadData;
    procedure ClearForm;
  public
    property Service: TMasterDataService read FService write FService;
  end;

var
  FormMediaMaster: TfrmMediaMaster;

implementation

{$R *.dfm}

procedure TfrmMediaMaster.FormCreate(Sender: TObject);
begin
  FMediaList := TList<TMedia>.Create;
  if not Assigned(FService) then
    FService := TMasterDataService.Create;
  InitGrid;
  ClearForm;
  LoadData;
end;

procedure TfrmMediaMaster.FormDestroy(Sender: TObject);
begin
  FMediaList.Free;
end;

procedure TfrmMediaMaster.InitGrid;
begin
  gridMedia.ColCount := 7;
  gridMedia.RowCount := 2;
  gridMedia.FixedRows := 1;
  gridMedia.FixedCols := 0;

  gridMedia.Cells[0, 0] := 'Code';
  gridMedia.Cells[1, 0] := 'Media / Substrate Name';
  gridMedia.Cells[2, 0] := 'Face Material';
  gridMedia.Cells[3, 0] := 'Liner Material';
  gridMedia.Cells[4, 0] := 'Adhesive';
  gridMedia.Cells[5, 0] := 'Caliper (um)';
  gridMedia.Cells[6, 0] := 'Status';

  gridMedia.ColWidths[0] := 90;
  gridMedia.ColWidths[1] := 180;
  gridMedia.ColWidths[2] := 140;
  gridMedia.ColWidths[3] := 120;
  gridMedia.ColWidths[4] := 110;
  gridMedia.ColWidths[5] := 85;
  gridMedia.ColWidths[6] := 70;
end;

procedure TfrmMediaMaster.LoadData;
var
  List: TList<TMedia>;
  M: TMedia;
  Row: Integer;
  Search: string;
begin
  FMediaList.Clear;
  List := FService.GetAllMedia(chkActiveOnly.Checked);
  try
    Search := Trim(edtSearch.Text).ToLower;
    for M in List do
    begin
      if (Search = '') or
         (M.Code.ToLower.Contains(Search)) or
         (M.Name.ToLower.Contains(Search)) or
         (M.FaceMaterial.ToLower.Contains(Search)) or
         (M.LinerMaterial.ToLower.Contains(Search)) then
      begin
        FMediaList.Add(M);
      end;
    end;
  finally
    List.Free;
  end;

  if FMediaList.Count = 0 then
  begin
    gridMedia.RowCount := 2;
    gridMedia.Rows[1].Clear;
    Exit;
  end;

  gridMedia.RowCount := FMediaList.Count + 1;
  for Row := 0 to FMediaList.Count - 1 do
  begin
    M := FMediaList[Row];
    gridMedia.Cells[0, Row + 1] := M.Code;
    gridMedia.Cells[1, Row + 1] := M.Name;
    gridMedia.Cells[2, Row + 1] := M.FaceMaterial;
    gridMedia.Cells[3, Row + 1] := M.LinerMaterial;
    gridMedia.Cells[4, Row + 1] := M.AdhesiveType;
    if M.TotalCaliperUm > 0 then
      gridMedia.Cells[5, Row + 1] := IntToStr(M.TotalCaliperUm)
    else
      gridMedia.Cells[5, Row + 1] := '—';
    if M.IsActive then
      gridMedia.Cells[6, Row + 1] := 'Active'
    else
      gridMedia.Cells[6, Row + 1] := 'Inactive';
  end;
end;

procedure TfrmMediaMaster.gridMediaSelectCell(
  Sender: TObject; ACol, ARow: Longint; var CanSelect: Boolean
);
var
  Idx: Integer;
  M: TMedia;
begin
  Idx := ARow - 1;
  if (Idx >= 0) and (Idx < FMediaList.Count) then
  begin
    M := FMediaList[Idx];
    FCurrentID := M.ID;
    edtCode.Text := M.Code;
    edtName.Text := M.Name;
    edtFace.Text := M.FaceMaterial;
    edtLiner.Text := M.LinerMaterial;
    edtAdhesive.Text := M.AdhesiveType;
    if M.TotalCaliperUm > 0 then
      edtCaliper.Text := IntToStr(M.TotalCaliperUm)
    else
      edtCaliper.Text := '';
    chkActive.Checked := M.IsActive;
    edtNotes.Text := M.Notes;
  end;
end;

procedure TfrmMediaMaster.ClearForm;
begin
  FCurrentID := 0;
  edtCode.Text := '';
  edtName.Text := '';
  edtFace.Text := '';
  edtLiner.Text := 'Glassine 62gsm';
  edtAdhesive.Text := 'Acrylic Permanent';
  edtCaliper.Text := '135';
  chkActive.Checked := True;
  edtNotes.Text := '';
  if Showing and edtCode.CanFocus then
    edtCode.SetFocus;
end;

procedure TfrmMediaMaster.btnNewClick(Sender: TObject);
begin
  ClearForm;
end;

procedure TfrmMediaMaster.btnSaveClick(Sender: TObject);
var
  M: TMedia;
begin
  if Trim(edtCode.Text) = '' then
  begin
    ShowMessage('Please enter a Media Code.');
    if Showing and edtCode.CanFocus then
      edtCode.SetFocus;
    Exit;
  end;
  if Trim(edtName.Text) = '' then
  begin
    ShowMessage('Please enter a Media Name.');
    if Showing and edtName.CanFocus then
      edtName.SetFocus;
    Exit;
  end;

  M := TMedia.CreateNew(Trim(edtCode.Text), Trim(edtName.Text));
  M.ID := FCurrentID;
  M.FaceMaterial := Trim(edtFace.Text);
  M.LinerMaterial := Trim(edtLiner.Text);
  M.AdhesiveType := Trim(edtAdhesive.Text);
  M.TotalCaliperUm := StrToIntDef(Trim(edtCaliper.Text), 0);
  M.Notes := Trim(edtNotes.Text);
  M.IsActive := chkActive.Checked;

  try
    FService.SaveMedia(M);
    ShowMessage('Media substrate saved successfully.');
    LoadData;
    ClearForm;
  except
    on E: Exception do
      ShowMessage('Error saving media: ' + E.Message);
  end;
end;

procedure TfrmMediaMaster.btnDeleteClick(Sender: TObject);
begin
  if FCurrentID <= 0 then
  begin
    ShowMessage('Select a media record to delete.');
    Exit;
  end;

  if MessageDlg('Are you sure you want to delete this media substrate record?',
                mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    try
      if FService.DeleteMedia(FCurrentID) then
      begin
        ShowMessage('Media substrate deleted successfully.');
        LoadData;
        ClearForm;
      end;
    except
      on E: Exception do
        ShowMessage('Cannot delete media: ' + E.Message);
    end;
  end;
end;

procedure TfrmMediaMaster.btnRefreshClick(Sender: TObject);
begin
  LoadData;
end;

procedure TfrmMediaMaster.chkActiveOnlyClick(Sender: TObject);
begin
  LoadData;
end;

procedure TfrmMediaMaster.edtSearchChange(Sender: TObject);
begin
  LoadData;
end;

procedure TfrmMediaMaster.btnCloseClick(Sender: TObject);
begin
  Close;
end;

end.
