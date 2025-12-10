object FrmPrincipal: TFrmPrincipal
  Left = 0
  Top = 0
  Caption = 'Principal'
  ClientHeight = 653
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
    Height = 418
    ActivePage = TabIBGE
    Align = alClient
    TabOrder = 0
    ExplicitWidth = 835
    ExplicitHeight = 417
    object TabAutenticacao: TTabSheet
      Caption = 'Autenticacao'
      object Label1: TLabel
        Left = 240
        Top = 113
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
        Top = 169
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
        Top = 225
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
        Top = 192
        Width = 321
        Height = 25
        TabOrder = 2
        Text = 'babingthon.bandeira@gmail.com'
      end
      object EdtPassword: TEdit
        Left = 240
        Top = 248
        Width = 321
        Height = 25
        PasswordChar = '#'
        TabOrder = 3
        Text = '123456'
      end
      object BtnLogin: TButton
        Left = 486
        Top = 288
        Width = 75
        Height = 25
        Caption = 'Login'
        TabOrder = 4
        OnClick = BtnLoginClick
      end
      object EdtNome: TEdit
        Left = 240
        Top = 136
        Width = 321
        Height = 25
        TabOrder = 1
        Text = 'Babingthon Bandeira'
      end
      object Panel1: TPanel
        Left = 0
        Top = 0
        Width = 831
        Height = 41
        Align = alTop
        Caption = 'OBTER O TOKEN'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
      end
    end
    object TabIBGE: TTabSheet
      Caption = 'IBGE'
      ImageIndex = 1
      object EdtInputFile: TEdit
        Left = 16
        Top = 21
        Width = 633
        Height = 25
        TabOrder = 0
      end
      object BtnBrowse: TButton
        Left = 672
        Top = 21
        Width = 137
        Height = 25
        Caption = 'Buscar Arquivo'
        TabOrder = 1
        OnClick = BtnBrowseClick
      end
      object BtnCarregarCSV: TButton
        Left = 672
        Top = 352
        Width = 137
        Height = 25
        Caption = 'Carregar Arquivo'
        TabOrder = 6
        OnClick = BtnCarregarCSVClick
      end
      object DBGrdMunicipios: TDBGrid
        Left = 16
        Top = 53
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
        Top = 352
        Width = 113
        Height = 25
        Caption = 'Consultar IBGE'
        Enabled = False
        TabOrder = 5
        OnClick = BtnConsultarIBGEClick
      end
      object RgFiltroStatus: TRadioGroup
        Left = 352
        Top = 292
        Width = 457
        Height = 53
        Caption = 'Status'
        Columns = 3
        ItemIndex = 0
        Items.Strings = (
          'Todos'
          'OK'
          'N'#227'o Encontrados')
        TabOrder = 3
        OnClick = RgFiltroStatusClick
      end
      object BtnProcessar: TButton
        Left = 24
        Top = 352
        Width = 145
        Height = 25
        Caption = 'Processar Resultados'
        Enabled = False
        TabOrder = 4
        OnClick = BtnProcessarClick
      end
    end
  end
  object MemLog: TMemo
    Left = 0
    Top = 418
    Width = 839
    Height = 235
    Align = alBottom
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 1
    ExplicitTop = 417
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
