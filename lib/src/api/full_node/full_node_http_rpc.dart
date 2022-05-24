// ignore_for_file: avoid_dynamic_calls, lines_longer_than_80_chars

import 'dart:convert';

import 'package:chia_utils/chia_crypto_utils.dart';
import 'package:chia_utils/src/api/full_node/models/responses/blockchain_state_response.dart';
import 'package:chia_utils/src/api/full_node/models/responses/chia_base_response.dart';
import 'package:chia_utils/src/api/full_node/models/responses/coin_record_response.dart';
import 'package:chia_utils/src/api/full_node/models/responses/coin_records_response.dart';
import 'package:chia_utils/src/api/full_node/models/responses/coin_spend_response.dart';
import 'package:meta/meta.dart';

@immutable
class FullNodeHttpRpc implements FullNode {
  const FullNodeHttpRpc(this.baseURL, {this.certBytes, this.keyBytes});

  @override
  final String baseURL;
  final Bytes? certBytes;
  final Bytes? keyBytes;

  Client get client => Client(baseURL, certBytes: certBytes, keyBytes: keyBytes);

  @override
  Future<CoinRecordsResponse> getCoinRecordsByPuzzleHashes(
    List<Puzzlehash> puzzlehashes, {
    int? startHeight,
    int? endHeight,
    bool includeSpentCoins = false,
  }) async {
    final body = <String, dynamic>{
      'puzzle_hashes': puzzlehashes.map((ph) => ph.toHex()).toList(),
    };
    if (startHeight != null) {
      body['start_height'] = startHeight;
    }
    if (endHeight != null) {
      body['end_height'] = endHeight;
    }
    body['include_spent_coins'] = includeSpentCoins;

    final response = await client.post(
      Uri.parse('get_coin_records_by_puzzle_hashes'),
      body,
    );
    mapResponseToError(response);

    return CoinRecordsResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<ChiaBaseResponse> pushTransaction(SpendBundle spendBundle) async {
    final response = await client.post(
      Uri.parse('push_tx'),
      {'spend_bundle': spendBundle.toJson()},
    );
    mapResponseToError(response);

    return ChiaBaseResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<CoinRecordResponse> getCoinByName(Bytes coinId) async {
    final response = await client.post(Uri.parse('get_coin_record_by_name'), {
      'name': coinId.toHex(),
    });
    mapResponseToError(response);

    return CoinRecordResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<CoinRecordsResponse> getCoinsByNames(
    List<Bytes> coinIds, {
    int? startHeight,
    int? endHeight,
    bool includeSpentCoins = false,
  }) async {
    final body = <String, dynamic>{
      'names': coinIds.map((coinId) => coinId.toHex()).toList(),
    };
    if (startHeight != null) {
      body['start_height'] = startHeight;
    }
    if (endHeight != null) {
      body['end_height'] = endHeight;
    }
    body['include_spent_coins'] = includeSpentCoins;
    final response = await client.post(Uri.parse('get_coin_records_by_names'), body);
    mapResponseToError(response);

    return CoinRecordsResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<CoinSpendResponse> getPuzzleAndSolution(Bytes coinId, int height) async {
    final response = await client.post(Uri.parse('get_puzzle_and_solution'), {
      'coin_id': coinId.toHex(),
      'height': height,
    });
    mapResponseToError(response);

    return CoinSpendResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<BlockchainStateResponse> getBlockchainState() async {
    final response = await client.post(Uri.parse('get_blockchain_state'), <dynamic, dynamic>{});
    mapResponseToError(response);

    return BlockchainStateResponse.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  static void mapResponseToError(Response response) {
    switch (response.statusCode) {
      case 500:
        throw InternalServeErrorException(message: response.body);
    }
  }

  @override
  String toString() => 'FullNode(${client.baseURL})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FullNodeHttpRpc && runtimeType == other.runtimeType && baseURL == other.baseURL;

  @override
  int get hashCode => runtimeType.hashCode ^ baseURL.hashCode;
}
