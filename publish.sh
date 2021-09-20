#! /bin/bash
#
# Author: Bert Van Vreckem <bert.vanvreckem@gmail.com>
#
# 

set -o errexit # abort on nonzero exitstatus
set -o nounset # abort on unbound variable

#{{{ Variables
# Debug info ('on' to enable)
readonly debug='off'

# Default Git commit message
commit_msg="Publishing to gh-pages at $(date --utc --iso-8601=seconds)"

# Output directory for the generated webpage
output_dir=public
#}}}

#{{{ Functions

usage() {
cat << _EOF_
Usage: ${0} [COMMIT_MSG]
       ${0} -h|--help

OPTIONS:
  -h, --help   Show this help message and exit

COMMIT_MSG is a custom Git commit message. If not specified, a default message
with a timestamp will be used.
_EOF_
}

# Usage: log [ARG]...
#
# Prints all arguments on the standard output stream
log() {
  printf '\e[0;33m>>> %s\e[0m\n' "${*}"
}

# Usage: debug [ARG]...
#
# Prints all arguments on the standard output stream,
# if debug output is enabled
debug() {
  [ "${debug}" != 'on' ] || printf '\e[0;36m### %s\e[0m\n' "${*}"
}

# Usage: error [ARG]...
#
# Prints all arguments on the standard error stream
error() {
  printf '\e[0;31m!!! %s\e[0m\n' "${*}" 1>&2
}

#}}}
#{{{ Command line parsing

case $* in
  -h|--help)
    usage
    exit
    ;;
  ?*)
    commit_msg="$*"
    ;;
esac

#}}}

#{{{ Check preconditions

log "Checking preconditions"

# Ensure ‘hugo server’ is not running
# Find and count processes with "hugo server".
num_processes=$(pgrep --full "hugo server" | wc --lines)

if [ "${num_processes}" -gt "0" ]; then
  error "Warning! Hugo server is running. Shut it down first!"
  error "PID: $(pgrep --full "hugo server")"
  exit 1
fi

# Ensure the main branch has no local changes
if [ "$(git status -s)" ]; then
  error 'Changes detected in working directory. Commit them before proceeding.'
  exit 1
fi

#}}}

log "Generating the site"
hugo --destination "${output_dir}"

log "Deleting old publication"
rm -rf "${output_dir}"
mkdir "${output_dir}"
git worktree prune
rm -rf ".git/worktrees/${output_dir}"

log 'Fetching gh-pages branch'
git fetch origin gh-pages

log 'Checking out gh-pages branch'
git worktree add -B gh-pages "${output_dir}" origin/gh-pages

log "Committing updated site with message: ${commit_msg}"
pushd "${output_dir}" > /dev/null
git add --all
git commit --message "${commit_msg}"
git push "${REPOSITORY:-origin}" gh-pages
popd > /dev/null
