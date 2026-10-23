object frmCylinderMaster: TfrmCylinderMaster
  Left = 0
  Top = 0
  Caption = 'Cylinder Fleet Master — DieVix'
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
      Width = 176
      Height = 21
      Caption = 'Cylinder Fleet Register'
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
  object gridCylinders: TStringGrid
    Left = 0
    Top = 65
    Width = 780
    Height = 275
    Align = alClient
    ColCount = 6
    DefaultRowHeight = 24
    FixedCols = 0
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goRowSelect]
    TabOrder = 1
    OnSelectCell = gridCylindersSelectCell
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
    object lblTeeth: TLabel
      Left = 20
      Top = 15
      Width = 31
      Height = 15
      Caption = 'Teeth:'
    end
    object lblPitch: TLabel
      Left = 130
      Top = 15
      Width = 59
      Height = 15
      Caption = 'Pitch (um):'
    end
    object lblRepeat: TLabel
      Left = 260
      Top = 15
      Width = 103
      Height = 15
      Caption = 'Calculated Repeat:'
    end
    object lblRepeatDisplay: TLabel
      Left = 260
      Top = 35
      Width = 12
      Height = 15
      Caption = '—'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clNavy
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblNotes: TLabel
      Left = 20
      Top = 65
      Width = 34
      Height = 15
      Caption = 'Notes:'
    end
    object edtTeeth: TEdit
      Left = 20
      Top = 32
      Width = 90
      Height = 23
      TabOrder = 0
      OnChange = edtTeethChange
    end
    object edtPitch: TEdit
      Left = 130
      Top = 32
      Width = 100
      Height = 23
      TabOrder = 1
      OnChange = edtPitchChange
    end
    object chkActive: TCheckBox
      Left = 460
      Top = 34
      Width = 80
      Height = 17
      Caption = 'Active'
      Checked = True
      State = cbChecked
      TabOrder = 2
    end
    object edtNotes: TEdit
      Left = 20
      Top = 85
      Width = 520
      Height = 23
      TabOrder = 3
    end
    object btnNew: TButton
      Left = 20
      Top = 130
      Width = 85
      Height = 30
      Caption = 'New'
      TabOrder = 4
      OnClick = btnNewClick
    end
    object btnSave: TButton
      Left = 120
      Top = 130
      Width = 95
      Height = 30
      Caption = 'Save Cylinder'
      Default = True
      TabOrder = 5
      OnClick = btnSaveClick
    end
    object btnDelete: TButton
      Left = 230
      Top = 130
      Width = 85
      Height = 30
      Caption = 'Delete'
      TabOrder = 6
      OnClick = btnDeleteClick
    end
    object btnClose: TButton
      Left = 670
      Top = 130
      Width = 85
      Height = 30
      Cancel = True
      Caption = 'Close'
      TabOrder = 7
      OnClick = btnCloseClick
    end
  end
end
