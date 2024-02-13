import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:dcdg/src/class_element_collector.dart';
import 'package:path/path.dart' as path;

/// Fetch and return the desired class elements from the package
/// rooted at the given path.
Future<Iterable<ClassElement>> findClassElements({
  required String packagePath,
  required bool exportedOnly,
  required String searchPath,
}) async {
  String makePackageSubPath(String part0, [String part1 = '']) =>
      path.normalize(
        path.absolute(
          path.join(
            packagePath,
            part0,
            part1,
          ),
        ),
      );

  final contextCollection = AnalysisContextCollection(
    includedPaths: [
      makePackageSubPath('lib'),
      makePackageSubPath('lib', 'src'),
      makePackageSubPath('bin'),
      makePackageSubPath('web'),
    ],
    resourceProvider: PhysicalResourceProvider.INSTANCE,
  );

  final collector = ClassElementCollector(
    exportedOnly: exportedOnly,
  );
  for (final context in contextCollection.contexts) {
    for (final filePath in context.contextRoot.analyzedFiles()) {
      if (!filePath.endsWith('.dart') ||
          (exportedOnly && filePath.contains('lib/src/'))) {
        continue;
      }

      final unitResult = await context.currentSession.getResolvedUnit(filePath);

      if (unitResult is ResolvedUnitResult) {
        // Skip parts files to avoid duplication.
        if (!unitResult.isPart) {
          unitResult.libraryElement.accept(collector);
        }
      }
    }
  }

  return collector.classElements;
}
