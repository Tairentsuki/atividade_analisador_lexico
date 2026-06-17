import 'package:flutter/material.dart';
import '../../core/models/lexer_models.dart';

/// Exibe os tokens em um layout de mosaico (Wrap) para evitar rolagem vertical.
class TelaAnalise extends StatelessWidget {
  final List<Token> tokens;

  const TelaAnalise({super.key, required this.tokens});

  @override
  Widget build(BuildContext context) {
    if (tokens.isEmpty) {
      return const Center(child: Text("Nenhum token", style: TextStyle(color: Colors.grey, fontSize: 12)));
    }

    // Lista de categorias para exibir
    final categorias = [
      _buildCategoria("Comentários", TipoToken.comentario, Colors.grey, Icons.comment),
      _buildCategoria("Reservadas", TipoToken.reservada, Colors.blue, Icons.code),
      _buildCategoria("Variáveis", TipoToken.identificador, Colors.purple, Icons.vignette),
      _buildCategoria("Literais", TipoToken.literal, Colors.green, Icons.text_format),
      _buildCategoria("Números", TipoToken.numero, Colors.orange, Icons.pin),
      _buildCategoria("Operadores", TipoToken.operador, Colors.red, Icons.calculate),
      _buildCategoria("Delimitadores", TipoToken.delimitador, Colors.blueGrey, Icons.drag_handle),
    ].whereType<Widget>().toList();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      // O Wrap principal faz as categorias se organizarem horizontalmente
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.start,
        children: categorias,
      ),
    );
  }

  Widget? _buildCategoria(String titulo, TipoToken tipo, Color cor, IconData icone) {
    final filtrados = tokens.where((t) => t.tipo == tipo).toList();
    if (filtrados.isEmpty) return null;

    final Map<String, int> agrupados = {};
    for (var t in filtrados) {
      agrupados[t.valor] = (agrupados[t.valor] ?? 0) + 1;
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 300), // Limite para não ficar largo demais sozinho
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icone, color: cor, size: 14),
              const SizedBox(width: 6),
              Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              const SizedBox(width: 8),
              Text("${filtrados.length}", style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          // Wrap interno para os tokens da categoria
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: agrupados.entries.map((e) => _buildTokenChip(e.key, e.value, cor)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenChip(String valor, int qtd, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            valor,
            style: TextStyle(fontSize: 10, color: cor.withDarkness(0.2), fontWeight: FontWeight.w600, fontFamily: 'monospace'),
          ),
          if (qtd > 1) ...[
            const SizedBox(width: 4),
            Text("x$qtd", style: TextStyle(fontSize: 8, color: cor.withValues(alpha: 0.5), fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }
}

extension ColorDarken on Color {
  Color withDarkness(double amount) {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }
}
