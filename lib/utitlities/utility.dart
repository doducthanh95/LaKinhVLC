import 'package:LaKinhVLC/const/const_value.dart';
import 'package:LaKinhVLC/translate/translate.dart';

extension StringExt on String {
  String tr() {
    if (language == 'ch') {
      if (!ch.containsKey(this)) {
        return "";
      }
      return ch[this] ?? '';
    }
    if (!vi.containsKey(this)) {
      return "";
    }
    return vi[this] ?? '';
  }
}
