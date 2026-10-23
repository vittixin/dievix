object frmMediaMaster: TfrmMediaMaster
  Left = 0
  Top = 0
  Caption = 'Media Substrate Master — DieVix'
  ClientHeight = 540
  ClientWidth = 840
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
    Width = 840
    Height = 65
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 10
      Width = 246
      Height = 21
      Caption = 'Standardized Media Substrates'
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
  object gridMedia: TStringGrid
    Left = 0
    Top = 65
    Width = 840
    Height = 275
    Align = alClient
    ColCount = 7
    DefaultRowHeight = 24
    FixedCols = 0
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goRowSelect]
    TabOrder = 1
    OnSelectCell = gridMediaSelectCell
  end
  object pnlEdit: TPanel
    Left = 0
    Top = 340
    Width = 840
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
      Width = 70
      Height = 15
      Caption = 'Media Name:'
    end
    object lblFace: TLabel
      Left = 450
      Top = 15
      Width = 73
      Height = 15
      Caption = 'Face Material:'
    end
    object lblLiner: TLabel
      Left = 640
      Top = 15
      Width = 75
      Height = 15
      Caption = 'Liner Material:'
    end
    object lblAdhesive: TLabel
      Left = 20
      Top = 65
      Width = 51
      Height = 15
      Caption = 'Adhesive:'
    end
    object lblCaliper: TLabel
      Left = 200
      Top = 65
      Width = 66
      Height = 15
      Caption = 'Caliper (um):'
    end
    object lblNotes: TLabel
      Left = 320
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
      Width = 300
      Height = 23
      TabOrder = 1
    end
    object edtFace: TEdit
      Left = 450
      Top = 32
      Width = 175
      Height = 23
      TabOrder = 2
    end
    object edtLiner: TEdit
      Left = 640
      Top = 32
      Width = 175
      Height = 23
      TabOrder = 3
    end
    object edtAdhesive: TEdit
      Left = 20
      Top = 85
      Width = 165
      Height = 23
      TabOrder = 4
    end
    object edtCaliper: TEdit
      Left = 200
      Top = 85
      Width = 100
      Height = 23
      TabOrder = 5
    end
    object edtNotes: TEdit
      Left = 320
      Top = 85
      Width = 410
      Height = 23
      TabOrder = 6
    end
    object chkActive: TCheckBox
      Left = 750
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
      Caption = 'Save Media'
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
      Left = 730
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
