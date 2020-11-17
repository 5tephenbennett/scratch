#!/bin/sh
GERRIT_URL=default.com
GERRIT_PORT=29418
GERRIT_USER=default_user
DO_HELP=0
DO_EXIT=0
DRY_RUN=0
DO_PROMPT=0

print_help()
{
cat << EOL
Usage: $0  [OPTION]... -- <git-import-url> <additional gerrit create-project options>
Import a git project to the $GERRIT_URL Gerrit server

note: the git-import-url MUST be specified before any create-project options

Options:
     --dry-run               show commands that will be run
     --prompt                prompt for user confirmation before running
  -g,--gerrit-url            set the gerrit url (default: ${GERRIT_URL})
  -p,--project               set the gerrit project (will default to same path as git repo)
  -t,--port                  set the gerrit port (default: ${GERRIT_PORT})
  -u,--user                  set the gerrit user to do the import (default: ${GERRIT_USER})
     --help                  display this help and exit
     
Links:
  create-project options     https://gerrit-review.googlesource.com/Documentation/cmd-create-project.html

Inspired by:
  Erik Sjölund: https://stackoverflow.com/a/26161391
EOL
}

cmd()
{
    [ ${DRY_RUN} -ne 0 ] && echo "$*" || $*
}

options=$(getopt -l "dry-run,prompt,gerrit-url:,project:,port:,user:,help," -o "g:p:t:u:" -a -- "$@")
eval set -- "$options"
while true; do
    case $1 in
    h|--help)
        DO_HELP=1; DO_EXIT=1;
        ;;

    --dry-run)
        DRY_RUN=1;
        ;;

    --prompt)
        DO_PROMPT=1;
        ;;

    -g|--url)
        GERRIT_URL=$2; shift
        ;;

    -p|--project)
        GERRIT_PROJECT=$2; shift
        ;;

    -t|--port)
        GERRIT_PORT=$2; shift
        ;;

    -u|--user)
        GERRIT_USER=$2; shift
        ;;

    --)
        shift
        break;;
    esac
    shift
done

if [ ${DO_HELP} -eq 0 ] && [ $# -lt 1 ]; then
   echo "ERROR: no git-import-url specified"
   DO_HELP=1; DO_EXIT=1;
fi
GIT_IMPORT_URL=$1
shift
CREATE_PROJECT_OPTIONS=$*

if [ -z ${GERRIT_PROJECT} ]; then
    GERRIT_PROJECT="$(echo ${GIT_IMPORT_URL} | sed -e's,^.*://\(.*\),\1,g' | cut -d/ -f2- | sed -e's,^\(.*\)\.git$,\1,g')"
fi

[ ${DO_HELP} -ne 0 ] && print_help
[ ${DO_EXIT} -ne 0 ] && exit 0

echo "config:"
printf "  Gerrit URL:          %-32s%-20s\n" "${GERRIT_URL}" "(port: ${GERRIT_PORT} user: ${GERRIT_USER})"
printf "  Import repo:         %s\n" "${GIT_IMPORT_URL}"
printf "  Destination project: %-32s%-20s\n" "${GERRIT_PROJECT}" "(options: ${CREATE_PROJECT_OPTIONS})"
echo

if [ ${DO_PROMPT} -ne 0 ]; then
  echo "Is the configuration correct (y/N)?"
  read REPLY
  [ "${REPLY}" != "y" ] && exit 0
fi
set -e
TMP_DIR=`mktemp -d`
cmd ssh -p ${GERRIT_PORT} ${GERRIT_USER}@${GERRIT_URL} gerrit create-project ${GERRIT_PROJECT} ${CREATE_PROJECT_OPTIONS}
cmd cd $TMP_DIR
cmd git clone --mirror ${GIT_IMPORT_URL} tmp_git_folder
cmd cd tmp_git_folder
cmd git remote add gerrit ssh://${GERRIT_USER}@${GERRIT_URL}:${GERRIT_PORT}/${GERRIT_PROJECT}
cmd git push gerrit refs/*:refs/*
