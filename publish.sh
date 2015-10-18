#! /usr/bin/bash
#
# Author: Bert Van Vreckem <bert.vanvreckem@gmail.com>
#
# 

set -o errexit # abort on nonzero exitstatus
set -o nounset # abort on unbound variable

#{{{ Functions

usage() {
cat << _EOF_
Usage: ${0} TITLE
  where TITLE is the title of the article to publish

_EOF_
}

#}}}
#{{{ Command line parsing

if [ "$#" -eq "0" ]; then
    echo "Expected an argument, got $#" >&2
    usage
    exit 2
fi

#}}}
#{{{ Variables
site_content=public
git_remote=git@github.com:bertvv/notes-to-self.git
website_branch=gh-pages
#}}}

# Script proper

# Ensure ‘hugo server’ is not running
# Find and count processes with "hugo server". There should
# be only one (the grep process itself)
num_processes=$(ps -ef | grep "hugo server" | wc --lines)

if [ "${num_processes}" -ne "1" ]; then
  echo "Warning! Hugo server is running. Shut it down first!" >&2
  exit 2
fi

# Generate the site
hugo

# Add everything to Git
git add .
git commit --message "$*"

# Push to Github
git push
git subtree push --prefix="${site_content}" "${git_remote}" "${website_branch}"


