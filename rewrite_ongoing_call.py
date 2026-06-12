import re

with open('lib/features/calls/ongoing_call_screen.dart', 'r') as f:
    content = f.read()

# Replace imports
content = content.replace("import 'package:pip_view/pip_view.dart';", "import 'package:simple_pip_mode/simple_pip.dart';\nimport 'package:simple_pip_mode/pip_widget.dart';")
content = content.replace("import '../chat/home_screen.dart';", "")

# Replace class signature
class_decl = """class OngoingCallScreen extends ConsumerStatefulWidget {
  const OngoingCallScreen({super.key});

  @override
  ConsumerState<OngoingCallScreen> createState() => _OngoingCallScreenState();
}

class _OngoingCallScreenState extends ConsumerState<OngoingCallScreen> with WidgetsBindingObserver {
  final SimplePip _pip = SimplePip();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // For Android 12+ auto enter
    _pip.setAutoPipMode();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.hidden) {
      _pip.enterPipMode();
    }
  }

  @override
  Widget build(BuildContext context) {"""

content = re.sub(r'class OngoingCallScreen extends ConsumerWidget \{[\s\S]*?Widget build\(BuildContext context, WidgetRef ref\) \{', class_decl, content)

# Replace PIPView with PipWidget
pip_view_start = """    return PIPView(
      builder: (context, isFloating) {"""
      
pip_widget_start = """    return PipWidget(
      pipChild: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: ref.watch(callNotifierProvider).isVideo 
            ? _buildVideoCallStream(ref.watch(callNotifierProvider), ref.watch(callNotifierProvider.notifier))
            : Icon(Icons.call, color: Colors.green, size: 50),
        ),
      ),
      child: Builder(
        builder: (context) {"""

content = content.replace(pip_view_start, pip_widget_start)

# Remove `if (!isFloating) ...[`
content = content.replace("                if (!isFloating) ...[", "")

# Fix PiP button action
content = content.replace("PIPView.of(context)!.presentBelow(const HomeScreen());", "_pip.enterPipMode();")

# The end of the file has `        ];` and `}, );` from PIPView.
# We will just replace it correctly. We can run flutter format later to check syntax.
# Actually, the python script will just do simple text replacement.

content = content.replace("              ],\n            ),\n          ),\n        );\n      },\n    );", "              ],\n            ),\n          ),\n        );\n      },\n    );")

with open('lib/features/calls/ongoing_call_screen.dart', 'w') as f:
    f.write(content)
print("Done")
