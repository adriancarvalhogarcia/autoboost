import 'package:flutter/material.dart';

import 'banco_dados.dart';
import 'manutencoes_page.dart';

const azul = Color(0xFF2563EB);
const escuro = Color(0xFF14213D);
const fundo = Color(0xFFF3F5F9);
const cinza = Color(0xFF64748B);

// Inicializa os plugins antes de iniciar a árvore de widgets do aplicativo.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AutoBoostApp());
}

BoxDecoration caixaBranca() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: const Color(0xFFE5EAF2)),
  );
}

/// Define o tema visual e a primeira tela do AutoBoost.
class AutoBoostApp extends StatelessWidget {
  const AutoBoostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoBoost',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: azul,
          primary: azul,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: fundo,
        appBarTheme: const AppBarTheme(
          backgroundColor: fundo,
          foregroundColor: escuro,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: escuro,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        floatingActionButtonTheme:
            const FloatingActionButtonThemeData(
          backgroundColor: azul,
          foregroundColor: Colors.white,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: azul,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(18),
          prefixIconColor: azul,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFFDFE5EF),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: azul,
              width: 2,
            ),
          ),
        ),
      ),
      home: const InicioPage(),
    );
  }
}

/// Reutiliza a apresentação de erros e a opção de tentar novamente.
class AvisoErro extends StatelessWidget {
  final String mensagem;
  final VoidCallback tentar;

