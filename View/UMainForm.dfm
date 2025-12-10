object FrmPrincipal: TFrmPrincipal
  Left = 0
  Top = 0
  Caption = 'Principal'
  ClientHeight = 569
  ClientWidth = 839
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poMainFormCenter
  OnCreate = FormCreate
  TextHeight = 17
  object PageControl: TPageControl
    Left = 0
    Top = 0
    Width = 839
    Height = 352
    ActivePage = TabIBGE
    Align = alClient
    TabOrder = 0
    ExplicitWidth = 835
    ExplicitHeight = 351
    object TabAutenticacao: TTabSheet
      Caption = 'Autenticacao'
      object Label1: TLabel
        Left = 240
        Top = 81
        Width = 37
        Height = 17
        Caption = 'Nome'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label2: TLabel
        Left = 240
        Top = 137
        Width = 34
        Height = 17
        Caption = 'Email'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object Label3: TLabel
        Left = 240
        Top = 193
        Width = 37
        Height = 17
        Caption = 'Senha'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object EdtEmail: TEdit
        Left = 240
        Top = 160
        Width = 321
        Height = 25
        TabOrder = 1
        Text = 'babingthon.bandeira@gmail.com'
      end
      object EdtPassword: TEdit
        Left = 240
        Top = 216
        Width = 321
        Height = 25
        PasswordChar = '#'
        TabOrder = 2
        Text = '123456'
      end
      object BtnLogin: TButton
        Left = 486
        Top = 256
        Width = 75
        Height = 25
        Caption = 'Login'
        TabOrder = 3
        OnClick = BtnLoginClick
      end
      object EdtNome: TEdit
        Left = 240
        Top = 104
        Width = 321
        Height = 25
        TabOrder = 0
        Text = 'Babingthon Bandeira'
      end
    end
    object TabIBGE: TTabSheet
      Caption = 'IBGE'
      ImageIndex = 1
      object EdtInputFile: TEdit
        Left = 16
        Top = 8
        Width = 633
        Height = 25
        TabOrder = 0
      end
      object BtnBrowse: TButton
        Left = 672
        Top = 8
        Width = 137
        Height = 25
        Caption = 'Buscar Arquivo'
        TabOrder = 1
        OnClick = BtnBrowseClick
      end
      object BtnCarregarCSV: TButton
        Left = 672
        Top = 287
        Width = 137
        Height = 25
        Caption = 'Carregar Arquivo'
        TabOrder = 4
        OnClick = BtnCarregarCSVClick
      end
      object DBGrdMunicipios: TDBGrid
        Left = 16
        Top = 40
        Width = 793
        Height = 233
        DataSource = DSInputData
        TabOrder = 2
        TitleFont.Charset = DEFAULT_CHARSET
        TitleFont.Color = clWindowText
        TitleFont.Height = -13
        TitleFont.Name = 'Segoe UI'
        TitleFont.Style = []
      end
      object BtnConsultarIBGE: TButton
        Left = 352
        Top = 287
        Width = 113
        Height = 25
        Caption = 'Consultar IBGE'
        Enabled = False
        TabOrder = 3
      end
    end
  end
  object MemLog: TMemo
    Left = 0
    Top = 352
    Width = 839
    Height = 217
    Align = alBottom
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 1
    ExplicitTop = 351
    ExplicitWidth = 835
  end
  object NetHttpClientAuth: TNetHTTPClient
    UserAgent = 'Embarcadero URI Client/1.0'
    Left = 452
    Top = 388
  end
  object OpenDialog: TOpenDialog
    Left = 564
    Top = 388
  end
  object CDSInputData: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 200
    Top = 408
  end
  object DSInputData: TDataSource
    DataSet = CDSInputData
    Left = 320
    Top = 416
  end
end
