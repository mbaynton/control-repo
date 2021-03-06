#!/bin/sh

ENVIRONMENTPATH=$1
# $ENVIRONMENTPATH may contain multiple colon-delimited locations.
# We need to pick the first one that contains $ENVIRONMENT.
IFS=":"
for CANDIDATEPATH in ${ENVIRONMENTPATH}; do
  if [ -d "${CANDIDATEPATH}/${2}" ]; then
    ENVIRONMENTPATH=$CANDIDATEPATH
    break
  fi
done

# Usage
if [ $# -ne 2 -o ! -d "${ENVIRONMENTPATH}" -o ! -d "${ENVIRONMENTPATH}/$2" ]; then
  echo "usage: $0 <environmentpath> <environment>" >&2
  exit 1
fi

# For portability, identify a preferred ruby executable to use
ruby() {
  [ -x /opt/puppetlabs/puppet/bin/ruby ] \
    && /opt/puppetlabs/puppet/bin/ruby "$@" \
    || /usr/bin/env ruby "$@"
}

# Determine how best to calculate a config_version
if [ -e ${ENVIRONMENTPATH}/$2/.r10k-deploy.json ]; then
  # The environment was deployed using r10k. We will calculate the config
  # version using the r10k data.
  ruby ${ENVIRONMENTPATH}/$2/scripts/config_version-r10k.rb $1 $2

elif [ -e /opt/puppetlabs/server/pe_version ]; then
  # This is a Puppet Enterprise system and we can rely on the rugged ruby gem
  # being available.
  ruby ${ENVIRONMENTPATH}/$2/scripts/config_version-rugged.rb $1 $2

elif type git >/dev/null; then
  # The git command is available.
  git --git-dir ${ENVIRONMENTPATH}/$2/.git rev-parse HEAD

else
  # Nothing else available; just use the date.
  date +%s

fi
