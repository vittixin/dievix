object frmFlatbedDieRegister: TfrmFlatbedDieRegister
  Left = 0
  Top = 0
  Caption = 'Flatbed Die Master Register '#8212' Tooling Inventory'
  ClientHeight = 720
  ClientWidth = 1150
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
    Width = 1150
    Height = 100
    Align = alTop
    BevelOuter = bvNone
    Color = 16119285
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 10
      Width = 475
      Height = 25
      Caption = 'Flatbed Tooling Register (Rollforms & Sheetforms)'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblSearch: TLabel
      Left = 16
      Top = 45
      Width = 38
      Height = 15
      Caption = 'Search:'
    end
    object lblCategoryFilter: TLabel
      Left = 240
      Top = 45
      Width = 51
      Height = 15
      Caption = 'Category:'
    end
    object lblCustomerFilter: TLabel
      Left = 440
      Top = 45
      Width = 55
      Height = 15
      Caption = 'Customer:'
    end
    object lblStatusFilter: TLabel
      Left = 660
      Top = 45
      Width = 35
      Height = 15
      Caption = 'Status:'
    end
    object edtSearch: TEdit
      Left = 16
      Top = 64
      Width = 205
      Height = 23
      TabOrder = 0
      OnChange = FilterChange
    end
    object cmbCategoryFilter: TComboBox
      Left = 240
      Top = 64
      Width = 180
      Height = 23
      Style = csDropDownList
      ItemIndex = 0
      TabOrder = 1
      Text = '(All Categories)'
      OnChange = FilterChange
      Items.Strings = (
        '(All Categories)'
        'ROLL_FORM (Rollforms)'
        'SHEET_FORM (Sheetforms)')
    end
    object cmbCustomerFilter: TComboBox
      Left = 440
      Top = 64
      Width = 200
      Height = 23
      Style = csDropDownList
      TabOrder = 2
      OnChange = FilterChange
    end
    object cmbStatusFilter: TComboBox
      Left = 660
      Top = 64
      Width = 130
      Height = 23
      Style = csDropDownList
      TabOrder = 3
      OnChange = FilterChange
    end
    object chkIncludeArchived: TCheckBox
      Left = 810
      Top = 66
      Width = 120
      Height = 17
      Caption = 'Include Archived'
      TabOrder = 4
      OnClick = FilterChange
    end
    object btnClearFilters: TButton
      Left = 945
      Top = 62
      Width = 90
      Height = 27
      Caption = 'Clear Filters'
      TabOrder = 5
      OnClick = btnClearFiltersClick
    end
  end
  object pnlSmartFinder: TPanel
    Left = 0
    Top = 100
    Width = 1150
    Height = 75
    Align = alTop
    BevelOuter = bvNone
    Color = 16448250
    ParentBackground = False
    TabOrder = 1
    object lblSmartTitle: TLabel
      Left = 16
      Top = 6
      Width = 437
      Height = 15
      Caption = 
        'Smart Dimensional Matcher '#8212' Searches standard and 90'#176' bi-directional' +
        ' rotated fits'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -12
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblTargetAround: TLabel
      Left = 16
      Top = 26
      Width = 97
      Height = 15
      Caption = 'Target Around mm:'
    end
    object lblTargetAcross: TLabel
      Left = 140
      Top = 26
      Width = 93
      Height = 15
      Caption = 'Target Across mm:'
    end
    object lblTolerance: TLabel
      Left = 264
      Top = 26
      Width = 79
      Height = 15
      Caption = 'Tolerance mm:'
    end
    object edtTargetAround: TEdit
      Left = 16
      Top = 44
      Width = 105
      Height = 23
      TabOrder = 0
    end
    object edtTargetAcross: TEdit
      Left = 140
      Top = 44
      Width = 105
      Height = 23
      TabOrder = 1
    end
    object edtTolerance: TEdit
      Left = 264
      Top = 44
      Width = 85
      Height = 23
      TabOrder = 2
      Text = '0.500'
    end
    object chkAllowRotation: TCheckBox
      Left = 370
      Top = 46
      Width = 195
      Height = 17
      Caption = 'Allow 90'#176' Bi-directional Rotation'
      Checked = True
      State = cbChecked
      TabOrder = 3
    end
    object btnSmartSearch: TButton
      Left = 580
      Top = 42
      Width = 120
      Height = 26
      Caption = 'Find Matching Dies'
      TabOrder = 4
      OnClick = btnSmartSearchClick
    end
    object btnClearSmartSearch: TButton
      Left = 710
      Top = 42
      Width = 90
      Height = 26
      Caption = 'Clear Match'
      TabOrder = 5
      OnClick = btnClearSmartSearchClick
    end
  end
  object pnlActions: TPanel
    Left = 0
    Top = 175
    Width = 1150
    Height = 40
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 2
    object btnNew: TButton
      Left = 16
      Top = 6
      Width = 95
      Height = 28
      Caption = '+ New Flatbed'
      TabOrder = 0
      OnClick = btnNewClick
    end
    object btnEdit: TButton
      Left = 118
      Top = 6
      Width = 80
      Height = 28
      Caption = 'Edit Tooling'
      TabOrder = 1
      OnClick = btnEditClick
    end
    object btnView: TButton
      Left = 204
      Top = 6
      Width = 80
      Height = 28
      Caption = 'View Details'
      TabOrder = 2
      OnClick = btnViewClick
    end
    object btnArchive: TButton
      Left = 290
      Top = 6
      Width = 75
      Height = 28
      Caption = 'Archive'
      TabOrder = 3
      OnClick = btnArchiveClick
    end
    object btnRestore: TButton
      Left = 371
      Top = 6
      Width = 75
      Height = 28
      Caption = 'Restore'
      TabOrder = 4
      OnClick = btnRestoreClick
    end
    object btnPermanentDelete: TButton
      Left = 452
      Top = 6
      Width = 75
      Height = 28
      Caption = 'Delete'
      TabOrder = 5
      OnClick = btnPermanentDeleteClick
    end
    object btnRefresh: TButton
      Left = 533
      Top = 6
      Width = 75
      Height = 28
      Caption = 'Refresh'
      TabOrder = 6
      OnClick = btnRefreshClick
    end
    object btnPrintCard: TButton
      Left = 618
      Top = 6
      Width = 100
      Height = 28
      Caption = 'Tooling Card'
      TabOrder = 7
      OnClick = btnPrintCardClick
    end
    object btnPrintCatalog: TButton
      Left = 724
      Top = 6
      Width = 95
      Height = 28
      Caption = 'Print Catalog'
      TabOrder = 8
      OnClick = btnPrintCatalogClick
    end
    object btnExportXlsx: TButton
      Left = 825
      Top = 6
      Width = 95
      Height = 28
      Caption = 'Export Excel'
      TabOrder = 9
      OnClick = btnExportXlsxClick
    end
    object btnClose: TButton
      Left = 1055
      Top = 6
      Width = 80
      Height = 28
      Anchors = [akTop, akRight]
      Caption = 'Close'
      TabOrder = 10
      OnClick = btnCloseClick
    end
  end
  object gridDies: TStringGrid
    Left = 0
    Top = 215
    Width = 1150
    Height = 475
    Align = alClient
    ColCount = 10
    DefaultRowHeight = 24
    FixedCols = 0
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goRowSelect]
    TabOrder = 3
    OnDblClick = gridDiesDblClick
  end
  object pnlStatus: TPanel
    Left = 0
    Top = 690
    Width = 1150
    Height = 30
    Align = alBottom
    BevelOuter = bvNone
    Color = 16119285
    ParentBackground = False
    TabOrder = 4
    object lblCount: TLabel
      Left = 16
      Top = 7
      Width = 104
      Height = 15
      Caption = 'Showing 0 tooling(s)'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblRotationSummary: TLabel
      Left = 400
      Top = 7
      Width = 320
      Height = 15
      Caption = 'Rotation Rule: 1x1 Rollform & Square Multi-ups = Bi-Directional'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
end
