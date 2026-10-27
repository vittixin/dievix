object frmDieRegister: TfrmDieRegister
  Left = 0
  Top = 0
  Caption = 'Die Master Register — Rotary Tooling Inventory'
  ClientHeight = 700
  ClientWidth = 1100
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
    Width = 1100
    Height = 100
    Align = alTop
    BevelOuter = bvNone
    Color = 16119285
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 10
      Width = 328
      Height = 25
      Caption = 'Rotary Die & Tooling Inventory Register'
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
      Width = 66
      Height = 15
      Caption = 'Quick Search:'
    end
    object lblCustomerFilter: TLabel
      Left = 240
      Top = 45
      Width = 55
      Height = 15
      Caption = 'Customer:'
    end
    object lblTeethFilter: TLabel
      Left = 430
      Top = 45
      Width = 32
      Height = 15
      Caption = 'Teeth:'
    end
    object lblStatusFilter: TLabel
      Left = 530
      Top = 45
      Width = 35
      Height = 15
      Caption = 'Status:'
    end
    object lblMediaFilter: TLabel
      Left = 670
      Top = 45
      Width = 36
      Height = 15
      Caption = 'Media:'
    end
    object edtSearch: TEdit
      Left = 16
      Top = 65
      Width = 210
      Height = 23
      Hint = 'Search Serial, Description, Customer Ref, Internal Ref'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 0
      OnChange = FilterChange
    end
    object cmbCustomerFilter: TComboBox
      Left = 240
      Top = 65
      Width = 180
      Height = 23
      Style = csDropDownList
      TabOrder = 1
      OnChange = FilterChange
    end
    object cmbTeethFilter: TComboBox
      Left = 430
      Top = 65
      Width = 90
      Height = 23
      Style = csDropDownList
      TabOrder = 2
      OnChange = FilterChange
    end
    object cmbStatusFilter: TComboBox
      Left = 530
      Top = 65
      Width = 130
      Height = 23
      Style = csDropDownList
      TabOrder = 3
      OnChange = FilterChange
    end
    object cmbMediaFilter: TComboBox
      Left = 670
      Top = 65
      Width = 120
      Height = 23
      Style = csDropDownList
      TabOrder = 4
      OnChange = FilterChange
    end
    object chkOnlySub3mm: TCheckBox
      Left = 800
      Top = 67
      Width = 95
      Height = 17
      Caption = 'Sub-3mm Gap'
      TabOrder = 5
      OnClick = FilterChange
    end
    object chkIncludeArchived: TCheckBox
      Left = 900
      Top = 67
      Width = 110
      Height = 17
      Caption = 'Include Archived'
      TabOrder = 6
      OnClick = FilterChange
    end
    object btnClearFilters: TButton
      Left = 1015
      Top = 63
      Width = 75
      Height = 26
      Caption = 'Reset'
      TabOrder = 7
      OnClick = btnClearFiltersClick
    end
  end
  object pnlSmartFinder: TPanel
    Left = 0
    Top = 100
    Width = 1100
    Height = 74
    Align = alTop
    BevelOuter = bvNone
    Color = 16250352
    ParentBackground = False
    TabOrder = 1
    object lblSmartTitle: TLabel
      Left = 16
      Top = 8
      Width = 127
      Height = 15
      Caption = 'Smart Die Size Finder:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
    object lblTargetAround: TLabel
      Left = 160
      Top = 8
      Width = 107
      Height = 15
      Caption = 'Target Around (mm):'
    end
    object lblTargetAcross: TLabel
      Left = 345
      Top = 8
      Width = 104
      Height = 15
      Caption = 'Target Across (mm):'
    end
    object lblTolerance: TLabel
      Left = 525
      Top = 8
      Width = 59
      Height = 15
      Caption = 'Tol ('#177'mm):'
    end
    object lblMachine: TLabel
      Left = 16
      Top = 42
      Width = 50
      Height = 15
      Caption = 'Machine:'
    end
    object lblShape: TLabel
      Left = 240
      Top = 42
      Width = 35
      Height = 15
      Caption = 'Shape:'
    end
    object lblCutType: TLabel
      Left = 400
      Top = 42
      Width = 50
      Height = 15
      Caption = 'Cut Type:'
    end
    object lblRadius: TLabel
      Left = 575
      Top = 42
      Width = 64
      Height = 15
      Caption = 'Radius (mm):'
    end
    object edtTargetAround: TEdit
      Left = 272
      Top = 5
      Width = 65
      Height = 23
      TabOrder = 0
      Text = '150.000'
    end
    object edtTargetAcross: TEdit
      Left = 454
      Top = 5
      Width = 65
      Height = 23
      TabOrder = 1
      Text = '100.000'
    end
    object edtTolerance: TEdit
      Left = 588
      Top = 5
      Width = 45
      Height = 23
      TabOrder = 2
      Text = '2.000'
    end
    object chkIncludeSlitting: TCheckBox
      Left = 645
      Top = 7
      Width = 240
      Height = 17
      Caption = 'Include Across Slitting Candidates'
      Checked = True
      State = cbChecked
      TabOrder = 3
    end
    object cmbMachineFilter: TComboBox
      Left = 72
      Top = 38
      Width = 155
      Height = 23
      Style = csDropDownList
      TabOrder = 4
    end
    object cmbShapeFilter: TComboBox
      Left = 282
      Top = 38
      Width = 105
      Height = 23
      Style = csDropDownList
      TabOrder = 5
    end
    object cmbCutTypeFilter: TComboBox
      Left = 455
      Top = 38
      Width = 110
      Height = 23
      Style = csDropDownList
      TabOrder = 6
    end
    object edtRadiusFilter: TEdit
      Left = 645
      Top = 38
      Width = 50
      Height = 23
      TabOrder = 7
    end
    object btnSmartSearch: TButton
      Left = 900
      Top = 5
      Width = 180
      Height = 27
      Caption = 'Find Reusable Dies'
      TabOrder = 8
      OnClick = btnSmartSearchClick
    end
    object btnClearSmartSearch: TButton
      Left = 900
      Top = 36
      Width = 180
      Height = 27
      Caption = 'Clear Size Search'
      TabOrder = 9
      OnClick = btnClearSmartSearchClick
    end
  end
  object pnlActions: TPanel
    Left = 0
    Top = 174
    Width = 1100
    Height = 45
    Align = alTop
    BevelOuter = bvNone
    Color = 15790320
    ParentBackground = False
    TabOrder = 2
    object btnNew: TButton
      Left = 16
      Top = 8
      Width = 95
      Height = 30
      Caption = '+ New Die...'
      Default = True
      TabOrder = 0
      OnClick = btnNewClick
    end
    object btnEdit: TButton
      Left = 117
      Top = 8
      Width = 95
      Height = 30
      Caption = 'Edit Tooling...'
      TabOrder = 1
      OnClick = btnEditClick
    end
    object btnView: TButton
      Left = 218
      Top = 8
      Width = 85
      Height = 30
      Caption = 'View Details'
      TabOrder = 2
      OnClick = btnViewClick
    end
    object btnChangeStatus: TButton
      Left = 309
      Top = 8
      Width = 105
      Height = 30
      Caption = 'Change Status...'
      TabOrder = 3
      OnClick = btnChangeStatusClick
    end
    object btnRelocate: TButton
      Left = 420
      Top = 8
      Width = 105
      Height = 30
      Caption = 'Move Location...'
      TabOrder = 4
      OnClick = btnRelocateClick
    end
    object btnArchive: TButton
      Left = 531
      Top = 8
      Width = 115
      Height = 30
      Caption = 'Archive Tooling...'
      TabOrder = 5
      OnClick = btnArchiveClick
    end
    object btnRestore: TButton
      Left = 652
      Top = 8
      Width = 110
      Height = 30
      Caption = 'Restore Tooling...'
      TabOrder = 6
      OnClick = btnRestoreClick
    end
    object btnPermanentDelete: TButton
      Left = 768
      Top = 8
      Width = 125
      Height = 30
      Caption = 'Permanent Delete...'
      TabOrder = 7
      OnClick = btnPermanentDeleteClick
    end
    object btnRefresh: TButton
      Left = 899
      Top = 8
      Width = 85
      Height = 30
      Caption = 'Refresh'
      TabOrder = 8
      OnClick = btnRefreshClick
    end
    object btnClose: TButton
      Left = 990
      Top = 8
      Width = 90
      Height = 30
      Cancel = True
      Caption = 'Close'
      TabOrder = 9
      OnClick = btnCloseClick
    end
  end
  object gridDies: TStringGrid
    Left = 0
    Top = 219
    Width = 1100
    Height = 451
    Align = alClient
    ColCount = 12
    DefaultColWidth = 90
    FixedCols = 0
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRowSelect]
    TabOrder = 3
    OnDblClick = gridDiesDblClick
  end
  object pnlStatus: TPanel
    Left = 0
    Top = 670
    Width = 1100
    Height = 30
    Align = alBottom
    BevelOuter = bvNone
    Color = 15790320
    ParentBackground = False
    TabOrder = 4
    object lblCount: TLabel
      Left = 16
      Top = 8
      Width = 115
      Height = 15
      Caption = 'Showing 0 of 0 records'
    end
    object lblSub3mmNotice: TLabel
      Left = 450
      Top = 8
      Width = 420
      Height = 15
      Caption = 
        '* Dies with around gap < 3.000 mm require production management override.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 1973790
      Font.Height = -11
      Font.Name = 'Segoe UI Semibold'
      Font.Style = []
      ParentFont = False
    end
  end
end
