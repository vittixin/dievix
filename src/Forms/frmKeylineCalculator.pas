unit frmKeylineCalculator;

{==============================================================================
  DieVix - Rotary Die & Keyline Manager
  Keyline Calculator & Rotary Layout Designer Form
  Implements Phase 4:
  - Exact integer-micrometre rotary repeat calculations
  - Cylinder fleet optimization from Firebird database
  - Machine compatibility and web-fit validation
  - Dimensionally faithful 2D visual layout preview
  - Existing die reuse integration via Smart Die Size Finder
  - "Create Die From Selection" draft generation without silent saving
==============================================================================}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Grids,
  Vcl.ExtCtrls, System.Generics.Collections, System.Math, System.UITypes,
  DieVix.Domain, DieVix.CalculationEngine, DieVix.KeylineService, DieVix.DieService,
  frmDieEditor;

type
  TfrmKeylineCalculator = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlLeft: TPanel;
    grpDimensions: TGroupBox;
    lblAroundSize: TLabel;
    lblAcrossSize: TLabel;
    lblShape: TLabel;
    lblCornerRadius: TLabel;
    edtAroundSize: TEdit;
    edtAcrossSize: TEdit;
    cmbShape: TComboBox;
    edtCornerRadius: TEdit;
    grpPress: TGroupBox;
    lblMachine: TLabel;
    lblCustomer: TLabel;
    cmbMachine: TComboBox;
    cmbCustomer: TComboBox;
    grpLayout: TGroupBox;
    lblMaxUps: TLabel;
    lblFixedUps: TLabel;
    lblAcrossUps: TLabel;
    rgUpsMode: TRadioGroup;
    edtMaxUps: TEdit;
    edtFixedUps: TEdit;
    edtAcrossUps: TEdit;
    grpGaps: TGroupBox;
    lblMinAroundGap: TLabel;
    lblAcrossGap: TLabel;
    lblMargins: TLabel;
    edtMinAroundGap: TEdit;
    edtAcrossGap: TEdit;
    edtLeftMargin: TEdit;
    edtRightMargin: TEdit;
    chkActiveCylinders: TCheckBox;
    pnlCalculateButtons: TPanel;
    btnCalculate: TButton;
    btnReset: TButton;
    pnlCenterArea: TPanel;
    splBottom: TSplitter;
    pnlRecommendations: TPanel;
    pnlRecHeader: TPanel;
    lblRecTitle: TLabel;
    lblRecSummary: TLabel;
    gridRecommendations: TStringGrid;
    splPreview: TSplitter;
    pnlRightPreview: TPanel;
    pnlPreviewToolbar: TPanel;
    lblPreviewTitle: TLabel;
    btnFit: TButton;
    btnZoomIn: TButton;
    btnZoomOut: TButton;
    chkShowDimensions: TCheckBox;
    pnlPreviewCanvas: TPanel;
    paintPreview: TPaintBox;
    lblPreviewFootnote: TLabel;
    pnlBottom: TPanel;
    pnlBottomHeader: TPanel;
    lblBottomTitle: TLabel;
    lblMatchCount: TLabel;
    gridExistingDies: TStringGrid;
    pnlBottomActions: TPanel;
    btnCreateDie: TButton;
    btnOpenExistingDie: TButton;
    btnClose: TButton;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure rgUpsModeClick(Sender: TObject);
    procedure btnCalculateClick(Sender: TObject);
    procedure btnResetClick(Sender: TObject);
    procedure gridRecommendationsDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure gridRecommendationsSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
    procedure btnFitClick(Sender: TObject);
    procedure btnZoomInClick(Sender: TObject);
    procedure btnZoomOutClick(Sender: TObject);
    procedure chkShowDimensionsClick(Sender: TObject);
    procedure paintPreviewPaint(Sender: TObject);
    procedure gridExistingDiesDblClick(Sender: TObject);
    procedure btnCreateDieClick(Sender: TObject);
    procedure btnOpenExistingDieClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  private
    FKeylineService: TKeylineService;
    FDieService: TDieService;
    FOwnsKeylineService: Boolean;
    FOwnsDieService: Boolean;
    FMachineIDs: TList<Integer>;
    FCustomerIDs: TList<Integer>;
    FCurrentInput: TKeylineInput;
    FCurrentResult: TKeylineCalculationResult;
    FCurrentExistingDies: TList<TSmartDieSearchResult>;
    FZoomFactor: Double;
    procedure InitGrids;
    procedure LoadLookups;
    procedure ResetInputs;
    procedure DoCalculate;
    procedure DisplayRecommendations;
    procedure UpdateRecommendationSelection(const ARow: Integer);
    function GetSelectedRecommendation(out ARec: TKeylineRecommendation): Boolean;
    function GetSelectedExistingDieID: Integer;
    procedure RenderLayoutPreview(Canvas: TCanvas; const PaintW, PaintH: Integer);
    procedure SetKeylineService(const Value: TKeylineService);
    procedure SetDieService(const Value: TDieService);
  public
    constructor Create(AOwner: TComponent); override;
    constructor CreateWithServices(AOwner: TComponent; AKeylineService: TKeylineService; ADieService: TDieService);
    property KeylineService: TKeylineService read FKeylineService write SetKeylineService;
    property DieService: TDieService read FDieService write SetDieService;
  end;

