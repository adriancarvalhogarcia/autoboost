# Testes e evidências

Os resultados abaixo foram observados pelo usuário no Samsung Galaxy A26, Android 16, durante o desenvolvimento. São testes manuais, não uma execução automatizada. A revisão deste pacote acrescentou comentários e documentação; o ambiente desta revisão não dispõe do Flutter para recompilar.

| Caso | Resultado informado/observado |
| --- | --- |
| Análise estática | `flutter analyze` retornou No issues found na versão final enviada |
| Cadastrar veículo | Veículo exibido na garagem |
| Persistência de veículo | Cadastro permaneceu após fechar e reabrir |
| Editar veículo | Quilometragem mudou de 35000 para 36000; histórico permaneceu com 35000 |
| Excluir veículo | Veículo excluído desapareceu da lista |
| Cadastrar manutenção | Troca de óleo exibida com R$ 250,00 |
| Editar manutenção | Valor e total passaram de R$ 250,00 para R$ 280,00 |
| Somar serviços | Outro serviço de R$ 300,00 levou o total a R$ 580,00 |
| Excluir manutenção | Remoção do serviço de teste levou o total a R$ 280,00 |
| Indicadores iniciais | 1 veículo, 1 manutenção e R$ 280,00 nas capturas finais |
| Build release | APK gerado com sucesso, aproximadamente 48 MB |
| Instalação e offline | Usuário confirmou abertura, novos cadastros e persistência após reabrir sem internet |

O cancelamento de exclusão e a remoção em cascata têm implementação no código, mas não houve confirmação separada de um teste completo para esses dois casos. A instalação release utilizada desinstalou a versão anterior e os dados precisaram ser cadastrados novamente.

## Roteiro para validar antes da entrega

1. Executar `flutter pub get` e `flutter analyze` no pacote comentado.
2. Abrir o app no Android; cadastrar veículo com placa nova.
3. Tentar salvar formulário vazio, ano inválido, placa inválida, placa duplicada e quilometragem negativa. Verificar mensagens e ausência de registro inválido.
4. Cadastrar manutenção de 250,00; editar para 280,00; cadastrar outra de 20,00; confirmar soma 300,00; cancelar sua exclusão; confirmar que permaneceu; excluir e conferir 280,00.
5. Editar o veículo e confirmar que os serviços continuam vinculados.
6. Em um veículo descartável, cadastrar um serviço e excluir o veículo; conferir que os indicadores globais não contam mais esse serviço.
7. Fechar e reabrir com modo avião; conferir dados. Restaurar as conexões do celular após o teste.

Não desinstalar para testar persistência: a desinstalação remove o banco. A análise estática não substitui testes de execução nem garante atualização preservando dados.
