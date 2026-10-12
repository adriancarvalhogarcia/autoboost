# Roteiro de apresentação — 3 a 5 minutos

## Abertura

“O AutoBoost ajuda a organizar veículos, serviços de manutenção e gastos. O projeto usa Flutter e Dart na interface e SQLite como banco local. Foi pensado para funcionar offline depois da instalação.”

## Demonstração

1. Mostrar o início e explicar os três indicadores.
2. Abrir a garagem e cadastrar um veículo de demonstração com placa diferente dos registros existentes.
3. Abrir o veículo e registrar uma troca de óleo de R$ 250,00.
4. Editar o serviço para R$ 280,00 e mostrar o recálculo.
5. Criar um serviço de teste de R$ 20,00, mostrar R$ 300,00 e excluir somente o teste para voltar a R$ 280,00.
6. Fechar e reabrir o aplicativo em modo avião para demonstrar persistência.

## Explicação técnica

“O banco tem duas tabelas: veículos e manutenções. O campo veiculo_id liga cada serviço ao seu veículo. Os valores são guardados como centavos inteiros. Ao excluir um veículo, seus serviços são removidos em cascata. As telas consultam novamente o banco depois de salvar, editar ou excluir.”

## Perguntas possíveis

| Pergunta | Resposta |
| --- | --- |
| Precisa de internet? | Para instalar dependências no desenvolvimento, sim. Para usar o app instalado, não. |
| Onde ficam os dados? | No arquivo SQLite local do aplicativo, no próprio celular. |
| Funciona em outro celular? | Um Android compatível pode receber o APK; começa com banco próprio, sem os dados do apresentador. |
| E se desinstalar? | Os dados locais são removidos; exportação/backup ainda não foi implementado. |
| Tem IA ou servidor? | Não nesta entrega; o foco é CRUD, interface e persistência local. |

Antes de apresentar: carregar o celular, ensaiar a sequência e guardar APK e código-fonte. Não usar registros reais para demonstrar exclusão.