var
  FormKeylineCalculator: TfrmKeylineCalculator;

implementation

{$R *.dfm}

{ TfrmKeylineCalculator }

constructor TfrmKeylineCalculator.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

constructor TfrmKeylineCalculator.CreateWithServices(AOwner: TComponent; AKeylineService: TKeylineService; ADieService: TDieService);
begin
  FKeylineService := AKeylineService;
  FOwnsKeylineService := False;
  FDieService := ADieService;
  FOwnsDieService := False;
  inherited Create(AOwner);
end;

procedure TfrmKeylineCalculator.SetKeylineService(const Value: TKeylineService);
begin
  if FKeylineService <> Value then
  begin
    if FOwnsKeylineService and Assigned(FKeylineService) then
      FreeAndNil(FKeylineService);
    FKeylineService := Value;
    FOwnsKeylineService := False;
    if Assigned(FKeylineService) and ([csLoading, csDesigning] * ComponentState = []) and Assigned(gridRecommendations) then
    begin
      LoadLookups;
      DoCalculate;
    end;
  end;
end;

procedure TfrmKeylineCalculator.SetDieService(const Value: TDieService);
begin
  if FDieService <> Value then
  begin
    if FOwnsDieService and Assigned(FDieService) then
      FreeAndNil(FDieService);
    FDieService := Value;
    FOwnsDieService := False;
    if Assigned(FDieService) and ([csLoading, csDesigning] * ComponentState = []) and Assigned(gridRecommendations) then
    begin
      LoadLookups;
      DoCalculate;
    end;
  end;
end;

procedure TfrmKeylineCalculator.FormCreate(Sender: TObject);
begin
  FMachineIDs := TList<Integer>.Create;
  FCustomerIDs := TList<Integer>.Create;
  FCurrentExistingDies := TList<TSmartDieSearchResult>.Create;
  FZoomFactor := 1.0;

  if not Assigned(FKeylineService) then
  begin
    FKeylineService := TKeylineService.Create;
    FOwnsKeylineService := True;
  end
  else
    FOwnsKeylineService := False;

  if not Assigned(FDieService) then
  begin
    FDieService := TDieService.Create;
    FOwnsDieService := True;
  end
  else
    FOwnsDieService := False;

  InitGrids;
  LoadLookups;
  ResetInputs;
  DoCalculate;
end;

procedure TfrmKeylineCalculator.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FCurrentExistingDies);
  FreeAndNil(FMachineIDs);
  FreeAndNil(FCustomerIDs);

  if FOwnsKeylineService then
    FreeAndNil(FKeylineService);
  if FOwnsDieService then
    FreeAndNil(FDieService);
end;

procedure TfrmKeylineCalculator.InitGrids;
begin
  // Recommendations Grid
  gridRecommendations.ColCount := 10;
  gridRecommendations.RowCount := 2;
  gridRecommendations.FixedRows := 1;
  gridRecommendations.FixedCols := 0;
  gridRecommendations.Cells[0, 0] := 'Ups';
  gridRecommendations.Cells[1, 0] := 'Teeth';
  gridRecommendations.Cells[2, 0] := 'Repeat (mm)';
  gridRecommendations.Cells[3, 0] := 'Repeat (in)';
  gridRecommendations.Cells[4, 0] := 'Around Gap';
  gridRecommendations.Cells[5, 0] := 'Gap %';
  gridRecommendations.Cells[6, 0] := 'Gap Status';
  gridRecommendations.Cells[7, 0] := 'Press Web-Fit';
  gridRecommendations.Cells[8, 0] := 'Existing Dies';
  gridRecommendations.Cells[9, 0] := 'Recommendation Reason';

  gridRecommendations.ColWidths[0] := 45;
  gridRecommendations.ColWidths[1] := 50;
  gridRecommendations.ColWidths[2] := 80;
  gridRecommendations.ColWidths[3] := 75;
  gridRecommendations.ColWidths[4] := 80;
  gridRecommendations.ColWidths[5] := 55;
  gridRecommendations.ColWidths[6] := 115;
  gridRecommendations.ColWidths[7] := 115;
  gridRecommendations.ColWidths[8] := 85;
  gridRecommendations.ColWidths[9] := 260;

  // Existing Dies Grid
  gridExistingDies.ColCount := 10;
  gridExistingDies.RowCount := 2;
  gridExistingDies.FixedRows := 1;
  gridExistingDies.FixedCols := 0;
  gridExistingDies.Cells[0, 0] := 'Die Serial';
  gridExistingDies.Cells[1, 0] := 'Around (mm)';
  gridExistingDies.Cells[2, 0] := 'Across (mm)';
  gridExistingDies.Cells[3, 0] := 'Diff (mm)';
  gridExistingDies.Cells[4, 0] := 'Teeth';
  gridExistingDies.Cells[5, 0] := 'Ups (Ar '#215' Ac)';
  gridExistingDies.Cells[6, 0] := 'Status';
  gridExistingDies.Cells[7, 0] := 'Location';
  gridExistingDies.Cells[8, 0] := 'Match Classification';
  gridExistingDies.Cells[9, 0] := 'Reusability Notes';

  gridExistingDies.ColWidths[0] := 110;
  gridExistingDies.ColWidths[1] := 80;
  gridExistingDies.ColWidths[2] := 80;
  gridExistingDies.ColWidths[3] := 75;
  gridExistingDies.ColWidths[4] := 55;
  gridExistingDies.ColWidths[5] := 90;
  gridExistingDies.ColWidths[6] := 85;
  gridExistingDies.ColWidths[7] := 95;
  gridExistingDies.ColWidths[8] := 140;
  gridExistingDies.ColWidths[9] := 260;
