$GIT_BRANCH_NAME = Escape(git rev-parse --abbrev-ref HEAD);
$GIT_COMMIT_HASH = git rev-parse HEAD
$GIT_COMMIT_MESSAGE = Escape(git log -1 --pretty=%s);
$GIT_COMMIT_DATE = git --no-pager log -1 --format="%ai"
$GIT_ORIGIN_URL = Escape(git config --get remote.origin.url);
$GIT_COMMIT_FILE = "${PSScriptRoot}\..\lib\utils\metadata.dart"

Clear-Content $GIT_COMMIT_FILE -Force

Add-Content $GIT_COMMIT_FILE "const String gitBranchName = '''$GIT_BRANCH_NAME''';"
Add-Content $GIT_COMMIT_FILE "const String gitCommitHash = '''$GIT_COMMIT_HASH''';"
Add-Content $GIT_COMMIT_FILE "const String gitCommitMessage = '''$GIT_COMMIT_MESSAGE''';"
Add-Content $GIT_COMMIT_FILE "const String gitCommitDate = '''$GIT_COMMIT_DATE''';"
Add-Content $GIT_COMMIT_FILE "const String gitOriginUrl = '''$GIT_ORIGIN_URL''';"

Function Escape($String) {
    $String = $String.Replace('\', '\\');
    $String = $String.Replace('$', '\$');
    Return $String
}