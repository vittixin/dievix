unit frmDieEditor;

{==============================================================================
  DieVix – Rotary Die & Keyline Manager
  Die Tooling Add/Edit Form
  Provides live integer micrometre calculations, gap warning badges,
  similar die reuse scanner, and audit trail inspection.
==============================================================================}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, Vcl.Grids, System.Generics.Collections, System.UITypes,
  DieVix.Domain, DieVix.DieService, DieVix.CalculationEngine;

type
  TfrmDieEditor = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblStatusBadge: TLabel;
    pnlBottom: TPanel;
    btnSave: TButton;
    btnCancel: TButton;
    btnCheckSimilar: TButton;
    pageDie: TPageControl;
    tabGeometry: TTabSheet;
    tabInventory: TTabSheet;
    tabAudit: TTabSheet;
    tabSimilar: TTabSheet;
    grpIdentification: TGroupBox;
    lblSerial: TLabel;
    edtSerial: TEdit;
    lblCustomer: TLabel;
    cmbCustomer: TComboBox;
    lblDescription: TLabel;
    edtDescription: TEdit;
    lblInternalRef: TLabel;
    edtInternalRef: TEdit;
    lblCustomerRef: TLabel;
    edtCustomerRef: TEdit;
    lblMedia: TLabel;
    cmbMedia: TComboBox;
    lblStatus: TLabel;
    cmbStatus: TComboBox;
    grpDimensions: TGroupBox;
    lblTeeth: TLabel;
    cmbTeeth: TComboBox;
    lblPitch: TLabel;
    edtPitch: TEdit;
    lblAroundSize: TLabel;
    edtAroundSize: TEdit;
    lblAcrossSize: TLabel;
    edtAcrossSize: TEdit;
    lblAroundUps: TLabel;
    edtAroundUps: TEdit;
    lblAcrossUps: TLabel;
    edtAcrossUps: TEdit;
    lblAcrossGap: TLabel;
    edtAcrossGap: TEdit;
    lblCornerRadius: TLabel;
    edtCornerRadius: TEdit;
    lblShape: TLabel;
    cmbShape: TComboBox;
    lblCutType: TLabel;
    cmbCutType: TComboBox;
    grpCalculated: TGroupBox;
    lblRepeatDisplay: TLabel;
    valRepeatMm: TLabel;
    valRepeatInch: TLabel;
    lblAroundGapDisplay: TLabel;
    valAroundGapMm: TLabel;
    valGapStatus: TLabel;
    lblCutPoolDisplay: TLabel;
    valCutLengthMm: TLabel;
    lblWasteDisplay: TLabel;
    valWastePercent: TLabel;
    lblOverrideReason: TLabel;
    edtOverrideReason: TEdit;
    lblFormulaExpl: TLabel;
    grpStorage: TGroupBox;
    lblRack: TLabel;
    edtStorageRack: TEdit;
    lblShelf: TLabel;
    edtStorageShelf: TEdit;
    lblBin: TLabel;
    edtStorageBin: TEdit;
    lblLocationNotes: TLabel;
    edtLocationNotes: TEdit;
    grpProcurement: TGroupBox;
    lblDieMaker: TLabel;
    edtDieMaker: TEdit;
    lblSupplierRef: TLabel;
    edtSupplierRef: TEdit;
    lblTotalRun: TLabel;
    edtTotalRun: TEdit;
    lblPurchaseDate: TLabel;
    edtPurchaseDate: TEdit;
    lblReceivedDate: TLabel;
    edtReceivedDate: TEdit;
    lblNotes: TLabel;
    edtNotes: TEdit;
    pnlAuditInfo: TPanel;
    lblVersion: TLabel;
    lblCreatedBy: TLabel;
    lblUpdatedBy: TLabel;
    gridAudit: TStringGrid;
    pnlSimilarHeader: TPanel;
    lblSimilarInfo: TLabel;
    gridSimilar: TStringGrid;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure ControlChange(Sender: TObject);
    procedure DimensionChange(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnCheckSimilarClick(Sender: TObject);
  private
    FDieService: TDieService;
    FDieID: Integer;
    FVersion: Integer;
    FIsDirty: Boolean;
    FReadOnly: Boolean;
    FLoading: Boolean;
    FCustomerIDs: TList<Integer>;
    FMediaIDs: TList<Integer>;
    procedure SetDieID(const Value: Integer);
    procedure SetReadOnlyMode(const Value: Boolean);
    procedure LoadLookups;
    procedure ClearForm;
    procedure LoadDieData;
    procedure CalculateLive;
    procedure RefreshAuditGrid;
    procedure InitGrids;
  public
    property DieService: TDieService read FDieService write FDieService;
    property DieID: Integer read FDieID write SetDieID;
    property ReadOnlyMode: Boolean read FReadOnly write SetReadOnlyMode;
  end;

var
  FormDieEditor: TfrmDieEditor;

implementation

{$R *.dfm}

{ TfrmDieEditor }

procedure TfrmDieEditor.FormCreate(Sender: TObject);
begin
  FCustomerIDs := TList<Integer>.Create;
  FMediaIDs := TList<Integer>.Create;
  FIsDirty := False;
  FReadOnly := False;
  FLoading := False;
  FVersion := 1;

  if not Assigned(FDieService) then
    FDieService := TDieService.Create;

  InitGrids;
  LoadLookups;
  ClearForm;
  CalculateLive;
end;

procedure TfrmDieEditor.FormDestroy(Sender: TObject);
begin
  FCustomerIDs.Free;
  FMediaIDs.Free;
end;

procedure TfrmDieEditor.InitGrids;
begin
  // Audit Grid
  gridAudit.ColCount := 7;
  gridAudit.RowCount := 2;
  gridAudit.FixedRows := 1;
  gridAudit.FixedCols := 0;
  gridAudit.Cells[0, 0] := 'Date/Time';
  gridAudit.Cells[1, 0] := 'Action';
  gridAudit.Cells[2, 0] := 'Field';
  gridAudit.Cells[3, 0] := 'Old Value';
  gridAudit.Cells[4, 0] := 'New Value';
  gridAudit.Cells[5, 0] := 'User';
  gridAudit.Cells[6, 0] := 'Details / Override Reason';

  gridAudit.ColWidths[0] := 130;
  gridAudit.ColWidths[1] := 110;
  gridAudit.ColWidths[2] := 100;
  gridAudit.ColWidths[3] := 100;
  gridAudit.ColWidths[4] := 100;
  gridAudit.ColWidths[5] := 90;
  gridAudit.ColWidths[6] := 200;

  // Similar Dies Grid
  gridSimilar.ColCount := 8;
  gridSimilar.RowCount := 2;
  gridSimilar.FixedRows := 1;
  gridSimilar.FixedCols := 0;
  gridSimilar.Cells[0, 0] := 'Die Serial';
  gridSimilar.Cells[1, 0] := 'Match Type';
  gridSimilar.Cells[2, 0] := 'Teeth';
  gridSimilar.Cells[3, 0] := 'Around (mm)';
  gridSimilar.Cells[4, 0] := 'Across (mm)';
  gridSimilar.Cells[5, 0] := 'Ups (Ar x Ac)';
  gridSimilar.Cells[6, 0] := 'Status';
  gridSimilar.Cells[7, 0] := 'Match Description';

  gridSimilar.ColWidths[0] := 110;
  gridSimilar.ColWidths[1] := 110;
  gridSimilar.ColWidths[2] := 55;
  gridSimilar.ColWidths[3] := 80;
  gridSimilar.ColWidths[4] := 80;
  gridSimilar.ColWidths[5] := 80;
  gridSimilar.ColWidths[6] := 90;
  gridSimilar.ColWidths[7] := 220;
end;

procedure TfrmDieEditor.LoadLookups;
var
  Custs: TList<TCustomer>;
  MediaList: TList<TMedia>;
  Cyls: TList<TCylinder>;
  Statuses: TList<TDieStatus>;
  I: Integer;
begin
  // Customers
  cmbCustomer.Clear;
  FCustomerIDs.Clear;
  cmbCustomer.Items.Add('(None)');
  FCustomerIDs.Add(0);

  Custs := FDieService.GetActiveCustomers;
  try
    for I := 0 to Custs.Count - 1 do
    begin
      cmbCustomer.Items.Add(Custs[I].Name);
      FCustomerIDs.Add(Custs[I].ID);
    end;
  finally
    Custs.Free;
  end;
  cmbCustomer.ItemIndex := 0;

  // Media
  cmbMedia.Clear;
  FMediaIDs.Clear;
  cmbMedia.Items.Add('(None)');
  FMediaIDs.Add(0);

  MediaList := FDieService.GetActiveMedia;
  try
    for I := 0 to MediaList.Count - 1 do
    begin
      cmbMedia.Items.Add(MediaList[I].Name);
      FMediaIDs.Add(MediaList[I].ID);
    end;
  finally
    MediaList.Free;
  end;
  cmbMedia.ItemIndex := 0;

  // Cylinders (Fleet teeth)
  cmbTeeth.Clear;
  Cyls := FDieService.GetActiveCylinders;
  try
    for I := 0 to Cyls.Count - 1 do
      cmbTeeth.Items.Add(IntToStr(Cyls[I].Teeth));
  finally
    Cyls.Free;
  end;
  if cmbTeeth.Items.Count > 0 then
    cmbTeeth.ItemIndex := 8; // Default 96T

  // Statuses
  cmbStatus.Clear;
  Statuses := FDieService.GetAllStatuses;
  try
    for I := 0 to Statuses.Count - 1 do
      cmbStatus.Items.Add(Statuses[I].Code);
  finally
    Statuses.Free;
  end;
  if cmbStatus.Items.IndexOf('AVAILABLE') >= 0 then
    cmbStatus.ItemIndex := cmbStatus.Items.IndexOf('AVAILABLE')
  else if cmbStatus.Items.IndexOf('ACTIVE') >= 0 then
    cmbStatus.ItemIndex := cmbStatus.Items.IndexOf('ACTIVE')
  else if cmbStatus.Items.Count > 0 then
    cmbStatus.ItemIndex := 0;
end;

procedure TfrmDieEditor.ClearForm;
begin
  FLoading := True;
  try
    FDieID := 0;
    FVersion := 1;
    lblTitle.Caption := 'New Die Tooling Definition';
    edtSerial.Text := '';
    edtDescription.Text := '';
    edtInternalRef.Text := '';
    edtCustomerRef.Text := '';
    if cmbCustomer.Items.Count > 0 then cmbCustomer.ItemIndex := 0;
    if cmbMedia.Items.Count > 0 then cmbMedia.ItemIndex := 0;

    if cmbTeeth.Items.IndexOf('96') >= 0 then
      cmbTeeth.ItemIndex := cmbTeeth.Items.IndexOf('96')
    else if cmbTeeth.Items.Count > 0 then
      cmbTeeth.ItemIndex := 0;

    edtPitch.Text := '3175';
    edtAroundSize.Text := '50.000';
    edtAcrossSize.Text := '50.000';
    edtAroundUps.Text := '1';
    edtAcrossUps.Text := '1';
    edtAcrossGap.Text := '3.000';
    edtCornerRadius.Text := '2.000';
    cmbShape.ItemIndex := 0;
    cmbCutType.ItemIndex := 0;
    edtOverrideReason.Text := '';

    edtStorageRack.Text := '';
    edtStorageShelf.Text := '';
    edtStorageBin.Text := '';
    edtLocationNotes.Text := '';
    edtDieMaker.Text := '';
    edtSupplierRef.Text := '';
    edtTotalRun.Text := '0';
    edtPurchaseDate.Text := '';
    edtReceivedDate.Text := '';
    edtNotes.Text := '';

    lblVersion.Caption := 'Version: 1';
    lblCreatedBy.Caption := 'Created: (New)';
    lblUpdatedBy.Caption := 'Modified: (New)';
    FIsDirty := False;
  finally
    FLoading := False;
  end;
  CalculateLive;
end;

procedure TfrmDieEditor.SetDieID(const Value: Integer);
begin
  FDieID := Value;
  if FDieID > 0 then
    LoadDieData
  else
    ClearForm;
end;

procedure TfrmDieEditor.SetReadOnlyMode(const Value: Boolean);
begin
  FReadOnly := Value;
  btnSave.Enabled := not FReadOnly;
  edtSerial.ReadOnly := FReadOnly;
  edtDescription.ReadOnly := FReadOnly;
  edtInternalRef.ReadOnly := FReadOnly;
  edtCustomerRef.ReadOnly := FReadOnly;
  cmbCustomer.Enabled := not FReadOnly;
  cmbMedia.Enabled := not FReadOnly;
  cmbStatus.Enabled := not FReadOnly;
  cmbTeeth.Enabled := not FReadOnly;
  edtPitch.ReadOnly := FReadOnly;
  edtAroundSize.ReadOnly := FReadOnly;
  edtAcrossSize.ReadOnly := FReadOnly;
  edtAroundUps.ReadOnly := FReadOnly;
  edtAcrossUps.ReadOnly := FReadOnly;
  edtAcrossGap.ReadOnly := FReadOnly;
  edtCornerRadius.ReadOnly := FReadOnly;
  cmbShape.Enabled := not FReadOnly;
  cmbCutType.Enabled := not FReadOnly;
  edtOverrideReason.ReadOnly := FReadOnly;

  edtStorageRack.ReadOnly := FReadOnly;
  edtStorageShelf.ReadOnly := FReadOnly;
  edtStorageBin.ReadOnly := FReadOnly;
  edtLocationNotes.ReadOnly := FReadOnly;
  edtDieMaker.ReadOnly := FReadOnly;
  edtSupplierRef.ReadOnly := FReadOnly;
  edtTotalRun.ReadOnly := FReadOnly;
  edtPurchaseDate.ReadOnly := FReadOnly;
  edtReceivedDate.ReadOnly := FReadOnly;
  edtNotes.ReadOnly := FReadOnly;

  if FReadOnly then
    lblTitle.Caption := 'View Die Tooling (Read-Only)';
end;

procedure TfrmDieEditor.LoadDieData;
var
  Die: TDie;
  Idx: Integer;
begin
  FLoading := True;
  try
    Die := FDieService.GetDieByID(FDieID);
    if Die.ID = 0 then
    begin
      ShowMessage('Die not found with ID ' + IntToStr(FDieID));
      Exit;
    end;

    FVersion := Die.Version;
    lblTitle.Caption := 'Edit Die: ' + Die.SerialNo;
    edtSerial.Text := Die.SerialNo;
    edtDescription.Text := Die.Description;
    edtInternalRef.Text := Die.InternalRef;
    edtCustomerRef.Text := Die.CustomerRef;

    // Customer
    Idx := FCustomerIDs.IndexOf(Die.CustomerID);
    if Idx >= 0 then cmbCustomer.ItemIndex := Idx else cmbCustomer.ItemIndex := 0;

    // Media
    Idx := FMediaIDs.IndexOf(Die.MediaID);
    if Idx >= 0 then cmbMedia.ItemIndex := Idx else cmbMedia.ItemIndex := 0;

    // Status
    Idx := cmbStatus.Items.IndexOf(Die.StatusCode);
    if Idx >= 0 then cmbStatus.ItemIndex := Idx;

    // Teeth
    Idx := cmbTeeth.Items.IndexOf(IntToStr(Die.Teeth));
    if Idx >= 0 then
      cmbTeeth.ItemIndex := Idx
    else
    begin
      cmbTeeth.Items.Add(IntToStr(Die.Teeth));
      cmbTeeth.ItemIndex := cmbTeeth.Items.Count - 1;
    end;

    edtPitch.Text := IntToStr(Die.PitchUm);
    edtAroundSize.Text := FormatFloat('0.000', Die.AroundSizeMm);
    edtAcrossSize.Text := FormatFloat('0.000', Die.AcrossSizeMm);
    edtAroundUps.Text := IntToStr(Die.AroundUps);
    edtAcrossUps.Text := IntToStr(Die.AcrossUps);
    edtAcrossGap.Text := FormatFloat('0.000', Die.AcrossGapMm);
    edtCornerRadius.Text := FormatFloat('0.000', Die.CornerRadiusMm);

    Idx := cmbShape.Items.IndexOf(Die.Shape);
    if Idx >= 0 then cmbShape.ItemIndex := Idx else cmbShape.ItemIndex := 0;

    Idx := cmbCutType.Items.IndexOf(Die.CutType);
    if Idx >= 0 then cmbCutType.ItemIndex := Idx else cmbCutType.ItemIndex := 0;

    edtOverrideReason.Text := Die.OverrideReason;

    // Storage
    edtStorageRack.Text := Die.StorageRack;
    edtStorageShelf.Text := Die.StorageShelf;
    edtStorageBin.Text := Die.StorageBin;
    edtLocationNotes.Text := Die.StorageLocation;

    // Procurement
    edtDieMaker.Text := Die.DieMaker;
    edtSupplierRef.Text := Die.SupplierRef;
    edtTotalRun.Text := IntToStr(Die.TotalRunMetres);
    if Die.PurchaseDate > 0 then
      edtPurchaseDate.Text := FormatDateTime('yyyy-mm-dd', Die.PurchaseDate)
    else
      edtPurchaseDate.Text := '';

    if Die.ReceivedDate > 0 then
      edtReceivedDate.Text := FormatDateTime('yyyy-mm-dd', Die.ReceivedDate)
    else
      edtReceivedDate.Text := '';

    edtNotes.Text := Die.Notes;

    // History & Concurrency
    lblVersion.Caption := 'Version: ' + IntToStr(Die.Version);
    lblCreatedBy.Caption := Format('Created: %s by %s', [FormatDateTime('yyyy-mm-dd hh:nn', Die.CreatedAt), Die.CreatedBy]);
    lblUpdatedBy.Caption := Format('Modified: %s by %s', [FormatDateTime('yyyy-mm-dd hh:nn', Die.UpdatedAt), Die.UpdatedBy]);

    RefreshAuditGrid;
    FIsDirty := False;
  finally
    FLoading := False;
  end;
  CalculateLive;
end;

procedure TfrmDieEditor.RefreshAuditGrid;
var
  LogList: TList<TDieAuditEntry>;
  I: Integer;
begin
  gridAudit.RowCount := 2;
  gridAudit.Rows[1].Clear;

  if FDieID = 0 then
    Exit;

  LogList := FDieService.GetDieAuditHistory(FDieID);
  try
    if LogList.Count > 0 then
    begin
      gridAudit.RowCount := LogList.Count + 1;
      for I := 0 to LogList.Count - 1 do
      begin
        gridAudit.Cells[0, I + 1] := FormatDateTime('yyyy-mm-dd hh:nn:ss', LogList[I].ChangedAt);
        gridAudit.Cells[1, I + 1] := LogList[I].Action;
        gridAudit.Cells[2, I + 1] := LogList[I].FieldName;
        gridAudit.Cells[3, I + 1] := LogList[I].OldValue;
        gridAudit.Cells[4, I + 1] := LogList[I].NewValue;
        gridAudit.Cells[5, I + 1] := LogList[I].ChangedBy;
        if LogList[I].OverrideReason <> '' then
          gridAudit.Cells[6, I + 1] := LogList[I].OverrideReason + ' (' + LogList[I].Details + ')'
        else
          gridAudit.Cells[6, I + 1] := LogList[I].Details;
      end;
    end;
  finally
    LogList.Free;
  end;
end;

procedure TfrmDieEditor.ControlChange(Sender: TObject);
begin
  if not FLoading then
    FIsDirty := True;
end;

procedure TfrmDieEditor.DimensionChange(Sender: TObject);
begin
  if not FLoading then
  begin
    FIsDirty := True;
    CalculateLive;
  end;
end;

procedure TfrmDieEditor.CalculateLive;
var
  Teeth, AroundUps, PitchUm: Integer;
  AroundSizeMm: Double;
  GapRes: TGapResult;
  TotalCutMm: Double;
begin
  Teeth := StrToIntDef(cmbTeeth.Text, 0);
  AroundUps := StrToIntDef(edtAroundUps.Text, 1);
  AroundSizeMm := StrToFloatDef(edtAroundSize.Text, 0.0);
  PitchUm := StrToIntDef(edtPitch.Text, 3175);

  if (Teeth <= 0) or (AroundUps <= 0) or (AroundSizeMm <= 0.0) then
  begin
    valRepeatMm.Caption := '-';
    valRepeatInch.Caption := '';
    valAroundGapMm.Caption := '-';
    valGapStatus.Caption := 'INVALID INPUT';
    valGapStatus.Color := clGray;
    valCutLengthMm.Caption := '-';
    valWastePercent.Caption := '-';
    Exit;
  end;

  GapRes := FDieService.CalculateDieGeometry(Teeth, AroundSizeMm, AroundUps, PitchUm);

  valRepeatMm.Caption := FormatFloat('0.000 mm', GapRes.CylinderRepeatMm);
  valRepeatInch.Caption := FormatFloat('(0.000")', GapRes.CylinderRepeatInch);
  valAroundGapMm.Caption := FormatFloat('0.000 mm', GapRes.AroundGapMm);
  TotalCutMm := (AroundUps * AroundSizeMm);
  valCutLengthMm.Caption := FormatFloat('0.000 mm', TotalCutMm);
  valWastePercent.Caption := FormatFloat('0.00 %', GapRes.WastePercent);

  case GapRes.Status of
    gsOptimal, gsStandardApproved:
    begin
      valGapStatus.Caption := 'APPROVED (>= 3.0 mm)';
      valGapStatus.Color := $002E7D32; // Rich Green
      valGapStatus.Font.Color := clWhite;
      edtOverrideReason.Color := clWindow;
      lblStatusBadge.Caption := 'APPROVED';
      lblStatusBadge.Color := $002E7D32;
    end;

    gsSubStandardWarning:
    begin
      valGapStatus.Caption := 'WARNING: SUB-3MM';
      valGapStatus.Color := $0000A5FF; // Orange
      valGapStatus.Font.Color := clWhite;
      edtOverrideReason.Color := $00E1FFFF; // Pale yellow/orange tint
      lblStatusBadge.Caption := 'OVERRIDE REQ';
      lblStatusBadge.Color := $0000A5FF;
    end;

    gsMechanicallyRejected:
    begin
      valGapStatus.Caption := 'REJECTED: IMPOSSIBLE';
      valGapStatus.Color := $002222B2; // Rich Red
      valGapStatus.Font.Color := clWhite;
      edtOverrideReason.Color := $00E8E8FF;
      lblStatusBadge.Caption := 'REJECTED';
      lblStatusBadge.Color := $002222B2;
    end;
  end;
end;

procedure TfrmDieEditor.btnCheckSimilarClick(Sender: TObject);
var
  Teeth, AroundUps, AcrossUps: Integer;
  AroundMm, AcrossMm: Double;
  Shape: string;
  Matches: TList<TSimilarDieResult>;
  I: Integer;
  TypeStr: string;
begin
  Teeth := StrToIntDef(cmbTeeth.Text, 0);
  AroundUps := StrToIntDef(edtAroundUps.Text, 1);
  AcrossUps := StrToIntDef(edtAcrossUps.Text, 1);
  AroundMm := StrToFloatDef(edtAroundSize.Text, 0.0);
  AcrossMm := StrToFloatDef(edtAcrossSize.Text, 0.0);
  Shape := cmbShape.Text;

  if (Teeth <= 0) or (AroundMm <= 0.0) or (AcrossMm <= 0.0) then
  begin
    ShowMessage('Please specify valid teeth and label dimensions before scanning for similar tooling.');
    Exit;
  end;

  Matches := FDieService.FindSimilarDies(Teeth, AroundMm, AcrossMm, AroundUps, AcrossUps, Shape, 1.0, FDieID);
  try
    pageDie.ActivePage := tabSimilar;
    gridSimilar.RowCount := 2;
    gridSimilar.Rows[1].Clear;

    if Matches.Count = 0 then
    begin
      lblSimilarInfo.Caption := Format('No similar dies found on %dT within 1.0 mm tolerance. Clean tooling canvas!', [Teeth]);
      Exit;
    end;

    lblSimilarInfo.Caption := Format('Found %d existing dies on %dT within 1.0 mm tolerance for reuse evaluation:', [Matches.Count, Teeth]);
    gridSimilar.RowCount := Matches.Count + 1;

    for I := 0 to Matches.Count - 1 do
    begin
      gridSimilar.Cells[0, I + 1] := Matches[I].Die.SerialNo;
      case Matches[I].MatchType of
        smtExact: TypeStr := 'EXACT MATCH';
        smtReusableAlternative: TypeStr := 'REUSABLE';
        smtIncompatible: TypeStr := 'INCOMPATIBLE';
      end;
      gridSimilar.Cells[1, I + 1] := TypeStr;
      gridSimilar.Cells[2, I + 1] := IntToStr(Matches[I].Die.Teeth);
      gridSimilar.Cells[3, I + 1] := FormatFloat('0.000', Matches[I].Die.AroundSizeMm);
      gridSimilar.Cells[4, I + 1] := FormatFloat('0.000', Matches[I].Die.AcrossSizeMm);
      gridSimilar.Cells[5, I + 1] := Format('%d x %d', [Matches[I].Die.AroundUps, Matches[I].Die.AcrossUps]);
      gridSimilar.Cells[6, I + 1] := Matches[I].Die.StatusCode;
      gridSimilar.Cells[7, I + 1] := Matches[I].MatchDescription;
    end;
  finally
    Matches.Free;
  end;
end;

procedure TfrmDieEditor.btnSaveClick(Sender: TObject);
var
  Die: TDie;
  SavedID: Integer;
begin
  if FReadOnly then
    Exit;

  // Populate Die Record
  FillChar(Die, SizeOf(Die), 0);
  Die.ID := FDieID;
  Die.Version := FVersion;
  Die.SerialNo := Trim(edtSerial.Text);
  Die.Description := Trim(edtDescription.Text);
  Die.InternalRef := Trim(edtInternalRef.Text);
  Die.CustomerRef := Trim(edtCustomerRef.Text);

  if cmbCustomer.ItemIndex > 0 then
    Die.CustomerID := FCustomerIDs[cmbCustomer.ItemIndex]
  else
    Die.CustomerID := 0;

  if cmbMedia.ItemIndex > 0 then
    Die.MediaID := FMediaIDs[cmbMedia.ItemIndex]
  else
    Die.MediaID := 0;

  Die.StatusCode := Trim(cmbStatus.Text);
  Die.Teeth := StrToIntDef(cmbTeeth.Text, 0);
  Die.PitchUm := StrToIntDef(edtPitch.Text, 3175);
  Die.AroundSizeMm := StrToFloatDef(edtAroundSize.Text, 0.0);
  Die.AcrossSizeMm := StrToFloatDef(edtAcrossSize.Text, 0.0);
  Die.AroundUps := StrToIntDef(edtAroundUps.Text, 1);
  Die.AcrossUps := StrToIntDef(edtAcrossUps.Text, 1);
  Die.AcrossGapMm := StrToFloatDef(edtAcrossGap.Text, 3.000);
  Die.CornerRadiusMm := StrToFloatDef(edtCornerRadius.Text, 2.000);
  Die.Shape := Trim(cmbShape.Text);
  Die.CutType := Trim(cmbCutType.Text);
  Die.OverrideReason := Trim(edtOverrideReason.Text);

  Die.StorageRack := Trim(edtStorageRack.Text);
  Die.StorageShelf := Trim(edtStorageShelf.Text);
  Die.StorageBin := Trim(edtStorageBin.Text);
  Die.StorageLocation := Trim(edtLocationNotes.Text);

  Die.DieMaker := Trim(edtDieMaker.Text);
  Die.SupplierRef := Trim(edtSupplierRef.Text);
  Die.TotalRunMetres := StrToIntDef(edtTotalRun.Text, 0);

  if Trim(edtPurchaseDate.Text) <> '' then
    Die.PurchaseDate := StrToDateDef(Trim(edtPurchaseDate.Text), 0);

  if Trim(edtReceivedDate.Text) <> '' then
    Die.ReceivedDate := StrToDateDef(Trim(edtReceivedDate.Text), 0);

  Die.Notes := Trim(edtNotes.Text);

  try
    SavedID := FDieService.SaveDie(Die, 'OPERATOR');
    FDieID := SavedID;
    FIsDirty := False;
    ModalResult := mrOk;
  except
    on E: EDieVixDuplicateException do
    begin
      pageDie.ActivePage := tabGeometry;
      if Showing and edtSerial.CanFocus then
        edtSerial.SetFocus;
      MessageDlg(E.Message, mtError, [mbOK], 0);
    end;
    on E: EDieVixConcurrencyException do
    begin
      MessageDlg(E.Message, mtWarning, [mbOK], 0);
    end;
    on E: EDieVixValidationException do
    begin
      pageDie.ActivePage := tabGeometry;
      if (Pos('Override', E.Message) > 0) and Showing and edtOverrideReason.CanFocus then
        edtOverrideReason.SetFocus;
      MessageDlg(E.Message, mtWarning, [mbOK], 0);
    end;
    on E: Exception do
    begin
      MessageDlg('Error saving die tooling: ' + E.Message, mtError, [mbOK], 0);
    end;
  end;
end;

procedure TfrmDieEditor.btnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmDieEditor.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if FIsDirty and not FReadOnly then
  begin
    if MessageDlg('You have unsaved changes to this die. Do you wish to discard them?',
       mtConfirmation, [mbYes, mbNo], 0) = mrNo then
    begin
      CanClose := False;
      Exit;
    end;
  end;
  CanClose := True;
end;

end.
