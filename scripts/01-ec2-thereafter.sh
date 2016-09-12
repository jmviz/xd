#!/bin/bash

WORKDIR=/tmp

if [ -z "$HOME" ] ; then
    HOME=/root
fi

# This script is passed as userdata to the launch-config, which the base AMI
# executes at the end of initialization.

export LC_ALL="en_US.UTF-8"
export LOGFILE=/tmp/`date +"%Y-%m-%d"`.log
export SUMLOGFILE=/tmp/`date +"%Y-%m-%d"`summary.log
# To run xdfile based scripts below
export PYTHONPATH=.

exec > >(tee -i ${LOGFILE}) 2>&1
echo 'SUMMARY: Start time:'`date +'%Y-%m-%d %H:%M'`

# Re-get config file from AWS
aws s3 cp --region=us-west-2 s3://xd-private/etc/config $WORKDIR/config
source $WORKDIR/config

cd $HOME/xd
git pull
git checkout ${BRANCH}

source scripts/helpers.sh

mkdir -p $SSHHOME/.ssh
aws s3 cp --region=$REGION s3://xd-private/etc/gxd_rsa $SSHHOME/.ssh/
chmod 600 $SSHHOME/.ssh/gxd_rsa

echo "Run deploy script"
/bin/bash scripts/05-full-pipeline.sh

echo 'SUMMARY: End time '`date +'%Y-%m-%d %H:%M'`
# Parse log to get summary to be mailed
egrep -i 'ERROR|WARNING|SUMMARY' ${LOGFILE} > ${SUMLOGFILE}
echo -e '\n' >> ${SUMLOGFILE}

echo "Getting summary"
scripts/48-stats.sh >> ${SUMLOGFILE}
echo -e '\n' >> ${SUMLOGFILE}

echo "SUMMARY: Full log file http://$DOMAIN/logs/`basename ${LOGFILE}`" >> ${SUMLOGFILE}

echo "Sending email"
scripts/send-email.py $ADMIN_EMAIL "execution logs for $TODAY" ${SUMLOGFILE}

echo "Copy logs to AWS"
aws s3 cp --region ${REGION} --content-type='text/plain' ${LOGFILE} s3://${DOMAIN}/logs/ --acl public-read
aws s3 cp --region ${REGION} --content-type='text/plain' ${SUMLOGFILE} s3://${DOMAIN}/logs/ --acl public-read

echo "Make logs index page"
scripts/49b-mkindex.sh