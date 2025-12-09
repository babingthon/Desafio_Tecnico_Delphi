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
  TextHeight = 17
  object PageControl: TPageControl
    Left = 0
    Top = 0
    Width = 839
    Height = 569
    ActivePage = TabAutenticacao
    Align = alClient
    TabOrder = 0
    object TabAutenticacao: TTabSheet
      Caption = 'Autenticacao'
      object EdtEmail: TEdit
        Left = 16
        Top = 56
        Width = 321
        Height = 25
        TabOrder = 1
        Text = 'babingthon.bandeira@gmail.com'
      end
      object EdtPassword: TEdit
        Left = 16
        Top = 96
        Width = 321
        Height = 25
        PasswordChar = '#'
        TabOrder = 2
        Text = '123456'
      end
      object BtnLogin: TButton
        Left = 262
        Top = 136
        Width = 75
        Height = 25
        Caption = 'Login'
        TabOrder = 3
        OnClick = BtnLoginClick
      end
      object MemLog: TMemo
        Left = 0
        Top = 176
        Width = 831
        Height = 361
        Align = alBottom
        ReadOnly = True
        TabOrder = 4
      end
      object EdtNome: TEdit
        Left = 16
        Top = 16
        Width = 321
        Height = 25
        TabOrder = 0
        Text = 'Babingthon Bandeira'
      end
    end
    object TabIBGE: TTabSheet
      Caption = 'IBGE'
      ImageIndex = 1
    end
  end
  object NetHttpClientAuth: TNetHTTPClient
    UserAgent = 'Embarcadero URI Client/1.0'
    Left = 452
    Top = 388
  end
end
