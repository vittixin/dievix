object frmBackup: TfrmBackup
  Left = 0
  Top = 0
  Caption = 'Database & Report Backup Manager - DieVix'
  ClientHeight = 720
  ClientWidth = 860
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
    Width = 860
    Height = 60
    Align = alTop
    BevelOuter = bvNone
    Color = 2102035
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 20
      Top = 10
      Width = 328
      Height = 21
      Caption = 'Database & Report Backup Console'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblSubtitle: TLabel
      Left = 20
      Top = 33
      Width = 472
      Height = 15
      Caption = 'Firebird 5.0 Database Archives, VittixReport Templates & Unified Full-System Packages'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 14474460
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsItalic]
      ParentFont = False
    end
  end
  object pgcBackup: TPageControl
    Left = 0
    Top = 60
    Width = 860
    Height = 440
    ActivePage = tabDatabase
    Align = alClient
    TabOrder = 1
    object tabDatabase: TTabSheet
      Caption = '  '#128452' Database Backup & Restore  '
      object pnlDbInfo: TPanel
        Left = 0
        Top = 0
        Width = 852
        Height = 45
        Align = alTop
        BevelOuter = bvNone
        Color = 15921906
        ParentBackground = False
        TabOrder = 0
        object lblActiveDbTitle: TLabel
          Left = 14
          Top = 6
          Width = 92
          Height = 15
          Caption = 'ACTIVE ENGINE:'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGrayText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblActiveDbPath: TLabel
          Left = 115
          Top = 6
          Width = 245
          Height = 15
          Caption = 'Database: D:\ketan\github\DieVix\bin\data\DIEVIX.FDB'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblActiveMode: TLabel
          Left = 14
          Top = 24
          Width = 195
          Height = 15
          Caption = 'Connection Mode: SERVER (localhost:3050)'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 4210752
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
      end
      object grpDbBackup: TGroupBox
        Left = 12
        Top = 55
        Width = 828
        Height = 160
        Caption = ' Database Backup (Firebird gbak .fbk / Physical Hot Copy) '
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
        TabOrder = 1
        object lblDbDest: TLabel
          Left = 16
          Top = 28
          Width = 157
          Height = 15
          Caption = 'Destination Backup File (.fbk):'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object edtDbDest: TEdit
          Left = 16
          Top = 48
          Width = 710
          Height = 23
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 0
        end
        object btnBrowseDbDest: TButton
          Left = 732
          Top = 47
          Width = 80
          Height = 25
          Caption = 'Browse...'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 1
          OnClick = btnBrowseDbDestClick
        end
        object chkVerbose: TCheckBox
          Left = 16
          Top = 82
          Width = 200
          Height = 20
          Caption = 'Verbose progress logging'
          Checked = True
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          State = cbChecked
          TabOrder = 2
        end
        object chkIgnoreChecksums: TCheckBox
          Left = 230
          Top = 82
          Width = 250
          Height = 20
          Caption = 'Ignore checksum / limbo transactions'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 3
        end
        object btnBackupDatabase: TButton
          Left = 16
          Top = 112
          Width = 210
          Height = 34
          Caption = #128190' Backup Database (.fbk)'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 4
          OnClick = btnBackupDatabaseClick
        end
        object btnPhysicalHotBackup: TButton
          Left = 236
          Top = 112
          Width = 240
          Height = 34
          Caption = #9889' Online Hot Binary Copy (.fdb.bak)'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 5
          OnClick = btnPhysicalHotBackupClick
        end
      end
      object grpDbRestore: TGroupBox
        Left = 12
        Top = 224
        Width = 828
        Height = 175
        Caption = ' Database Restore (from .fbk Archive) '
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
        TabOrder = 2
        object lblRestoreSrc: TLabel
          Left = 16
          Top = 26
          Width = 143
          Height = 15
          Caption = 'Source Backup Archive (.fbk):'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object edtRestoreSrc: TEdit
          Left = 16
          Top = 45
          Width = 710
          Height = 23
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 0
        end
        object btnBrowseRestoreSrc: TButton
          Left = 732
          Top = 44
          Width = 80
          Height = 25
          Caption = 'Browse...'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 1
          OnClick = btnBrowseRestoreSrcClick
        end
        object lblRestoreDest: TLabel
          Left = 16
          Top = 75
          Width = 165
          Height = 15
          Caption = 'Target Database File Path (.fdb):'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object edtRestoreDest: TEdit
          Left = 16
          Top = 94
          Width = 710
          Height = 23
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 2
        end
        object btnBrowseRestoreDest: TButton
          Left = 732
          Top = 93
          Width = 80
          Height = 25
          Caption = 'Browse...'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 3
          OnClick = btnBrowseRestoreDestClick
        end
        object chkOverwriteDb: TCheckBox
          Left = 16
          Top = 128
          Width = 260
          Height = 20
          Caption = 'Overwrite existing database if present'
          Checked = True
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          State = cbChecked
          TabOrder = 4
        end
        object btnRestoreDatabase: TButton
          Left = 290
          Top = 124
          Width = 220
          Height = 34
          Caption = #9851' Restore Database Now...'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 5
          OnClick = btnRestoreDatabaseClick
        end
      end
    end
    object tabReports: TTabSheet
      Caption = '  '#128196' Report Templates Backup & Restore  '
      ImageIndex = 1
      object pnlRepInfo: TPanel
        Left = 0
        Top = 0
        Width = 852
        Height = 45
        Align = alTop
        BevelOuter = bvNone
        Color = 15921906
        ParentBackground = False
        TabOrder = 0
        object lblReportsPathTitle: TLabel
          Left = 14
          Top = 6
          Width = 111
          Height = 15
          Caption = 'ACTIVE REPOSITORY:'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGrayText
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblReportsPath: TLabel
          Left = 135
          Top = 6
          Width = 217
          Height = 15
          Caption = 'Active Path: D:\ketan\github\DieVix\reports'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object lblReportCount: TLabel
          Left = 14
          Top = 24
          Width = 127
          Height = 15
          Caption = 'Discovered Templates: 3'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 4210752
          Font.Height = -11
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
      end
      object lvTemplates: TListView
        Left = 12
        Top = 55
        Width = 828
        Height = 240
        Columns = <
          item
            Caption = 'Template File'
            Width = 180
          end
          item
            Caption = 'Report Title'
            Width = 250
          end
          item
            Caption = 'File Size'
            Width = 90
          end
          item
            Caption = 'Last Modified'
            Width = 140
          end
          item
            Caption = 'JSON Validation'
            Width = 140
          end>
        GridLines = True
        ReadOnly = True
        RowSelect = True
        TabOrder = 1
        ViewStyle = vsReport
      end
      object grpRepActions: TGroupBox
        Left = 12
        Top = 302
        Width = 828
        Height = 98
        Caption = ' Report Backup & Restore Operations '
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
        TabOrder = 2
        object btnBackupReportsZip: TButton
          Left = 16
          Top = 32
          Width = 180
          Height = 36
          Caption = #128230' Backup to ZIP...'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 0
          OnClick = btnBackupReportsZipClick
        end
        object btnBackupReportsFolder: TButton
          Left = 204
          Top = 32
          Width = 170
          Height = 36
          Caption = #128193' Backup to Folder'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 1
          OnClick = btnBackupReportsFolderClick
        end
        object btnRestoreReportsZip: TButton
          Left = 384
          Top = 32
          Width = 180
          Height = 36
          Caption = #9851' Restore from ZIP...'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 2
          OnClick = btnRestoreReportsZipClick
        end
        object btnRestoreReportsFolder: TButton
          Left = 572
          Top = 32
          Width = 160
          Height = 36
          Caption = #128194' Restore Folder...'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 3
          OnClick = btnRestoreReportsFolderClick
        end
        object btnRefreshTemplates: TButton
          Left = 740
          Top = 32
          Width = 75
          Height = 36
          Caption = 'Refresh'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 4
          OnClick = btnRefreshTemplatesClick
        end
      end
    end
    object tabFullSystem: TTabSheet
      Caption = '  '#127760' Unified Full System Backup (DB + Reports)  '
      ImageIndex = 2
      object grpFullBackup: TGroupBox
        Left = 14
        Top = 15
        Width = 824
        Height = 180
        Caption = ' Generate Consolidated System Backup Package '
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        object lblFullHelp: TLabel
          Left = 16
          Top = 24
          Width = 770
          Height = 30
          Caption = 
            'Packages the active Firebird 5.0 database snapshot (.fbk), all VittixReport definitions (*.vrt), and a machine-readable backup_manifest.json into a single compressed ZIP archive.'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clGrayText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsItalic]
          ParentFont = False
          WordWrap = True
        end
        object lblOperator: TLabel
          Left = 16
          Top = 64
          Width = 86
          Height = 15
          Caption = 'Operator Name:'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object edtOperator: TEdit
          Left = 16
          Top = 82
          Width = 200
          Height = 23
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 0
          Text = 'OPERATOR'
        end
        object lblFullZipDest: TLabel
          Left = 230
          Top = 64
          Width = 147
          Height = 15
          Caption = 'Destination Package (.zip):'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object edtFullZipDest: TEdit
          Left = 230
          Top = 82
          Width = 495
          Height = 23
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 1
        end
        object btnBrowseFullZip: TButton
          Left = 732
          Top = 81
          Width = 76
          Height = 25
          Caption = 'Browse...'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 2
          OnClick = btnBrowseFullZipClick
        end
        object btnRunFullBackup: TButton
          Left = 16
          Top = 122
          Width = 260
          Height = 38
          Caption = #128230' Generate Full System Backup (ZIP)'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 3
          OnClick = btnRunFullBackupClick
        end
      end
      object grpFullRestore: TGroupBox
        Left = 14
        Top = 208
        Width = 824
        Height = 185
        Caption = ' Restore from System Backup Package '
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -12
        Font.Name = 'Segoe UI Semibold'
        Font.Style = []
        ParentFont = False
        TabOrder = 1
        object lblFullRestoreSrc: TLabel
          Left = 16
          Top = 26
          Width = 141
          Height = 15
          Caption = 'Source Backup ZIP Package:'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object edtFullRestoreSrc: TEdit
          Left = 16
          Top = 45
          Width = 710
          Height = 23
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 0
        end
        object btnBrowseFullRestoreSrc: TButton
          Left = 732
          Top = 44
          Width = 76
          Height = 25
          Caption = 'Browse...'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 1
          OnClick = btnBrowseFullRestoreSrcClick
        end
        object lblFullRestoreDbTarget: TLabel
          Left = 16
          Top = 75
          Width = 191
          Height = 15
          Caption = 'Target Database for Restoration (.fdb):'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object edtFullRestoreDbTarget: TEdit
          Left = 16
          Top = 94
          Width = 710
          Height = 23
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 2
        end
        object btnBrowseFullRestoreDbTarget: TButton
          Left = 732
          Top = 93
          Width = 76
          Height = 25
          Caption = 'Browse...'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
          TabOrder = 3
          OnClick = btnBrowseFullRestoreDbTargetClick
        end
        object btnRunFullRestore: TButton
          Left = 16
          Top = 130
          Width = 260
          Height = 38
          Caption = #9851' Restore Full System Package...'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 4
          OnClick = btnRunFullRestoreClick
        end
      end
    end
    object tabHistory: TTabSheet
      Caption = '  '#128338' Backup Archive Catalog & Verification  '
      ImageIndex = 3
      object pnlHistTop: TPanel
        Left = 0
        Top = 0
        Width = 852
        Height = 45
        Align = alTop
        BevelOuter = bvNone
        Color = 15921906
        ParentBackground = False
        TabOrder = 0
        object lblHistFolder: TLabel
          Left = 14
          Top = 13
          Width = 83
          Height = 15
          Caption = 'Archive Folder:'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object edtHistFolder: TEdit
          Left = 105
          Top = 10
          Width = 475
          Height = 23
          TabOrder = 0
        end
        object btnBrowseHistFolder: TButton
          Left = 586
          Top = 9
          Width = 75
          Height = 25
          Caption = 'Browse...'
          TabOrder = 1
          OnClick = btnBrowseHistFolderClick
        end
        object btnRefreshHistory: TButton
          Left = 668
          Top = 9
          Width = 75
          Height = 25
          Caption = 'Scan'
          TabOrder = 2
          OnClick = btnRefreshHistoryClick
        end
        object btnVerifySelected: TButton
          Left = 750
          Top = 9
          Width = 90
          Height = 25
          Caption = 'Verify...'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -12
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 3
          OnClick = btnVerifySelectedClick
        end
      end
      object lvHistory: TListView
        Left = 12
        Top = 55
        Width = 828
        Height = 340
        Columns = <
          item
            Caption = 'Archive File Name'
            Width = 240
          end
          item
            Caption = 'Archive Type / Description'
            Width = 250
          end
          item
            Caption = 'Size'
            Width = 90
          end
          item
            Caption = 'Date Created'
            Width = 140
          end
          item
            Caption = 'Full System Path'
            Width = 280
          end>
        GridLines = True
        ReadOnly = True
        RowSelect = True
        TabOrder = 1
        ViewStyle = vsReport
      end
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 500
    Width = 860
    Height = 220
    Align = alBottom
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 2
    object lblLog: TLabel
      Left = 14
      Top = 6
      Width = 147
      Height = 15
      Caption = 'Operational Execution Log:'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGrayText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object memLog: TMemo
      Left = 12
      Top = 26
      Width = 836
      Height = 145
      Color = 2102035
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 15790320
      Font.Height = -11
      Font.Name = 'Consolas'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 0
    end
    object pnlButtons: TPanel
      Left = 0
      Top = 175
      Width = 860
      Height = 45
      Align = alBottom
      BevelOuter = bvNone
      Color = clWhite
      ParentBackground = False
      TabOrder = 1
      object btnClearLog: TButton
        Left = 12
        Top = 8
        Width = 90
        Height = 30
        Caption = 'Clear Log'
        TabOrder = 0
        OnClick = btnClearLogClick
      end
      object btnClose: TButton
        Left = 758
        Top = 8
        Width = 90
        Height = 30
        Cancel = True
        Caption = 'Close'
        TabOrder = 1
        OnClick = btnCloseClick
      end
    end
  end
  object dlgSaveFbk: TSaveDialog
    DefaultExt = 'fbk'
    Filter = 'Firebird Backup Archive (*.fbk)|*.fbk|All Files (*.*)|*.*'
    Title = 'Select Firebird Backup Destination'
    Left = 600
    Top = 100
  end
  object dlgOpenFbk: TOpenDialog
    DefaultExt = 'fbk'
    Filter = 'Firebird Backup Archive (*.fbk)|*.fbk|All Files (*.*)|*.*'
    Title = 'Select Source Firebird Backup Archive'
    Left = 650
    Top = 100
  end
  object dlgSaveZip: TSaveDialog
    DefaultExt = 'zip'
    Filter = 'ZIP Archive (*.zip)|*.zip|All Files (*.*)|*.*'
    Title = 'Save ZIP Backup Archive'
    Left = 700
    Top = 100
  end
  object dlgOpenZip: TOpenDialog
    DefaultExt = 'zip'
    Filter = 'ZIP Archive (*.zip)|*.zip|All Files (*.*)|*.*'
    Title = 'Open ZIP Backup Archive'
    Left = 750
    Top = 100
  end
  object dlgSaveFdb: TSaveDialog
    DefaultExt = 'fdb'
    Filter = 'Firebird Database (*.fdb)|*.fdb|All Files (*.*)|*.*'
    Title = 'Specify Target Database Destination'
    Left = 800
    Top = 100
  end
  object dlgOpenFolder: TFileOpenDialog
    Left = 550
    Top = 100
  end
end
