object frmMachineCylinderMatrix: TfrmMachineCylinderMatrix
  Left = 0
  Top = 0
  Caption = 'Machine '#215' Cylinder Assignment Matrix - DieVix'
  ClientHeight = 560
  ClientWidth = 920
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
    Width = 920
    Height = 65
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 10
      Width = 325
      Height = 21
      Caption = 'Machine '#215' Cylinder Compatibility Matrix'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblInstructions: TLabel
      Left = 16
      Top = 38
      Width = 398
      Height = 15
      Caption = 'Click any cell to toggle compatibility. Green cell [X] indicates assigned cylinder.'
    end
    object btnSaveMatrix: TButton
      Left = 680
      Top = 18
      Width = 110
      Height = 32
      Caption = 'Save Matrix'
      Default = True
      TabOrder = 0
      OnClick = btnSaveMatrixClick
    end
    object btnReload: TButton
      Left = 800
      Top = 18
      Width = 85
      Height = 32
      Caption = 'Reload'
      TabOrder = 1
      OnClick = btnReloadClick
    end
  end
  object gridMatrix: TStringGrid
    Left = 0
    Top = 65
    Width = 920
    Height = 445
    Align = alClient
    ColCount = 2
    DefaultDrawing = False
    DefaultRowHeight = 26
    FixedCols = 1
    RowCount = 2
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect]
    TabOrder = 1
    OnClick = gridMatrixClick
    OnDrawCell = gridMatrixDrawCell
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 510
    Width = 920
    Height = 50
    Align = alBottom
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 2
    object lblLegend: TLabel
      Left = 16
      Top = 16
      Width = 264
      Height = 15
      Caption = 'Grayed out cells indicate inactive press or cylinder.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGrayText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsItalic]
      ParentFont = False
    end
    object btnAssignAll: TButton
      Left = 380
      Top = 10
      Width = 135
      Height = 30
      Caption = 'Assign All For Row'
      TabOrder = 0
      OnClick = btnAssignAllClick
    end
    object btnUnassignAll: TButton
      Left = 525
      Top = 10
      Width = 145
      Height = 30
      Caption = 'Unassign All For Row'
      TabOrder = 1
      OnClick = btnUnassignAllClick
    end
    object btnClose: TButton
      Left = 800
      Top = 10
      Width = 85
      Height = 30
      Cancel = True
      Caption = 'Close'
      TabOrder = 2
      OnClick = btnCloseClick
    end
  end
end
