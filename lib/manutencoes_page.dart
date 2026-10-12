import 'package:flutter/material.dart';
import 'banco_dados.dart';

const _azul = Color(0xFF2563EB);
const _escuro = Color(0xFF14213D);
const _fundo = Color(0xFFF3F5F9);

/// Converte centavos para a apresentação brasileira, sem mudar o valor armazenado.
String formatarValor(int centavos) {
  final partes = (centavos / 100).toStringAsFixed(2).split('.');
  final inteiro = partes[0].replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]}.',
  );
  return 'R\$ $inteiro,${partes[1]}';
}

/// Apresenta em DD/MM/AAAA a data armazenada como AAAA-MM-DD.
String formatarData(String data) {
  final partes = data.split('-');
  if (partes.length != 3) return data;
  return '${partes[2]}/${partes[1]}/${partes[0]}';
}

InputDecoration _campo(
  String titulo,
  IconData icone, {
  String? dica,
  String? prefixo,
  String? sufixo,
}) {
  return InputDecoration(
    labelText: titulo,
    hintText: dica,
    prefixIcon: Icon(icone, color: _azul),
    prefixText: prefixo,
    suffixText: sufixo,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.all(18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFDFE5EF)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _azul, width: 2),
    ),
  );
}

/// Consulta somente as manutenções do veículo selecionado.
class ManutencoesPage extends StatefulWidget {
  final int veiculoId;
  final String nomeVeiculo;

  const ManutencoesPage({
    super.key,
    required this.veiculoId,
    required this.nomeVeiculo,
  });

  @override
  State<ManutencoesPage> createState() => _ManutencoesPageState();
}

class _ManutencoesPageState extends State<ManutencoesPage> {
  List<Map<String, Object?>> _registros = [];
  bool _carregando = true;
  bool _excluindo = false;
  String? _erro;

