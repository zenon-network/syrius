/// Git branch name injected at build time via `SYRIUS_GIT_BRANCH_NAME`.
const String gitBranchName = String.fromEnvironment('SYRIUS_GIT_BRANCH_NAME');

/// Git commit hash injected at build time via `SYRIUS_GIT_COMMIT_HASH`.
const String gitCommitHash = String.fromEnvironment('SYRIUS_GIT_COMMIT_HASH');

/// Git commit message injected at build time via `SYRIUS_GIT_COMMIT_MESSAGE`.
const String gitCommitMessage = String.fromEnvironment(
  'SYRIUS_GIT_COMMIT_MESSAGE',
);

/// Git commit date injected at build time via `SYRIUS_GIT_COMMIT_DATE`.
const String gitCommitDate = String.fromEnvironment('SYRIUS_GIT_COMMIT_DATE');

/// Git origin URL injected at build time via `SYRIUS_GIT_ORIGIN_URL`.
const String gitOriginUrl = String.fromEnvironment('SYRIUS_GIT_ORIGIN_URL');
