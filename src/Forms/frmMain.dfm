object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'DieVix — Rotary Die & Keyline Manager'
  ClientHeight = 620
  ClientWidth = 1000
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
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 1000
    Height = 70
    Align = alTop
    BevelOuter = bvNone
    Color = 2102035
    ParentBackground = False
    TabOrder = 0
    object lblAppTitle: TLabel
      Left = 24
      Top = 14
      Width = 72
      Height = 28
      Caption = 'DieVix'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -20
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblTagline: TLabel
      Left = 105
      Top = 22
      Width = 144
      Height = 17
      Caption = 'Precision in Every Repeat.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 14474460
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsItalic]
      ParentFont = False
    end
  end
  object pnlSidebar: TPanel
    Left = 0
    Top = 70
    Width = 200
    Height = 525
    Align = alLeft
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 1
    object btnCylinders: TButton
      Left = 12
      Top = 15
      Width = 176
      Height = 36
      Caption = '  Cylinder Master'
      TabOrder = 0
      OnClick = btnCylindersClick
    end
    object btnMachines: TButton
      Left = 12
      Top = 60
      Width = 176
      Height = 36
      Caption = '  Machine Master'
      TabOrder = 1
      OnClick = btnMachinesClick
    end
    object btnMatrix: TButton
      Left = 12
      Top = 105
      Width = 176
      Height = 36
      Caption = '  Machine '#215' Cylinders'
      TabOrder = 2
      OnClick = btnMatrixClick
    end
    object btnCustomers: TButton
      Left = 12
      Top = 150
      Width = 176
      Height = 36
      Caption = '  Customer Master'
      TabOrder = 3
      OnClick = btnCustomersClick
    end
    object btnMedia: TButton
      Left = 12
      Top = 195
      Width = 176
      Height = 36
      Caption = '  Media Substrates'
      TabOrder = 4
      OnClick = btnMediaClick
    end
    object btnStatuses: TButton
      Left = 12
      Top = 240
      Width = 176
      Height = 36
      Caption = '  Die Status Codes'
      TabOrder = 5
      OnClick = btnStatusesClick
    end
    object btnSettings: TButton
      Left = 12
      Top = 300
      Width = 176
      Height = 36
      Caption = '  Settings & Tolerances'
      TabOrder = 6
      OnClick = btnSettingsClick
    end
  end
  object pnlContent: TPanel
    Left = 200
    Top = 70
    Width = 800
    Height = 525
    Align = alClient
    BevelOuter = bvNone
    Color = 16250871
    ParentBackground = False
    TabOrder = 2
    object pnlDashboardCards: TPanel
      Left = 0
      Top = 0
      Width = 800
      Height = 140
      Align = alTop
      BevelOuter = bvNone
      ParentBackground = False
      TabOrder = 0
      object cardCylinders: TPanel
        Left = 24
        Top = 20
        Width = 165
        Height = 100
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 0
        object lblCountCylinders: TLabel
          Left = 16
          Top = 12
          Width = 32
          Height = 37
          Caption = '16'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clNavy
          Font.Height = -27
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblTitleCylinders: TLabel
          Left = 16
          Top = 60
          Width = 98
          Height = 15
          Caption = 'Fleet Cylinder Sizes'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGrayText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
      end
      object cardMachines: TPanel
        Left = 210
        Top = 20
        Width = 165
        Height = 100
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 1
        object lblCountMachines: TLabel
          Left = 16
          Top = 12
          Width = 16
          Height = 37
          Caption = '2'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 26521
          Font.Height = -27
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblTitleMachines: TLabel
          Left = 16
          Top = 60
          Width = 80
          Height = 15
          Caption = 'Printing Presses'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGrayText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
      end
      object cardCustomers: TPanel
        Left = 395
        Top = 20
        Width = 165
        Height = 100
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 2
        object lblCountCustomers: TLabel
          Left = 16
          Top = 12
          Width = 16
          Height = 37
          Caption = '0'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 10496
          Font.Height = -27
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblTitleCustomers: TLabel
          Left = 16
          Top = 60
          Width = 105
          Height = 15
          Caption = 'Customer Accounts'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGrayText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
      end
      object cardMedia: TPanel
        Left = 580
        Top = 20
        Width = 165
        Height = 100
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 3
        object lblCountMedia: TLabel
          Left = 16
          Top = 12
          Width = 16
          Height = 37
          Caption = '4'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 8388736
          Font.Height = -27
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblTitleMedia: TLabel
          Left = 16
          Top = 60
          Width = 91
          Height = 15
          Caption = 'Media Substrates'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGrayText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
      end
    end
    object pnlQuickActions: TPanel
      Left = 24
      Top = 160
      Width = 721
      Height = 220
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 1
      object lblQuickActions: TLabel
        Left = 20
        Top = 18
        Width = 160
        Height = 20
        Caption = 'Quick Operations Hub'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -15
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object btnQuickMatrix: TButton
        Left = 20
        Top = 60
        Width = 200
        Height = 45
        Caption = 'Configure Press '#215' Cylinders'
        TabOrder = 0
        OnClick = btnMatrixClick
      end
      object btnQuickCylinder: TButton
        Left = 240
        Top = 60
        Width = 200
        Height = 45
        Caption = 'Manage Fleet Cylinders'
        TabOrder = 1
        OnClick = btnCylindersClick
      end
      object btnQuickCustomer: TButton
        Left = 460
        Top = 60
        Width = 200
        Height = 45
        Caption = 'Register New Customer'
        TabOrder = 2
        OnClick = btnCustomersClick
      end
      object btnQuickSettings: TButton
        Left = 20
        Top = 125
        Width = 200
        Height = 45
        Caption = 'Set Around Gap Policy'
        TabOrder = 3
        OnClick = btnSettingsClick
      end
    end
  end
  object statBar: TStatusBar
    Left = 0
    Top = 595
    Width = 1000
    Height = 25
    Panels = <
      item
        Width = 200
      end
      item
        Width = 350
      end
      item
        Width = 180
      end
      item
        Width = 200
      end>
  end
end
