# Documentação técnica e funcional — AutoBoost

Versão do aplicativo: 1.0.0+1. Documentação preparada em 12/10/2026 a partir do código recebido e dos testes realizados pelo usuário.

## 1. Objetivo

Permitir que uma pessoa organize seus veículos e acompanhe serviços e gastos de manutenção no próprio celular. O projeto demonstra interface mobile, navegação entre telas, validação e persistência em banco de dados. Atende ao enunciado informado: tema livre, Flutter/Dart, conexão com banco e mais de uma tela. O banco escolhido é local; não há conexão com um servidor externo.

## 2. Requisitos funcionais

| Código | Comportamento |
| --- | --- |
| RF01 | Cadastrar veículo com marca, modelo, ano, placa e quilometragem |
| RF02 | Listar veículos do banco, com os mais recentes primeiro |
| RF03 | Editar um veículo sem alterar seu identificador |
| RF04 | Excluir veículo após confirmação e remover seus serviços em cascata |
| RF05 | Consultar serviços apenas do veículo selecionado |
| RF06 | Cadastrar serviço, data, quilometragem, valor e observações opcionais |
| RF07 | Editar e excluir manutenção, recalculando a soma mostrada |
| RF08 | Mostrar quantidade de veículos e manutenções e soma global dos gastos |
| RF09 | Reabrir o app e recuperar os dados persistidos |

## 3. Regras de validação

- Marca, modelo e serviço: texto obrigatório após remover espaços nas extremidades.
- Ano: inteiro de 1900 até o ano atual mais um.
- Placa: normalizada em maiúsculas, sem espaços ou hífen; aceita os formatos brasileiros usados no projeto (`ABC1234` e `ABC1D23`). A validação de formato não consulta a existência da placa em serviços oficiais.
- Placa única: consulta prévia oferece mensagem amigável; a tabela também possui `UNIQUE`.
- Quilometragem: inteiro não negativo. O programa não impõe crescimento entre serviços nem compara a quilometragem do serviço com a atual do veículo.
- Valor: até nove dígitos inteiros e duas casas decimais, ponto ou vírgula decimal, sem separador de milhar; zero é permitido. A entrada é convertida para centavos inteiros.
- Data: o seletor de novos serviços permite datas de 1900 até hoje; o armazenamento é `AAAA-MM-DD` e a apresentação é `DD/MM/AAAA`.
- A edição do veículo mantém o histórico original de cada serviço. Alterar a quilometragem atual não muda a quilometragem das manutenções.
- A exclusão requer confirmação. Cancelar fecha o diálogo sem remover registros.

## 4. Telas e navegação

| Tela | Conteúdo e ações |
| --- | --- |
| Início | Indicadores globais, acesso à garagem e atalho de cadastro |
| Minha garagem | Cartões com marca, modelo, placa, ano e quilometragem; menu editar/excluir |
| Formulário de veículo | Campos validados; mesmo formulário para criar e atualizar |
| Histórico de serviços | Total por veículo, cartões ordenados por data/id e menu editar/excluir |
| Formulário de manutenção | Serviço, seletor de data, quilometragem, valor e observações |

`Navigator.push` abre telas e `Navigator.pop(context, true)` sinaliza um salvamento. Ao retornar, a tela anterior consulta novamente o banco. `mounted` evita atualizar uma tela que saiu da árvore durante uma operação assíncrona. Os controladores de texto são liberados em `dispose`. O estado fica nos widgets: não existe uma camada separada de repositórios ou gerenciamento global.

## 5. Banco de dados

Arquivo: `autoboost.db`, criado na pasta de bancos do aplicativo via `getDatabasesPath`. A classe `BancoDados` expõe uma instância compartilhada e reutiliza a conexão aberta. Esquema versão 1; `onCreate` cria as tabelas apenas em um banco novo. `PRAGMA foreign_keys = ON` ativa a integridade referencial em `onConfigure`.

### Tabela `veiculos`

| Coluna | Tipo | Regra |
| --- | --- | --- |
| id | INTEGER | Chave primária autoincremental |
| marca | TEXT | NOT NULL |
| modelo | TEXT | NOT NULL |
| ano | INTEGER | NOT NULL |
| placa | TEXT | NOT NULL, UNIQUE |
| quilometragem | INTEGER | NOT NULL, padrão 0 |

### Tabela `manutencoes`

| Coluna | Tipo | Regra |
| --- | --- | --- |
| id | INTEGER | Chave primária autoincremental |
| veiculo_id | INTEGER | NOT NULL, referência a `veiculos.id` |
| servico | TEXT | NOT NULL |
| data | TEXT | NOT NULL, formato AAAA-MM-DD |
| quilometragem | INTEGER | NOT NULL |
| valor_centavos | INTEGER | NOT NULL |
| observacoes | TEXT | NOT NULL, padrão vazio |

Relacionamento: um veículo possui zero ou várias manutenções; cada manutenção pertence a um veículo. A chave estrangeira usa `ON DELETE CASCADE`. Uma edição usa `UPDATE` no mesmo id; não recria o veículo. As consultas por identificadores e placas utilizam parâmetros (`?`, `whereArgs`). Os indicadores globais são consultados na mesma transação. O histórico soma centavos inteiros e formata o resultado para reais.

## 6. Operações CRUD

| Operação | Veículos | Manutenções |
| --- | --- | --- |
| Create | `db.insert('veiculos', dados)` | `db.insert('manutencoes', dados)` |
| Read | `db.query`, resumo com COUNT | `db.query` filtrado por veículo, resumo com SUM |
| Update | `db.update` por id | `db.update` por id e veículo |
| Delete | `db.delete` por id | `db.delete` por id e veículo |

## 7. Operação e limitações

- Android foi validado no Samsung A26. Pastas iOS/macOS/web/Windows/Linux presentes são scaffolds; não representam suporte validado.
- A interface usa ícones e componentes Flutter, sem imagens externas ou chamadas de rede.
- Banco local sem backup/exportação, autenticação, criptografia específica, servidor ou sincronização. Desinstalar/limpar dados remove os registros.
- `publish_to: none` impede publicação acidental como pacote Dart. O APK atual é de demonstração acadêmica e usa assinatura de debug também no build release. Não foi configurada publicação na Play Store.
- Sem testes automatizados. O histórico de verificação manual está em TESTES.md.
- Mudanças futuras no esquema precisam de versão nova e `onUpgrade`; alterar apenas `onCreate` não migra bancos existentes.
- A abertura compartilhada não possui bloqueio explícito para duas primeiras chamadas simultâneas; o fluxo atual começa pela tela inicial.

## 8. Melhorias futuras

Backup/exportação, testes automatizados de validação e banco, separação entre interface e acesso a dados, calendário em português com localização completa, pesquisa de veículos, política de quilometragem e assinatura própria para distribuição. Esses itens não estão implementados.
