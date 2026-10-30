object frmDieEditor: TfrmDieEditor
  Left = 0
  Top = 0
  Caption = 'Die Tooling Editor'
  ClientHeight = 650
  ClientWidth = 850
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  OnCloseQuery = FormCloseQuery
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
      Width = 196
      Height = 25
      Caption = 'Die Tooling Definition'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblStatusBadge: TLabel
      Left = 580
      Top = 14
      Width = 100
      Height = 20
      Alignment = taCenter
      AutoSize = False
      Caption = 'READY'
      Color = clSilver
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -12
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentColor = False
      ParentFont = False
      Transparent = False
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 600
    Width = 850
    Height = 50
    Align = alBottom
    BevelOuter = bvNone
    Color = 15790320
    ParentBackground = False
    TabOrder = 1
    object btnSave: TButton
      Left = 570
      Top = 10
      Width = 120
      Height = 30
      Caption = 'Save Die Tooling'
      Default = True
      TabOrder = 0
      OnClick = btnSaveClick
    end
    object btnCancel: TButton
      Left = 710
      Top = 10
      Width = 120
      Height = 30
      Cancel = True
      Caption = 'Cancel / Close'
      TabOrder = 1
      OnClick = btnCancelClick
    end
    object btnCheckSimilar: TButton
      Left = 16
      Top = 10
      Width = 160
      Height = 30
      Caption = 'Check Similar Tooling...'
      TabOrder = 2
      OnClick = btnCheckSimilarClick
    end
    object btnPrintJobCard: TButton
      Left = 185
      Top = 10
      Width = 150
      Height = 30
      Caption = 'Print Job Card...'
      TabOrder = 3
      OnClick = btnPrintJobCardClick
    end
  end
  object pageDie: TPageControl
    Left = 0
    Top = 50
    Width = 850
    Height = 550
    ActivePage = tabGeometry
    Align = alClient
    TabOrder = 2
    object tabGeometry: TTabSheet
      Caption = 'Tooling & Geometry'
      object grpIdentification: TGroupBox
        Left = 10
        Top = 10
        Width = 400
        Height = 260
        Caption = ' Identification '
        TabOrder = 0
        object lblSerial: TLabel
          Left = 12
          Top = 25
          Width = 79
          Height = 15
          Caption = 'Die Serial No *:'
        end
        object lblCustomer: TLabel
          Left = 12
          Top = 55
          Width = 55
          Height = 15
          Caption = 'Customer:'
        end
        object lblDescription: TLabel
          Left = 12
          Top = 85
          Width = 63
          Height = 15
          Caption = 'Description:'
        end
        object lblInternalRef: TLabel
          Left = 12
          Top = 115
          Width = 62
          Height = 15
          Caption = 'Internal Ref:'
        end
        object lblCustomerRef: TLabel
          Left = 12
          Top = 145
          Width = 75
          Height = 15
          Caption = 'Customer Ref:'
        end
        object lblMedia: TLabel
          Left = 12
          Top = 175
          Width = 36
          Height = 15
          Caption = 'Media:'
        end
        object lblStatus: TLabel
          Left = 12
          Top = 205
          Width = 44
          Height = 15
          Caption = 'Status *:'
        end
        object edtSerial: TEdit
          Left = 110
          Top = 22
          Width = 270
          Height = 23
          TabOrder = 0
          OnChange = ControlChange
        end
        object cmbCustomer: TComboBox
          Left = 110
          Top = 52
          Width = 270
          Height = 23
          Style = csDropDownList
          TabOrder = 1
          OnChange = ControlChange
        end
        object edtDescription: TEdit
          Left = 110
          Top = 82
          Width = 270
          Height = 23
          TabOrder = 2
          OnChange = ControlChange
        end
        object edtInternalRef: TEdit
          Left = 110
          Top = 112
          Width = 270
          Height = 23
          TabOrder = 3
          OnChange = ControlChange
        end
        object edtCustomerRef: TEdit
          Left = 110
          Top = 142
          Width = 270
          Height = 23
          TabOrder = 4
          OnChange = ControlChange
        end
        object cmbMedia: TComboBox
          Left = 110
          Top = 172
          Width = 270
          Height = 23
          Style = csDropDownList
          TabOrder = 5
          OnChange = ControlChange
        end
        object cmbStatus: TComboBox
          Left = 110
          Top = 202
          Width = 270
          Height = 23
          Style = csDropDownList
          TabOrder = 6
          OnChange = ControlChange
        end
      end
      object grpDimensions: TGroupBox
        Left = 425
        Top = 10
        Width = 400
        Height = 260
        Caption = ' Tooling Specifications '
        TabOrder = 1
        object lblTeeth: TLabel
          Left = 12
          Top = 25
          Width = 84
          Height = 15
          Caption = 'Cylinder Teeth *:'
        end
        object lblPitch: TLabel
          Left = 215
          Top = 25
          Width = 60
          Height = 15
          Caption = 'Pitch (um):'
        end
        object lblAroundSize: TLabel
          Left = 12
          Top = 55
          Width = 106
          Height = 15
          Caption = 'Label Around (mm)*:'
        end
        object lblAcrossSize: TLabel
          Left = 215
          Top = 55
          Width = 102
          Height = 15
          Caption = 'Label Across (mm)*:'
        end
        object lblAroundUps: TLabel
          Left = 12
          Top = 85
          Width = 73
          Height = 15
          Caption = 'Around Ups *:'
        end
        object lblAcrossUps: TLabel
          Left = 215
          Top = 85
          Width = 69
          Height = 15
          Caption = 'Across Ups *:'
        end
        object lblAcrossGap: TLabel
          Left = 12
          Top = 115
          Width = 89
          Height = 15
          Caption = 'Across Gap (mm):'
        end
        object lblCornerRadius: TLabel
          Left = 215
          Top = 115
          Width = 105
          Height = 15
          Caption = 'Corner Radius (mm):'
        end
        object lblShape: TLabel
          Left = 12
          Top = 145
          Width = 35
          Height = 15
          Caption = 'Shape:'
        end
        object lblCutType: TLabel
          Left = 215
          Top = 145
          Width = 49
          Height = 15
          Caption = 'Cut Type:'
        end
        object cmbTeeth: TComboBox
          Left = 120
          Top = 22
          Width = 80
          Height = 23
          Style = csDropDownList
          TabOrder = 0
          OnChange = DimensionChange
        end
        object edtPitch: TEdit
          Left = 285
          Top = 22
          Width = 100
          Height = 23
          TabOrder = 1
          Text = '3175'
          OnChange = DimensionChange
        end
        object edtAroundSize: TEdit
          Left = 120
          Top = 52
          Width = 80
          Height = 23
          TabOrder = 2
          Text = '50.000'
          OnChange = DimensionChange
        end
        object edtAcrossSize: TEdit
          Left = 320
          Top = 52
          Width = 65
          Height = 23
          TabOrder = 3
          Text = '50.000'
          OnChange = DimensionChange
        end
        object edtAroundUps: TEdit
          Left = 120
          Top = 82
          Width = 80
          Height = 23
          TabOrder = 4
          Text = '1'
          OnChange = DimensionChange
        end
        object edtAcrossUps: TEdit
          Left = 320
          Top = 82
          Width = 65
          Height = 23
          TabOrder = 5
          Text = '1'
          OnChange = DimensionChange
        end
        object edtAcrossGap: TEdit
          Left = 120
          Top = 112
          Width = 80
          Height = 23
          TabOrder = 6
          Text = '3.000'
          OnChange = ControlChange
        end
        object edtCornerRadius: TEdit
          Left = 325
          Top = 112
          Width = 60
          Height = 23
          TabOrder = 7
          Text = '2.000'
          OnChange = ControlChange
        end
        object cmbShape: TComboBox
          Left = 120
          Top = 142
          Width = 80
          Height = 23
          Style = csDropDownList
          ItemIndex = 0
          TabOrder = 8
          Text = 'RECTANGLE'
          OnChange = ControlChange
          Items.Strings = (
            'RECTANGLE'
            'CIRCLE'
            'OVAL'
            'SPECIAL')
        end
        object cmbCutType: TComboBox
          Left = 285
          Top = 142
          Width = 100
          Height = 23
          Style = csDropDownList
          ItemIndex = 0
          TabOrder = 9
          Text = 'ROTARY'
          OnChange = ControlChange
          Items.Strings = (
            'ROTARY'
            'FLEXIBLE'
            'SEMI-ROTARY')
        end
      end
      object grpCalculated: TGroupBox
        Left = 10
        Top = 280
        Width = 815
        Height = 230
        Caption = ' Live Rotary Geometry & Gap Policy (Exact Integer Micrometre Math) '
        TabOrder = 2
        object lblRepeatDisplay: TLabel
          Left = 16
          Top = 28
          Width = 150
          Height = 15
          Caption = 'Cylinder Repeat:'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI Semibold'
          Font.Style = []
          ParentFont = False
        end
        object valRepeatMm: TLabel
          Left = 175
          Top = 28
          Width = 100
          Height = 15
          Caption = '304.800 mm'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object valRepeatInch: TLabel
          Left = 300
          Top = 28
          Width = 70
          Height = 15
          Caption = '(12.000")'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGrayText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblAroundGapDisplay: TLabel
          Left = 16
          Top = 58
          Width = 150
          Height = 15
          Caption = 'Calculated Around Gap:'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI Semibold'
          Font.Style = []
          ParentFont = False
        end
        object valAroundGapMm: TLabel
          Left = 175
          Top = 58
          Width = 100
          Height = 15
          Caption = '3.000 mm'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object valGapStatus: TLabel
          Left = 300
          Top = 56
          Width = 140
          Height = 20
          Alignment = taCenter
          AutoSize = False
          Caption = 'APPROVED'
          Color = 32768
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -11
          Font.Name = 'Segoe UI Semibold'
          Font.Style = []
          ParentColor = False
          ParentFont = False
          Transparent = False
        end
        object lblCutPoolDisplay: TLabel
          Left = 470
          Top = 28
          Width = 140
          Height = 15
          Caption = 'Total Cut Length:'
        end
        object valCutLengthMm: TLabel
          Left = 620
          Top = 28
          Width = 100
          Height = 15
          Caption = '294.000 mm'
        end
        object lblWasteDisplay: TLabel
          Left = 470
          Top = 58
          Width = 140
          Height = 15
          Caption = 'Circumference Waste %:'
        end
        object valWastePercent: TLabel
          Left = 620
          Top = 58
          Width = 100
          Height = 15
          Caption = '3.54 %'
        end
        object lblOverrideReason: TLabel
          Left = 16
          Top = 95
          Width = 240
          Height = 15
          Caption = 'Override Reason (Mandatory if gap < 3.000 mm):'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 1973790
          Font.Height = -12
          Font.Name = 'Segoe UI Semibold'
          Font.Style = []
          ParentFont = False
        end
        object edtOverrideReason: TEdit
          Left = 16
          Top = 118
          Width = 780
          Height = 23
          Color = clWindow
          TabOrder = 0
          OnChange = ControlChange
        end
        object lblFormulaExpl: TLabel
          Left = 16
          Top = 155
          Width = 780
          Height = 30
          AutoSize = False
          Caption = 
            'Exact Math: AroundGapUm = (Teeth * PitchUm - AroundUps * AroundSizeUm) / AroundUps. No floating point rounding errors.'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGrayText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsItalic]
          ParentFont = False
          WordWrap = True
        end
      end
    end
    object tabInventory: TTabSheet
      Caption = 'Physical Storage & Sourcing'
      ImageIndex = 1
      object grpStorage: TGroupBox
        Left = 16
        Top = 16
        Width = 800
        Height = 220
        Caption = ' Tooling Storage Location '
        TabOrder = 0
        object lblRack: TLabel
          Left = 20
          Top = 35
          Width = 72
          Height = 15
          Caption = 'Storage Rack:'
        end
        object lblShelf: TLabel
          Left = 20
          Top = 75
          Width = 72
          Height = 15
          Caption = 'Storage Shelf:'
        end
        object lblBin: TLabel
          Left = 20
          Top = 115
          Width = 67
          Height = 15
          Caption = 'Storage Bin:'
        end
        object lblLocationNotes: TLabel
          Left = 20
          Top = 155
          Width = 77
          Height = 15
          Caption = 'Location Desc:'
        end
        object edtStorageRack: TEdit
          Left = 120
          Top = 32
          Width = 200
          Height = 23
          TabOrder = 0
          OnChange = ControlChange
        end
        object edtStorageShelf: TEdit
          Left = 120
          Top = 72
          Width = 200
          Height = 23
          TabOrder = 1
          OnChange = ControlChange
        end
        object edtStorageBin: TEdit
          Left = 120
          Top = 112
          Width = 200
          Height = 23
          TabOrder = 2
          OnChange = ControlChange
        end
        object edtLocationNotes: TEdit
          Left = 120
          Top = 152
          Width = 500
          Height = 23
          TabOrder = 3
          OnChange = ControlChange
        end
      end
      object grpProcurement: TGroupBox
        Left = 16
        Top = 250
        Width = 800
        Height = 240
        Caption = ' Manufacturing & Procurement Details '
        TabOrder = 1
        object lblDieMaker: TLabel
          Left = 20
          Top = 35
          Width = 58
          Height = 15
          Caption = 'Die Maker:'
        end
        object lblSupplierRef: TLabel
          Left = 20
          Top = 75
          Width = 70
          Height = 15
          Caption = 'Supplier Ref:'
        end
        object lblTotalRun: TLabel
          Left = 20
          Top = 115
          Width = 106
          Height = 15
          Caption = 'Total Run (Metres):'
        end
        object lblPurchaseDate: TLabel
          Left = 400
          Top = 35
          Width = 77
          Height = 15
          Caption = 'Purchase Date:'
        end
        object lblReceivedDate: TLabel
          Left = 400
          Top = 75
          Width = 77
          Height = 15
          Caption = 'Received Date:'
        end
        object lblNotes: TLabel
          Left = 20
          Top = 155
          Width = 83
          Height = 15
          Caption = 'Tooling Notes:'
        end
        object edtDieMaker: TEdit
          Left = 135
          Top = 32
          Width = 220
          Height = 23
          TabOrder = 0
          OnChange = ControlChange
        end
        object edtSupplierRef: TEdit
          Left = 135
          Top = 72
          Width = 220
          Height = 23
          TabOrder = 1
          OnChange = ControlChange
        end
        object edtTotalRun: TEdit
          Left = 135
          Top = 112
          Width = 220
          Height = 23
          TabOrder = 2
          Text = '0'
          OnChange = ControlChange
        end
        object edtPurchaseDate: TEdit
          Left = 500
          Top = 32
          Width = 150
          Height = 23
          TabOrder = 3
          OnChange = ControlChange
        end
        object edtReceivedDate: TEdit
          Left = 500
          Top = 72
          Width = 150
          Height = 23
          TabOrder = 4
          OnChange = ControlChange
        end
        object edtNotes: TEdit
          Left = 135
          Top = 152
          Width = 630
          Height = 23
          TabOrder = 5
          OnChange = ControlChange
        end
      end
    end
    object tabAudit: TTabSheet
      Caption = 'Audit History & Concurrency'
      ImageIndex = 2
      object pnlAuditInfo: TPanel
        Left = 0
        Top = 0
        Width = 842
        Height = 45
        Align = alTop
        BevelOuter = bvNone
        Color = 15790320
        ParentBackground = False
        TabOrder = 0
        object lblVersion: TLabel
          Left = 16
          Top = 14
          Width = 47
          Height = 15
          Caption = 'Version: 1'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI Semibold'
          Font.Style = []
          ParentFont = False
        end
        object lblCreatedBy: TLabel
          Left = 150
          Top = 14
          Width = 120
          Height = 15
          Caption = 'Created: -'
        end
        object lblUpdatedBy: TLabel
          Left = 450
          Top = 14
          Width = 120
          Height = 15
          Caption = 'Modified: -'
        end
      end
      object gridAudit: TStringGrid
        Left = 0
        Top = 45
        Width = 842
        Height = 475
        Align = alClient
        ColCount = 7
        DefaultColWidth = 110
        FixedCols = 0
        RowCount = 2
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRowSelect]
        TabOrder = 1
      end
    end
    object tabSimilar: TTabSheet
      Caption = 'Similar Tooling Reuse'
      ImageIndex = 3
      object pnlSimilarHeader: TPanel
        Left = 0
        Top = 0
        Width = 842
        Height = 50
        Align = alTop
        BevelOuter = bvNone
        Color = 15790320
        ParentBackground = False
        TabOrder = 0
        object lblSimilarInfo: TLabel
          Left = 16
          Top = 16
          Width = 650
          Height = 20
          AutoSize = False
          Caption = 'Search existing rotary tooling fleet for potential reuse matches before ordering new dies.'
        end
      end
      object gridSimilar: TStringGrid
        Left = 0
        Top = 50
        Width = 842
        Height = 470
        Align = alClient
        ColCount = 8
        DefaultColWidth = 95
        FixedCols = 0
        RowCount = 2
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRowSelect]
        TabOrder = 1
      end
    end
  end
end
