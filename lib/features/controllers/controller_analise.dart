import '../../core/models/lexer_models.dart';
import '../../core/automato/motor_lexico.dart';

class ControllerAnalise {
  final _motor = MotorLexico();

  /// Pede para o motor analisar o texto e retorna o resultado.
  ResultadoAnalise analisar(String texto) {
    return _motor.analisarTexto(texto);
  }
}