  const AvisoErro({
    super.key,
    required this.mensagem,
    required this.tentar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: cinza, size: 40),
          const SizedBox(height: 12),
          Text(mensagem, textAlign: TextAlign.center),
          TextButton(
            onPressed: tentar,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

/// Exibe os totais da garagem; os valores são consultados no SQLite.
class InicioPage extends StatefulWidget {
  const InicioPage({super.key});

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  int _quantidade = 0;
  int _servicos = 0;
  int _total = 0;
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final db = await BancoDados.instancia.banco;

      // Consulta os indicadores na mesma transação para obter um resumo consistente.
      final resumo = await db.transaction((txn) async {
        final veiculos = await txn.rawQuery(
          'SELECT COUNT(*) AS quantidade FROM veiculos',
        );
        final manutencoes = await txn.rawQuery(
          'SELECT COUNT(*) AS quantidade, '
          'COALESCE(SUM(valor_centavos), 0) AS total '
          'FROM manutencoes',
        );

        return <String, int>{
          'veiculos': veiculos.first['quantidade'] as int,
          'servicos': manutencoes.first['quantidade'] as int,
          'total': manutencoes.first['total'] as int,
        };
      });

      // A operação é assíncrona: a tela pode ter sido fechada durante a espera.
      if (!mounted) return;
      setState(() {
        _quantidade = resumo['veiculos']!;
        _servicos = resumo['servicos']!;
        _total = resumo['total']!;
        _carregando = false;
        _erro = null;
      });
    } catch (_) {
      // A operação é assíncrona: a tela pode ter sido fechada durante a espera.
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = 'Não foi possível carregar o resumo.';
      });
    }
  }

  Future<void> _abrirVeiculos() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VeiculosPage()),
    );
    // Atualiza o resumo/lista após retornar de outra tela.
    if (mounted) await _carregar();
  }

  Future<void> _novoVeiculo() async {
    final salvo = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const CadastroVeiculoPage(),
      ),
    );
    if (salvo == true && mounted) await _carregar();
  }

  Widget _indicador(
    IconData icone,
    String valor,
    String descricao,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: caixaBranca(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icone, color: azul),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valor,
                  style: const TextStyle(
                    color: escuro,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  descricao,
                  style: const TextStyle(color: cinza),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.directions_car_rounded, color: azul),
            SizedBox(width: 10),
            Text('AutoBoost'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _carregar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [escuro, Color(0xFF23447B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.directions_car_rounded,
                    size: 48,
                    color: Color(0xFF93C5FD),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Sua garagem.\nTudo sob controle.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Veículos, serviços e gastos organizados '
                    'em um só lugar.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Visão geral',
              style: TextStyle(
                color: escuro,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Acompanhe os números da sua garagem.',
              style: TextStyle(color: cinza),
            ),
            const SizedBox(height: 18),
            if (_carregando)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_erro != null)
              AvisoErro(
                mensagem: _erro!,
                tentar: _carregar,
              )
            else ...[
              _indicador(
                Icons.garage_outlined,
                '$_quantidade',
                _quantidade == 1
                    ? 'Veículo cadastrado'
                    : 'Veículos cadastrados',
              ),
              const SizedBox(height: 12),
              _indicador(
                Icons.build_outlined,
                '$_servicos',
                _servicos == 1
                    ? 'Manutenção registrada'
                    : 'Manutenções registradas',
              ),
              const SizedBox(height: 12),
              _indicador(
                Icons.account_balance_wallet_outlined,
                formatarValor(_total),
                'Total gasto em manutenção',
              ),
            ],
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _abrirVeiculos,
              icon: const Icon(Icons.directions_car_outlined),
              label: const Text('Acessar minha garagem'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _novoVeiculo,
              icon: const Icon(Icons.add),
              label: const Text('Cadastrar novo veículo'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lista veículos e oferece navegação, edição e exclusão.
class VeiculosPage extends StatefulWidget {
  const VeiculosPage({super.key});

  @override
  State<VeiculosPage> createState() => _VeiculosPageState();
}

class _VeiculosPageState extends State<VeiculosPage> {
  List<Map<String, Object?>> _veiculos = [];
  bool _carregando = true;
  bool _excluindo = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final db = await BancoDados.instancia.banco;
      final registros = await db.query(
        'veiculos',
        orderBy: 'id DESC',
      );

      // A operação é assíncrona: a tela pode ter sido fechada durante a espera.
      if (!mounted) return;
      setState(() {
        _veiculos = registros;
        _carregando = false;
        _erro = null;
      });
    } catch (_) {
      // A operação é assíncrona: a tela pode ter sido fechada durante a espera.
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = 'Não foi possível carregar os veículos.';
      });
    }
  }

  // O mesmo formulário recebe um veículo na edição ou null no cadastro.
  Future<void> _formulario({
    Map<String, Object?>? veiculo,
  }) async {
    final salvo = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CadastroVeiculoPage(veiculo: veiculo),
      ),
    );
    if (salvo == true && mounted) await _carregar();
  }

  Future<void> _abrirManutencoes(
    Map<String, Object?> veiculo,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManutencoesPage(
          veiculoId: veiculo['id'] as int,
          nomeVeiculo: '${veiculo['marca']} ${veiculo['modelo']}',
        ),
      ),
    );
    // Atualiza o resumo/lista após retornar de outra tela.
    if (mounted) await _carregar();
  }

  // Só executa a exclusão após confirmação; as manutenções são removidas em cascata.
  Future<void> _excluirVeiculo(
    Map<String, Object?> veiculo,
  ) async {
    if (_excluindo) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir veículo?'),
        content: Text(
          'Excluir ${veiculo['marca']} ${veiculo['modelo']} '
          '(${veiculo['placa']})?\n\n'
          'Todas as manutenções deste veículo também serão excluídas. '
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
        'veiculos',
        where: 'id = ?',
        whereArgs: [veiculo['id']],
      );
      // A operação é assíncrona: a tela pode ter sido fechada durante a espera.
      if (!mounted) return;
      await _carregar();
      // A operação é assíncrona: a tela pode ter sido fechada durante a espera.
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veículo excluído.')),
      );
    } catch (_) {
      // A operação é assíncrona: a tela pode ter sido fechada durante a espera.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível excluir o veículo.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _excluindo = false);
    }
  }

  Widget _cartaoVeiculo(Map<String, Object?> veiculo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: caixaBranca(),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _abrirManutencoes(veiculo),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.directions_car_rounded,
                        color: azul,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            veiculo['marca'] as String,
                            style: const TextStyle(
                              color: cinza,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            veiculo['modelo'] as String,
                            style: const TextStyle(
                              color: escuro,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      enabled: !_excluindo,
                      tooltip: 'Opções do veículo',
                      onSelected: (opcao) async {
                        if (opcao == 'editar') {
                          await _formulario(veiculo: veiculo);
                        } else {
                          await _excluirVeiculo(veiculo);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'editar',
                          child: Text('Editar veículo'),
                        ),
                        PopupMenuItem(
                          value: 'excluir',
                          child: Text(
                            'Excluir veículo',
                            style: TextStyle(
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    Chip(
                      avatar: const Icon(
                        Icons.confirmation_number_outlined,
                        size: 18,
                        color: azul,
                      ),
                      label: Text(veiculo['placa'] as String),
                      backgroundColor: const Color(0xFFF8FAFC),
                      side: BorderSide.none,
                    ),
                    Chip(
                      avatar: const Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: azul,
                      ),
                      label: Text(veiculo['ano'].toString()),
                      backgroundColor: const Color(0xFFF8FAFC),
                      side: BorderSide.none,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.speed_outlined,
                      color: cinza,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${veiculo['quilometragem']} km',
                        style: const TextStyle(color: cinza),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 28),
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ver manutenções',
                        style: TextStyle(
                          color: azul,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_rounded, color: azul),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minha garagem')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _formulario(),
        icon: const Icon(Icons.add),
        label: const Text('Novo veículo'),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(
                  child: AvisoErro(
                    mensagem: _erro!,
                    tentar: _carregar,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                    children: [
                      const Text(
                        'Seus veículos',
                        style: TextStyle(
                          color: escuro,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Toque em um veículo para acompanhar os serviços.',
                        style: TextStyle(color: cinza),
                      ),
                      const SizedBox(height: 24),
                      if (_veiculos.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: caixaBranca(),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.garage_outlined,
                                size: 64,
                                color: azul,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Sua garagem começa aqui',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: escuro,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Cadastre seu primeiro veículo '
                                'em Novo veículo.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: cinza),
                              ),
                            ],
                          ),
                        ),
                      ..._veiculos.map(_cartaoVeiculo),
                    ],
                  ),
                ),
    );
  }
}

/// Formulário compartilhado entre cadastro e edição de veículos.
class CadastroVeiculoPage extends StatefulWidget {
  final Map<String, Object?>? veiculo;

  const CadastroVeiculoPage({
    super.key,
    this.veiculo,
  });

  @override
  State<CadastroVeiculoPage> createState() =>
      _CadastroVeiculoPageState();
}

class _CadastroVeiculoPageState extends State<CadastroVeiculoPage> {
  final _formulario = GlobalKey<FormState>();
  final _marca = TextEditingController();
  final _modelo = TextEditingController();
  final _ano = TextEditingController();
  final _placa = TextEditingController();
  final _quilometragem = TextEditingController(text: '0');

  bool _salvando = false;
  bool get _editando => widget.veiculo != null;

  @override
  void initState() {
    super.initState();
    final veiculo = widget.veiculo;
    if (veiculo != null) {
      _marca.text = veiculo['marca'] as String;
      _modelo.text = veiculo['modelo'] as String;
      _ano.text = veiculo['ano'].toString();
      _placa.text = veiculo['placa'] as String;
      _quilometragem.text = veiculo['quilometragem'].toString();
    }
  }

  @override
  // Libera os controladores quando o formulário sai da árvore de widgets.
  void dispose() {
    _marca.dispose();
    _modelo.dispose();
    _ano.dispose();
    _placa.dispose();
    _quilometragem.dispose();
    super.dispose();
  }

  String? _obrigatorio(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Preencha este campo.';
    }
    return null;
  }

  Future<void> _salvar() async {
    if (_salvando || !_formulario.currentState!.validate()) return;
    setState(() => _salvando = true);

    try {
      final db = await BancoDados.instancia.banco;
      final placa = _placa.text
          .trim()
          .toUpperCase()
          .replaceAll(RegExp(r'[\s-]'), '');

      // A placa deve ser única, mas pode pertencer ao próprio veículo em edição.
      final existente = await db.query(
        'veiculos',
        where: 'placa = ?',
        whereArgs: [placa],
        limit: 1,
      );

      // A operação é assíncrona: a tela pode ter sido fechada durante a espera.
      if (!mounted) return;

      if (existente.isNotEmpty &&
          existente.first['id'] != widget.veiculo?['id']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Essa placa já está cadastrada.'),
          ),
        );
        return;
      }

      // Dados normalizados; o id existente é mantido para preservar o histórico.
      final dados = <String, Object?>{
        'marca': _marca.text.trim(),
        'modelo': _modelo.text.trim(),
        'ano': int.parse(_ano.text.trim()),
        'placa': placa,
        'quilometragem': int.parse(_quilometragem.text.trim()),
      };

      if (_editando) {
        final alterados = await db.update(
          'veiculos',
          dados,
          where: 'id = ?',
          whereArgs: [widget.veiculo!['id']],
        );
        if (alterados == 0) {
          throw StateError('Veículo não encontrado.');
        }
      } else {
        await db.insert('veiculos', dados);
      }

      // A operação é assíncrona: a tela pode ter sido fechada durante a espera.
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      // A operação é assíncrona: a tela pode ter sido fechada durante a espera.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar. Tente novamente.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar veículo' : 'Novo veículo'),
      ),
      body: Form(
        key: _formulario,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              _editando ? 'Seu veículo, atualizado.' : 'Bem-vindo à garagem.',
              style: const TextStyle(
                color: escuro,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Preencha os dados para organizar seus serviços e gastos.',
              style: TextStyle(color: cinza),
            ),
            const SizedBox(height: 28),
            TextFormField(
              controller: _marca,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Marca',
                hintText: 'Ex.: Fiat',
                prefixIcon: Icon(Icons.business_outlined),
              ),
              validator: _obrigatorio,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _modelo,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Modelo',
                hintText: 'Ex.: Argo',
                prefixIcon: Icon(Icons.directions_car_outlined),
              ),
              validator: _obrigatorio,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ano,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Ano',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              validator: (valor) {
                final ano = int.tryParse(valor?.trim() ?? '');
                if (ano == null ||
                    ano < 1900 ||
                    ano > DateTime.now().year + 1) {
                  return 'Informe um ano válido.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _placa,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Placa',
                hintText: 'ABC1D23 ou ABC1234',
                prefixIcon: Icon(Icons.confirmation_number_outlined),
              ),
              validator: (valor) {
                final placa = (valor ?? '')
                    .toUpperCase()
                    .replaceAll(RegExp(r'[\s-]'), '');
                if (!RegExp(r'^[A-Z]{3}[0-9][A-Z0-9][0-9]{2}$')
                    .hasMatch(placa)) {
                  return 'Informe uma placa brasileira válida.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quilometragem,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quilometragem atual',
                suffixText: 'km',
                prefixIcon: Icon(Icons.speed_outlined),
              ),
              validator: (valor) {
                final km = int.tryParse(valor?.trim() ?? '');
                if (km == null || km < 0) {
                  return 'Informe uma quilometragem válida.';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _salvando ? null : _salvar,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                _salvando
                    ? 'Salvando...'
                    : _editando
                        ? 'Salvar alterações'
                        : 'Salvar veículo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}