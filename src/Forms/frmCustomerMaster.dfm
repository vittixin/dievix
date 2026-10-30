object frmCustomerMaster: TfrmCustomerMaster
  Left = 0
  Top = 0
  Caption = 'Customer Master - DieVix'
  ClientHeight = 540
  ClientWidth = 820
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
    Width = 820
    Height = 65
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 10
      Width = 147
      Height = 21
      Caption = 'Customer Directory'
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
      Width = 200
      Height = 23
      TabOrder = 0
      OnChange = edtSearchChange
    end
    object chkActiveOnly: TCheckBox
      Left = 280
      Top = 38
      Width = 100
      Height = 17
      Caption = 'Active Only'
      TabOrder = 1
      OnClick = chkActiveOnlyClick
    end
    object btnRefresh: TButton
      Left = 400
      Top = 34
      Width = 75
      Height = 25
      Caption = 'Refresh'
      TabOrder = 2
      OnClick = btnRefreshClick
    end
  end
  object gridCustomers: TStringGrid
    Left = 0
    Top = 65
    Width = 820
    Height = 275
    Align = alClient
    ColCount = 7
    DefaultRowHeight = 24
    FixedCols = 0
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goRowSelect]
    TabOrder = 1
    OnSelectCell = gridCustomersSelectCell
  end
  object pnlEdit: TPanel
    Left = 0
    Top = 340
    Width = 820
    Height = 200
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
      Width = 89
      Height = 15
      Caption = 'Customer Name:'
    end
    object lblContact: TLabel
      Left = 420
      Top = 15
      Width = 84
      Height = 15
      Caption = 'Contact Person:'
    end
    object lblPhone: TLabel
      Left = 620
      Top = 15
      Width = 37
      Height = 15
      Caption = 'Phone:'
    end
    object lblEmail: TLabel
      Left = 20
      Top = 65
      Width = 32
      Height = 15
      Caption = 'Email:'
    end
    object lblCity: TLabel
      Left = 250
      Top = 65
      Width = 24
      Height = 15
      Caption = 'City:'
    end
    object lblNotes: TLabel
      Left = 420
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
      Width = 270
      Height = 23
      TabOrder = 1
    end
    object edtContact: TEdit
      Left = 420
      Top = 32
      Width = 180
      Height = 23
      TabOrder = 2
    end
    object edtPhone: TEdit
      Left = 620
      Top = 32
      Width = 160
      Height = 23
      TabOrder = 3
    end
    object edtEmail: TEdit
      Left = 20
      Top = 85
      Width = 210
      Height = 23
      TabOrder = 4
    end
    object edtCity: TEdit
      Left = 250
      Top = 85
      Width = 150
      Height = 23
      TabOrder = 5
    end
    object edtNotes: TEdit
      Left = 420
      Top = 85
      Width = 270
      Height = 23
      TabOrder = 6
    end
    object chkActive: TCheckBox
      Left = 710
      Top = 87
      Width = 70
      Height = 17
      Caption = 'Active'
      Checked = True
      State = cbChecked
      TabOrder = 7
    end
    object btnNew: TButton
      Left = 20
      Top = 135
      Width = 85
      Height = 32
      Caption = 'New'
      TabOrder = 8
      OnClick = btnNewClick
    end
    object btnSave: TButton
      Left = 120
      Top = 135
      Width = 100
      Height = 32
      Caption = 'Save Customer'
      Default = True
      TabOrder = 9
      OnClick = btnSaveClick
    end
    object btnDelete: TButton
      Left = 235
      Top = 135
      Width = 85
      Height = 32
      Caption = 'Delete'
      TabOrder = 10
      OnClick = btnDeleteClick
    end
    object btnClose: TButton
      Left = 700
      Top = 135
      Width = 85
      Height = 32
      Cancel = True
      Caption = 'Close'
      TabOrder = 11
      OnClick = btnCloseClick
    end
  end
end
