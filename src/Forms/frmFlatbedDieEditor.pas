unit frmFlatbedDieEditor;

{==============================================================================
  DieVix - Rotary Die & Keyline Manager
  Flatbed Die Tooling Add/Edit Form
  Provides live cavity footprint calculation, category classification (Rollform
  vs Sheetform), and real-time bi-directional rotation evaluation badge.
==============================================================================}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, System.Generics.Collections, System.UITypes,
  DieVix.Domain, DieVix.FlatbedDieService, DieVix.CalculationEngine;

type
  TfrmFlatbedDieEditor = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblStatusBadge: TLabel;
    pnlBottom: TPanel;
    btnSave: TButton;
    btnCancel: TButton;
    pageDie: TPageControl;
    tabGeometry: TTabSheet;
    tabInventory: TTabSheet;
    grpIdentification: TGroupBox;
    lblSerial: TLabel;
    edtSerial: TEdit;
    btnGenerateSerial: TButton;
    lblCategory: TLabel;
    cmbCategory: TComboBox;
    lblCustomer: TLabel;
    cmbCustomer: TComboBox;
    lblDescription: TLabel;
    edtDescription: TEdit;
    lblMedia: TLabel;
    cmbMedia: TComboBox;
    grpDimensions: TGroupBox;
    lblAroundSize: TLabel;
    edtAroundSize: TEdit;
    lblAcrossSize: TLabel;
    edtAcrossSize: TEdit;
    lblAroundUps: TLabel;
    edtAroundUps: TEdit;
    lblAcrossUps: TLabel;
    edtAcrossUps: TEdit;
    lblAroundGap: TLabel;
    edtAroundGap: TEdit;
    lblAcrossGap: TLabel;
    edtAcrossGap: TEdit;
    lblCornerRadius: TLabel;
    edtCornerRadius: TEdit;
    lblShape: TLabel;
    cmbShape: TComboBox;
    lblPlateWidth: TLabel;
    edtPlateWidth: TEdit;
    lblPlateLength: TLabel;
    edtPlateLength: TEdit;
    lblMaxFeed: TLabel;
    edtMaxFeedStroke: TEdit;
    grpCalculated: TGroupBox;
    lblFootprintAround: TLabel;
    valTotalCutAround: TLabel;
    lblFootprintAcross: TLabel;
    valTotalCutAcross: TLabel;
    lblTotalUpsDisplay: TLabel;
    valTotalUps: TLabel;
    lblRotationCapability: TLabel;
    valRotationSupport: TLabel;
    pnlRuleExplanation: TPanel;
    lblRotationRuleInfo: TLabel;
    grpStorage: TGroupBox;
    lblLocation: TLabel;
    edtStorageLocation: TEdit;
    lblRack: TLabel;
    edtStorageRack: TEdit;
    lblShelf: TLabel;
    edtStorageShelf: TEdit;
    lblBin: TLabel;
    edtStorageBin: TEdit;
    grpLifecycle: TGroupBox;
    lblStatus: TLabel;
    cmbStatus: TComboBox;
    lblDieMaker: TLabel;
    edtDieMaker: TEdit;
    lblTotalImpressions: TLabel;
    edtTotalImpressions: TEdit;
    lblNotes: TLabel;
    memNotes: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure DimensionChange(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnGenerateSerialClick(Sender: TObject);
  private
    FFlatbedService: TFlatbedDieService;
    FDie: TFlatbedDie;
    FIsNew: Boolean;
    FCustomerIDs: TList<Integer>;
    FMediaIDs: TList<Integer>;
    procedure PopulateCombos;
    procedure RecalculateFootprint;
    procedure ReadControlsToDie(var ADie: TFlatbedDie);
    procedure WriteDieToControls(const ADie: TFlatbedDie);
  public
    property FlatbedService: TFlatbedDieService read FFlatbedService write FFlatbedService;
    property FlatbedDie: TFlatbedDie read FDie write FDie;
    property IsNew: Boolean read FIsNew write FIsNew;
    procedure InitForCreate(const ACategory: string = 'ROLL_FORM');
    procedure InitForEdit(const ADie: TFlatbedDie);
  end;

implementation

{$R *.dfm}

procedure TfrmFlatbedDieEditor.FormCreate(Sender: TObject);
begin
  FCustomerIDs := TList<Integer>.Create;
  FMediaIDs := TList<Integer>.Create;
end;

procedure TfrmFlatbedDieEditor.FormDestroy(Sender: TObject);
begin
  FCustomerIDs.Free;
  FMediaIDs.Free;
end;

procedure TfrmFlatbedDieEditor.PopulateCombos;
var
  Custs: TList<TCustomer>;
  MediaList: TList<TMedia>;
  Statuses: TList<TDieStatus>;
  I: Integer;
begin
  cmbCategory.Items.Clear;
  cmbCategory.Items.Add('ROLL_FORM - Continuous Rollforms');
  cmbCategory.Items.Add('SHEET_FORM - Sheetform & Booklets');
  cmbCategory.ItemIndex := 0;

  cmbCustomer.Items.Clear;
  FCustomerIDs.Clear;
  cmbCustomer.Items.Add('(None)');
  FCustomerIDs.Add(0);
  if Assigned(FFlatbedService) then
  begin
    Custs := FFlatbedService.GetActiveCustomers;
    try
      for I := 0 to Custs.Count - 1 do
      begin
        cmbCustomer.Items.Add(Format('%s - %s', [Custs[I].Code, Custs[I].Name]));
        FCustomerIDs.Add(Custs[I].ID);
      end;
    finally
      Custs.Free;
    end;
  end;
  cmbCustomer.ItemIndex := 0;

  cmbMedia.Items.Clear;
  FMediaIDs.Clear;
  cmbMedia.Items.Add('(None)');
  FMediaIDs.Add(0);
  if Assigned(FFlatbedService) then
  begin
    MediaList := FFlatbedService.GetActiveMedia;
    try
      for I := 0 to MediaList.Count - 1 do
      begin
        cmbMedia.Items.Add(Format('%s - %s', [MediaList[I].Code, MediaList[I].Name]));
        FMediaIDs.Add(MediaList[I].ID);
      end;
    finally
      MediaList.Free;
    end;
  end;
  cmbMedia.ItemIndex := 0;

  cmbStatus.Items.Clear;
  if Assigned(FFlatbedService) then
  begin
    Statuses := FFlatbedService.GetAllStatuses;
    try
      for I := 0 to Statuses.Count - 1 do
        cmbStatus.Items.Add(Statuses[I].Code);
    finally
      Statuses.Free;
    end;
  end;
  if cmbStatus.Items.IndexOf('ACTIVE') >= 0 then
    cmbStatus.ItemIndex := cmbStatus.Items.IndexOf('ACTIVE')
  else if cmbStatus.Items.Count > 0 then
    cmbStatus.ItemIndex := 0;
end;

procedure TfrmFlatbedDieEditor.InitForCreate(const ACategory: string);
begin
  FIsNew := True;
  lblTitle.Caption := 'Register New Flatbed Tooling';
  PopulateCombos;

  if SameText(Trim(ACategory), 'SHEET_FORM') or SameText(Trim(ACategory), 'SHEETFORM') then
    cmbCategory.ItemIndex := 1
  else
    cmbCategory.ItemIndex := 0;

  if Assigned(FFlatbedService) then
    edtSerial.Text := FFlatbedService.GenerateSerialNumber
  else
    edtSerial.Text := 'FBD-' + FormatDateTime('YYMMDD-HHNNSS', Now);

  edtSerial.ReadOnly := False;
  btnGenerateSerial.Enabled := True;

  edtAroundSize.Text := '75.000';
  edtAcrossSize.Text := '50.000';
  edtAroundUps.Text := '1';
  edtAcrossUps.Text := '1';
  edtAroundGap.Text := '3.000';
  edtAcrossGap.Text := '3.000';
  edtCornerRadius.Text := '2.000';
  cmbShape.ItemIndex := 0;
  edtTotalImpressions.Text := '0';

  RecalculateFootprint;
end;

procedure TfrmFlatbedDieEditor.InitForEdit(const ADie: TFlatbedDie);
begin
  FIsNew := False;
  FDie := ADie;
  lblTitle.Caption := Format('Edit Flatbed Tooling - %s', [ADie.SerialNo]);
  PopulateCombos;
  WriteDieToControls(ADie);
  RecalculateFootprint;
end;

procedure TfrmFlatbedDieEditor.DimensionChange(Sender: TObject);
begin
  RecalculateFootprint;
end;

procedure TfrmFlatbedDieEditor.RecalculateFootprint;
var
  AroundMm, AcrossMm, AroundGap, AcrossGap: Double;
  AroundUps, AcrossUps, TotalUps: Integer;
  TotalCutAround, TotalCutAcross: Double;
  Cat: string;
  CanRot: Boolean;
begin
  AroundMm := StrToFloatDef(edtAroundSize.Text, 0.0);
  AcrossMm := StrToFloatDef(edtAcrossSize.Text, 0.0);
  AroundUps := StrToIntDef(edtAroundUps.Text, 1);
  AcrossUps := StrToIntDef(edtAcrossUps.Text, 1);
  AroundGap := StrToFloatDef(edtAroundGap.Text, 3.0);
  AcrossGap := StrToFloatDef(edtAcrossGap.Text, 3.0);

  if AroundUps < 1 then AroundUps := 1;
  if AcrossUps < 1 then AcrossUps := 1;
  TotalUps := AroundUps * AcrossUps;

  TotalCutAround := (AroundUps * AroundMm) + ((AroundUps - 1) * AroundGap);
  TotalCutAcross := (AcrossUps * AcrossMm) + ((AcrossUps - 1) * AcrossGap);

  valTotalCutAround.Caption := Format('%.3f mm', [TotalCutAround]);
  valTotalCutAcross.Caption := Format('%.3f mm', [TotalCutAcross]);
  valTotalUps.Caption := Format('%d ups (%d x %d)', [TotalUps, AroundUps, AcrossUps]);

  if cmbCategory.ItemIndex = 1 then
    Cat := 'SHEET_FORM'
  else
    Cat := 'ROLL_FORM';

  CanRot := CanFlatbedDieRotate(Cat, AroundUps, AcrossUps, AroundMm, AcrossMm);

  if CanRot then
  begin
    valRotationSupport.Caption := 'BI-DIRECTIONAL (90'#176' Rotation Allowed)';
    valRotationSupport.Font.Color := 32768; // Green
  end
  else
  begin
    valRotationSupport.Caption := 'FIXED DIRECTION (Standard Loading)';
    valRotationSupport.Font.Color := clNavy;
  end;
end;

procedure TfrmFlatbedDieEditor.ReadControlsToDie(var ADie: TFlatbedDie);
begin
  ADie.SerialNo := Trim(edtSerial.Text);
  if cmbCategory.ItemIndex = 1 then
    ADie.Category := 'SHEET_FORM'
  else
    ADie.Category := 'ROLL_FORM';

  ADie.Description := Trim(edtDescription.Text);

  if (cmbCustomer.ItemIndex >= 0) and (cmbCustomer.ItemIndex < FCustomerIDs.Count) then
    ADie.CustomerID := FCustomerIDs[cmbCustomer.ItemIndex]
  else
    ADie.CustomerID := 0;

  if (cmbMedia.ItemIndex >= 0) and (cmbMedia.ItemIndex < FMediaIDs.Count) then
    ADie.MediaID := FMediaIDs[cmbMedia.ItemIndex]
  else
    ADie.MediaID := 0;

  ADie.AroundSizeMm := StrToFloatDef(edtAroundSize.Text, 0.0);
  ADie.AcrossSizeMm := StrToFloatDef(edtAcrossSize.Text, 0.0);
  ADie.AroundUps := StrToIntDef(edtAroundUps.Text, 1);
  ADie.AcrossUps := StrToIntDef(edtAcrossUps.Text, 1);
  ADie.AroundGapMm := StrToFloatDef(edtAroundGap.Text, 3.0);
  ADie.AcrossGapMm := StrToFloatDef(edtAcrossGap.Text, 3.0);
  ADie.CornerRadiusMm := StrToFloatDef(edtCornerRadius.Text, 2.0);
  ADie.Shape := Trim(cmbShape.Text);

  ADie.PlateWidthMm := StrToFloatDef(edtPlateWidth.Text, 0.0);
  ADie.PlateLengthMm := StrToFloatDef(edtPlateLength.Text, 0.0);
  ADie.MaxFeedStrokeMm := StrToFloatDef(edtMaxFeedStroke.Text, 0.0);

  ADie.StorageLocation := Trim(edtStorageLocation.Text);
  ADie.StorageRack := Trim(edtStorageRack.Text);
  ADie.StorageShelf := Trim(edtStorageShelf.Text);
  ADie.StorageBin := Trim(edtStorageBin.Text);

  if cmbStatus.ItemIndex >= 0 then
    ADie.StatusCode := Trim(cmbStatus.Text)
  else
    ADie.StatusCode := 'ACTIVE';

  ADie.DieMaker := Trim(edtDieMaker.Text);
  ADie.TotalImpressions := StrToIntDef(edtTotalImpressions.Text, 0);
  ADie.Notes := Trim(memNotes.Text);

  if Assigned(FFlatbedService) then
    FFlatbedService.CalculateFootprint(ADie);
end;

procedure TfrmFlatbedDieEditor.WriteDieToControls(const ADie: TFlatbedDie);
var
  Idx: Integer;
begin
  edtSerial.Text := ADie.SerialNo;
  edtSerial.ReadOnly := not FIsNew;
  btnGenerateSerial.Enabled := FIsNew;

  if SameText(ADie.Category, 'SHEET_FORM') or SameText(ADie.Category, 'SHEETFORM') then
    cmbCategory.ItemIndex := 1
  else
    cmbCategory.ItemIndex := 0;

  edtDescription.Text := ADie.Description;

  Idx := FCustomerIDs.IndexOf(ADie.CustomerID);
  if Idx >= 0 then cmbCustomer.ItemIndex := Idx else cmbCustomer.ItemIndex := 0;

  Idx := FMediaIDs.IndexOf(ADie.MediaID);
  if Idx >= 0 then cmbMedia.ItemIndex := Idx else cmbMedia.ItemIndex := 0;

  edtAroundSize.Text := Format('%.3f', [ADie.AroundSizeMm]);
  edtAcrossSize.Text := Format('%.3f', [ADie.AcrossSizeMm]);
  edtAroundUps.Text := IntToStr(ADie.AroundUps);
  edtAcrossUps.Text := IntToStr(ADie.AcrossUps);
  edtAroundGap.Text := Format('%.3f', [ADie.AroundGapMm]);
  edtAcrossGap.Text := Format('%.3f', [ADie.AcrossGapMm]);
  edtCornerRadius.Text := Format('%.3f', [ADie.CornerRadiusMm]);

  Idx := cmbShape.Items.IndexOf(ADie.Shape);
  if Idx >= 0 then cmbShape.ItemIndex := Idx else cmbShape.ItemIndex := 0;

  if ADie.PlateWidthMm > 0 then
    edtPlateWidth.Text := Format('%.3f', [ADie.PlateWidthMm])
  else
    edtPlateWidth.Text := '';

  if ADie.PlateLengthMm > 0 then
    edtPlateLength.Text := Format('%.3f', [ADie.PlateLengthMm])
  else
    edtPlateLength.Text := '';

  if ADie.MaxFeedStrokeMm > 0 then
    edtMaxFeedStroke.Text := Format('%.3f', [ADie.MaxFeedStrokeMm])
  else
    edtMaxFeedStroke.Text := '';

  edtStorageLocation.Text := ADie.StorageLocation;
  edtStorageRack.Text := ADie.StorageRack;
  edtStorageShelf.Text := ADie.StorageShelf;
  edtStorageBin.Text := ADie.StorageBin;

  Idx := cmbStatus.Items.IndexOf(ADie.StatusCode);
  if Idx >= 0 then cmbStatus.ItemIndex := Idx;

  edtDieMaker.Text := ADie.DieMaker;
  edtTotalImpressions.Text := IntToStr(ADie.TotalImpressions);
  memNotes.Text := ADie.Notes;
  lblStatusBadge.Caption := ADie.StatusCode;
end;

procedure TfrmFlatbedDieEditor.btnGenerateSerialClick(Sender: TObject);
begin
  if not FIsNew then
  begin
    MessageDlg('Serial number cannot be regenerated for an existing saved tooling.', mtInformation, [mbOK], 0);
    Exit;
  end;

  if Assigned(FFlatbedService) then
    edtSerial.Text := FFlatbedService.GenerateSerialNumber
  else
    edtSerial.Text := 'FBD-' + FormatDateTime('YYMMDD-HHNNSS', Now);
end;

procedure TfrmFlatbedDieEditor.btnSaveClick(Sender: TObject);
var
  SavedID: Integer;
begin
  ReadControlsToDie(FDie);
  try
    SavedID := FFlatbedService.SaveFlatbedDie(FDie, GetCurrentAppUser);
    FDie.ID := SavedID;
    ModalResult := mrOk;
  except
    on E: Exception do
    begin
      MessageDlg('Failed to save flatbed tooling:' + sLineBreak + sLineBreak + E.Message, mtError, [mbOK], 0);
    end;
  end;
end;

end.
