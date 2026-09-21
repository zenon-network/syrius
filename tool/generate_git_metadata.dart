import 'dart:convert';
import 'dart:io';

const String _outputFileName = 'git_metadata.json';

Future<void> main() async {
  final String repositoryRoot = await _runGit(
    <String>['rev-parse', '--show-toplevel'],
  );
  final String commitHash = await _runGit(
    <String>['rev-parse', 'HEAD'],
    workingDirectory: repositoryRoot,
  );
  final String branchName =
      _nonEmpty(Platform.environment['GITHUB_HEAD_REF']) ??
      _nonEmpty(Platform.environment['GITHUB_REF_NAME']) ??
      await _gitReference(repositoryRoot);
  final String commitMessage = await _runGit(
    <String>['show', '-s', '--format=%s', commitHash],
    workingDirectory: repositoryRoot,
  );
  final String commitDate = await _runGit(
    <String>['show', '-s', '--format=%as', commitHash],
    workingDirectory: repositoryRoot,
  );
  final String originUrl = await _gitOriginUrl(repositoryRoot);

  final Map<String, String> metadata = <String, String>{
    'SYRIUS_GIT_BRANCH_NAME': branchName,
    'SYRIUS_GIT_COMMIT_HASH': commitHash,
    'SYRIUS_GIT_COMMIT_MESSAGE': commitMessage,
    'SYRIUS_GIT_COMMIT_DATE': commitDate,
    'SYRIUS_GIT_ORIGIN_URL': originUrl,
  };

  final Directory outputDirectory = Directory(
    '$repositoryRoot${Platform.pathSeparator}.dart_tool',
  );
  await outputDirectory.create(recursive: true);

  final File outputFile = File(
    '${outputDirectory.path}${Platform.pathSeparator}$_outputFileName',
  );
  const JsonEncoder encoder = JsonEncoder.withIndent('  ');
  await outputFile.writeAsString('${encoder.convert(metadata)}\n');

  stdout.writeln('Generated Git metadata at ${outputFile.path}');
}

Future<String> _gitReference(String workingDirectory) async {
  final String? branchName = await _tryRunGit(
    <String>['symbolic-ref', '--short', 'HEAD'],
    workingDirectory: workingDirectory,
  );
  if (branchName != null) {
    return branchName;
  }

  return await _tryRunGit(
        <String>['describe', '--tags', '--exact-match', 'HEAD'],
        workingDirectory: workingDirectory,
      ) ??
      'HEAD';
}

Future<String> _gitOriginUrl(String workingDirectory) async {
  final String? serverUrl = _nonEmpty(
    Platform.environment['GITHUB_SERVER_URL'],
  );
  final String? repository = _nonEmpty(
    Platform.environment['GITHUB_REPOSITORY'],
  );
  if (serverUrl != null && repository != null) {
    return '$serverUrl/$repository';
  }

  return _runGit(
    <String>['config', '--get', 'remote.origin.url'],
    workingDirectory: workingDirectory,
  );
}

String? _nonEmpty(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  return value;
}

Future<String> _runGit(
  List<String> arguments, {
  String? workingDirectory,
}) async {
  final ProcessResult result = await Process.run(
    'git',
    arguments,
    workingDirectory: workingDirectory,
  );
  if (result.exitCode != 0) {
    final String error = (result.stderr as String).trim();
    throw StateError('git ${arguments.join(' ')} failed: $error');
  }
  return (result.stdout as String).trim();
}

Future<String?> _tryRunGit(
  List<String> arguments, {
  required String workingDirectory,
}) async {
  final ProcessResult result = await Process.run(
    'git',
    arguments,
    workingDirectory: workingDirectory,
  );
  if (result.exitCode != 0) {
    return null;
  }
  return _nonEmpty((result.stdout as String).trim());
}
