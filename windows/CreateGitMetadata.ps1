Function Escape($String) {
    Return $String.Replace("'", "'`"'`"r'");
}

$GIT_BRANCH_NAME = git rev-parse --abbrev-ref HEAD
$GIT_COMMIT_HASH = git rev-parse HEAD
$GIT_COMMIT_MESSAGE = git log -1 --pretty=%s
$GIT_COMMIT_DATE = git --no-pager log -1 --format="%ai"
$GIT_ORIGIN_URL = git config --get remote.origin.url
$GIT_COMMIT_FILE = "${PSScriptRoot}\..\lib\utils\metadata.dart"

Clear-Content $GIT_COMMIT_FILE -Force

Add-Content $GIT_COMMIT_FILE "const String gitBranchName = r'$(Escape $GIT_BRANCH_NAME)';"
Add-Content $GIT_COMMIT_FILE "const String gitCommitHash = r'$GIT_COMMIT_HASH';"
Add-Content $GIT_COMMIT_FILE "const String gitCommitMessage = r'$(Escape $GIT_COMMIT_MESSAGE)';"
Add-Content $GIT_COMMIT_FILE "const String gitCommitDate = r'$GIT_COMMIT_DATE';"
Add-Content $GIT_COMMIT_FILE "const String gitOriginUrl = r'$(Escape $GIT_ORIGIN_URL)';"