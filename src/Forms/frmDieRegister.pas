unit frmDieRegister;

{==============================================================================
  DieVix - Rotary Die & Keyline Manager
  Die Master Register Form
  Comprehensive searchable & filterable rotary tooling register with
  gap validation indicators and physical inventory tracking.
==============================================================================}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Grids,
  Vcl.ExtCtrls, System.Generics.Collections, System.UITypes,
  DieVix.Domain, DieVix.CalculationEngine, DieVix.DieService, DieVix.ReportService, frmDieEditor;

type
  TfrmDieRegister = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblSearch: TLabel;
    lblCustomerFilter: TLabel;
    lblTeethFilter: TLabel;
    lblStatusFilter: TLabel;
    lblMediaFilter: TLabel;
    edtSearch: TEdit;
    cmbCustomerFilter: TComboBox;
    cmbTeethFilter: TComboBox;
    cmbStatusFilter: TComboBox;
    cmbMediaFilter: TComboBox;
    chkOnlySub3mm: TCheckBox;
    chkIncludeArchived: TCheckBox;
    btnClearFilters: TButton;
    pnlSmartFinder: TPanel;
    lblSmartTitle: TLabel;
    lblTargetAround: TLabel;
    lblTargetAcross: TLabel;
    lblTolerance: TLabel;
    lblMachine: TLabel;
    lblShape: TLabel;
    lblCutType: TLabel;
    lblRadius: TLabel;
    edtTargetAround: TEdit;
    edtTargetAcross: TEdit;
    edtTolerance: TEdit;
    chkIncludeSlitting: TCheckBox;
    cmbMachineFilter: TComboBox;
    cmbShapeFilter: TComboBox;
    cmbCutTypeFilter: TComboBox;
    edtRadiusFilter: TEdit;
    btnSmartSearch: TButton;
    btnClearSmartSearch: TButton;
    pnlActions: TPanel;
    btnNew: TButton;
    btnEdit: TButton;
    btnView: TButton;
    btnChangeStatus: TButton;
    btnRelocate: TButton;
    btnArchive: TButton;
    btnRestore: TButton;
    btnPermanentDelete: TButton;
    btnRefresh: TButton;
    btnClose: TButton;
    btnPrintCard: TButton;
    btnPrintCatalog: TButton;
    btnExportXlsx: TButton;
    btnFleetMatrix: TButton;
    gridDies: TStringGrid;
    pnlStatus: TPanel;
    lblCount: TLabel;
    lblSub3mmNotice: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FilterChange(Sender: TObject);
    procedure btnClearFiltersClick(Sender: TObject);
    procedure btnSmartSearchClick(Sender: TObject);
    procedure btnClearSmartSearchClick(Sender: TObject);
    procedure btnNewClick(Sender: TObject);
    procedure btnEditClick(Sender: TObject);
    procedure btnViewClick(Sender: TObject);
    procedure btnChangeStatusClick(Sender: TObject);
    procedure btnRelocateClick(Sender: TObject);
    procedure btnArchiveClick(Sender: TObject);
    procedure btnRestoreClick(Sender: TObject);
    procedure btnPermanentDeleteClick(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure btnPrintCardClick(Sender: TObject);
    procedure btnPrintCatalogClick(Sender: TObject);
    procedure btnExportXlsxClick(Sender: TObject);
    procedure btnFleetMatrixClick(Sender: TObject);
    procedure gridDiesDblClick(Sender: TObject);
  private
    FDieService: TDieService;
    FDieList: TList<TDie>;
    FSmartList: TList<TSmartDieSearchResult>;
    FCustomerIDs: TList<Integer>;
    FMediaIDs: TList<Integer>;
    FMachineIDs: TList<Integer>;
    FIsSmartSearch: Boolean;
    function GetCurrentFilter: TDieSearchFilter;
    procedure InitGrid;
    procedure InitGridForSmartSearch;
    procedure LoadFilterLookups;
    procedure LoadData;
    procedure PerformSmartSearch;
    procedure DisplaySmartResults;
    function GetSelectedDieID: Integer;
    function GetSelectedDie: TDie;
  public
    property DieService: TDieService read FDieService write FDieService;
  end;

var
  FormDieRegister: TfrmDieRegister;

implementation

{$R *.dfm}

{ TfrmDieRegister }

procedure TfrmDieRegister.FormCreate(Sender: TObject);
begin
  FDieList := TList<TDie>.Create;
  FSmartList := TList<TSmartDieSearchResult>.Create;
  FCustomerIDs := TList<Integer>.Create;
  FMediaIDs := TList<Integer>.Create;
  FMachineIDs := TList<Integer>.Create;
  FIsSmartSearch := False;

  if not Assigned(FDieService) then
    FDieService := TDieService.Create;

  InitGrid;
  LoadFilterLookups;
  LoadData;
end;

procedure TfrmDieRegister.FormDestroy(Sender: TObject);
begin
  FDieList.Free;
  FSmartList.Free;
  FCustomerIDs.Free;
  FMediaIDs.Free;
  FMachineIDs.Free;
end;

procedure TfrmDieRegister.InitGrid;
begin
  gridDies.ColCount := 12;
  gridDies.RowCount := 2;
  gridDies.FixedRows := 1;
  gridDies.FixedCols := 0;

  gridDies.Cells[0, 0] := 'Die Serial';
  gridDies.Cells[1, 0] := 'Customer';
  gridDies.Cells[2, 0] := 'Description';
  gridDies.Cells[3, 0] := 'Teeth';
  gridDies.Cells[4, 0] := 'Around (mm)';
  gridDies.Cells[5, 0] := 'Across (mm)';
  gridDies.Cells[6, 0] := 'Ups (Ar x Ac)';
  gridDies.Cells[7, 0] := 'Around Gap (mm)';
  gridDies.Cells[8, 0] := 'Media Substrate';
  gridDies.Cells[9, 0] := 'Status';
  gridDies.Cells[10, 0] := 'Storage Location';
  gridDies.Cells[11, 0] := 'Last Modified';

  gridDies.ColWidths[0] := 110;
  gridDies.ColWidths[1] := 140;
  gridDies.ColWidths[2] := 180;
  gridDies.ColWidths[3] := 55;
  gridDies.ColWidths[4] := 80;
  gridDies.ColWidths[5] := 80;
  gridDies.ColWidths[6] := 80;
  gridDies.ColWidths[7] := 105;
  gridDies.ColWidths[8] := 140;
  gridDies.ColWidths[9] := 90;
  gridDies.ColWidths[10] := 130;
  gridDies.ColWidths[11] := 115;
end;

procedure TfrmDieRegister.InitGridForSmartSearch;
begin
  gridDies.ColCount := 12;
  gridDies.RowCount := 2;
  gridDies.FixedRows := 1;
  gridDies.FixedCols := 0;

  gridDies.Cells[0, 0] := 'Match Classification';
  gridDies.Cells[1, 0] := 'Die Serial';
  gridDies.Cells[2, 0] := 'Label Size (mm)';
  gridDies.Cells[3, 0] := #916' Around (mm)';
  gridDies.Cells[4, 0] := #916' Across (mm)';
  gridDies.Cells[5, 0] := 'Ups (Ar x Ac)';
  gridDies.Cells[6, 0] := 'Teeth';
  gridDies.Cells[7, 0] := 'Shape / Radius';
  gridDies.Cells[8, 0] := 'Status';
  gridDies.Cells[9, 0] := 'Reusability Assessment & Engineering Note';
  gridDies.Cells[10, 0] := 'Location';
  gridDies.Cells[11, 0] := 'Customer';

  gridDies.ColWidths[0] := 160;
  gridDies.ColWidths[1] := 100;
  gridDies.ColWidths[2] := 115;
  gridDies.ColWidths[3] := 85;
  gridDies.ColWidths[4] := 85;
  gridDies.ColWidths[5] := 80;
  gridDies.ColWidths[6] := 55;
  gridDies.ColWidths[7] := 110;
  gridDies.ColWidths[8] := 85;
  gridDies.ColWidths[9] := 320;
  gridDies.ColWidths[10] := 100;
  gridDies.ColWidths[11] := 120;
end;

procedure TfrmDieRegister.LoadFilterLookups;
var
  Custs: TList<TCustomer>;
  MediaList: TList<TMedia>;
  Cyls: TList<TCylinder>;
  Statuses: TList<TDieStatus>;
  Machs: TList<TMachine>;
  I: Integer;
begin
  // Customers
  cmbCustomerFilter.Clear;
  FCustomerIDs.Clear;
  cmbCustomerFilter.Items.Add('All Customers');
  FCustomerIDs.Add(0);

  Custs := FDieService.GetActiveCustomers;
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

  // Media
  cmbMediaFilter.Clear;
  FMediaIDs.Clear;
  cmbMediaFilter.Items.Add('All Media');
  FMediaIDs.Add(0);

  MediaList := FDieService.GetActiveMedia;
  try
    for I := 0 to MediaList.Count - 1 do
    begin
      cmbMediaFilter.Items.Add(MediaList[I].Name);
      FMediaIDs.Add(MediaList[I].ID);
    end;
  finally
    MediaList.Free;
  end;
  cmbMediaFilter.ItemIndex := 0;

  // Teeth
  cmbTeethFilter.Clear;
  cmbTeethFilter.Items.Add('All Teeth');
  Cyls := FDieService.GetActiveCylinders;
  try
    for I := 0 to Cyls.Count - 1 do
      cmbTeethFilter.Items.Add(IntToStr(Cyls[I].Teeth));
  finally
    Cyls.Free;
  end;
  cmbTeethFilter.ItemIndex := 0;

  // Statuses
  cmbStatusFilter.Clear;
  cmbStatusFilter.Items.Add('All Statuses');
  Statuses := FDieService.GetAllStatuses;
  try
    for I := 0 to Statuses.Count - 1 do
      cmbStatusFilter.Items.Add(Statuses[I].Code);
  finally
    Statuses.Free;
  end;
  cmbStatusFilter.ItemIndex := 0;

  // Machines
  cmbMachineFilter.Clear;
  FMachineIDs.Clear;
  cmbMachineFilter.Items.Add('All Machines');
  FMachineIDs.Add(0);

  Machs := FDieService.GetActiveMachines;
  try
    for I := 0 to Machs.Count - 1 do
    begin
      cmbMachineFilter.Items.Add(Machs[I].Name);
      FMachineIDs.Add(Machs[I].ID);
    end;
  finally
    Machs.Free;
  end;
  cmbMachineFilter.ItemIndex := 0;

  // Shapes
  cmbShapeFilter.Clear;
  cmbShapeFilter.Items.Add('All Shapes');
  cmbShapeFilter.Items.Add('RECTANGLE');
  cmbShapeFilter.Items.Add('OVAL');
  cmbShapeFilter.Items.Add('CIRCLE');
  cmbShapeFilter.Items.Add('SPECIAL');
  cmbShapeFilter.ItemIndex := 0;

  // Cut Types
  cmbCutTypeFilter.Clear;
  cmbCutTypeFilter.Items.Add('All Cut Types');
  cmbCutTypeFilter.Items.Add('METAL_TO_METAL');
  cmbCutTypeFilter.Items.Add('METAL_TO_BACKING');
  cmbCutTypeFilter.ItemIndex := 0;
end;

function TfrmDieRegister.GetCurrentFilter: TDieSearchFilter;
begin
  Result := TDieSearchFilter.Default;
  Result.SearchText := Trim(edtSearch.Text);

  if cmbCustomerFilter.ItemIndex > 0 then
    Result.CustomerID := FCustomerIDs[cmbCustomerFilter.ItemIndex];

  if (cmbTeethFilter.ItemIndex > 0) and (cmbTeethFilter.Text <> 'All Teeth') then
    Result.Teeth := StrToIntDef(cmbTeethFilter.Text, 0);

  if cmbMediaFilter.ItemIndex > 0 then
    Result.MediaID := FMediaIDs[cmbMediaFilter.ItemIndex];

  if (cmbStatusFilter.ItemIndex > 0) and (cmbStatusFilter.Text <> 'All Statuses') then
    Result.StatusCode := cmbStatusFilter.Text;

  Result.OnlySub3mm := chkOnlySub3mm.Checked;
  Result.IncludeArchived := chkIncludeArchived.Checked;
end;

procedure TfrmDieRegister.LoadData;
var
  Filter: TDieSearchFilter;
  I: Integer;
  Die: TDie;
  GapStr, LocStr: string;
begin
  Filter := GetCurrentFilter;
  FDieList.Free;
  FDieList := FDieService.SearchDies(Filter);

  gridDies.RowCount := 2;
  gridDies.Rows[1].Clear;

  if FDieList.Count > 0 then
  begin
    gridDies.RowCount := FDieList.Count + 1;
    for I := 0 to FDieList.Count - 1 do
    begin
      Die := FDieList[I];
      gridDies.Cells[0, I + 1] := Die.SerialNo;
      gridDies.Cells[1, I + 1] := Die.CustomerName;
      gridDies.Cells[2, I + 1] := Die.Description;
      gridDies.Cells[3, I + 1] := IntToStr(Die.Teeth);
      gridDies.Cells[4, I + 1] := FormatFloat('0.000', Die.AroundSizeMm);
      gridDies.Cells[5, I + 1] := FormatFloat('0.000', Die.AcrossSizeMm);
      gridDies.Cells[6, I + 1] := Format('%d x %d', [Die.AroundUps, Die.AcrossUps]);

      // Format gap with sub-minimum indicator
      if Die.AroundGapMm < UmToMm(FDieService.GetMinAroundGapUm) then
        GapStr := FormatFloat('0.000', Die.AroundGapMm) + ' *'
      else
        GapStr := FormatFloat('0.000', Die.AroundGapMm);
      gridDies.Cells[7, I + 1] := GapStr;

      gridDies.Cells[8, I + 1] := Die.MediaName;
      gridDies.Cells[9, I + 1] := Die.StatusCode;

      if (Die.StorageRack <> '') or (Die.StorageShelf <> '') or (Die.StorageBin <> '') then
        LocStr := Format('%s/%s/%s', [Die.StorageRack, Die.StorageShelf, Die.StorageBin])
      else
        LocStr := Die.StorageLocation;
      gridDies.Cells[10, I + 1] := LocStr;

      gridDies.Cells[11, I + 1] := FormatDateTime('yyyy-mm-dd hh:nn', Die.UpdatedAt);
    end;
  end;

  lblCount.Caption := Format('Showing %d tooling records', [FDieList.Count]);
  lblSub3mmNotice.Caption := Format('* Dies with around gap < %0.3f mm require production management override.', [UmToMm(FDieService.GetMinAroundGapUm)]);
end;

procedure TfrmDieRegister.PerformSmartSearch;
var
  Filter: TSmartDieSizeFilter;
  AroundVal, AcrossVal, TolVal: Double;
  TotalCount: Integer;
  FS: TFormatSettings;
begin
  FS := TFormatSettings.Create('en-US');

  if not TryStrToFloat(Trim(edtTargetAround.Text), AroundVal, FS) or (AroundVal <= 0.0) then
  begin
    ShowMessage('Please enter a valid positive Target Around dimension in mm.');
    if Showing and edtTargetAround.CanFocus then
      edtTargetAround.SetFocus;
    Exit;
  end;

  if not TryStrToFloat(Trim(edtTargetAcross.Text), AcrossVal, FS) or (AcrossVal <= 0.0) then
  begin
    ShowMessage('Please enter a valid positive Target Across dimension in mm.');
    if Showing and edtTargetAcross.CanFocus then
      edtTargetAcross.SetFocus;
    Exit;
  end;

  if not TryStrToFloat(Trim(edtTolerance.Text), TolVal, FS) or (TolVal < 0.0) then
    TolVal := 2.0;

  Filter := TSmartDieSizeFilter.CreateDefault(AroundVal, AcrossVal, TolVal);
  Filter.IncludeSlitting := chkIncludeSlitting.Checked;
  Filter.IncludeArchived := chkIncludeArchived.Checked;

  // Optional Teeth filter
  if (cmbTeethFilter.ItemIndex > 0) and (cmbTeethFilter.Text <> 'All Teeth') then
    Filter.Teeth := StrToIntDef(cmbTeethFilter.Text, 0);

  // Optional Status filter
  if (cmbStatusFilter.ItemIndex > 0) and (cmbStatusFilter.Text <> 'All Statuses') then
    Filter.StatusCode := cmbStatusFilter.Text;

  // Machine filter
  if (cmbMachineFilter.ItemIndex > 0) and (cmbMachineFilter.ItemIndex < FMachineIDs.Count) then
    Filter.MachineID := FMachineIDs[cmbMachineFilter.ItemIndex];

  // Shape filter
  if (cmbShapeFilter.ItemIndex > 0) and (cmbShapeFilter.Text <> 'All Shapes') then
    Filter.Shape := cmbShapeFilter.Text;

  // Cut Type filter
  if (cmbCutTypeFilter.ItemIndex > 0) and (cmbCutTypeFilter.Text <> 'All Cut Types') then
    Filter.CutType := cmbCutTypeFilter.Text;

  // Corner Radius
  if Trim(edtRadiusFilter.Text) <> '' then
  begin
    Filter.CornerRadiusMm := StrToFloatDef(Trim(edtRadiusFilter.Text), 0.0);
    Filter.CornerRadiusTolMm := 0.5;
  end;

  FSmartList.Free;
  FSmartList := FDieService.SmartSearchDies(Filter, TotalCount);
  FIsSmartSearch := True;

  DisplaySmartResults;
end;

procedure TfrmDieRegister.DisplaySmartResults;
var
  I: Integer;
  Item: TSmartDieSearchResult;
  LocStr, ShapeCutStr, DiffArStr, DiffAcStr: string;
  ExactCnt, Near1Cnt, Near2Cnt, SlitCnt: Integer;
begin
  InitGridForSmartSearch;
  gridDies.RowCount := 2;
  gridDies.Rows[1].Clear;

  ExactCnt := 0;
  Near1Cnt := 0;
  Near2Cnt := 0;
  SlitCnt := 0;

  if FSmartList.Count > 0 then
  begin
    gridDies.RowCount := FSmartList.Count + 1;
    for I := 0 to FSmartList.Count - 1 do
    begin
      Item := FSmartList[I];

      case Item.MatchClass of
        sdmExactMatch: Inc(ExactCnt);
        sdmNearMatchTier1: Inc(Near1Cnt);
        sdmNearMatchTier2: Inc(Near2Cnt);
        sdmSlittingCandidate: Inc(SlitCnt);
      end;

      gridDies.Cells[0, I + 1] := Item.MatchClassName;
      gridDies.Cells[1, I + 1] := Item.Die.SerialNo;
      gridDies.Cells[2, I + 1] := FormatFloat('0.000', Item.Die.AroundSizeMm) + ' x ' + FormatFloat('0.000', Item.Die.AcrossSizeMm);

      if Item.AroundDiffMm >= 0.0 then
        DiffArStr := '+' + FormatFloat('0.000', Item.AroundDiffMm)
      else
        DiffArStr := FormatFloat('0.000', Item.AroundDiffMm);
      gridDies.Cells[3, I + 1] := DiffArStr;

      if Item.AcrossDiffMm >= 0.0 then
        DiffAcStr := '+' + FormatFloat('0.000', Item.AcrossDiffMm)
      else
        DiffAcStr := FormatFloat('0.000', Item.AcrossDiffMm);
      gridDies.Cells[4, I + 1] := DiffAcStr;

      gridDies.Cells[5, I + 1] := Format('%d x %d', [Item.Die.AroundUps, Item.Die.AcrossUps]);
      gridDies.Cells[6, I + 1] := IntToStr(Item.Die.Teeth);

      ShapeCutStr := Item.Die.Shape;
      if Item.Die.CornerRadiusMm > 0 then
        ShapeCutStr := ShapeCutStr + Format(' (R%0.1f)', [Item.Die.CornerRadiusMm]);
      gridDies.Cells[7, I + 1] := ShapeCutStr;

      gridDies.Cells[8, I + 1] := Item.Die.StatusCode;
      gridDies.Cells[9, I + 1] := Item.ReusabilityNote;

      if (Item.Die.StorageRack <> '') or (Item.Die.StorageShelf <> '') or (Item.Die.StorageBin <> '') then
        LocStr := Format('%s/%s/%s', [Item.Die.StorageRack, Item.Die.StorageShelf, Item.Die.StorageBin])
      else
        LocStr := Item.Die.StorageLocation;
      gridDies.Cells[10, I + 1] := LocStr;

      gridDies.Cells[11, I + 1] := Item.Die.CustomerName;
    end;
  end;

  lblCount.Caption := Format(
    'Smart Search: %d candidate(s) (%d exact, %d near-1mm, %d near-tol, %d slitting)',
    [FSmartList.Count, ExactCnt, Near1Cnt, Near2Cnt, SlitCnt]
  );
  lblSub3mmNotice.Caption := 'CAUTION: Geometrical size match is NOT proof of physical tooling reusability. Detailed review required.';
end;

procedure TfrmDieRegister.btnSmartSearchClick(Sender: TObject);
begin
  PerformSmartSearch;
end;

procedure TfrmDieRegister.btnClearSmartSearchClick(Sender: TObject);
begin
  FIsSmartSearch := False;
  FSmartList.Clear;
  InitGrid;
  LoadData;
  lblSub3mmNotice.Caption := Format('* Dies with around gap < %0.3f mm require production management override.', [UmToMm(FDieService.GetMinAroundGapUm)]);
end;

function TfrmDieRegister.GetSelectedDieID: Integer;
var
  Idx: Integer;
begin
  Result := 0;
  Idx := gridDies.Row - 1;
  if FIsSmartSearch then
  begin
    if (Idx >= 0) and (Idx < FSmartList.Count) then
      Result := FSmartList[Idx].Die.ID;
  end
  else
  begin
    if (Idx >= 0) and (Idx < FDieList.Count) then
      Result := FDieList[Idx].ID;
  end;
end;

function TfrmDieRegister.GetSelectedDie: TDie;
var
  Idx: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  Idx := gridDies.Row - 1;
  if FIsSmartSearch then
  begin
    if (Idx >= 0) and (Idx < FSmartList.Count) then
      Result := FSmartList[Idx].Die;
  end
  else
  begin
    if (Idx >= 0) and (Idx < FDieList.Count) then
      Result := FDieList[Idx];
  end;
end;

procedure TfrmDieRegister.FilterChange(Sender: TObject);
begin
  if FIsSmartSearch then
  begin
    if Sender = edtSearch then
    begin
      FIsSmartSearch := False;
      InitGrid;
      LoadData;
    end
    else
      PerformSmartSearch;
  end
  else
    LoadData;
end;

procedure TfrmDieRegister.btnClearFiltersClick(Sender: TObject);
begin
  edtSearch.Text := '';
  cmbCustomerFilter.ItemIndex := 0;
  cmbTeethFilter.ItemIndex := 0;
  cmbStatusFilter.ItemIndex := 0;
  cmbMediaFilter.ItemIndex := 0;
  chkOnlySub3mm.Checked := False;
  chkIncludeArchived.Checked := False;

  if FIsSmartSearch then
  begin
    FIsSmartSearch := False;
    InitGrid;
  end;

  LoadData;
end;

procedure TfrmDieRegister.btnNewClick(Sender: TObject);
var
  Editor: TfrmDieEditor;
begin
  Editor := TfrmDieEditor.Create(Self);
  try
    Editor.DieService := FDieService;
    Editor.DieID := 0;
    if Editor.ShowModal = mrOk then
    begin
      if FIsSmartSearch then
        PerformSmartSearch
      else
        LoadData;
    end;
  finally
    Editor.Free;
  end;
end;

procedure TfrmDieRegister.btnEditClick(Sender: TObject);
var
  SelectedID: Integer;
  Editor: TfrmDieEditor;
begin
  SelectedID := GetSelectedDieID;
  if SelectedID <= 0 then
  begin
    ShowMessage('Please select a die tooling record to edit.');
    Exit;
  end;

  Editor := TfrmDieEditor.Create(Self);
  try
    Editor.DieService := FDieService;
    Editor.DieID := SelectedID;
    if Editor.ShowModal = mrOk then
    begin
      if FIsSmartSearch then
        PerformSmartSearch
      else
        LoadData;
    end;
  finally
    Editor.Free;
  end;
end;

procedure TfrmDieRegister.btnViewClick(Sender: TObject);
var
  SelectedID: Integer;
  Editor: TfrmDieEditor;
begin
  SelectedID := GetSelectedDieID;
  if SelectedID <= 0 then
  begin
    ShowMessage('Please select a die tooling record to view.');
    Exit;
  end;

  Editor := TfrmDieEditor.Create(Self);
  try
    Editor.DieService := FDieService;
    Editor.DieID := SelectedID;
    Editor.ReadOnlyMode := True;
    Editor.ShowModal;
  finally
    Editor.Free;
  end;
end;

procedure TfrmDieRegister.gridDiesDblClick(Sender: TObject);
begin
  btnEditClick(Sender);
end;

procedure TfrmDieRegister.btnChangeStatusClick(Sender: TObject);
var
  SelectedID: Integer;
  SelectedDie: TDie;
  NewStatus, Reason: string;
begin
  SelectedID := GetSelectedDieID;
  if SelectedID <= 0 then
  begin
    ShowMessage('Please select a die tooling record to change status.');
    Exit;
  end;

  SelectedDie := GetSelectedDie;
  NewStatus := InputBox('Change Die Status', 'Enter new status code (e.g. AVAILABLE, IN_USE, REPAIR, SCRAPPED):', SelectedDie.StatusCode);
  if (Trim(NewStatus) = '') or (SameText(Trim(NewStatus), SelectedDie.StatusCode)) then
    Exit;

  Reason := InputBox('Status Change Reason', 'Enter reason for status change:', '');

  try
    FDieService.ChangeDieStatus(SelectedID, UpperCase(Trim(NewStatus)), Reason);
    if FIsSmartSearch then
      PerformSmartSearch
    else
      LoadData;
  except
    on E: Exception do
      ShowMessage('Error changing status: ' + E.Message);
  end;
end;

procedure TfrmDieRegister.btnRelocateClick(Sender: TObject);
var
  SelectedID: Integer;
  SelectedDie: TDie;
  Rack, Shelf, Bin, Notes: string;
begin
  SelectedID := GetSelectedDieID;
  if SelectedID <= 0 then
  begin
    ShowMessage('Please select a die tooling record to relocate.');
    Exit;
  end;

  SelectedDie := GetSelectedDie;
  Rack := InputBox('Move Tooling Location', 'Enter Storage Rack:', SelectedDie.StorageRack);
  Shelf := InputBox('Move Tooling Location', 'Enter Storage Shelf:', SelectedDie.StorageShelf);
  Bin := InputBox('Move Tooling Location', 'Enter Storage Bin:', SelectedDie.StorageBin);
  Notes := InputBox('Relocation Notes', 'Enter relocation notes / movement reason:', '');

  try
    FDieService.UpdateDieLocation(SelectedID, Rack, Shelf, Bin, Notes);
    if FIsSmartSearch then
      PerformSmartSearch
    else
      LoadData;
  except
    on E: Exception do
      ShowMessage('Error updating tooling location: ' + E.Message);
  end;
end;

procedure TfrmDieRegister.btnArchiveClick(Sender: TObject);
var
  SelectedID: Integer;
  SelectedDie: TDie;
  Reason: string;
begin
  SelectedID := GetSelectedDieID;
  if SelectedID <= 0 then
  begin
    ShowMessage('Please select a die tooling record to archive.');
    Exit;
  end;

  SelectedDie := GetSelectedDie;
  if SameText(SelectedDie.StatusCode, 'ARCHIVED') then
  begin
    ShowMessage(Format('Die tooling "%s" is already archived.', [SelectedDie.SerialNo]));
    Exit;
  end;

  if MessageDlg(Format('Archive die tooling "%s" (%s)?'#13#10#13#10 +
                       'It will be excluded from normal tooling searches and recommendations, ' +
                       'but its history, audit log, and legacy import links will be preserved.',
                       [SelectedDie.SerialNo, SelectedDie.Description]),
                mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  Reason := InputBox('Archive Tooling Reason',
                     'Enter mandatory archive reason (e.g. Artwork discontinued, Obsolete geometry):', '');
  if Trim(Reason) = '' then
  begin
    ShowMessage('Archive operation cancelled: An archive reason is required.');
    Exit;
  end;

  try
    FDieService.ArchiveDie(SelectedID, Trim(Reason));
    ShowMessage(Format('Die tooling "%s" has been successfully archived.', [SelectedDie.SerialNo]));
    if FIsSmartSearch then
      PerformSmartSearch
    else
      LoadData;
  except
    on E: Exception do
      ShowMessage('Error archiving die tooling: ' + E.Message);
  end;
end;

procedure TfrmDieRegister.btnRestoreClick(Sender: TObject);
var
  SelectedID: Integer;
  SelectedDie: TDie;
  Reason: string;
begin
  SelectedID := GetSelectedDieID;
  if SelectedID <= 0 then
  begin
    ShowMessage('Please select a die tooling record to restore.');
    Exit;
  end;

  SelectedDie := GetSelectedDie;
  if not SameText(SelectedDie.StatusCode, 'ARCHIVED') then
  begin
    ShowMessage(Format('Die tooling "%s" is currently "%s".'#13#10 +
                       'Only archived tooling records can be restored.',
                       [SelectedDie.SerialNo, SelectedDie.StatusCode]));
    Exit;
  end;

  if MessageDlg(Format('Restore die tooling "%s" (%s) to active tooling status?'#13#10#13#10 +
                       'It will become available again in active tooling searches and calculator recommendations.',
                       [SelectedDie.SerialNo, SelectedDie.Description]),
                mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  Reason := InputBox('Restore Tooling Reason',
                     'Enter restore reason (optional, press OK to accept default):',
                     'Reactivated for production');
  if Trim(Reason) = '' then
    Reason := 'Reactivated for production';

  try
    FDieService.RestoreDie(SelectedID, Trim(Reason));
    ShowMessage(Format('Die tooling "%s" has been successfully restored to ACTIVE status.', [SelectedDie.SerialNo]));
    if FIsSmartSearch then
      PerformSmartSearch
    else
      LoadData;
  except
    on E: Exception do
      ShowMessage('Error restoring die tooling: ' + E.Message);
  end;
end;

procedure TfrmDieRegister.btnPermanentDeleteClick(Sender: TObject);
var
  SelectedID: Integer;
  SelectedDie: TDie;
  RefusalReason, ConfirmPhrase: string;
begin
  SelectedID := GetSelectedDieID;
  if SelectedID <= 0 then
  begin
    ShowMessage('Please select a die tooling record.');
    Exit;
  end;

  SelectedDie := GetSelectedDie;

  // Pre-flight check: Can this record be permanently deleted?
  if not FDieService.CanPermanentlyDeleteDie(SelectedID, RefusalReason) then
  begin
    MessageDlg(Format('Cannot permanently delete die tooling "%s" (%s):'#13#10#13#10 +
                      '%s'#13#10#13#10 +
                      'To retire this die safely while preserving historical integrity, ' +
                      'please use "Archive Tooling..." instead.',
                      [SelectedDie.SerialNo, SelectedDie.Description, RefusalReason]),
               mtWarning, [mbOK], 0);
    Exit;
  end;

  // Strict double confirmation for permanent deletion
  if MessageDlg(Format('PERMANENT DELETION WARNING:'#13#10#13#10 +
                       'Die tooling "%s" (%s) and all its specifications will be permanently and irreversibly removed from the database.'#13#10#13#10 +
                       'Are you absolutely sure you want to proceed?',
                       [SelectedDie.SerialNo, SelectedDie.Description]),
                mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  ConfirmPhrase := InputBox('Confirm Permanent Deletion',
                            'Type DELETE in uppercase to authorize permanent removal:', '');
  if ConfirmPhrase <> 'DELETE' then
  begin
    ShowMessage('Permanent deletion cancelled. Confirmation phrase did not match.');
    Exit;
  end;

  try
    FDieService.PermanentlyDeleteDie(SelectedID, True);
    ShowMessage(Format('Die tooling "%s" has been permanently removed.', [SelectedDie.SerialNo]));
    if FIsSmartSearch then
      PerformSmartSearch
    else
      LoadData;
  except
    on E: Exception do
      ShowMessage('Error deleting die tooling: ' + E.Message);
  end;
end;

procedure TfrmDieRegister.btnRefreshClick(Sender: TObject);
begin
  if FIsSmartSearch then
    PerformSmartSearch
  else
    LoadData;
end;

procedure TfrmDieRegister.btnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmDieRegister.btnPrintCardClick(Sender: TObject);
var
  SelectedID: Integer;
  RepSvc: TDieVixReportService;
begin
  SelectedID := GetSelectedDieID;
  if SelectedID <= 0 then
  begin
    MessageDlg('Please select a rotary die from the list to print its Job Bag Card.', mtInformation, [mbOK], 0);
    Exit;
  end;

  RepSvc := TDieVixReportService.Create;
  try
    RepSvc.PreviewToolingCard(SelectedID);
  finally
    RepSvc.Free;
  end;
end;

procedure TfrmDieRegister.btnPrintCatalogClick(Sender: TObject);
var
  RepSvc: TDieVixReportService;
begin
  RepSvc := TDieVixReportService.Create;
  try
    RepSvc.PreviewRegisterCatalog(GetCurrentFilter);
  finally
    RepSvc.Free;
  end;
end;

procedure TfrmDieRegister.btnExportXlsxClick(Sender: TObject);
var
  SaveDlg: TSaveDialog;
  RepSvc: TDieVixReportService;
begin
  SaveDlg := TSaveDialog.Create(nil);
  try
    SaveDlg.Title := 'Export Die Register Catalog to Excel';
    SaveDlg.Filter := 'Excel Workbook (*.xlsx)|*.xlsx|All Files (*.*)|*.*';
    SaveDlg.DefaultExt := 'xlsx';
    SaveDlg.FileName := 'DieVix_Register_Catalog_' + FormatDateTime('yyyymmdd', Now) + '.xlsx';
    if SaveDlg.Execute then
    begin
      RepSvc := TDieVixReportService.Create;
      try
        if RepSvc.ExportRegisterCatalogXlsx(GetCurrentFilter, SaveDlg.FileName) then
          MessageDlg('Die register catalog successfully exported to:' + #13#10 + SaveDlg.FileName, mtInformation, [mbOK], 0)
        else
          MessageDlg('Failed to export catalog to Excel.', mtError, [mbOK], 0);
      finally
        RepSvc.Free;
      end;
    end;
  finally
    SaveDlg.Free;
  end;
end;

procedure TfrmDieRegister.btnFleetMatrixClick(Sender: TObject);
var
  RepSvc: TDieVixReportService;
begin
  RepSvc := TDieVixReportService.Create;
  try
    RepSvc.PreviewFleetMatrix;
  finally
    RepSvc.Free;
  end;
end;

end.
