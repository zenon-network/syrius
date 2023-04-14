GIT_BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)
GIT_COMMIT_HASH=$(git rev-parse HEAD)
GIT_COMMIT_MESSAGE=$(git log -1 --pretty=%s)
GIT_COMMIT_DATE=$(git --no-pager log -1 --format="%ai")
GIT_ORIGIN_URL=$(git config --get remote.origin.url)
GIT_COMMIT_FILE="../lib/utils/metadata.dart"

escape () {
    local retval=${1//\\/\\\\}
    retval=${retval//\$/\\\$}
    echo $retval
}

echo "const String gitBranchName = '''$( escape "$GIT_BRANCH_NAME" )''';" >> $GIT_COMMIT_FILE
echo "const String gitCommitHash = '''$GIT_COMMIT_HASH''';" >> $GIT_COMMIT_FILE
echo "const String gitCommitMessage = '''$( escape "$GIT_COMMIT_MESSAGE" )''';" >> $GIT_COMMIT_FILE
echo "const String gitCommitDate = '''$GIT_COMMIT_DATE''';" >> $GIT_COMMIT_FILE
echo "const String gitOriginUrl = '''$( escape "$GIT_ORIGIN_URL" )''';" >> $GIT_COMMIT_FILE