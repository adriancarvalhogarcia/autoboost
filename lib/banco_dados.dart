import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Centraliza a abertura do banco local autoboost.db.
class BancoDados {
  // Construtor privado: as telas acessam a instância compartilhada abaixo.
  BancoDados._();

  static final BancoDados instancia = BancoDados._();

  Database? _banco;

  Future<Database> get banco async {
    // Reutiliza a conexão já aberta, quando disponível.
    if (_banco != null) return _banco!;

    // Usa a pasta de banco do aplicativo, sem caminho específico de um computador.
    final pasta = await getDatabasesPath();
    final caminho = join(pasta, 'autoboost.db');

    _banco = await openDatabase(
      caminho,
      // Versão inicial do esquema; futuras mudanças exigem migração em onUpgrade.
      version: 1,
      onConfigure: (db) async {
        // Ativa a integridade referencial e a exclusão em cascata no SQLite.
        await db.execute('PRAGMA foreign_keys = ON');
      },
      // Cria as tabelas apenas na primeira abertura de um banco novo.
      onCreate: (db, version) async {
        // A restrição UNIQUE impede que dois veículos tenham a mesma placa.
        await db.execute('''
          CREATE TABLE veiculos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            marca TEXT NOT NULL,
            modelo TEXT NOT NULL,
            ano INTEGER NOT NULL,
            placa TEXT NOT NULL UNIQUE,
            quilometragem INTEGER NOT NULL DEFAULT 0
          )
        ''');

        // Um veículo possui vários serviços. Valores são inteiros em centavos.
        // ON DELETE CASCADE remove seus serviços quando o veículo é excluído.
        await db.execute('''
          CREATE TABLE manutencoes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            veiculo_id INTEGER NOT NULL,
            servico TEXT NOT NULL,
            data TEXT NOT NULL,
            quilometragem INTEGER NOT NULL,
            valor_centavos INTEGER NOT NULL,
            observacoes TEXT NOT NULL DEFAULT '',
            FOREIGN KEY (veiculo_id)
              REFERENCES veiculos (id)
              ON DELETE CASCADE
          )
        ''');
      },
    );

    return _banco!;
  }
}