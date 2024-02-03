import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tsdm_client/exceptions/exceptions.dart';
import 'package:tsdm_client/features/packet/repository/packet_repository.dart';
import 'package:tsdm_client/utils/debug.dart';

part 'packet_state.dart';

/// Cubit of read packets.
class PacketCubit extends Cubit<PacketState> {
  /// Constructor.
  PacketCubit({required PacketRepository packetRepository})
      : _packetRepository = packetRepository,
        super(const PacketState());

  final PacketRepository _packetRepository;

  /// Try to get coins from the packet.
  Future<void> receivePacket(String url) async {
    emit(state.copyWith(status: PacketStatus.loading));
    try {
      final document = await _packetRepository.receivePacket(url);
      final result = document
          .querySelector('div#messagetext > p')
          ?.innerText
          .split('setTimeout')
          .firstOrNull;
      if (result != null &&
          (result.contains('已经领取过') || result.contains('领取成功'))) {
        emit(state.copyWith(status: PacketStatus.success, reason: result));
      } else if (result != null &&
          result.contains('err_packet_has_gone_away')) {
        emit(state.copyWith(status: PacketStatus.takenAway));
      } else {
        emit(state.copyWith(status: PacketStatus.failed, reason: result));
      }
    } on HttpRequestFailedException catch (e) {
      debug('failed to receive packet: $e');
      emit(
        state.copyWith(
          status: PacketStatus.failed,
          reason: e.toString(),
        ),
      );
    }
  }
}