end;

procedure TfrmKeylineCalculator.LoadLookups;
var
  MachList: TList<TMachine>;
  CustList: TList<TCustomer>;
  I: Integer;
begin
  // Presses
  cmbMachine.Clear;
  FMachineIDs.Clear;
  cmbMachine.Items.Add('(All Active Presses / Fleet)');
  FMachineIDs.Add(0);

  MachList := FKeylineService.GetActiveMachines;
  try
    for I := 0 to MachList.Count - 1 do
    begin
      cmbMachine.Items.Add(Format('%s (Max %.0f mm)', [MachList[I].Name, MachList[I].MaxWebWidthMm]));
      FMachineIDs.Add(MachList[I].ID);
    end;
  finally
    MachList.Free;
  end;
  cmbMachine.ItemIndex := 0;

  // Customers
  cmbCustomer.Clear;
  FCustomerIDs.Clear;
  cmbCustomer.Items.Add('(None)');
  FCustomerIDs.Add(0);

  CustList := FDieService.GetActiveCustomers;
  try
    for I := 0 to CustList.Count - 1 do
    begin
      cmbCustomer.Items.Add(CustList[I].Name);
      FCustomerIDs.Add(CustList[I].ID);
    end;
  finally
    CustList.Free;
  end;
  cmbCustomer.ItemIndex := 0;
end;

procedure TfrmKeylineCalculator.ResetInputs;
begin
  edtAroundSize.Text := '150.000';
  edtAcrossSize.Text := '100.000';
  cmbShape.ItemIndex := 0; // Rectangle
  edtCornerRadius.Text := '2.000';
  if cmbMachine.Items.Count > 0 then cmbMachine.ItemIndex := 0;
  if cmbCustomer.Items.Count > 0 then cmbCustomer.ItemIndex := 0;
  rgUpsMode.ItemIndex := 0; // Auto Scan
  edtMaxUps.Text := '10';
  edtFixedUps.Text := '3';
  edtAcrossUps.Text := '2';
  edtMinAroundGap.Text := '3.000';
  edtAcrossGap.Text := '3.000';
  edtLeftMargin.Text := '5.000';
  edtRightMargin.Text := '5.000';
  chkActiveCylinders.Checked := True;
  rgUpsModeClick(Self);
end;

procedure TfrmKeylineCalculator.rgUpsModeClick(Sender: TObject);
begin
  if rgUpsMode.ItemIndex = 0 then
  begin
    edtMaxUps.Enabled := True;
    edtFixedUps.Enabled := False;
  end
  else
  begin
    edtMaxUps.Enabled := False;
    edtFixedUps.Enabled := True;
  end;
end;

procedure TfrmKeylineCalculator.btnResetClick(Sender: TObject);
begin
  ResetInputs;
  DoCalculate;
end;

procedure TfrmKeylineCalculator.btnCalculateClick(Sender: TObject);
begin
  DoCalculate;
end;

procedure TfrmKeylineCalculator.DoCalculate;
var
  Input: TKeylineInput;
  ValAround, ValAcross, ValRadius: Double;
  ValMinGap, ValAcrossGap, ValLeftM, ValRightM: Double;
  ValMaxUps, ValFixedUps, ValAcrossUps: Integer;
begin
  // Input Validation
  if not TryStrToFloat(Trim(edtAroundSize.Text), ValAround) or (ValAround <= 0) then
  begin
    ShowMessage('Please enter a valid positive Target Around Size in millimetres.');
    edtAroundSize.SetFocus;
    Exit;
  end;

  if not TryStrToFloat(Trim(edtAcrossSize.Text), ValAcross) or (ValAcross <= 0) then
  begin
    ShowMessage('Please enter a valid positive Target Across Size in millimetres.');
    edtAcrossSize.SetFocus;
    Exit;
  end;

  if not TryStrToFloat(Trim(edtCornerRadius.Text), ValRadius) or (ValRadius < 0) then
    ValRadius := 0.0;

  if not TryStrToInt(Trim(edtMaxUps.Text), ValMaxUps) or (ValMaxUps < 1) then
    ValMaxUps := 10;

  if not TryStrToInt(Trim(edtFixedUps.Text), ValFixedUps) or (ValFixedUps < 1) then
    ValFixedUps := 1;

  if not TryStrToInt(Trim(edtAcrossUps.Text), ValAcrossUps) or (ValAcrossUps < 1) then
    ValAcrossUps := 1;

  if not TryStrToFloat(Trim(edtMinAroundGap.Text), ValMinGap) or (ValMinGap < 0) then
    ValMinGap := 3.000;

  if not TryStrToFloat(Trim(edtAcrossGap.Text), ValAcrossGap) or (ValAcrossGap < 0) then
    ValAcrossGap := 3.000;

  if not TryStrToFloat(Trim(edtLeftMargin.Text), ValLeftM) or (ValLeftM < 0) then
    ValLeftM := 5.000;

  if not TryStrToFloat(Trim(edtRightMargin.Text), ValRightM) or (ValRightM < 0) then
    ValRightM := 5.000;

  Input.LabelAroundMm := ValAround;
  Input.LabelAcrossMm := ValAcross;
  Input.MachineID := 0;
  if (cmbMachine.ItemIndex > 0) and (cmbMachine.ItemIndex < FMachineIDs.Count) then
    Input.MachineID := FMachineIDs[cmbMachine.ItemIndex];

  if rgUpsMode.ItemIndex = 0 then
    Input.UpsMode := usmAutoScan
  else
    Input.UpsMode := usmFixedUps;

  Input.MaxAroundUps := ValMaxUps;
  Input.FixedAroundUps := ValFixedUps;
  Input.AcrossUps := ValAcrossUps;
  Input.MinAroundGapMm := ValMinGap;
  Input.HardBlockGapMm := 0.0;
  Input.AcrossGapMm := ValAcrossGap;
  Input.LeftMarginMm := ValLeftM;
  Input.RightMarginMm := ValRightM;
  Input.Shape := cmbShape.Text;
  Input.CornerRadiusMm := ValRadius;
  Input.MediaID := 0;
  Input.ActiveCylindersOnly := chkActiveCylinders.Checked;
  Input.PitchUm := STANDARD_PITCH_UM;

  FCurrentInput := Input;
  FCurrentResult := FKeylineService.Calculate(FCurrentInput);

  DisplayRecommendations;
