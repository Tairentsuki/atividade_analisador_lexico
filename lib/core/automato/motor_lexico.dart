import '../models/lexer_models.dart';

/// Gerencia a lógica de análise léxica (Autômato Finito).
/// 
/// Esta classe isola a gramática da linguagem e as transições de estado.
class MotorLexico {
  /// Definição das regras gramaticais através de expressões regulares.
  final Map<TipoToken, RegExp> _regrasDeBusca = {
    TipoToken.comentario:    RegExp(r'//.*'),
    TipoToken.literal:       RegExp(r'"[^"]*"|' r"'[^']*'"),
    TipoToken.reservada:     RegExp(r'\b(if|else|while|for|class|void|int|float|double|string|function|return|print|bool|true|false)\b'),
    TipoToken.numero:        RegExp(r'\b\d+(\.\d+)?\b'),
    TipoToken.operador:      RegExp(r'!=|==|<=|>=|&&|\|\||[+\-*/^<>=!]'),
    TipoToken.delimitador:   RegExp(r'[;(){}\[\]]'),
    TipoToken.identificador: RegExp(r'[a-zA-Z_][a-zA-Z0-9_]*'),
  };

  /// Inicia o processamento do texto bruto para geração de tokens e logs.
  ResultadoAnalise analisarTexto(String textoOriginal) {
    if (textoOriginal.isEmpty) return ResultadoAnalise.vazio();

    final List<Token> tokensValidados = [];
    final List<LogPasso> passosDaSimulacao = [];
    
    _executarVarredura(textoOriginal, tokensValidados, passosDaSimulacao);

    return ResultadoAnalise(tokens: tokensValidados, historico: passosDaSimulacao);
  }

  /// Percorre o texto utilizando o motor de busca unificado.
  void _executarVarredura(String texto, List<Token> tokens, List<LogPasso> logs) {
    final buscador = _gerarBuscadorUnificado();
    final trechos = buscador.allMatches(texto);
    int posicaoAtual = 0;

    for (final trecho in trechos) {
      _processarIntervaloVazio(texto, posicaoAtual, trecho.start, logs);
      _processarTokenEncontrado(trecho, tokens, logs);
      posicaoAtual = trecho.end;
    }
  }

  /// Cria uma expressão regular que combina todas as regras da gramática.
  RegExp _gerarBuscadorUnificado() {
    return RegExp(_regrasDeBusca.values.map((r) => '(${r.pattern})').join('|'));
  }

  /// Registra no histórico os caracteres ignorados entre dois tokens.
  void _processarIntervaloVazio(String texto, int inicio, int fim, List<LogPasso> logs) {
    if (fim > inicio) {
      final conteudo = texto.substring(inicio, fim);
      logs.add(LogPasso(
        texto: conteudo,
        acao: TipoAcao.descartando,
        detalhe: "Ignorando caracteres sem valor léxico",
        inicio: inicio,
        fim: fim,
        regra: r"\s+",
      ));
    }
  }

  /// Classifica, valida e armazena um trecho de texto identificado.
  void _processarTokenEncontrado(Match trecho, List<Token> tokens, List<LogPasso> logs) {
    final valor = trecho.group(0)!;
    final categoria = _identificarCategoria(valor);

    if (categoria != null) {
      final padrao = _regrasDeBusca[categoria]?.pattern;
      
      _registrarFaseDeBusca(valor, categoria, trecho, padrao, logs);
      _armazenarToken(valor, categoria, trecho, padrao, tokens, logs);
    }
  }

  /// Registra o momento em que o autômato identifica um padrão.
  void _registrarFaseDeBusca(String valor, TipoToken tipo, Match m, String? regra, List<LogPasso> logs) {
    logs.add(LogPasso(
      texto: valor,
      acao: TipoAcao.buscando,
      detalhe: "Padrão identificado como ${tipo.name.toUpperCase()}",
      inicio: m.start,
      fim: m.end,
      regra: regra,
      tipo: tipo,
    ));
  }

  /// Salva o token na lista oficial e gera o log de confirmação.
  void _armazenarToken(String valor, TipoToken tipo, Match m, String? regra, List<Token> tokens, List<LogPasso> logs) {
    tokens.add(Token(valor: valor, tipo: tipo));
    logs.add(LogPasso(
      texto: valor,
      acao: TipoAcao.armazenando,
      detalhe: "Token aceito na gramática",
      inicio: m.start,
      fim: m.end,
      regra: regra,
      tipo: tipo,
    ));
  }

  /// Compara o texto com as regras individuais para definir sua categoria.
  TipoToken? _identificarCategoria(String texto) {
    for (var regra in _regrasDeBusca.entries) {
      // Usamos matchAsPrefix para garantir que o texto inteiro bata com a regra
      final match = regra.value.matchAsPrefix(texto);
      if (match != null && match.group(0) == texto) {
        return regra.key;
      }
    }
    return null;
  }
}
