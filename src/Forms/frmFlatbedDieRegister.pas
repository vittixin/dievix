unit frmFlatbedDieRegister;

{==============================================================================
  DieVix - Rotary Die & Keyline Manager
  Flatbed Die Master Register Form
  Comprehensive searchable & filterable register for flatbed tooling
  (Rollforms and Sheetforms) with smart bi-directional rotation search.
==============================================================================}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Grids,
  Vcl.ExtCtrls, System.Generics.Collections, System.UITypes,
  DieVix.Domain, DieVix.CalculationEngine, DieVix.FlatbedDieService, DieVix.ReportService,
  frmFlatbedDieEditor;

type
  TfrmFlatbedDieRegister = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblSearch: TLabel;
    lblCategoryFilter: TLabel;
    lblCustomerFilter: TLabel;
    lblStatusFilter: TLabel;
    edtSearch: TEdit;
    cmbCategoryFilter: TComboBox;
    cmbCustomerFilter: TComboBox;
    cmbStatusFilter: TComboBox;
    chkIncludeArchived: TCheckBox;
    btnClearFilters: TButton;
    pnlSmartFinder: TPanel;
    lblSmartTitle: TLabel;
    lblTargetAround: TLabel;
    lblTargetAcross: TLabel;
    lblTolerance: TLabel;
    edtTargetAround: TEdit;
    edtTargetAcross: TEdit;
    edtTolerance: TEdit;
    chkAllowRotation: TCheckBox;
    btnSmartSearch: TButton;
    btnClearSmartSearch: TButton;
    pnlActions: TPanel;
    btnNew: TButton;
    btnEdit: TButton;
    btnView: TButton;
    btnArchive: TButton;
    btnRestore: TButton;
    btnPermanentDelete: TButton;
    btnRefresh: TButton;
    btnPrintCard: TButton;
    btnPrintCatalog: TButton;
    btnExportXlsx: TButton;
    btnClose: TButton;
    gridDies: TStringGrid;
    pnlStatus: TPanel;
    lblCount: TLabel;
    lblRotationSummary: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FilterChange(Sender: TObject);
    procedure btnClearFiltersClick(Sender: TObject);
    procedure btnSmartSearchClick(Sender: TObject);
    procedure btnClearSmartSearchClick(Sender: TObject);
    procedure btnNewClick(Sender: TObject);
    procedure btnEditClick(Sender: TObject);
    procedure btnViewClick(Sender: TObject);
    procedure btnArchiveClick(Sender: TObject);
    procedure btnRestoreClick(Sender: TObject);
    procedure btnPermanentDeleteClick(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
    procedure btnPrintCardClick(Sender: TObject);
    procedure btnPrintCatalogClick(Sender: TObject);
    procedure btnExportXlsxClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure gridDiesDblClick(Sender: TObject);
  private
    FFlatbedService: TFlatbedDieService;
    FDieList: TList<TFlatbedDie>;
    FMatchList: TList<TFlatbedDieSearchResult>;
    FCustomerIDs: TList<Integer>;
    FIsSmartSearchActive: Boolean;
    procedure SetupGrid;
    procedure PopulateCombos;
    procedure ReloadData;
    function GetSelectedDie(out ADie: TFlatbedDie): Boolean;
    function GetCurrentFilter: TFlatbedDieSearchFilter;
  public
    property FlatbedService: TFlatbedDieService read FFlatbedService write FFlatbedService;
  end;

implementation

{$R *.dfm}

procedure TfrmFlatbedDieRegister.FormCreate(Sender: TObject);
begin
  FDieList := TList<TFlatbedDie>.Create;
  FMatchList := TList<TFlatbedDieSearchResult>.Create;
  FCustomerIDs := TList<Integer>.Create;
  FIsSmartSearchActive := False;

  SetupGrid;
  PopulateCombos;
  ReloadData;
end;

procedure TfrmFlatbedDieRegister.FormDestroy(Sender: TObject);
begin
  FDieList.Free;
  FMatchList.Free;
  FCustomerIDs.Free;
end;

procedure TfrmFlatbedDieRegister.SetupGrid;
begin
  gridDies.ColCount := 10;
  gridDies.RowCount := 2;
  gridDies.FixedRows := 1;
  gridDies.FixedCols := 0;

  gridDies.Cells[0, 0] := 'Serial No';
  gridDies.Cells[1, 0] := 'Category';
  gridDies.Cells[2, 0] := 'Cavity Size (Around x Across)';
  gridDies.Cells[3, 0] := 'Ups (Ar x Ac = Tot)';
  gridDies.Cells[4, 0] := 'Cut Footprint (mm)';
  gridDies.Cells[5, 0] := 'Rotation Support';
  gridDies.Cells[6, 0] := 'Customer';
  gridDies.Cells[7, 0] := 'Location (Rack/Shelf/Bin)';
  gridDies.Cells[8, 0] := 'Status';
  gridDies.Cells[9, 0] := 'Description / Fit Note';

  gridDies.ColWidths[0] := 115;
  gridDies.ColWidths[1] := 100;
  gridDies.ColWidths[2] := 170;
  gridDies.ColWidths[3] := 115;
  gridDies.ColWidths[4] := 130;
  gridDies.ColWidths[5] := 150;
  gridDies.ColWidths[6] := 140;
  gridDies.ColWidths[7] := 130;
  gridDies.ColWidths[8] := 80;
  gridDies.ColWidths[9] := 200;
end;

procedure TfrmFlatbedDieRegister.PopulateCombos;
var
  Custs: TList<TCustomer>;
  Statuses: TList<TDieStatus>;
  I: Integer;
begin
  if not Assigned(FFlatbedService) then
    FFlatbedService := TFlatbedDieService.Create;

  cmbCustomerFilter.Items.Clear;
  FCustomerIDs.Clear;
  cmbCustomerFilter.Items.Add('(All Customers)');
  FCustomerIDs.Add(0);

  Custs := FFlatbedService.GetActiveCustomers;
  try
    for I := 0 to Custs.Count - 1 do
    begin
      cmbCustomerFilter.Items.Add(Custs[I].Name);
      FCustomerIDs.Add(Custs[I].ID);
    end;
  finally
    Custs.Free;
  end;
  cmbCustomerFilter.ItemIndex := 0;

  cmbStatusFilter.Items.Clear;
  cmbStatusFilter.Items.Add('(All Statuses)');
  Statuses := FFlatbedService.GetAllStatuses;
  try
    for I := 0 to Statuses.Count - 1 do
      cmbStatusFilter.Items.Add(Statuses[I].Code);
  finally
    Statuses.Free;
  end;
  cmbStatusFilter.ItemIndex := 0;
end;

function TfrmFlatbedDieRegister.GetCurrentFilter: TFlatbedDieSearchFilter;
begin
  Result := TFlatbedDieSearchFilter.Default;
  Result.SearchText := Trim(edtSearch.Text);

  if cmbCategoryFilter.ItemIndex = 1 then
    Result.Category := 'ROLL_FORM'
  else if cmbCategoryFilter.ItemIndex = 2 then
    Result.Category := 'SHEET_FORM';

  if (cmbCustomerFilter.ItemIndex > 0) and (cmbCustomerFilter.ItemIndex < FCustomerIDs.Count) then
    Result.CustomerID := FCustomerIDs[cmbCustomerFilter.ItemIndex];

  if cmbStatusFilter.ItemIndex > 0 then
    Result.StatusCode := cmbStatusFilter.Text;

  Result.IncludeArchived := chkIncludeArchived.Checked;

  if FIsSmartSearchActive then
  begin
    Result.MatchDimensions := True;
    Result.TargetAroundMm := StrToFloatDef(Trim(edtTargetAround.Text), 0);
    Result.TargetAcrossMm := StrToFloatDef(Trim(edtTargetAcross.Text), 0);
    Result.ToleranceMm := StrToFloatDef(Trim(edtTolerance.Text), 0.500);
    Result.AllowRotation := chkAllowRotation.Checked;
  end;
end;

procedure TfrmFlatbedDieRegister.ReloadData;
var
  Filter: TFlatbedDieSearchFilter;
  I, Row: Integer;
  Die: TFlatbedDie;
  BiCount: Integer;
begin
  if not Assigned(FFlatbedService) then Exit;

  if FIsSmartSearchActive then
  begin
    // Handled by btnSmartSearchClick
    Exit;
  end;

  Filter := GetCurrentFilter;

  FDieList.Free;
  FDieList := FFlatbedService.SearchFlatbedDies(Filter);

  gridDies.RowCount := Max(2, FDieList.Count + 1);

  // Clear row 1 if empty
  if FDieList.Count = 0 then
  begin
    for I := 0 to gridDies.ColCount - 1 do
      gridDies.Cells[I, 1] := '';
    lblCount.Caption := 'Showing 0 flatbed tooling(s)';
    Exit;
  end;

  BiCount := 0;
  for I := 0 to FDieList.Count - 1 do
  begin
    Row := I + 1;
    Die := FDieList[I];

    gridDies.Cells[0, Row] := Die.SerialNo;
    gridDies.Cells[1, Row] := Die.Category;
    gridDies.Cells[2, Row] := Format('%.3f x %.3f mm', [Die.AroundSizeMm, Die.AcrossSizeMm]);
    gridDies.Cells[3, Row] := Format('%d x %d = %d', [Die.AroundUps, Die.AcrossUps, Die.TotalUps]);
    gridDies.Cells[4, Row] := Format('%.3f x %.3f', [Die.TotalCutAroundMm, Die.TotalCutAcrossMm]);

    if Die.CanRotate then
    begin
      gridDies.Cells[5, Row] := 'BI-DIRECTIONAL (90'#176')';
      Inc(BiCount);
    end
    else
      gridDies.Cells[5, Row] := 'FIXED DIRECTION';

    gridDies.Cells[6, Row] := Die.CustomerName;
    gridDies.Cells[7, Row] := Format('%s / %s / %s', [Die.StorageRack, Die.StorageShelf, Die.StorageBin]);
    gridDies.Cells[8, Row] := Die.StatusCode;
    gridDies.Cells[9, Row] := Die.Description;
  end;

  lblCount.Caption := Format('Showing %d flatbed tooling(s) (%d bi-directional)', [FDieList.Count, BiCount]);
end;

procedure TfrmFlatbedDieRegister.FilterChange(Sender: TObject);
begin
  FIsSmartSearchActive := False;
  ReloadData;
end;

procedure TfrmFlatbedDieRegister.btnClearFiltersClick(Sender: TObject);
begin
  edtSearch.Text := '';
  cmbCategoryFilter.ItemIndex := 0;
  cmbCustomerFilter.ItemIndex := 0;
  cmbStatusFilter.ItemIndex := 0;
  chkIncludeArchived.Checked := False;
  FIsSmartSearchActive := False;
  ReloadData;
end;

procedure TfrmFlatbedDieRegister.btnSmartSearchClick(Sender: TObject);
var
  TargetAround, TargetAcross, Tol: Double;
  Cat: string;
  I, Row: Integer;
  Match: TFlatbedDieSearchResult;
  BiCount: Integer;
begin
  TargetAround := StrToFloatDef(edtTargetAround.Text, 0.0);
  TargetAcross := StrToFloatDef(edtTargetAcross.Text, 0.0);
  Tol := StrToFloatDef(edtTolerance.Text, 0.500);

  if (TargetAround <= 0.0) or (TargetAcross <= 0.0) then
  begin
    MessageDlg('Please enter valid positive target cavity dimensions (Around & Across in mm).', mtWarning, [mbOK], 0);
    Exit;
  end;

  Cat := '';
  if cmbCategoryFilter.ItemIndex = 1 then
    Cat := 'ROLL_FORM'
  else if cmbCategoryFilter.ItemIndex = 2 then
    Cat := 'SHEET_FORM';

  FMatchList.Free;
  FMatchList := FFlatbedService.FindMatchingFlatbedDies(
    TargetAround, TargetAcross, Cat, Tol, chkAllowRotation.Checked, not chkIncludeArchived.Checked
  );

  FIsSmartSearchActive := True;
  gridDies.RowCount := Max(2, FMatchList.Count + 1);

  if FMatchList.Count = 0 then
  begin
    for I := 0 to gridDies.ColCount - 1 do
      gridDies.Cells[I, 1] := '';
    lblCount.Caption := Format('No flatbed tooling matched %.3f x %.3f mm (+/- %.3f mm)', [TargetAround, TargetAcross, Tol]);
    Exit;
  end;

  BiCount := 0;
  for I := 0 to FMatchList.Count - 1 do
  begin
    Row := I + 1;
    Match := FMatchList[I];

    gridDies.Cells[0, Row] := Match.Die.SerialNo;
    gridDies.Cells[1, Row] := Match.Die.Category;
    gridDies.Cells[2, Row] := Format('%.3f x %.3f mm', [Match.Die.AroundSizeMm, Match.Die.AcrossSizeMm]);
    gridDies.Cells[3, Row] := Format('%d x %d = %d', [Match.Die.AroundUps, Match.Die.AcrossUps, Match.Die.TotalUps]);
    gridDies.Cells[4, Row] := Format('%.3f x %.3f', [Match.Die.TotalCutAroundMm, Match.Die.TotalCutAcrossMm]);

    if Match.IsRotated then
    begin
      gridDies.Cells[5, Row] := 'ROTATED 90'#176' FIT';
      Inc(BiCount);
    end
    else if Match.Die.CanRotate then
    begin
      gridDies.Cells[5, Row] := 'BI-DIRECTIONAL (90'#176')';
      Inc(BiCount);
    end
    else
      gridDies.Cells[5, Row] := 'FIXED DIRECTION';

    gridDies.Cells[6, Row] := Match.Die.CustomerName;
    gridDies.Cells[7, Row] := Format('%s / %s / %s', [Match.Die.StorageRack, Match.Die.StorageShelf, Match.Die.StorageBin]);
    gridDies.Cells[8, Row] := Match.Die.StatusCode;
    gridDies.Cells[9, Row] := Format('[%s] %s', [Match.MatchNote, Match.Die.Description]);
  end;

  lblCount.Caption := Format('Found %d matching tooling(s) (%d rotated fits) for %.3f x %.3f mm', [FMatchList.Count, BiCount, TargetAround, TargetAcross]);
end;

procedure TfrmFlatbedDieRegister.btnClearSmartSearchClick(Sender: TObject);
begin
  edtTargetAround.Text := '';
  edtTargetAcross.Text := '';
  FIsSmartSearchActive := False;
  ReloadData;
end;

function TfrmFlatbedDieRegister.GetSelectedDie(out ADie: TFlatbedDie): Boolean;
var
  Idx: Integer;
begin
  Result := False;
  Idx := gridDies.Row - 1;
  if FIsSmartSearchActive then
  begin
    if (Idx >= 0) and (Idx < FMatchList.Count) then
    begin
      ADie := FMatchList[Idx].Die;
      Result := True;
    end;
  end
  else
  begin
    if (Idx >= 0) and (Idx < FDieList.Count) then
    begin
      ADie := FDieList[Idx];
      Result := True;
    end;
  end;
end;

procedure TfrmFlatbedDieRegister.btnNewClick(Sender: TObject);
var
  Editor: TfrmFlatbedDieEditor;
  InitialCat: string;
begin
  Editor := TfrmFlatbedDieEditor.Create(Self);
  try
    Editor.FlatbedService := FFlatbedService;
    if cmbCategoryFilter.ItemIndex = 2 then
      InitialCat := 'SHEET_FORM'
    else
      InitialCat := 'ROLL_FORM';

    Editor.InitForCreate(InitialCat);
    if Editor.ShowModal = mrOk then
    begin
      FIsSmartSearchActive := False;
      ReloadData;
    end;
  finally
    Editor.Free;
  end;
end;

procedure TfrmFlatbedDieRegister.btnEditClick(Sender: TObject);
var
  Editor: TfrmFlatbedDieEditor;
  Die: TFlatbedDie;
begin
  if not GetSelectedDie(Die) then
  begin
    MessageDlg('Please select a flatbed die to edit.', mtInformation, [mbOK], 0);
    Exit;
  end;

  Editor := TfrmFlatbedDieEditor.Create(Self);
  try
    Editor.FlatbedService := FFlatbedService;
    Editor.InitForEdit(Die);
    if Editor.ShowModal = mrOk then
    begin
      FIsSmartSearchActive := False;
      ReloadData;
    end;
  finally
    Editor.Free;
  end;
end;

procedure TfrmFlatbedDieRegister.btnViewClick(Sender: TObject);
begin
  btnEditClick(Sender);
end;

procedure TfrmFlatbedDieRegister.gridDiesDblClick(Sender: TObject);
begin
  btnEditClick(Sender);
end;

procedure TfrmFlatbedDieRegister.btnArchiveClick(Sender: TObject);
var
  Die: TFlatbedDie;
  Reason: string;
begin
  if not GetSelectedDie(Die) then
  begin
    MessageDlg('Please select a flatbed die to archive.', mtInformation, [mbOK], 0);
    Exit;
  end;

  if SameText(Die.StatusCode, 'ARCHIVED') then
  begin
    MessageDlg('This die is already archived.', mtInformation, [mbOK], 0);
    Exit;
  end;

  Reason := InputBox('Archive Flatbed Tooling', 'Enter reason for archiving ' + Die.SerialNo + ':', 'Inactive production tooling');
  if Trim(Reason) = '' then Exit;

  try
    FFlatbedService.ArchiveFlatbedDie(Die.ID, Reason, GetCurrentAppUser, Die.Version);
    FIsSmartSearchActive := False;
    ReloadData;
  except
    on E: Exception do
      MessageDlg('Archive failed: ' + E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TfrmFlatbedDieRegister.btnRestoreClick(Sender: TObject);
var
  Die: TFlatbedDie;
begin
  if not GetSelectedDie(Die) then
  begin
    MessageDlg('Please select an archived flatbed die to restore.', mtInformation, [mbOK], 0);
    Exit;
  end;

  if not SameText(Die.StatusCode, 'ARCHIVED') then
  begin
    MessageDlg('Only archived dies can be restored.', mtInformation, [mbOK], 0);
    Exit;
  end;

  try
    FFlatbedService.RestoreFlatbedDie(Die.ID, 'Restored by user', GetCurrentAppUser, Die.Version);
    FIsSmartSearchActive := False;
    ReloadData;
  except
    on E: Exception do
      MessageDlg('Restore failed: ' + E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TfrmFlatbedDieRegister.btnPermanentDeleteClick(Sender: TObject);
var
  Die: TFlatbedDie;
  Refusal: string;
begin
  if not GetSelectedDie(Die) then
  begin
    MessageDlg('Please select a flatbed die to delete.', mtInformation, [mbOK], 0);
    Exit;
  end;

  if not FFlatbedService.CanPermanentlyDeleteFlatbedDie(Die.ID, Refusal) then
  begin
    MessageDlg('Cannot delete flatbed die:' + sLineBreak + Refusal + sLineBreak + sLineBreak + 'Please use Archive instead.', mtWarning, [mbOK], 0);
    Exit;
  end;

  if MessageDlg(Format('Are you sure you want to permanently delete flatbed die "%s"? This action cannot be undone.', [Die.SerialNo]),
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    try
      FFlatbedService.PermanentlyDeleteFlatbedDie(Die.ID, True);
      FIsSmartSearchActive := False;
      ReloadData;
    except
      on E: Exception do
        MessageDlg('Delete failed: ' + E.Message, mtError, [mbOK], 0);
    end;
  end;
end;

procedure TfrmFlatbedDieRegister.btnRefreshClick(Sender: TObject);
begin
  ReloadData;
end;

procedure TfrmFlatbedDieRegister.btnPrintCardClick(Sender: TObject);
var
  Die: TFlatbedDie;
  RepSvc: TDieVixReportService;
begin
  if not GetSelectedDie(Die) then
  begin
    MessageDlg('Please select a flatbed die from the list to print its Tooling Job Bag Card.', mtInformation, [mbOK], 0);
    Exit;
  end;

  RepSvc := TDieVixReportService.Create;
  try
    RepSvc.PreviewFlatbedToolingCard(Die.ID);
  finally
    RepSvc.Free;
  end;
end;

procedure TfrmFlatbedDieRegister.btnPrintCatalogClick(Sender: TObject);
var
  RepSvc: TDieVixReportService;
begin
  RepSvc := TDieVixReportService.Create;
  try
    RepSvc.PreviewFlatbedRegisterCatalog(GetCurrentFilter);
  finally
    RepSvc.Free;
  end;
end;

procedure TfrmFlatbedDieRegister.btnExportXlsxClick(Sender: TObject);
var
  SaveDlg: TSaveDialog;
  RepSvc: TDieVixReportService;
begin
  SaveDlg := TSaveDialog.Create(nil);
  try
    SaveDlg.Title := 'Export Flatbed Die Register Catalog to Excel';
    SaveDlg.Filter := 'Excel Workbook (*.xlsx)|*.xlsx|All Files (*.*)|*.*';
    SaveDlg.DefaultExt := 'xlsx';
    SaveDlg.FileName := 'Flatbed_Die_Catalog_' + FormatDateTime('yyyymmdd', Now) + '.xlsx';
    if SaveDlg.Execute then
    begin
      RepSvc := TDieVixReportService.Create;
      try
        if RepSvc.ExportFlatbedRegisterCatalogXlsx(GetCurrentFilter, SaveDlg.FileName) then
          MessageDlg('Flatbed register catalog successfully exported to:' + sLineBreak + SaveDlg.FileName, mtInformation, [mbOK], 0)
        else
          MessageDlg('Failed to export flatbed catalog to Excel.', mtError, [mbOK], 0);
      finally
        RepSvc.Free;
      end;
    end;
  finally
    SaveDlg.Free;
  end;
end;

procedure TfrmFlatbedDieRegister.btnCloseClick(Sender: TObject);
begin
  Close;
end;

end.
