object frmKeylineCalculator: TfrmKeylineCalculator
  Left = 0
  Top = 0
  Caption = 'Keyline Calculator & Rotary Layout Designer '#8212' DieVix'
  ClientHeight = 800
  ClientWidth = 1260
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 1260
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = 16119285
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 8
      Width = 437
      Height = 25
      Caption = 'Intelligent Keyline Calculator & Cylinder Optimizer'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblSubtitle: TLabel
      Left = 16
      Top = 35
      Width = 595
      Height = 15
      Caption = 'Calculate repeats, around/across gaps, press web-fit, discover reusable tooling, and design production layouts.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 5395026
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
  object pnlLeft: TPanel
    Left = 0
    Top = 60
    Width = 320
    Height = 740
    Align = alLeft
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 1
    object grpDimensions: TGroupBox
      Left = 10
      Top = 6
      Width = 300
      Height = 130
      Caption = ' Target Label Geometry '
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      object lblAroundSize: TLabel
        Left = 12
        Top = 22
        Width = 96
        Height = 15
        Caption = 'Around Size (mm):'
        Font.Style = []
        ParentFont = False
      end
      object lblAcrossSize: TLabel
        Left = 156
        Top = 22
        Width = 92
        Height = 15
        Caption = 'Across Size (mm):'
        Font.Style = []
        ParentFont = False
      end
      object lblShape: TLabel
        Left = 12
        Top = 72
        Width = 35
        Height = 15
        Caption = 'Shape:'
        Font.Style = []
        ParentFont = False
      end
      object lblCornerRadius: TLabel
        Left = 156
        Top = 72
        Width = 84
        Height = 15
        Caption = 'Radius (mm):'
        Font.Style = []
        ParentFont = False
      end
      object edtAroundSize: TEdit
        Left = 12
        Top = 40
        Width = 130
        Height = 23
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        Text = '150.000'
      end
      object edtAcrossSize: TEdit
        Left = 156
        Top = 40
        Width = 130
        Height = 23
        Font.Style = []
        ParentFont = False
        TabOrder = 1
        Text = '100.000'
      end
      object cmbShape: TComboBox
        Left = 12
        Top = 90
        Width = 130
        Height = 23
        Style = csDropDownList
        Font.Style = []
        ItemIndex = 0
        ParentFont = False
        TabOrder = 2
        Text = 'Rectangle'
        Items.Strings = (
          'Rectangle'
          'Oval'
          'Circle'
          'Special')
      end
      object edtCornerRadius: TEdit
        Left = 156
        Top = 90
        Width = 130
        Height = 23
        Font.Style = []
        ParentFont = False
        TabOrder = 3
        Text = '2.000'
      end
    end
    object grpPress: TGroupBox
      Left = 10
      Top = 142
      Width = 300
      Height = 125
      Caption = ' Printing Press & Tooling Fleet '
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      object lblMachine: TLabel
        Left = 12
        Top = 22
        Width = 75
        Height = 15
        Caption = 'Printing Press:'
        Font.Style = []
        ParentFont = False
      end
      object lblCustomer: TLabel
        Left = 12
        Top = 70
        Width = 113
        Height = 15
        Caption = 'Customer (Optional):'
        Font.Style = []
        ParentFont = False
      end
      object cmbMachine: TComboBox
        Left = 12
        Top = 40
        Width = 274
        Height = 23
        Style = csDropDownList
        Font.Style = []
        ParentFont = False
        TabOrder = 0
      end
      object cmbCustomer: TComboBox
        Left = 12
        Top = 88
        Width = 274
        Height = 23
        Style = csDropDownList
        Font.Style = []
        ParentFont = False
        TabOrder = 1
      end
    end
    object grpLayout: TGroupBox
      Left = 10
      Top = 273
      Width = 300
      Height = 175
      Caption = ' Multi-Ups & Scan Mode '
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      object lblMaxUps: TLabel
        Left = 12
        Top = 80
        Width = 74
        Height = 15
        Caption = 'Max Scan Ups:'
        Font.Style = []
        ParentFont = False
      end
      object lblFixedUps: TLabel
        Left = 156
        Top = 80
        Width = 87
        Height = 15
        Caption = 'Fixed Around-Up:'
        Font.Style = []
        ParentFont = False
      end
      object lblAcrossUps: TLabel
        Left = 12
        Top = 128
        Width = 99
        Height = 15
        Caption = 'Across Ups (Lanes):'
        Font.Style = []
        ParentFont = False
      end
      object rgUpsMode: TRadioGroup
        Left = 12
        Top = 22
        Width = 274
        Height = 52
        Caption = ' Around Ups Mode '
        Columns = 2
        Font.Style = []
        ItemIndex = 0
        Items.Strings = (
          'Auto Scan'
          'Fixed Ups')
        ParentFont = False
        TabOrder = 0
        OnClick = rgUpsModeClick
      end
      object edtMaxUps: TEdit
        Left = 12
        Top = 98
        Width = 130
        Height = 23
        Font.Style = []
        ParentFont = False
        TabOrder = 1
        Text = '10'
      end
      object edtFixedUps: TEdit
        Left = 156
        Top = 98
        Width = 130
        Height = 23
        Enabled = False
        Font.Style = []
        ParentFont = False
        TabOrder = 2
        Text = '3'
      end
      object edtAcrossUps: TEdit
        Left = 12
        Top = 146
        Width = 130
        Height = 23
        Font.Style = []
        ParentFont = False
        TabOrder = 3
        Text = '2'
      end
    end
    object grpGaps: TGroupBox
      Left = 10
      Top = 454
      Width = 300
      Height = 165
      Caption = ' Gaps & Margins (mm) '
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
      object lblMinAroundGap: TLabel
        Left = 12
        Top = 22
        Width = 123
        Height = 15
        Caption = 'Min Around Gap (mm):'
        Font.Style = []
        ParentFont = False
      end
      object lblAcrossGap: TLabel
        Left = 156
        Top = 22
        Width = 89
        Height = 15
        Caption = 'Across Gap (mm):'
        Font.Style = []
        ParentFont = False
      end
      object lblMargins: TLabel
        Left = 12
        Top = 70
        Width = 128
        Height = 15
        Caption = 'Left / Right Margin (mm):'
        Font.Style = []
        ParentFont = False
      end
      object edtMinAroundGap: TEdit
        Left = 12
        Top = 40
        Width = 130
        Height = 23
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        Text = '3.000'
      end
      object edtAcrossGap: TEdit
        Left = 156
        Top = 40
        Width = 130
        Height = 23
        Font.Style = []
        ParentFont = False
        TabOrder = 1
        Text = '3.000'
      end
      object edtLeftMargin: TEdit
        Left = 12
        Top = 88
        Width = 130
        Height = 23
        Font.Style = []
        ParentFont = False
        TabOrder = 2
        Text = '5.000'
      end
      object edtRightMargin: TEdit
        Left = 156
        Top = 88
        Width = 130
        Height = 23
        Font.Style = []
        ParentFont = False
        TabOrder = 3
        Text = '5.000'
      end
      object chkActiveCylinders: TCheckBox
        Left = 12
        Top = 130
        Width = 274
        Height = 17
        Caption = 'Filter Active Cylinder Fleet Only'
        Checked = True
        Font.Style = []
        ParentFont = False
        State = cbChecked
        TabOrder = 4
      end
    end
    object pnlCalculateButtons: TPanel
      Left = 10
      Top = 625
      Width = 300
      Height = 90
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 4
      object btnCalculate: TButton
        Left = 0
        Top = 6
        Width = 300
        Height = 40
        Caption = #9889' Calculate Recommendations'
        Default = True
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        OnClick = btnCalculateClick
      end
      object btnReset: TButton
        Left = 0
        Top = 52
        Width = 300
        Height = 30
        Caption = 'Reset Defaults'
        Font.Style = []
        ParentFont = False
        TabOrder = 1
        OnClick = btnResetClick
      end
    end
  end
  object pnlCenterArea: TPanel
    Left = 320
    Top = 60
    Width = 940
    Height = 740
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    object splBottom: TSplitter
      Left = 0
      Top = 515
      Width = 940
      Height = 5
      Cursor = crVSplit
      Align = alBottom
      ExplicitTop = 500
    end
    object pnlRecommendations: TPanel
      Left = 0
      Top = 0
      Width = 490
      Height = 515
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 0
      object pnlRecHeader: TPanel
        Left = 0
        Top = 0
        Width = 490
        Height = 36
        Align = alTop
        BevelOuter = bvNone
        Color = 15395562
        ParentBackground = False
        TabOrder = 0
        object lblRecTitle: TLabel
          Left = 12
          Top = 9
          Width = 191
          Height = 17
          Caption = 'Cylinder Recommendations'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Segoe UI Semibold'
          Font.Style = []
          ParentFont = False
        end
        object lblRecSummary: TLabel
          Left = 215
          Top = 10
          Width = 143
          Height = 15
          Caption = 'Ready for calculation'
          Font.Color = 5395026
          ParentFont = False
        end
      end
      object gridRecommendations: TStringGrid
        Left = 0
        Top = 36
        Width = 490
        Height = 479
        Align = alClient
        ColCount = 10
        DefaultRowHeight = 24
        FixedCols = 0
        RowCount = 2
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRowSelect, goSelectionActive]
        TabOrder = 1
        OnDrawCell = gridRecommendationsDrawCell
        OnSelectCell = gridRecommendationsSelectCell
      end
    end
    object splPreview: TSplitter
      Left = 490
      Top = 0
      Width = 5
      Height = 515
      Align = alRight
      ExplicitLeft = 500
      ExplicitTop = 36
      ExplicitHeight = 479
    end
    object pnlRightPreview: TPanel
      Left = 495
      Top = 0
      Width = 445
      Height = 515
      Align = alRight
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 1
      object pnlPreviewToolbar: TPanel
        Left = 0
        Top = 0
        Width = 445
        Height = 36
        Align = alTop
        BevelOuter = bvNone
        Color = 15395562
        ParentBackground = False
        TabOrder = 0
        object lblPreviewTitle: TLabel
          Left = 10
          Top = 9
          Width = 139
          Height = 17
          Caption = '2D Rotary Die Preview'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Segoe UI Semibold'
          Font.Style = []
          ParentFont = False
        end
        object btnFit: TButton
          Left = 160
          Top = 5
          Width = 45
          Height = 25
          Caption = 'Fit'
          TabOrder = 0
          OnClick = btnFitClick
        end
        object btnZoomIn: TButton
          Left = 210
          Top = 5
          Width = 55
          Height = 25
          Caption = 'Zoom +'
          TabOrder = 1
          OnClick = btnZoomInClick
        end
        object btnZoomOut: TButton
          Left = 270
          Top = 5
          Width = 55
          Height = 25
          Caption = 'Zoom -'
          TabOrder = 2
          OnClick = btnZoomOutClick
        end
        object chkShowDimensions: TCheckBox
          Left = 335
          Top = 9
          Width = 100
          Height = 17
          Caption = 'Dimensions'
          Checked = True
          State = cbChecked
          TabOrder = 3
          OnClick = chkShowDimensionsClick
        end
      end
      object pnlPreviewCanvas: TPanel
        Left = 0
        Top = 36
        Width = 445
        Height = 457
        Align = alClient
        BevelOuter = bvNone
        Color = 16579836
        DoubleBuffered = True
        ParentBackground = False
        TabOrder = 1
        object paintPreview: TPaintBox
          Left = 0
          Top = 0
          Width = 445
          Height = 457
          Align = alClient
          OnPaint = paintPreviewPaint
        end
      end
      object lblPreviewFootnote: TLabel
        Left = 0
        Top = 493
        Width = 445
        Height = 22
        Align = alBottom
        Alignment = taCenter
        AutoSize = False
        Caption = 'Schematic 2D representation. Complex blade shapes must be verified with tooling specs.'
        Color = 15921906
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 5395026
        Font.Height = -10
        Font.Name = 'Segoe UI'
        Font.Style = [fsItalic]
        ParentColor = False
        ParentFont = False
        Transparent = False
        Layout = tlCenter
      end
    end
    object pnlBottom: TPanel
      Left = 0
      Top = 520
      Width = 940
      Height = 220
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 2
      object pnlBottomHeader: TPanel
        Left = 0
        Top = 0
        Width = 940
        Height = 32
        Align = alTop
        BevelOuter = bvNone
        Color = 15395562
        ParentBackground = False
        TabOrder = 0
        object lblBottomTitle: TLabel
          Left = 12
          Top = 7
          Width = 265
          Height = 17
          Caption = 'Matching Reusable Tooling in Inventory'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Segoe UI Semibold'
          Font.Style = []
          ParentFont = False
        end
        object lblMatchCount: TLabel
          Left = 290
          Top = 8
          Width = 107
          Height = 15
          Caption = '0 matching dies found'
          Font.Color = 5395026
          ParentFont = False
        end
      end
      object gridExistingDies: TStringGrid
        Left = 0
        Top = 32
        Width = 940
        Height = 146
        Align = alClient
        ColCount = 10
        DefaultRowHeight = 22
        FixedCols = 0
        RowCount = 2
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRowSelect, goSelectionActive]
        TabOrder = 1
        OnDblClick = gridExistingDiesDblClick
      end
      object pnlBottomActions: TPanel
        Left = 0
        Top = 178
        Width = 940
        Height = 42
        Align = alBottom
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 2
        object btnCreateDie: TButton
          Left = 12
          Top = 6
          Width = 220
          Height = 30
          Caption = #9733' Create Die From Selection...'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI Semibold'
          Font.Style = []
          ParentFont = False
          TabOrder = 0
          OnClick = btnCreateDieClick
        end
        object btnOpenExistingDie: TButton
          Left = 240
          Top = 6
          Width = 180
          Height = 30
          Caption = 'Open Selected Tooling...'
          TabOrder = 1
          OnClick = btnOpenExistingDieClick
        end
        object btnClose: TButton
          Left = 840
          Top = 6
          Width = 90
          Height = 30
          Anchors = [akTop, akRight]
          Caption = 'Close'
          TabOrder = 2
          OnClick = btnCloseClick
        end
      end
    end
  end
end