  @override
  // Inicializa a tela; no formulário de edição, preenche os dados existentes.
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final db = await BancoDados.instancia.banco;
      final registros = await db.query(
        'manutencoes',
        where: 'veiculo_id = ?',
        whereArgs: [widget.veiculoId],
        orderBy: 'data DESC, id DESC',
      );
      if (!mounted) return;
      setState(() {
        _registros = registros;
        _carregando = false;
        _erro = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = 'Não foi possível carregar as manutenções.';
      });
    }
  }

  // Um registro recebido indica edição; null indica uma manutenção nova.
  Future<void> _abrirFormulario({
    Map<String, Object?>? manutencao,
  }) async {
    final salvo = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CadastroManutencaoPage(
          veiculoId: widget.veiculoId,
          manutencao: manutencao,
        ),
      ),
    );
    if (salvo == true && mounted) await _carregar();
  }

  // A confirmação evita exclusão por toque acidental; a lista é recarregada após excluir.
  Future<void> _excluir(Map<String, Object?> registro) async {
    if (_excluindo) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir manutenção?'),
        content: Text(
          'Excluir "${registro['servico']}"?\n\n'
          'O valor será removido do total gasto. '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted || _excluindo) return;
    setState(() => _excluindo = true);

    try {
      final db = await BancoDados.instancia.banco;
      await db.delete(
        'manutencoes',
        // Parâmetros vinculados restringem a operação ao registro deste veículo.
        where: 'id = ? AND veiculo_id = ?',
        whereArgs: [registro['id'], widget.veiculoId],
      );
      if (!mounted) return;
      await _carregar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Manutenção excluída.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir.')),
      );
    } finally {
      if (mounted) setState(() => _excluindo = false);
    }
  }

  Widget _cartao(Map<String, Object?> registro) {
    final observacoes = registro['observacoes'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5EAF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.build_outlined, color: _azul),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  registro['servico'] as String,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _escuro,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                enabled: !_excluindo,
                tooltip: 'Opções da manutenção',
                onSelected: (opcao) async {
                  if (opcao == 'editar') {
                    await _abrirFormulario(manutencao: registro);
                  } else {
                    await _excluir(registro);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'editar',
                    child: Text('Editar manutenção'),
                  ),
                  PopupMenuItem(
                    value: 'excluir',
                    child: Text(
                      'Excluir manutenção',
                      style: TextStyle(color: Color(0xFFDC2626)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Text(
                formatarData(registro['data'] as String),
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
              Text(
                '${registro['quilometragem']} km',
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formatarValor(registro['valor_centavos'] as int),
            style: const TextStyle(
              fontSize: 22,
              color: _azul,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (observacoes.isNotEmpty) ...[
            const Divider(height: 28),
            Text(
              observacoes,
              style: const TextStyle(color: Color(0xFF475569)),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Soma os valores inteiros em centavos dos serviços do veículo.
    final total = _registros.fold<int>(
      0,
      (soma, registro) => soma + (registro['valor_centavos'] as int),
    );

    return Scaffold(
      backgroundColor: _fundo,
      appBar: AppBar(
        backgroundColor: _fundo,
        title: Text(
          widget.nomeVeiculo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _azul,
        foregroundColor: Colors.white,
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nova manutenção'),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_erro!),
                      TextButton(
                        onPressed: _carregar,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_escuro, Color(0xFF23447B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.account_balance_wallet_outlined,
                              color: Color(0xFF93C5FD),
                              size: 32,
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'TOTAL EM MANUTENÇÕES',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                letterSpacing: 1.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              formatarValor(total),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${_registros.length} '
                              '${_registros.length == 1 ? 'serviço registrado' : 'serviços registrados'}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Histórico de serviços',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _escuro,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Acompanhe os cuidados com seu veículo.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 20),
                      if (_registros.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.build_circle_outlined,
                                size: 64,
                                color: _azul,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Seu histórico começa aqui',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Registre o primeiro serviço em Nova manutenção.',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ..._registros.map(_cartao),
                    ],
                  ),
                ),
    );
  }
}

/// Cadastra ou edita um serviço mantendo o vínculo com o veículo.
class CadastroManutencaoPage extends StatefulWidget {
  final int veiculoId;
  final Map<String, Object?>? manutencao;

  const CadastroManutencaoPage({
    super.key,
    required this.veiculoId,
    this.manutencao,
  });

  @override
  State<CadastroManutencaoPage> createState() =>
      _CadastroManutencaoPageState();
}

class _CadastroManutencaoPageState extends State<CadastroManutencaoPage> {
  final _formulario = GlobalKey<FormState>();
  final _servico = TextEditingController();
  final _km = TextEditingController();
  final _valor = TextEditingController();
  final _observacoes = TextEditingController();

  DateTime _data = DateUtils.dateOnly(DateTime.now());
  bool _salvando = false;

  bool get _editando => widget.manutencao != null;

  @override
  // Inicializa a tela; no formulário de edição, preenche os dados existentes.
  void initState() {
    super.initState();
    final registro = widget.manutencao;
    if (registro != null) {
      _servico.text = registro['servico'] as String;
      _km.text = registro['quilometragem'].toString();
      final centavos = registro['valor_centavos'] as int;
      _valor.text = '${centavos ~/ 100},'
          '${(centavos % 100).toString().padLeft(2, '0')}';
      _observacoes.text = registro['observacoes'] as String;
      _data = DateTime.parse(registro['data'] as String);
    }
  }

  @override
  // Libera os controladores de texto ao fechar o formulário.
  void dispose() {
    _servico.dispose();
    _km.dispose();
    _valor.dispose();
    _observacoes.dispose();
    super.dispose();
  }

  String get _dataBanco {
    final ano = _data.year.toString().padLeft(4, '0');
    final mes = _data.month.toString().padLeft(2, '0');
    final dia = _data.day.toString().padLeft(2, '0');
    return '$ano-$mes-$dia';
  }

  // Aceita vírgula ou ponto decimal e até duas casas; não aceita separador de milhar.
  // A conversão usa inteiros para não introduzir arredondamento no valor salvo.
  int? _valorEmCentavos(String texto) {
    final normalizado = texto.trim().replaceAll(',', '.');
    if (!RegExp(r'^\d{1,9}(\.\d{1,2})?$').hasMatch(normalizado)) {
      return null;
    }

    final partes = normalizado.split('.');
    return int.parse(partes[0]) * 100 +
        (partes.length == 2
            ? int.parse(partes[1].padRight(2, '0'))
            : 0);
  }

  // Registra serviços realizados, por isso impede escolher uma data futura.
  Future<void> _escolherData() async {
    final hoje = DateUtils.dateOnly(DateTime.now());
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _data.isAfter(hoje) ? hoje : _data,
      firstDate: DateTime(1900),
      lastDate: hoje,
      helpText: 'Data do serviço',
      cancelText: 'Cancelar',
      confirmText: 'Selecionar',
    );
    if (escolhida != null && mounted) {
      setState(() => _data = escolhida);
    }
  }

  // Valida os campos e bloqueia cliques repetidos antes de acessar o banco.
  Future<void> _salvar() async {
    if (_salvando || !_formulario.currentState!.validate()) return;
    setState(() => _salvando = true);

    try {
      final db = await BancoDados.instancia.banco;
      final dados = <String, Object?>{
        'veiculo_id': widget.veiculoId,
        'servico': _servico.text.trim(),
        'data': _dataBanco,
        'quilometragem': int.parse(_km.text.trim()),
        'valor_centavos': _valorEmCentavos(_valor.text)!,
        'observacoes': _observacoes.text.trim(),
      };

      if (_editando) {
        final alterados = await db.update(
          'manutencoes',
          dados,
          // Parâmetros vinculados restringem a operação ao registro deste veículo.
        where: 'id = ? AND veiculo_id = ?',
          whereArgs: [widget.manutencao!['id'], widget.veiculoId],
        );
        if (alterados == 0) {
          throw StateError('Manutenção não encontrada.');
        }
      } else {
        await db.insert('manutencoes', dados);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar a manutenção.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fundo,
      appBar: AppBar(
        backgroundColor: _fundo,
        title: Text(
          _editando ? 'Editar manutenção' : 'Nova manutenção',
        ),
      ),
      body: Form(
        key: _formulario,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Cada cuidado conta.',
              style: TextStyle(
                color: _escuro,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Organize o serviço, a data e o valor em um só lugar.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: _servico,
              decoration: _campo(
                'Serviço realizado',
                Icons.build_outlined,
                dica: 'Ex.: Troca de óleo',
              ),
              validator: (valor) {
                if (valor == null || valor.trim().isEmpty) {
                  return 'Informe o serviço.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _azul,
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _escolherData,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text('Data: ${formatarData(_dataBanco)}'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _km,
              keyboardType: TextInputType.number,
              decoration: _campo(
                'Quilometragem no serviço',
                Icons.speed_outlined,
                sufixo: 'km',
              ),
              validator: (valor) {
                final km = int.tryParse(valor?.trim() ?? '');
                if (km == null || km < 0) {
                  return 'Informe uma quilometragem válida.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valor,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _campo(
                'Valor pago',
                Icons.payments_outlined,
                prefixo: 'R\$ ',
                dica: '250,00',
              ),
              validator: (valor) {
                if (_valorEmCentavos(valor ?? '') == null) {
                  return 'Use 250,00, por exemplo, sem separador de milhar.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _observacoes,
              maxLines: 3,
              decoration: _campo(
                'Observações (opcional)',
                Icons.notes_rounded,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _azul,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _salvando ? null : _salvar,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                _salvando
                    ? 'Salvando...'
                    : _editando
                        ? 'Salvar alterações'
                        : 'Salvar manutenção',
              ),
            ),
          ],
        ),
      ),
    );
  }
}