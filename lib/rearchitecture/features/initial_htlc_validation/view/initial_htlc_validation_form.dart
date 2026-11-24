import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/initial_htlc_validation/bloc/initial_htlc_validation_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/initial_htlc_validation/view/initial_htlc_validation_button.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/input_validators.dart';

/// Form for finding and validating an initial HTLC deposit.
class InitialHtlcValidationForm extends StatefulWidget {
  /// Creates an [InitialHtlcValidationForm].
  const InitialHtlcValidationForm({super.key});

  @override
  State<InitialHtlcValidationForm> createState() =>
      _InitialHtlcValidationFormState();
}

class _InitialHtlcValidationFormState extends State<InitialHtlcValidationForm> {
  final TextEditingController _depositIdController = TextEditingController();

  @override
  void dispose() {
    _depositIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _depositIdController,
      builder: (_, TextEditingValue value, _) {
        final String? depositIdError = InputValidators.checkHash(value.text);
        final bool isDepositIdValid =
            value.text.isNotEmpty && depositIdError == null;

        return Column(
          spacing: kVerticalGap16.height!,
          children: <Widget>[
            TextField(
              decoration: InputDecoration(
                errorText: value.text.isNotEmpty ? depositIdError : null,
                hintText: context.l10n.depositIdProvidedByCounterparty,
                suffixIcon: FieldSuffixButtons(
                  controller: _depositIdController,
                  onClear: () {
                    context.read<InitialHtlcValidationBloc>().add(
                      const InitialHtlcValidationRefreshed(),
                    );
                  },
                ),
              ),
              controller: _depositIdController,
            ),
            _buildValidationError(),
            InitialHtlcValidationButton(
              depositId: value.text,
              isEnabled: isDepositIdValid,
            ),
          ],
        );
      },
    );
  }

  Widget _buildValidationError() {
    return BlocSelector<
      InitialHtlcValidationBloc,
      InitialHtlcValidationState,
      SyriusException?
    >(
      selector: (InitialHtlcValidationState state) => switch (state) {
        InitialHtlcValidationFailure(:final SyriusException exception) =>
          exception,
        _ => null,
      },
      builder: (_, SyriusException? exception) {
        if (exception == null) {
          return const SizedBox.shrink();
        }

        return Column(
          children: <Widget>[
            Warning(text: exception.toString()),
            kVerticalGap16,
          ],
        );
      },
    );
  }
}