end;

procedure TfrmKeylineCalculator.DisplayRecommendations;
var
  I, Count: Integer;
  Rec: TKeylineRecommendation;
  StatusStr, MachStr: string;
begin
  Count := Length(FCurrentResult.Recommendations);
  if Count = 0 then
  begin
    gridRecommendations.RowCount := 2;
    for I := 0 to 9 do
      gridRecommendations.Cells[I, 1] := '';
    lblRecSummary.Caption := '0 recommendations found.';
    FCurrentExistingDies.Clear;
    gridExistingDies.RowCount := 2;
    for I := 0 to 9 do
      gridExistingDies.Cells[I, 1] := '';
    lblMatchCount.Caption := '0 matching dies found';
    paintPreview.Invalidate;
    Exit;
  end;

  gridRecommendations.RowCount := Count + 1;
  for I := 0 to Count - 1 do
  begin
    Rec := FCurrentResult.Recommendations[I];
    gridRecommendations.Cells[0, I + 1] := IntToStr(Rec.AroundUps);
    gridRecommendations.Cells[1, I + 1] := IntToStr(Rec.Teeth) + 'T';
    gridRecommendations.Cells[2, I + 1] := FormatFloat('0.000', Rec.RepeatMm);
    gridRecommendations.Cells[3, I + 1] := FormatFloat('0.0000', Rec.RepeatInch);
    gridRecommendations.Cells[4, I + 1] := FormatFloat('0.000', Rec.AroundGapMm);
    gridRecommendations.Cells[5, I + 1] := FormatFloat('0.00', Rec.CircumferentialGapPercent) + '%';

    case Rec.Category of
      krcPreferred:           StatusStr := '[PREFERRED] OK';
      krcValidAlternative:    StatusStr := '[VALID] Standard';
      krcSubStandardWarning:  StatusStr := '[BELOW MIN] Sub-3mm';
      krcMachineIncompatible: StatusStr := '[INCOMPATIBLE]';
      krcMechanicallyRejected: StatusStr := '[IMPOSSIBLE]';
    else
      StatusStr := Rec.CategoryText;
    end;
    gridRecommendations.Cells[6, I + 1] := StatusStr;

    case Rec.MachineStatus of
      mfsCompatible:          MachStr := '[OK] Fits Web';
      mfsUnsupportedCylinder: MachStr := '[UNSUPPORTED]';
      mfsExceedsWebWidth:     MachStr := '[EXCEEDS WEB]';
      mfsNoMachineSelected:   MachStr := '(Fleet)';
      mfsNotVerified:         MachStr := '[NOT VERIFIED]';
    else
      MachStr := Rec.MachineStatusText;
    end;
    gridRecommendations.Cells[7, I + 1] := MachStr;

    if Rec.ExistingDieCount > 0 then
      gridRecommendations.Cells[8, I + 1] := Format('%d Reusable', [Rec.ExistingDieCount])
    else
      gridRecommendations.Cells[8, I + 1] := '0';

    gridRecommendations.Cells[9, I + 1] := Rec.RecommendationReason;
  end;

  lblRecSummary.Caption := Format('%d candidates (%d Preferred, %d Valid, %d Below-Min, %d Incompatible)',
    [Count, FCurrentResult.PreferredCount, FCurrentResult.AlternativeCount,
     FCurrentResult.WarningCount, FCurrentResult.IncompatibleCount]);

  gridRecommendations.Row := 1;
  UpdateRecommendationSelection(1);
end;

procedure TfrmKeylineCalculator.gridRecommendationsSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
begin
  CanSelect := True;
  if ARow > 0 then
    UpdateRecommendationSelection(ARow);
end;

