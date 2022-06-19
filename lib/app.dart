// ignore_for_file: todo

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:widgetbook_challenge/api/widgetbook_api.dart';

const _kAnimDuration = Duration(milliseconds: 250);
const _kRequestTimeout = Duration(milliseconds: 1020);
final _kNameRegex = RegExp(r'\p{Letter}', unicode: true);

/// The app.
class App extends StatelessWidget {
  /// Creates a new instance of [App].
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: kDebugMode,
      darkTheme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(title: const Text('Interview Challenge')),
        body: const _ScaffoldBody(),
      ),
    );
  }
}

class _ScaffoldBody extends HookWidget {
  const _ScaffoldBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formFieldKey = useMemoized(GlobalKey<FormFieldState>.new, []);
    final formFieldController = useTextEditingController();
    final formFieldFocusNode = useFocusNode();
    final request = useState(Future.value(''));
    final requestFuture = useFuture(
      request.value,
      preserveState: false,
    );
    final sendFormCallback = useCallback(
      () {
        formFieldFocusNode.requestFocus();
        final form = formFieldKey.currentState?.validate();
        if (form == null ||
            !form ||
            requestFuture.connectionState == ConnectionState.waiting) {
          return;
        }
        request.value = WidgetbookApi()
            .welcomeToWidgetbook(message: formFieldController.text)
            .timeout(_kRequestTimeout);
      },
      [formFieldController.text, requestFuture],
    );

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 72,
            child: TextFormField(
              controller: formFieldController,
              key: formFieldKey,
              focusNode: formFieldFocusNode,
              autofocus: true,
              inputFormatters: [
                FilteringTextInputFormatter.allow(_kNameRegex),
                LengthLimitingTextInputFormatter(32),
              ],
              onFieldSubmitted: (val) => sendFormCallback.call(),
              validator: (value) {
                if (value == null) {
                  return 'Unknown error.';
                } else if (value.isEmpty) {
                  return 'Please enter a name.';
                } else if (value.length < 4) {
                  return 'Please enter at least 4 characters.';
                }
                return null;
              },
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Name',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20, top: 10),
            child: ElevatedButton(
              onPressed: requestFuture.connectionState != ConnectionState.done
                  ? null
                  : sendFormCallback,
              child: const Text('Submit'),
            ),
          ),
          AnimatedSwitcher(
            duration: _kAnimDuration,
            child: (requestFuture.hasData &&
                    !requestFuture.hasError &&
                    requestFuture.data!.isNotEmpty)
                ? Text(
                    requestFuture.data!,
                    style: const TextStyle(color: Colors.green),
                  )
                : requestFuture.hasError
                    ? Text(
                        requestFuture.error.toString().isEmpty
                            ? 'Error'
                            : requestFuture.error.toString(),
                        key: const ValueKey('errorResultKey'),
                        style: const TextStyle(color: Colors.red),
                      )
                    : (requestFuture.connectionState == ConnectionState.waiting)
                        ? const LinearProgressIndicator(minHeight: 19)
                        : const Text(''),
          ),
        ],
      ),
    );
  }
}
