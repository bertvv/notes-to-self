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

# Push source (branch master) to Git
git add .
git commit --message "$*"
git push

# Push  generated website (branch gh-pages) to Git
pushd public > /dev/null
git add .
git commit --message "$*"
git push
popd > /dev/null

