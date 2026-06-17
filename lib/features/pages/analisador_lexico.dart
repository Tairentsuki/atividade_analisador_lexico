import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/models/lexer_models.dart';
import '../controllers/controller_analise.dart';
import 'tela_analise.dart';

class AnalisadorLexico extends StatefulWidget {
  const AnalisadorLexico({super.key});

  @override
  State<AnalisadorLexico> createState() => _AnalisadorLexicoState();
}

class _AnalisadorLexicoState extends State<AnalisadorLexico> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _lineScrollController = ScrollController();
  final _highlightScrollController = ScrollController();
  final _controller = ControllerAnalise();
  
  List<Token> _tokens = [];
  List<LogPasso> _logs = [];
  int _lineCount = 1;
  bool _modoSimulacao = false;
  int _passoAtual = -1;
  bool _estaRodando = false;
  Timer? _timerSimulacao;
  double _velocidade = 1.0;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_aoMudarTexto);
    _scrollController.addListener(_sincronizarScrolls);
  }

  void _sincronizarScrolls() {
    if (_lineScrollController.hasClients) _lineScrollController.jumpTo(_scrollController.offset);
    if (_highlightScrollController.hasClients) _highlightScrollController.jumpTo(_scrollController.offset);
  }

  void _aoMudarTexto() {
    final count = _inputController.text.split('\n').length;
    if (count != _lineCount) setState(() => _lineCount = count);
    final resultado = _controller.analisar(_inputController.text);
    setState(() {
      _tokens = resultado.tokens;
      _logs = resultado.historico;
      if (_modoSimulacao) { _pararSimulacao(); _passoAtual = -1; }
    });
  }

  void _alternarSimulacao(bool ativo) {
    setState(() {
      _modoSimulacao = ativo;
      if (ativo && _logs.isNotEmpty) {
        _passoAtual = 0;
        _estaRodando = false;
        WidgetsBinding.instance.addPostFrameCallback((_) => _centralizarNoPasso());
      } else {
        _passoAtual = -1;
        _pararSimulacao();
      }
    });
  }

  void _playPause() {
    if (_estaRodando) _pararSimulacao(); else _iniciarSimulacao();
  }

  void _iniciarSimulacao() {
    setState(() => _estaRodando = true);
    _timerSimulacao = Timer.periodic(
      Duration(milliseconds: (1000 / _velocidade).round()), 
      (timer) {
        if (_passoAtual < _logs.length - 1) {
          setState(() => _passoAtual++);
          _centralizarNoPasso();
        } else {
          _pararSimulacao();
        }
      }
    );
  }

  void _pararSimulacao() {
    _timerSimulacao?.cancel();
    setState(() => _estaRodando = false);
  }

  void _centralizarNoPasso() {
    if (_passoAtual < 0 || _passoAtual >= _logs.length) return;
    final log = _logs[_passoAtual];
    final textoAteAqui = _inputController.text.substring(0, log.inicio);
    final linha = textoAteAqui.split('\n').length - 1;
    const alturaLinha = 14 * 1.6;
    final offset = (linha * alturaLinha).clamp(0.0, _scrollController.position.maxScrollExtent);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(offset, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("Analisador léxico", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        actions: [
          const Center(child: Text("SIMULAÇÃO", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
          Switch.adaptive(value: _modoSimulacao, onChanged: _alternarSimulacao),
          const SizedBox(width: 16),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final useColumn = constraints.maxWidth < 800; // Muda se a tela for estreita

          return Column(
            children: [
              if (_modoSimulacao) _buildBarraControle(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: useColumn
                    ? Column(children: _buildLayoutItems())
                    : Row(children: _buildLayoutItems()),
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  List<Widget> _buildLayoutItems() {
    return [
      Expanded(
        flex: 4,
        child: _buildPainel(titulo: "Código", filho: _buildEditor())
      ),
      const SizedBox(width: 12, height: 12),
      Expanded(
        flex: 5,
        child: _modoSimulacao
            ? _buildDashboard()
            : _buildPainel(titulo: "Tokens", filho: TelaAnalise(tokens: _tokens))
      ),
    ];
  }

  Widget _buildBarraControle() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        color: Colors.white,
        child: Row(
          children: [
            IconButton(onPressed: () => setState(() { _passoAtual = 0; _centralizarNoPasso(); }), icon: const Icon(Icons.first_page)),
            IconButton(onPressed: _playPause, icon: Icon(_estaRodando ? Icons.pause_circle : Icons.play_circle, color: Colors.indigo)),
            IconButton(onPressed: () => setState(() { if (_passoAtual < _logs.length - 1) { _passoAtual++; _centralizarNoPasso(); } }), icon: const Icon(Icons.navigate_next)),
            const SizedBox(width: 20),
            const Text("Velocidade", style: TextStyle(fontSize: 11, color: Colors.grey)),
            SizedBox(width: 100, child: Slider(value: _velocidade, min: 0.5, max: 4.0, onChanged: (v) => setState(() => _velocidade = v))),
            Text("${_passoAtual + 1}/${_logs.length}"),
          ],
        ),
      ),
    );
  }

  Widget _buildPainel({required String titulo, required Widget filho}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(width: double.infinity, padding: const EdgeInsets.all(8), color: Colors.grey[50], child: Text(titulo.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blueGrey))),
          Expanded(child: filho),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    final log = _passoAtual >= 0 && _passoAtual < _logs.length ? _logs[_passoAtual] : null;
    final tokensAteAgora = _logs.take(_passoAtual + 1)
        .where((l) => l.acao == TipoAcao.armazenando && l.tipo != null)
        .map((l) => Token(valor: l.texto, tipo: l.tipo!))
        .toList();

    return Column(
      children: [
        // Grid para Foco e Regex
        LayoutBuilder(builder: (context, c) {
          final isWide = c.maxWidth > 500;
          return isWide
            ? Row(children: [Expanded(child: _buildCardFoco(log)), const SizedBox(width: 12), Expanded(child: _buildCardRegex(log))])
            : Column(children: [_buildCardFoco(log), const SizedBox(height: 12), _buildCardRegex(log)]);
        }),
        const SizedBox(height: 12),
        Expanded(child: _buildPainel(titulo: "Tokens Identificados", filho: TelaAnalise(tokens: tokensAteAgora))),
      ],
    );
  }

  Widget _buildCardFoco(LogPasso? log) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.indigo.withValues(alpha: 0.1))),
      child: log == null ? const Center(child: Text("...")) : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(log.acao == TipoAcao.descartando ? "LIMPANDO" : "ANALISANDO", style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
          Text("'${log.texto.replaceAll('\n', '\\n')}'", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildCardRegex(LogPasso? log) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.indigo.withValues(alpha: 0.1))),
      child: log == null ? const Center(child: Text("Regra")) : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("REGRA ATIVA", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
          Text(log.regra ?? "N/A", style: const TextStyle(fontSize: 11, color: Colors.indigo, fontWeight: FontWeight.bold, fontFamily: 'monospace'), softWrap: true),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    return Row(
      children: [
        Container(
          width: 40,
          color: Colors.grey[50],
          padding: const EdgeInsets.only(top: 20),
          child: ListView.builder(
            controller: _lineScrollController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _lineCount,
            itemBuilder: (context, i) => SizedBox(height: 14 * 1.6, child: Center(child: Text("${i + 1}", style: const TextStyle(fontSize: 10, color: Colors.black26)))),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              TextField(
                controller: _inputController,
                scrollController: _scrollController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(fontFamily: 'monospace', height: 1.6, fontSize: 14, color: _modoSimulacao ? Colors.transparent : Colors.black87),
                decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(20), hintText: "// Código aqui..."),
              ),
              if (_modoSimulacao)
                IgnorePointer(
                  child: SingleChildScrollView(
                    controller: _highlightScrollController,
                    padding: const EdgeInsets.all(20),
                    child: RichText(text: _gerarDestaque()),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  TextSpan _gerarDestaque() {
    final texto = _inputController.text;
    if (_passoAtual < 0 || _logs.isEmpty || _passoAtual >= _logs.length) return TextSpan(text: texto, style: const TextStyle(fontSize: 14, height: 1.6));
    final log = _logs[_passoAtual];
    return TextSpan(
      style: const TextStyle(fontFamily: 'monospace', height: 1.6, fontSize: 14, color: Colors.black26),
      children: [
        TextSpan(text: texto.substring(0, log.inicio)),
        TextSpan(text: texto.substring(log.inicio, log.fim), style: TextStyle(backgroundColor: log.acao == TipoAcao.armazenando ? Colors.green[100] : (log.acao == TipoAcao.buscando ? Colors.amber[100] : Colors.grey[200]), color: Colors.black87, fontWeight: FontWeight.bold)),
        TextSpan(text: texto.substring(log.fim)),
      ],
    );
  }

  @override
  void dispose() { 
    _timerSimulacao?.cancel(); 
    _inputController.dispose(); 
    _scrollController.dispose();
    _lineScrollController.dispose();
    _highlightScrollController.dispose();
    super.dispose(); 
  }
}
