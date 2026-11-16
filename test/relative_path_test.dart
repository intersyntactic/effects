import 'package:is_effects/is_effects.dart';
import 'package:test/test.dart';

void main() {
  group('RelativePath.folder', () {
    test('a plain file is in its directory', () {
      expect(RelativePath('a/b.txt').folder, RelativePath('a'));
    });

    test('a top-level file is in root', () {
      expect(RelativePath('a.txt').folder, RelativePath.root);
    });

    test("root's folder is root", () {
      expect(RelativePath.root.folder, RelativePath.root);
    });

    test('an escaping path one level up is one level further up again', () {
      expect(RelativePath('..').folder, RelativePath('../..'));
    });

    test('an escaping path already inside a folder walks up correctly', () {
      expect(RelativePath('../a.txt').folder, RelativePath('..'));
      expect(RelativePath('../..').folder, RelativePath('../../..'));
    });
  });
}
