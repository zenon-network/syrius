import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';

/// Stores the beneficiary address selected for Plasma fusion.
class PlasmaBeneficiaryAddressCubit extends Cubit<String?> {
  /// Creates a cubit with a default beneficiary address.
  PlasmaBeneficiaryAddressCubit() : super(kSelectedAddress);

  /// Updates the Plasma beneficiary address.
  void changeAddress(String? address) => emit(address);
}
