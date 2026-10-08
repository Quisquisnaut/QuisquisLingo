import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';

CourseAuditResult _result(List<AuditSeverity> severities) => CourseAuditResult([
  for (final (index, severity) in severities.indexed)
    CourseAuditIssue(
      severity: severity,
      location: 'Exercise $index',
      message: 'finding $index',
    ),
]);

void main() {
  group('export audit notice', () {
    test('a clean Course adds nothing to the export confirmation', () {
      expect(_result(const []).exportNotice, isNull);
      expect(_result(const [AuditSeverity.info]).exportNotice, isNull);
    });

    test('Errors say the file will be refused on import', () {
      // Import blocks on any Audit Error, but export does not gate, so this
      // sentence is the only warning an author gets that the file they just
      // wrote cannot be read back.
      final notice = _result(const [AuditSeverity.error]).exportNotice;
      expect(notice, contains('1 error'));
      expect(notice, contains('refused'));
    });

    test('Warnings say the file still imports', () {
      final notice = _result(const [
        AuditSeverity.warning,
        AuditSeverity.warning,
      ]).exportNotice;
      expect(notice, contains('2 warnings'));
      expect(notice, contains('imports'));
      expect(notice, isNot(contains('refused')));
    });

    test('Errors outrank warnings in the same Course', () {
      final notice = _result(const [
        AuditSeverity.warning,
        AuditSeverity.error,
        AuditSeverity.info,
      ]).exportNotice;
      expect(notice, contains('1 error'));
      expect(notice, isNot(contains('warning')));
    });

    test('singular and plural wording both read correctly', () {
      expect(
        _result(const [AuditSeverity.error]).exportNotice,
        contains('1 error:'),
      );
      expect(
        _result(const [AuditSeverity.error, AuditSeverity.error]).exportNotice,
        contains('2 errors:'),
      );
      expect(
        _result(const [AuditSeverity.warning]).exportNotice,
        contains('1 warning:'),
      );
    });
  });
}