procedure TfrmKeylineCalculator.UpdateRecommendationSelection(const ARow: Integer);
var
  Idx, I: Integer;
  Rec: TKeylineRecommendation;
  Matches: TList<TSmartDieSearchResult>;
  Res: TSmartDieSearchResult;
begin
  Idx := ARow - 1;
  if (Idx < 0) or (Idx >= Length(FCurrentResult.Recommendations)) then
  begin
    FCurrentExistingDies.Clear;
    gridExistingDies.RowCount := 2;
    for I := 0 to 9 do gridExistingDies.Cells[I, 1] := '';
    lblMatchCount.Caption := '0 matching dies found';
    paintPreview.Invalidate;
    Exit;
  end;

  Rec := FCurrentResult.Recommendations[Idx];

  // Refresh Existing Dies Lookup for this specific cylinder
  FCurrentExistingDies.Clear;
  Matches := FKeylineService.FindMatchingDies(Rec.Teeth, FCurrentInput.LabelAroundMm, FCurrentInput.LabelAcrossMm, 2.0);
  try
    for I := 0 to Matches.Count - 1 do
      FCurrentExistingDies.Add(Matches[I]);
  finally
    Matches.Free;
  end;

  // Populate Existing Dies Grid
  if FCurrentExistingDies.Count > 0 then
  begin
    gridExistingDies.RowCount := FCurrentExistingDies.Count + 1;
    for I := 0 to FCurrentExistingDies.Count - 1 do
    begin
      Res := FCurrentExistingDies[I];
      gridExistingDies.Cells[0, I + 1] := Res.Die.SerialNo;
      gridExistingDies.Cells[1, I + 1] := FormatFloat('0.000', Res.Die.AroundSizeMm);
      gridExistingDies.Cells[2, I + 1] := FormatFloat('0.000', Res.Die.AcrossSizeMm);
      gridExistingDies.Cells[3, I + 1] := Format('%+.3f / %+.3f', [Res.AroundDiffMm, Res.AcrossDiffMm]);
      gridExistingDies.Cells[4, I + 1] := IntToStr(Res.Die.Teeth) + 'T';
      gridExistingDies.Cells[5, I + 1] := Format('%d '#215' %d', [Res.Die.AroundUps, Res.Die.AcrossUps]);
      gridExistingDies.Cells[6, I + 1] := Res.Die.StatusCode;
      gridExistingDies.Cells[7, I + 1] := Res.Die.StorageLocation;
      gridExistingDies.Cells[8, I + 1] := Res.MatchClassName;
      gridExistingDies.Cells[9, I + 1] := Res.ReusabilityNote;
    end;
    lblMatchCount.Caption := Format('%d reusable tooling candidates found for %dT cylinder', [FCurrentExistingDies.Count, Rec.Teeth]);
  end
  else
  begin
    gridExistingDies.RowCount := 2;
    for I := 0 to 9 do gridExistingDies.Cells[I, 1] := '';
    lblMatchCount.Caption := Format('0 existing tooling records found for %dT cylinder', [Rec.Teeth]);
  end;

  paintPreview.Invalidate;
end;

procedure TfrmKeylineCalculator.gridRecommendationsDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
var
  CellTxt: string;
begin
  if ARow = 0 then
  begin
    gridRecommendations.Canvas.Brush.Color := $00EFEFEF;
    gridRecommendations.Canvas.Font.Style := [fsBold];
    gridRecommendations.Canvas.Font.Color := clBlack;
    gridRecommendations.Canvas.FillRect(Rect);
    gridRecommendations.Canvas.TextRect(Rect, Rect.Left + 4, Rect.Top + 4, gridRecommendations.Cells[ACol, ARow]);
    Exit;
  end;

  CellTxt := gridRecommendations.Cells[ACol, ARow];

  if gdSelected in State then
  begin
    gridRecommendations.Canvas.Brush.Color := $00E4F0F7;
    gridRecommendations.Canvas.Font.Color := clBlack;
  end
  else
  begin
    if (ARow mod 2) = 0 then
      gridRecommendations.Canvas.Brush.Color := $00FAFAFA
    else
      gridRecommendations.Canvas.Brush.Color := clWhite;
    gridRecommendations.Canvas.Font.Color := clBlack;
  end;

  if (ACol = 6) then // Gap Status
  begin
    if Pos('PREFERRED', CellTxt) > 0 then
      gridRecommendations.Canvas.Font.Color := $00008000
    else if Pos('VALID', CellTxt) > 0 then
      gridRecommendations.Canvas.Font.Color := $00804000
    else if Pos('BELOW MIN', CellTxt) > 0 then
      gridRecommendations.Canvas.Font.Color := $000066CC
    else if Pos('INCOMPATIBLE', CellTxt) > 0 then
      gridRecommendations.Canvas.Font.Color := $000000CC
    else if Pos('IMPOSSIBLE', CellTxt) > 0 then
      gridRecommendations.Canvas.Font.Color := $000000FF;
  end
  else if (ACol = 7) then // Web-Fit
  begin
    if Pos('[OK]', CellTxt) > 0 then
      gridRecommendations.Canvas.Font.Color := $00008000
    else if Pos('EXCEEDS', CellTxt) > 0 then
      gridRecommendations.Canvas.Font.Color := $000000CC
    else if Pos('UNSUPPORTED', CellTxt) > 0 then
      gridRecommendations.Canvas.Font.Color := $00707070;
  end
  else if (ACol = 8) and (CellTxt <> '0') and (CellTxt <> '') then
  begin
    gridRecommendations.Canvas.Font.Color := $00993300;
    gridRecommendations.Canvas.Font.Style := [fsBold];
  end;

  gridRecommendations.Canvas.FillRect(Rect);
  gridRecommendations.Canvas.TextRect(Rect, Rect.Left + 4, Rect.Top + 4, CellTxt);
end;

function TfrmKeylineCalculator.GetSelectedRecommendation(out ARec: TKeylineRecommendation): Boolean;
var
  Idx: Integer;
begin
  Result := False;
  Idx := gridRecommendations.Row - 1;
  if (Idx >= 0) and (Idx < Length(FCurrentResult.Recommendations)) then
  begin
    ARec := FCurrentResult.Recommendations[Idx];
    Result := True;
  end;
end;

function TfrmKeylineCalculator.GetSelectedExistingDieID: Integer;
var
  Idx: Integer;
begin
  Result := 0;
  Idx := gridExistingDies.Row - 1;
  if (Idx >= 0) and (Idx < FCurrentExistingDies.Count) then
    Result := FCurrentExistingDies[Idx].Die.ID;
end;

procedure TfrmKeylineCalculator.btnFitClick(Sender: TObject);
begin
  FZoomFactor := 1.0;
  paintPreview.Invalidate;
end;

procedure TfrmKeylineCalculator.btnZoomInClick(Sender: TObject);
begin
  FZoomFactor := FZoomFactor * 1.25;
  paintPreview.Invalidate;
end;

procedure TfrmKeylineCalculator.btnZoomOutClick(Sender: TObject);
begin
  FZoomFactor := Max(0.2, FZoomFactor / 1.25);
  paintPreview.Invalidate;
end;

procedure TfrmKeylineCalculator.chkShowDimensionsClick(Sender: TObject);
begin
  paintPreview.Invalidate;
end;

procedure TfrmKeylineCalculator.paintPreviewPaint(Sender: TObject);
begin
  RenderLayoutPreview(paintPreview.Canvas, paintPreview.Width, paintPreview.Height);
end;

procedure TfrmKeylineCalculator.RenderLayoutPreview(Canvas: TCanvas; const PaintW, PaintH: Integer);
var
  Rec: TKeylineRecommendation;
  RepeatUm: Int64;
  LabelAroundUm, LabelAcrossUm, AcrossGapUm: Int64;
  LeftMarginUm, RightMarginUm, TotalWebUm: Int64;
  AroundGapRational: Double;
  CornerRadUm: Int64;
  AcrossUps, AroundUps: Integer;
  MarginLeftPix, MarginRightPix, MarginTopPix, MarginBottomPix: Integer;
  AvailW, AvailH: Integer;
  ScaleX, ScaleY, BaseScale, Scale: Double;
  WebPixW, RepeatPixH: Integer;
  OriginX, OriginY: Integer;
  C, R: Integer;
  LaneX1, LaneX2, RowY1, RowY2: Int64;
  X1, X2, Y1, Y2: Integer;
  CornerRadPix: Integer;
  LblTxt, HeaderTxt: string;
  DimX, DimY, GapX, GapY, GapY1, GapY2, GapX1, GapX2: Integer;

  function PxX(const Um: Int64): Integer;
  begin
    Result := OriginX + Round(Um * Scale);
  end;

  function PxY(const Um: Int64): Integer;
  begin
    Result := OriginY + Round(Um * Scale);
  end;

  procedure DrawArrowV(const Ax, Ay1, Ay2: Integer; const Txt: string);
  var
    MidY: Integer;
  begin
    Canvas.Pen.Color := $00404040;
    Canvas.Pen.Style := psSolid;
    Canvas.Pen.Width := 1;
    Canvas.MoveTo(Ax, Ay1); Canvas.LineTo(Ax, Ay2);
    // Arrows
    Canvas.MoveTo(Ax - 3, Ay1 + 5); Canvas.LineTo(Ax, Ay1); Canvas.LineTo(Ax + 3, Ay1 + 5);
    Canvas.MoveTo(Ax - 3, Ay2 - 5); Canvas.LineTo(Ax, Ay2); Canvas.LineTo(Ax + 3, Ay2 - 5);
    // Text
    MidY := (Ay1 + Ay2) div 2;
    Canvas.Font.Size := 8;
    Canvas.Font.Color := $00202020;
    Canvas.Brush.Style := bsClear;
    Canvas.TextOut(Ax + 5, MidY - 7, Txt);
  end;

  procedure DrawArrowH(const Ay, Ax1, Ax2: Integer; const Txt: string);
  var
    MidX: Integer;
  begin
    Canvas.Pen.Color := $00404040;
    Canvas.Pen.Style := psSolid;
    Canvas.Pen.Width := 1;
    Canvas.MoveTo(Ax1, Ay); Canvas.LineTo(Ax2, Ay);
    // Arrows
    Canvas.MoveTo(Ax1 + 5, Ay - 3); Canvas.LineTo(Ax1, Ay); Canvas.LineTo(Ax1 + 5, Ay + 3);
    Canvas.MoveTo(Ax2 - 5, Ay - 3); Canvas.LineTo(Ax2, Ay); Canvas.LineTo(Ax2 - 5, Ay + 3);
    // Text
    MidX := (Ax1 + Ax2) div 2;
    Canvas.Font.Size := 8;
    Canvas.Font.Color := $00202020;
    Canvas.Brush.Style := bsClear;
    Canvas.TextOut(MidX - (Canvas.TextWidth(Txt) div 2), Ay + 4, Txt);
  end;

begin
  // Background
  Canvas.Brush.Color := $00FCFCFC;
  Canvas.FillRect(Rect(0, 0, PaintW, PaintH));

  if not GetSelectedRecommendation(Rec) then
  begin
    Canvas.Font.Size := 10;
    Canvas.Font.Color := clGray;
    Canvas.Brush.Style := bsClear;
    Canvas.TextOut(20, 20, 'No recommendation selected. Click "Calculate Recommendations" to view layout.');
    Exit;
  end;

  RepeatUm := Int64(Rec.Teeth) * Int64(Rec.PitchUm);
  LabelAroundUm := Round(FCurrentInput.LabelAroundMm * 1000.0);
  LabelAcrossUm := Round(FCurrentInput.LabelAcrossMm * 1000.0);
  AcrossGapUm := Round(FCurrentInput.AcrossGapMm * 1000.0);
  LeftMarginUm := Round(FCurrentInput.LeftMarginMm * 1000.0);
  RightMarginUm := Round(FCurrentInput.RightMarginMm * 1000.0);
  CornerRadUm := Round(FCurrentInput.CornerRadiusMm * 1000.0);
  AcrossUps := FCurrentInput.AcrossUps;
  AroundUps := Rec.AroundUps;

  if (AcrossUps < 1) or (AroundUps < 1) or (RepeatUm <= 0) then Exit;

  TotalWebUm := (AcrossUps * LabelAcrossUm) + ((AcrossUps - 1) * AcrossGapUm) + LeftMarginUm + RightMarginUm;
  AroundGapRational := (RepeatUm - (AroundUps * LabelAroundUm)) / AroundUps;

  MarginLeftPix := 35;
  MarginRightPix := 75; // Space for vertical dimension line
  MarginTopPix := 45;   // Space for header
  MarginBottomPix := 45;// Space for horizontal dimension line

  AvailW := PaintW - (MarginLeftPix + MarginRightPix);
  AvailH := PaintH - (MarginTopPix + MarginBottomPix);

  if (AvailW <= 20) or (AvailH <= 20) or (TotalWebUm <= 0) then Exit;

  ScaleX := AvailW / TotalWebUm;
  ScaleY := AvailH / RepeatUm;
  BaseScale := Min(ScaleX, ScaleY);
  Scale := BaseScale * FZoomFactor;
  if Scale < 0.00001 then Scale := 0.00001;

  WebPixW := Round(TotalWebUm * Scale);
  RepeatPixH := Round(RepeatUm * Scale);

  OriginX := MarginLeftPix + Max(0, (AvailW - WebPixW) div 2);
  OriginY := MarginTopPix + Max(0, (AvailH - RepeatPixH) div 2);

  // 1. Web Substrate
  Canvas.Brush.Color := $00F5F6F7;
  Canvas.Pen.Color := $00C0C4C8;
  Canvas.Pen.Style := psSolid;
  Canvas.Pen.Width := 1;
  Canvas.Rectangle(PxX(0), PxY(0), PxX(TotalWebUm), PxY(RepeatUm));

  // 2. Edge Margins
  Canvas.Brush.Color := $00E8EBED;
  Canvas.Pen.Style := psClear;
  // Left margin
  Canvas.Rectangle(PxX(0), PxY(0), PxX(LeftMarginUm), PxY(RepeatUm));
  // Right margin
  Canvas.Rectangle(PxX(TotalWebUm - RightMarginUm), PxY(0), PxX(TotalWebUm), PxY(RepeatUm));

  // 3. Repeat Seams (Top and Bottom of Cylinder Revolution)
  Canvas.Pen.Style := psDash;
  Canvas.Pen.Color := $00C06000; // Orange-Blue indicator
  Canvas.Pen.Width := 1;
  Canvas.MoveTo(PxX(0) - 15, PxY(0));
  Canvas.LineTo(PxX(TotalWebUm) + 15, PxY(0));
  Canvas.MoveTo(PxX(0) - 15, PxY(RepeatUm));
  Canvas.LineTo(PxX(TotalWebUm) + 15, PxY(RepeatUm));

  // 4. Label Cutouts
  Canvas.Pen.Style := psSolid;
  Canvas.Pen.Width := 1;
  Canvas.Pen.Color := $00993300; // Tooling Die Blue
  Canvas.Brush.Color := clWhite;
  CornerRadPix := Round(CornerRadUm * Scale);

  for C := 0 to AcrossUps - 1 do
  begin
    LaneX1 := LeftMarginUm + (C * (LabelAcrossUm + AcrossGapUm));
    LaneX2 := LaneX1 + LabelAcrossUm;
    for R := 0 to AroundUps - 1 do
    begin
      RowY1 := Round(R * (LabelAroundUm + AroundGapRational));
      RowY2 := RowY1 + LabelAroundUm;
      X1 := PxX(LaneX1);
      X2 := PxX(LaneX2);
      Y1 := PxY(RowY1);
      Y2 := PxY(RowY2);

      if SameText(FCurrentInput.Shape, 'Circle') or SameText(FCurrentInput.Shape, 'Oval') then
        Canvas.Ellipse(X1, Y1, X2, Y2)
      else if CornerRadPix > 0 then
        Canvas.RoundRect(X1, Y1, X2, Y2, CornerRadPix * 2, CornerRadPix * 2)
      else
        Canvas.Rectangle(X1, Y1, X2, Y2);

      // Label index text (e.g. 1,1)
      LblTxt := Format('%d,%d', [R + 1, C + 1]);
      Canvas.Font.Size := 8;
      Canvas.Font.Color := $00808080;
      Canvas.Brush.Style := bsClear;
      Canvas.TextOut((X1 + X2 - Canvas.TextWidth(LblTxt)) div 2, (Y1 + Y2 - Canvas.TextHeight(LblTxt)) div 2, LblTxt);
    end;
  end;

  // 5. Dimension Callouts
  if chkShowDimensions.Checked then
  begin
    // Vertical Repeat Dimension
    DimX := PxX(TotalWebUm) + 15;
    DrawArrowV(DimX, PxY(0), PxY(RepeatUm), Format('Repeat %.3f mm (%dT)', [Rec.RepeatMm, Rec.Teeth]));

    // Horizontal Web Width Dimension
    DimY := PxY(RepeatUm) + 15;
    DrawArrowH(DimY, PxX(0), PxX(TotalWebUm), Format('Web %.1f mm', [Rec.TotalWebWidthMm]));

    // Around Gap Callout (between row 0 and row 1 if AroundUps > 1)
    if AroundUps > 1 then
    begin
      GapY1 := PxY(LabelAroundUm);
      GapY2 := PxY(Round(LabelAroundUm + AroundGapRational));
      GapX := PxX(LeftMarginUm + (LabelAcrossUm div 2));
      DrawArrowV(GapX, GapY1, GapY2, Format('Around: %.3f mm', [Rec.AroundGapMm]));
    end;

    // Across Gap Callout (between lane 0 and lane 1 if AcrossUps > 1)
    if AcrossUps > 1 then
    begin
      GapX1 := PxX(LeftMarginUm + LabelAcrossUm);
      GapX2 := PxX(LeftMarginUm + LabelAcrossUm + AcrossGapUm);
      GapY := PxY(LabelAroundUm div 2);
      DrawArrowH(GapY, GapX1, GapX2, Format('Across: %.3f mm', [FCurrentInput.AcrossGapMm]));
    end;
  end;

  // 6. Header summary
  HeaderTxt := Format('%dT Cylinder '#8212' Repeat: %.3f mm | Layout: %d Around '#215' %d Across (%d Total)',
    [Rec.Teeth, Rec.RepeatMm, Rec.AroundUps, Rec.AcrossUps, Rec.AroundUps * Rec.AcrossUps]);
  Canvas.Font.Size := 9;
  Canvas.Font.Style := [fsBold];
  Canvas.Font.Color := clBlack;
  Canvas.Brush.Style := bsClear;
  Canvas.TextOut(OriginX, 12, HeaderTxt);
end;

procedure TfrmKeylineCalculator.gridExistingDiesDblClick(Sender: TObject);
begin
  btnOpenExistingDieClick(Sender);
end;

procedure TfrmKeylineCalculator.btnCreateDieClick(Sender: TObject);
var
  Rec: TKeylineRecommendation;
  DraftDie: TDie;
  Editor: TfrmDieEditor;
  CustID: Integer;
begin
  if not GetSelectedRecommendation(Rec) then
  begin
    ShowMessage('Please select a cylinder recommendation first.');
    Exit;
  end;

  CustID := 0;
  if (cmbCustomer.ItemIndex > 0) and (cmbCustomer.ItemIndex < FCustomerIDs.Count) then
    CustID := FCustomerIDs[cmbCustomer.ItemIndex];

  // Generate draft die using pure engine geometry & unique serial generator
  DraftDie := FKeylineService.CreateDraftDie(Rec, FCurrentInput, CustID);

  Editor := TfrmDieEditor.Create(Self);
  try
    Editor.DieService := FDieService;
    Editor.PopulateDraft(DraftDie);
    if Editor.ShowModal = mrOk then
    begin
      // Recalculate to immediately refresh matches and tooling counts
      DoCalculate;
    end;
  finally
    Editor.Free;
  end;
end;

procedure TfrmKeylineCalculator.btnOpenExistingDieClick(Sender: TObject);
var
  DieID: Integer;
  Editor: TfrmDieEditor;
begin
  DieID := GetSelectedExistingDieID;
  if DieID <= 0 then
  begin
    ShowMessage('Please select a matching existing die from the inventory table.');
    Exit;
  end;

  Editor := TfrmDieEditor.Create(Self);
  try
    Editor.DieService := FDieService;
    Editor.DieID := DieID;
    if Editor.ShowModal = mrOk then
    begin
      DoCalculate;
    end;
  finally
    Editor.Free;
  end;
end;

procedure TfrmKeylineCalculator.btnCloseClick(Sender: TObject);
begin
  Close;
end;

end.
