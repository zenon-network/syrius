escape () {
    echo $1 | sed "s/'/'\"'\"r'/g"
}

GIT_BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
GIT_COMMIT_HASH=$(git rev-parse HEAD)
GIT_COMMIT_MESSAGE=$(git log -1 --pretty=%s)
GIT_COMMIT_DATE=$(git --no-pager log -1 --format="%as")
GIT_ORIGIN_URL=$(git config --get remote.origin.url)
GIT_COMMIT_FILE="../lib/utils/metadata.dart"

sed --i '1,5d' $GIT_COMMIT_FILE

echo "const String gitBranchName = r'$(escape $GIT_BRANCH_NAME)';" >> $GIT_COMMIT_FILE
echo "const String gitCommitHash = r'$GIT_COMMIT_HASH';" >> $GIT_COMMIT_FILE
echo "const String gitCommitMessage = r'$(escape $GIT_COMMIT_MESSAGE)';" >> $GIT_COMMIT_FILE
echo "const String gitCommitDate = r'$GIT_COMMIT_DATE';" >> $GIT_COMMIT_FILE
echo "const String gitOriginUrl = r'$(escape $GIT_ORIGIN_URL)';" >> $GIT_COMMIT_FILE