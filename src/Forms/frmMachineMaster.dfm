object frmMachineMaster: TfrmMachineMaster
  Left = 0
  Top = 0
  Caption = 'Machine Master - DieVix'
  ClientHeight = 520
  ClientWidth = 780
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  Scaled = True
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 780
    Height = 65
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 10
      Width = 142
      Height = 21
      Caption = 'Printing Presses'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblSearch: TLabel
      Left = 16
      Top = 38
      Width = 38
      Height = 15
      Caption = 'Search:'
    end
    object edtSearch: TEdit
      Left = 60
      Top = 35
      Width = 180
      Height = 23
      TabOrder = 0
      OnChange = edtSearchChange
    end
    object chkActiveOnly: TCheckBox
      Left = 260
      Top = 38
      Width = 100
      Height = 17
      Caption = 'Active Only'
      TabOrder = 1
      OnClick = chkActiveOnlyClick
    end
    object btnRefresh: TButton
      Left = 380
      Top = 34
      Width = 75
      Height = 25
      Caption = 'Refresh'
      TabOrder = 2
      OnClick = btnRefreshClick
    end
  end
  object gridMachines: TStringGrid
    Left = 0
    Top = 65
    Width = 780
    Height = 275
    Align = alClient
    ColCount = 7
    DefaultRowHeight = 24
    FixedCols = 0
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goRowSelect]
    TabOrder = 1
    OnSelectCell = gridMachinesSelectCell
  end
  object pnlEdit: TPanel
    Left = 0
    Top = 340
    Width = 780
    Height = 180
    Align = alBottom
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 2
    object lblCode: TLabel
      Left = 20
      Top = 15
      Width = 31
      Height = 15
      Caption = 'Code:'
    end
    object lblName: TLabel
      Left = 130
      Top = 15
      Width = 35
      Height = 15
      Caption = 'Name:'
    end
    object lblMaxWeb: TLabel
      Left = 360
      Top = 15
      Width = 77
      Height = 15
      Caption = 'Max Web (mm):'
    end
    object lblMinWeb: TLabel
      Left = 470
      Top = 15
      Width = 76
      Height = 15
      Caption = 'Min Web (mm):'
    end
    object lblMargin: TLabel
      Left = 580
      Top = 15
      Width = 69
      Height = 15
      Caption = 'Margin (mm):'
    end
    object lblPrintMethod: TLabel
      Left = 20
      Top = 65
      Width = 73
      Height = 15
      Caption = 'Print Method:'
    end
    object lblNotes: TLabel
      Left = 200
      Top = 65
      Width = 34
      Height = 15
      Caption = 'Notes:'
    end
    object edtCode: TEdit
      Left = 20
      Top = 32
      Width = 95
      Height = 23
      TabOrder = 0
    end
    object edtName: TEdit
      Left = 130
      Top = 32
      Width = 215
      Height = 23
      TabOrder = 1
    end
    object edtMaxWeb: TEdit
      Left = 360
      Top = 32
      Width = 95
      Height = 23
      TabOrder = 2
    end
    object edtMinWeb: TEdit
      Left = 470
      Top = 32
      Width = 95
      Height = 23
      TabOrder = 3
    end
    object edtMargin: TEdit
      Left = 580
      Top = 32
      Width = 85
      Height = 23
      TabOrder = 4
    end
    object chkActive: TCheckBox
      Left = 685
      Top = 34
      Width = 75
      Height = 17
      Caption = 'Active'
      Checked = True
      State = cbChecked
      TabOrder = 5
    end
    object edtPrintMethod: TEdit
      Left = 20
      Top = 85
      Width = 165
      Height = 23
      TabOrder = 6
    end
    object edtNotes: TEdit
      Left = 200
      Top = 85
      Width = 465
      Height = 23
      TabOrder = 7
    end
    object btnNew: TButton
      Left = 20
      Top = 130
      Width = 85
      Height = 30
      Caption = 'New'
      TabOrder = 8
      OnClick = btnNewClick
    end
    object btnSave: TButton
      Left = 120
      Top = 130
      Width = 95
      Height = 30
      Caption = 'Save Machine'
      Default = True
      TabOrder = 9
      OnClick = btnSaveClick
    end
    object btnDelete: TButton
      Left = 230
      Top = 130
      Width = 85
      Height = 30
      Caption = 'Delete'
      TabOrder = 10
      OnClick = btnDeleteClick
    end
    object btnClose: TButton
      Left = 670
      Top = 130
      Width = 85
      Height = 30
      Cancel = True
      Caption = 'Close'
      TabOrder = 11
      OnClick = btnCloseClick
    end
  end
end
