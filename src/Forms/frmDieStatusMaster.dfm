object frmDieStatusMaster: TfrmDieStatusMaster
  Left = 0
  Top = 0
  Caption = 'Die Status Codes — DieVix'
  ClientHeight = 480
  ClientWidth = 680
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
    Width = 680
    Height = 50
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 14
      Width = 167
      Height = 21
      Caption = 'Die Tooling Statuses'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object gridStatuses: TStringGrid
    Left = 0
    Top = 50
    Width = 680
    Height = 250
    Align = alClient
    ColCount = 5
    DefaultRowHeight = 24
    FixedCols = 0
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goRowSelect]
    TabOrder = 1
    OnSelectCell = gridStatusesSelectCell
  end
  object pnlEdit: TPanel
    Left = 0
    Top = 300
    Width = 680
    Height = 180
    Align = alBottom
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 2
    object lblCode: TLabel
      Left = 20
      Top = 15
      Width = 65
      Height = 15
      Caption = 'Status Code:'
    end
    object lblDescription: TLabel
      Left = 160
      Top = 15
      Width = 63
      Height = 15
      Caption = 'Description:'
    end
    object lblBadgeColor: TLabel
      Left = 380
      Top = 15
      Width = 68
      Height = 15
      Caption = 'Badge Color:'
    end
    object lblSortOrder: TLabel
      Left = 510
      Top = 15
      Width = 56
      Height = 15
      Caption = 'Sort Order:'
    end
    object edtCode: TEdit
      Left = 20
      Top = 32
      Width = 125
      Height = 23
      TabOrder = 0
    end
    object edtDescription: TEdit
      Left = 160
      Top = 32
      Width = 200
      Height = 23
      TabOrder = 1
    end
    object cmbBadgeColor: TComboBox
      Left = 380
      Top = 32
      Width = 110
      Height = 23
      ItemIndex = 0
      TabOrder = 2
      Text = 'Green'
      Items.Strings = (
        'Green'
        'Blue'
        'Orange'
        'Purple'
        'Red'
        'Gray')
    end
    object edtSortOrder: TEdit
      Left = 510
      Top = 32
      Width = 60
      Height = 23
      TabOrder = 3
      Text = '10'
    end
    object chkUsable: TCheckBox
      Left = 20
      Top = 75
      Width = 180
      Height = 17
      Caption = 'Permit Use in Production'
      Checked = True
      State = cbChecked
      TabOrder = 4
    end
    object btnNew: TButton
      Left = 20
      Top = 120
      Width = 85
      Height = 32
      Caption = 'New'
      TabOrder = 5
      OnClick = btnNewClick
    end
    object btnSave: TButton
      Left = 120
      Top = 120
      Width = 95
      Height = 32
      Caption = 'Save Status'
      Default = True
      TabOrder = 6
      OnClick = btnSaveClick
    end
    object btnClose: TButton
      Left = 575
      Top = 120
      Width = 85
      Height = 32
      Cancel = True
      Caption = 'Close'
      TabOrder = 7
      OnClick = btnCloseClick
    end
  end
end
