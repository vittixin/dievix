object frmSettings: TfrmSettings
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Application Settings — DieVix'
  ClientHeight = 490
  ClientWidth = 560
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  Scaled = True
  OnCreate = FormCreate
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 560
    Height = 55
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 20
      Top = 15
      Width = 151
      Height = 21
      Caption = 'DieVix Preferences'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object pnlBody: TPanel
    Left = 0
    Top = 55
    Width = 560
    Height = 375
    Align = alClient
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 1
    object grpGapPolicy: TGroupBox
      Left = 20
      Top = 10
      Width = 520
      Height = 130
      Caption = ' Around Gap Policy '
      TabOrder = 0
      object lblMinGap: TLabel
        Left = 20
        Top = 25
        Width = 139
        Height = 15
        Caption = 'Minimum Gap (mm):'
      end
      object lblMinGapHelp: TLabel
        Left = 250
        Top = 25
        Width = 248
        Height = 15
        Caption = 'Gaps below this require an override reason.'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGrayText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object lblHardBlock: TLabel
        Left = 20
        Top = 75
        Width = 145
        Height = 15
        Caption = 'Hard Block Gap (mm):'
      end
      object lblHardBlockHelp: TLabel
        Left = 250
        Top = 75
        Width = 254
        Height = 15
        Caption = 'Set to 0.000 to disable hard blocking.'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGrayText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object edtMinGapMm: TEdit
        Left = 20
        Top = 45
        Width = 100
        Height = 23
        TabOrder = 0
        Text = '3.000'
      end
      object edtHardBlockMm: TEdit
        Left = 20
        Top = 95
        Width = 100
        Height = 23
        TabOrder = 1
        Text = '0.000'
      end
    end
    object grpToolingDefaults: TGroupBox
      Left = 20
      Top = 150
      Width = 520
      Height = 110
      Caption = ' Layout & Tooling Defaults '
      TabOrder = 1
      object lblAcrossGap: TLabel
        Left = 20
        Top = 25
        Width = 117
        Height = 15
        Caption = 'Default Across Gap:'
      end
      object lblCornerRadius: TLabel
        Left = 180
        Top = 25
        Width = 114
        Height = 15
        Caption = 'Default Corner Rad:'
      end
      object lblMargin: TLabel
        Left = 340
        Top = 25
        Width = 110
        Height = 15
        Caption = 'Default Edge Margin:'
      end
      object edtAcrossGapMm: TEdit
        Left = 20
        Top = 45
        Width = 100
        Height = 23
        TabOrder = 0
        Text = '3.000'
      end
      object edtCornerRadiusMm: TEdit
        Left = 180
        Top = 45
        Width = 100
        Height = 23
        TabOrder = 1
        Text = '2.000'
      end
      object edtMarginMm: TEdit
        Left = 340
        Top = 45
        Width = 100
        Height = 23
        TabOrder = 2
        Text = '5.000'
      end
    end
    object grpPitch: TGroupBox
      Left = 20
      Top = 270
      Width = 520
      Height = 85
      Caption = ' Circular Gear Pitch '
      TabOrder = 2
      object lblPitch: TLabel
        Left = 20
        Top = 25
        Width = 135
        Height = 15
        Caption = 'Standard Pitch (um):'
      end
      object lblPitchHelp: TLabel
        Left = 180
        Top = 48
        Width = 312
        Height = 15
        Caption = 'Industry standard: 1/8" = 3.175 mm = 3,175 micrometres'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGrayText
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object edtPitchUm: TEdit
        Left = 20
        Top = 45
        Width = 120
        Height = 23
        TabOrder = 0
        Text = '3175'
      end
    end
  end
  object pnlButtons: TPanel
    Left = 0
    Top = 430
    Width = 560
    Height = 60
    Align = alBottom
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 2
    object btnSave: TButton
      Left = 340
      Top = 15
      Width = 95
      Height = 32
      Caption = 'Save'
      Default = True
      TabOrder = 0
      OnClick = btnSaveClick
    end
    object btnCancel: TButton
      Left = 445
      Top = 15
      Width = 95
      Height = 32
      Cancel = True
      Caption = 'Cancel'
      TabOrder = 1
      OnClick = btnCancelClick
    end
  end
end
