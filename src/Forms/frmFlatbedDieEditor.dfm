object frmFlatbedDieEditor: TfrmFlatbedDieEditor
  Left = 0
  Top = 0
  Caption = 'Flatbed Die Tooling Editor'
  ClientHeight = 650
  ClientWidth = 850
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 850
    Height = 50
    Align = alTop
    BevelOuter = bvNone
    Color = 16119285
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 12
      Width = 246
      Height = 25
      Caption = 'Flatbed Die Tooling Definition'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblStatusBadge: TLabel
      Left = 700
      Top = 16
      Width = 120
      Height = 20
      Alignment = taRightJustify
      Caption = 'ACTIVE'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 32768
      Font.Height = -13
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 605
    Width = 850
    Height = 45
    Align = alBottom
    BevelOuter = bvNone
    Color = 16119285
    ParentBackground = False
    TabOrder = 2
    object btnSave: TButton
      Left = 650
      Top = 8
      Width = 90
      Height = 30
      Caption = 'Save Tooling'
      Default = True
      TabOrder = 0
      OnClick = btnSaveClick
    end
    object btnCancel: TButton
      Left = 748
      Top = 8
      Width = 90
      Height = 30
      Cancel = True
      Caption = 'Cancel'
      ModalResult = 2
      TabOrder = 1
    end
  end
  object pageDie: TPageControl
    Left = 0
    Top = 50
    Width = 850
    Height = 555
    ActivePage = tabGeometry
    Align = alClient
    TabOrder = 1
    object tabGeometry: TTabSheet
      Caption = 'Geometry & Tooling Specs'
      object grpIdentification: TGroupBox
        Left = 16
        Top = 12
        Width = 808
        Height = 120
        Caption = ' Identification & Classification '
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        object lblSerial: TLabel
          Left = 16
          Top = 24
          Width = 53
          Height = 15
          Caption = 'Serial No:'
          Font.Name = 'Segoe UI'
          ParentFont = False
        end
        object lblCategory: TLabel
          Left = 216
          Top = 24
          Width = 54
          Height = 15
          Caption = 'Category:'
          Font.Name = 'Segoe UI'
          ParentFont = False
        end
        object lblCustomer: TLabel
          Left = 460
          Top = 24
          Width = 55
          Height = 15
          Caption = 'Customer:'
          Font.Name = 'Segoe UI'
          ParentFont = False
        end
        object lblDescription: TLabel
          Left = 16
          Top = 68
          Width = 63
          Height = 15
          Caption = 'Description:'
          Font.Name = 'Segoe UI'
          ParentFont = False
        end
        object lblMedia: TLabel
          Left = 460
          Top = 68
          Width = 36
          Height = 15
          Caption = 'Media:'
          Font.Name = 'Segoe UI'
          ParentFont = False
        end
        object edtSerial: TEdit
          Left = 16
          Top = 42
          Width = 140
          Height = 23
          Font.Name = 'Segoe UI'
          ParentFont = False
          TabOrder = 0
        end
        object btnGenerateSerial: TButton
          Left = 160
          Top = 41
          Width = 44
          Height = 25
          Hint = 'Generate new unique serial number'
          Caption = 'Gen'
          ParentShowHint = False
          ShowHint = True
          TabOrder = 1
          OnClick = btnGenerateSerialClick
        end
        object cmbCategory: TComboBox
          Left = 216
          Top = 42
          Width = 224
          Height = 23
          Style = csDropDownList
          Font.Name = 'Segoe UI'
          ParentFont = False
          TabOrder = 2
          OnChange = DimensionChange
        end
        object cmbCustomer: TComboBox
          Left = 460
          Top = 42
          Width = 332
          Height = 23
          Style = csDropDownList
          Font.Name = 'Segoe UI'
          ParentFont = False
          TabOrder = 3
        end
        object edtDescription: TEdit
          Left = 16
          Top = 86
          Width = 424
          Height = 23
          Font.Name = 'Segoe UI'
          ParentFont = False
          TabOrder = 4
        end
        object cmbMedia: TComboBox
          Left = 460
          Top = 86
          Width = 332
          Height = 23
          Style = csDropDownList
          Font.Name = 'Segoe UI'
          ParentFont = False
          TabOrder = 5
        end
      end
      object grpDimensions: TGroupBox
        Left = 16
        Top = 138
        Width = 808
        Height = 140
        Caption = ' Cavity Dimensions & Layout '
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
        TabOrder = 1
        object lblAroundSize: TLabel
          Left = 16
          Top = 24
          Width = 92
          Height = 15
          Caption = 'Around Size (mm):'
          Font.Name = 'Segoe UI'
          ParentFont = False
        end
        object lblAcrossSize: TLabel
          Left = 150
          Top = 24
          Width = 88
          Height = 15
          Caption = 'Across Size (mm):'
          Font.Name = 'Segoe UI'
          ParentFont = False
        end
        object lblAroundUps: TLabel
          Left = 284
          Top = 24
          Width = 65
          Height = 15
          Caption = 'Around Ups:'
          Font.Name = 'Segoe UI'
          ParentFont = False
        end
        object lblAcrossUps: TLabel
          Left = 384
          Top = 24
          Width = 61
          Height = 15
          Caption = 'Across Ups:'
          Font.Name = 'Segoe UI'
          ParentFont = False
        end
        object lblAroundGap: TLabel
          Left = 484
          Top = 24
          Width = 92
          Height = 15
          Caption = 'Around Gap (mm):'
          Font.Name = 'Segoe UI'
          ParentFont = False
        end
        object lblAcrossGap: TLabel
          Left = 618
          Top = 24
          Width = 88
          Height = 15
          Caption = 'Across Gap (mm):'
          Font.Name = 'Segoe UI'
          ParentFont = False
        end
        object lblCornerRadius: TLabel
          Left = 16
          Top = 78
          Width = 101
          Height = 15
          Caption = 'Corner Radius (mm):'
          Font.Name = 'Segoe UI'
          ParentFont = False
        end
        object lblShape: TLabel
          Left = 150
          Top = 78
          Width = 35
          Height = 15
          Caption = 'Shape:'
          Font.Name = 'Segoe UI'
          ParentFont = False
        end
        object lblPlateWidth: TLabel
          Left = 284
          Top = 78
          Width = 88
          Height = 15
          Caption = 'Plate Width (mm):'
          Font.Name = 'Segoe UI'
          ParentFont = False
        end
        object lblPlateLength: TLabel
          Left = 418
          Top = 78
          Width = 92
          Height = 15
          Caption = 'Plate Length (mm):'
          Font.Name = 'Segoe UI'
          ParentFont = False
        end
        object lblMaxFeed: TLabel
          Left = 552
          Top = 78
          Width = 117
          Height = 15
          Caption = 'Max Feed Stroke (mm):'
          Font.Name = 'Segoe UI'
          ParentFont = False
        end
        object edtAroundSize: TEdit
          Left = 16
          Top = 42
          Width = 115
          Height = 23
          Font.Name = 'Segoe UI'
          ParentFont = False
          TabOrder = 0
          Text = '75.000'
          OnChange = DimensionChange
        end
        object edtAcrossSize: TEdit
          Left = 150
          Top = 42
          Width = 115
          Height = 23
          Font.Name = 'Segoe UI'
          ParentFont = False
          TabOrder = 1
          Text = '50.000'
          OnChange = DimensionChange
        end
        object edtAroundUps: TEdit
          Left = 284
          Top = 42
          Width = 80
          Height = 23
          Font.Name = 'Segoe UI'
          ParentFont = False
          TabOrder = 2
          Text = '1'
          OnChange = DimensionChange
        end
        object edtAcrossUps: TEdit
          Left = 384
          Top = 42
          Width = 80
          Height = 23
          Font.Name = 'Segoe UI'
          ParentFont = False
          TabOrder = 3
          Text = '1'
          OnChange = DimensionChange
        end
        object edtAroundGap: TEdit
          Left = 484
          Top = 42
          Width = 115
          Height = 23
          Font.Name = 'Segoe UI'
          ParentFont = False
          TabOrder = 4
          Text = '3.000'
          OnChange = DimensionChange
        end
        object edtAcrossGap: TEdit
          Left = 618
          Top = 42
          Width = 115
          Height = 23
          Font.Name = 'Segoe UI'
          ParentFont = False
          TabOrder = 5
          Text = '3.000'
          OnChange = DimensionChange
        end
        object edtCornerRadius: TEdit
          Left = 16
          Top = 96
          Width = 115
          Height = 23
          Font.Name = 'Segoe UI'
          ParentFont = False
          TabOrder = 6
          Text = '2.000'
        end
        object cmbShape: TComboBox
          Left = 150
          Top = 96
          Width = 115
          Height = 23
          Style = csDropDownList
          Font.Name = 'Segoe UI'
          ItemIndex = 0
          ParentFont = False
          TabOrder = 7
          Text = 'RECTANGLE'
          Items.Strings = (
            'RECTANGLE'
            'CIRCLE'
            'OVAL'
            'SPECIAL')
        end
        object edtPlateWidth: TEdit
          Left = 284
          Top = 96
          Width = 115
          Height = 23
          Font.Name = 'Segoe UI'
          ParentFont = False
          TabOrder = 8
        end
        object edtPlateLength: TEdit
          Left = 418
          Top = 96
          Width = 115
          Height = 23
          Font.Name = 'Segoe UI'
          ParentFont = False
          TabOrder = 9
        end
        object edtMaxFeedStroke: TEdit
          Left = 552
          Top = 96
          Width = 115
          Height = 23
          Font.Name = 'Segoe UI'
          ParentFont = False
          TabOrder = 10
        end
      end
      object grpCalculated: TGroupBox
        Left = 16
        Top = 284
        Width = 808
        Height = 170
        Caption = ' Live Footprint & Bi-Directional Rotation Rule '
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
        TabOrder = 2
        object lblFootprintAround: TLabel
          Left = 16
          Top = 28
          Width = 135
          Height = 15
          Caption = 'Total Cut Around Length:'
          Font.Name = 'Segoe UI'
          ParentFont = False
        end
        object valTotalCutAround: TLabel
          Left = 16
          Top = 48
          Width = 79
          Height = 25
          Caption = '75.000 mm'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clNavy
          Font.Height = -19
          Font.Name = 'Segoe UI Bold'
          Font.Style = []
          ParentFont = False
        end
        object lblFootprintAcross: TLabel
          Left = 220
          Top = 28
          Width = 127
          Height = 15
          Caption = 'Total Cut Across Width:'
          Font.Name = 'Segoe UI'
          ParentFont = False
        end
        object valTotalCutAcross: TLabel
          Left = 220
          Top = 48
          Width = 79
          Height = 25
          Caption = '50.000 mm'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clNavy
          Font.Height = -19
          Font.Name = 'Segoe UI Bold'
          Font.Style = []
          ParentFont = False
        end
        object lblTotalUpsDisplay: TLabel
          Left = 420
          Top = 28
          Width = 50
          Height = 15
          Caption = 'Total Ups:'
          Font.Name = 'Segoe UI'
          ParentFont = False
        end
        object valTotalUps: TLabel
          Left = 420
          Top = 48
          Width = 31
          Height = 25
          Caption = '1 up'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clNavy
          Font.Height = -19
          Font.Name = 'Segoe UI Bold'
          Font.Style = []
          ParentFont = False
        end
        object lblRotationCapability: TLabel
          Left = 560
          Top = 28
          Width = 141
          Height = 15
          Caption = 'Direction / Rotation Rule:'
          Font.Name = 'Segoe UI'
          ParentFont = False
        end
        object valRotationSupport: TLabel
          Left = 560
          Top = 48
          Width = 230
          Height = 25
          Caption = 'BI-DIRECTIONAL (90'#176')'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 32768
          Font.Height = -19
          Font.Name = 'Segoe UI Bold'
          Font.Style = []
          ParentFont = False
        end
        object pnlRuleExplanation: TPanel
          Left = 16
          Top = 88
          Width = 774
          Height = 65
          BevelOuter = bvLowered
          Color = 16316664
          ParentBackground = False
          TabOrder = 0
          object lblRotationRuleInfo: TLabel
            Left = 12
            Top = 8
            Width = 748
            Height = 45
            AutoSize = False
            Caption = 
              'Directionality Rules:'#13#10'  '#8226' ROLL_FORM: 1x1 ups tooling can be loaded' +
              ' in both directions (90'#176' bi-directional). Multi-ups tooling can rotate ' +
              'ONLY if around and across sizes are identical.'#13#10'  '#8226' SHEET_FORM: Fixe' +
              'd sheetfed orientation (rotation unsupported).'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -11
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
            WordWrap = True
          end
        end
      end
    end
    object tabInventory: TTabSheet
      Caption = 'Inventory, Storage & History'
      ImageIndex = 1
      object grpStorage: TGroupBox
        Left = 16
        Top = 16
        Width = 808
        Height = 110
        Caption = ' Physical Storage Location '
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        object lblLocation: TLabel
          Left = 16
          Top = 28
          Width = 91
          Height = 15
          Caption = 'Storage Location:'
          Font.Name = 'Segoe UI'
          ParentFont = False
        end
        object lblRack: TLabel
          Left = 240
          Top = 28
          Width = 28
          Height = 15
          Caption = 'Rack:'
          Font.Name = 'Segoe UI'
          ParentFont = False
        end
        object lblShelf: TLabel
          Left = 400
          Top = 28
          Width = 28
          Height = 15
          Caption = 'Shelf:'
          Font.Name = 'Segoe UI'
          ParentFont = False
        end
        object lblBin: TLabel
          Left = 560
          Top = 28
          Width = 20
          Height = 15
          Caption = 'Bin:'
          Font.Name = 'Segoe UI'
          ParentFont = False
        end
        object edtStorageLocation: TEdit
          Left = 16
          Top = 48
          Width = 200
          Height = 23
          Font.Name = 'Segoe UI'
          ParentFont = False
          TabOrder = 0
        end
        object edtStorageRack: TEdit
          Left = 240
          Top = 48
          Width = 140
          Height = 23
          Font.Name = 'Segoe UI'
          ParentFont = False
          TabOrder = 1
        end
        object edtStorageShelf: TEdit
          Left = 400
          Top = 48
          Width = 140
          Height = 23
          Font.Name = 'Segoe UI'
          ParentFont = False
          TabOrder = 2
        end
        object edtStorageBin: TEdit
          Left = 560
          Top = 48
          Width = 140
          Height = 23
          Font.Name = 'Segoe UI'
          ParentFont = False
          TabOrder = 3
        end
      end
      object grpLifecycle: TGroupBox
        Left = 16
        Top = 138
        Width = 808
        Height = 220
        Caption = ' Status, Procurement & Lifecycle '
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
        TabOrder = 1
        object lblStatus: TLabel
          Left = 16
          Top = 28
          Width = 35
          Height = 15
          Caption = 'Status:'
          Font.Name = 'Segoe UI'
          ParentFont = False
        end
        object lblDieMaker: TLabel
          Left = 200
          Top = 28
          Width = 56
          Height = 15
          Caption = 'Die Maker:'
          Font.Name = 'Segoe UI'
          ParentFont = False
        end
        object lblTotalImpressions: TLabel
          Left = 460
          Top = 28
          Width = 99
          Height = 15
          Caption = 'Total Impressions:'
          Font.Name = 'Segoe UI'
          ParentFont = False
        end
        object lblNotes: TLabel
          Left = 16
          Top = 78
          Width = 34
          Height = 15
          Caption = 'Notes:'
          Font.Name = 'Segoe UI'
          ParentFont = False
        end
        object cmbStatus: TComboBox
          Left = 16
          Top = 48
          Width = 165
          Height = 23
          Style = csDropDownList
          Font.Name = 'Segoe UI'
          ParentFont = False
          TabOrder = 0
        end
        object edtDieMaker: TEdit
          Left = 200
          Top = 48
          Width = 240
          Height = 23
          Font.Name = 'Segoe UI'
          ParentFont = False
          TabOrder = 1
        end
        object edtTotalImpressions: TEdit
          Left = 460
          Top = 48
          Width = 160
          Height = 23
          Font.Name = 'Segoe UI'
          ParentFont = False
          TabOrder = 2
          Text = '0'
        end
        object memNotes: TMemo
          Left = 16
          Top = 98
          Width = 776
          Height = 100
          Font.Name = 'Segoe UI'
          ParentFont = False
          ScrollBars = ssVertical
          TabOrder = 3
        end
      end
    end
  end
end
