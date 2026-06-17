/// Categorias que o analisador consegue identificar.
enum TipoToken {
  comentario,
  reservada,
  identificador,
  literal,
  numero,
  operador,
  delimitador
}

/// Ações que o motor realiza passo a passo.
enum TipoAcao {
  buscando,    // Procurando o que é esse pedaço de texto
  descartando, // Jogando fora o que é espaço ou quebra de linha
  armazenando  // Validou e guardou o item na lista
}

/// Representa um item identificado no código (ex: uma variável ou um número).
class Token {
  final String valor;
  final TipoToken tipo;
  Token({required this.valor, required this.tipo});
}

/// Representa uma etapa da explicação didática.
class LogPasso {
  final String texto;
  final TipoAcao acao;
  final String detalhe;
  final String? regra; // A regra (regex) que foi usada
  final TipoToken? tipo; // Categoria do token se houver
  final int inicio;   // Onde começa no texto
  final int fim;      // Onde termina no texto

  LogPasso({
    required this.texto,
    required this.acao,
    required this.detalhe,
    required this.inicio,
    required this.fim,
    this.regra,
    this.tipo,
  });
}

/// O resultado final entregue pelo motor de análise.
class ResultadoAnalise {
  final List<Token> tokens;
  final List<LogPasso> historico;

  ResultadoAnalise({required this.tokens, required this.historico});

  factory ResultadoAnalise.vazio() => ResultadoAnalise(tokens: [], historico: []);
}
