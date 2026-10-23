unit frmSettings;

{==============================================================================
  DieVix – Rotary Die & Keyline Manager
  Application Settings Form
==============================================================================}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  DieVix.MasterDataService;

type
  TfrmSettings = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    pnlBody: TPanel;
    grpGapPolicy: TGroupBox;
    lblMinGap: TLabel;
    edtMinGapMm: TEdit;
    lblMinGapHelp: TLabel;
    lblHardBlock: TLabel;
    edtHardBlockMm: TEdit;
    lblHardBlockHelp: TLabel;
    grpToolingDefaults: TGroupBox;
    lblAcrossGap: TLabel;
    edtAcrossGapMm: TEdit;
    lblCornerRadius: TLabel;
    edtCornerRadiusMm: TEdit;
    lblMargin: TLabel;
    edtMarginMm: TEdit;
    grpPitch: TGroupBox;
    lblPitch: TLabel;
    edtPitchUm: TEdit;
    lblPitchHelp: TLabel;
    pnlButtons: TPanel;
    btnSave: TButton;
    btnCancel: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
  private
    FService: TMasterDataService;
    procedure LoadSettings;
  public
    property Service: TMasterDataService read FService write FService;
  end;

var
  FormSettings: TfrmSettings;

implementation

{$R *.dfm}

procedure TfrmSettings.FormCreate(Sender: TObject);
begin
  if not Assigned(FService) then
    FService := TMasterDataService.Create;
  LoadSettings;
end;

procedure TfrmSettings.LoadSettings;
var
  MinGapUm, HardBlockUm: Int64;
  AcrossGap, Radius, Margin: Double;
  Pitch: Integer;
begin
  MinGapUm := FService.GetMinAroundGapUm;
  HardBlockUm := FService.GetHardBlockGapUm;
  AcrossGap := FService.GetDefaultAcrossGapMm;
  Radius := FService.GetDefaultCornerRadiusMm;
  Margin := FService.SettingRepo.GetFloat('DEFAULT_EDGE_MARGIN_MM', 5.0);
  Pitch := FService.SettingRepo.GetInt('STANDARD_PITCH_UM', 3175);

  edtMinGapMm.Text := FormatFloat('0.000', MinGapUm / 1000.0);
  edtHardBlockMm.Text := FormatFloat('0.000', HardBlockUm / 1000.0);
  edtAcrossGapMm.Text := FormatFloat('0.000', AcrossGap);
  edtCornerRadiusMm.Text := FormatFloat('0.000', Radius);
  edtMarginMm.Text := FormatFloat('0.000', Margin);
  edtPitchUm.Text := IntToStr(Pitch);
end;

procedure TfrmSettings.btnSaveClick(Sender: TObject);
var
  MinGapUm, HardBlockUm: Int64;
  AcrossGap, Radius, Margin: Double;
  Pitch: Integer;
begin
  MinGapUm := Round(StrToFloatDef(Trim(edtMinGapMm.Text), 3.0) * 1000.0);
  HardBlockUm := Round(StrToFloatDef(Trim(edtHardBlockMm.Text), 0.0) * 1000.0);
  AcrossGap := StrToFloatDef(Trim(edtAcrossGapMm.Text), 3.0);
  Radius := StrToFloatDef(Trim(edtCornerRadiusMm.Text), 2.0);
  Margin := StrToFloatDef(Trim(edtMarginMm.Text), 5.0);
  Pitch := StrToIntDef(Trim(edtPitchUm.Text), 3175);

  try
    FService.SaveSettings(MinGapUm, HardBlockUm, AcrossGap, Radius);
    FService.SettingRepo.SetValue('DEFAULT_EDGE_MARGIN_MM', FormatFloat('0.000', Margin), 'Default web edge margin (mm)');
    FService.SettingRepo.SetValue('STANDARD_PITCH_UM', IntToStr(Pitch), 'Standard 1/8" circular pitch in um');

    ShowMessage('Application settings updated successfully.');
    Close;
  except
    on E: Exception do
      ShowMessage('Error saving settings: ' + E.Message);
  end;
end;

procedure TfrmSettings.btnCancelClick(Sender: TObject);
begin
  Close;
end;

end.
