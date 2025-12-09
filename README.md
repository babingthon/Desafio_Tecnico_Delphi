# Prova Técnica – Processamento de Dados Municipais

![Delphi](https://img.shields.io/badge/Delphi-EE1F35?style=for-the-badge&logo=delphi&logoColor=white)
![REST](https://img.shields.io/badge/REST-0080FF?style=for-the-badge)
![CSV](https://img.shields.io/badge/CSV-4CAF50?style=for-the-badge)
![APIs](https://img.shields.io/badge/APIs-FF9800?style=for-the-badge)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)

Este projeto atende ao desafio proposto, focado em integração com APIs, 
tratamento de dados e comunicação segura entre serviços.

A aplicação realiza:

1. Autenticação no Supabase para obtenção de um token de acesso.
2. Leitura de um arquivo CSV contendo municípios e populações.
3. Enriquecimento das informações consultando a API pública do IBGE.
4. Geração de um novo arquivo CSV consolidando os resultados.
5. Cálculo de estatísticas gerais e por região.
6. Envio desses indicadores para uma API de correção, utilizando autorização Bearer.
7. Exibição do score retornado pela plataforma.

O projeto demonstra domínio em:
- Consumo de APIs REST,
- Tratamento e validação de dados,
- Organização de fluxo completo de ponta a ponta,
- Manipulação de arquivos e geração de relatórios,
- Uso de autenticação via token.

## Como executar

1. Abra o projeto no Delphi (versão 11 ou superior recomendada).
2. Compile e execute a aplicação.
3. Realize o login com seu e-mail e senha cadastrados no Supabase.
4. O arquivo `input.csv` deve estar na pasta do executável.
5. Após o processamento, os arquivos `resultado.csv` e o JSON de estatísticas serão gerados automaticamente.
6. Ao final, o score retornado pela API de correção será exibido na aplicação.

A solução foi desenvolvida seguindo práticas adequadas para aplicações que 
dependem de comunicação externa e padronização de resultados.
