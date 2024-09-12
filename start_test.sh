#!/usr/bin/env bash

#=== FUNCTION ================================================================
#        NAME: logit
# DESCRIPTION: Log into file and screen.
# PARAMETER - 1 : Level (ERROR, INFO)
#           - 2 : Message
#
#===============================================================================
logit()
{
    case "$1" in
        "INFO")
            echo -e " [\e[94m $1 \e[0m] [ $(date '+%d-%m-%y %H:%M:%S') ] $2 \e[0m" ;;
        "WARN")
            echo -e " [\e[93m $1 \e[0m] [ $(date '+%d-%m-%y %H:%M:%S') ]  \e[93m $2 \e[0m " && sleep 2 ;;
        "ERROR")
            echo -e " [\e[91m $1 \e[0m] [ $(date '+%d-%m-%y %H:%M:%S') ]  $2 \e[0m " ;;
    esac
}

#=== FUNCTION ================================================================
#        NAME: usage
# DESCRIPTION: Helper of the function
# PARAMETER - None
#
#===============================================================================
usage()
{
  logit "INFO" "-j <filename.jmx>"
  logit "INFO" "-r flag to enable report generation at the end of the test"
  logit "INFO" "-s flag to set github source"
  logit "INFO" "-re flag to set github repo"
  logit "INFO" "-p flag to github file"
  logit "INFO" "-rv flag to set revision of github"
  exit 1
}

### Parsing the arguments ###
while getopts 'j:s:o:v:p:h:r' option;
    do
      case $option in
        r    )   enable_report=1 ;;
        j    )   jmx=${OPTARG} ;;
        s    )   source=${OPTARG} ;;
        o    )   repo=${OPTARG} ;;
        p    )   path=${OPTARG} ;;
        v    )   revision=${OPTARG} ;;
        h    )   usage ;;
        ?    )   usage ;;
      esac
done

if [ "$#" -eq 0 ]
  then
    usage
fi


if [ -z "${jmx}" ]; then
    #read -rp 'Enter the name of the jmx file ' jmx
    logit "ERROR" "jmx jmeter project not provided!"
    usage
fi

NOW=$(date +"%Y%m%d-%H%M%S")
JMETER_HOME="/opt/jmeter/apache-jmeter"
jmx_dir="${jmx%%.*}"

if [ "$source" == "git" ]; then
  echo "REPO = ${repo}"

  if [ -z "${repo}" ]; then
      logit "ERROR" "git repo not provided!"
      usage
  fi
  if [ -z "${path}" ]; then
      logit "ERROR" "git path not provided!"
      usage
  fi

  if [ -z "${revision}" ]; then
      logit "ERROR" "git revision not provided!"
      usage
  fi

  GITHUB_TOKEN="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"
  GITHUB_API_HEADER_ACCEPT="Accept: application/vnd.github.v3+json"
  curl=$(curl -s  -o  /tmp/${jmx} https://$GITHUB_TOKEN@raw.githubusercontent.com/${repo}/${revision}/${path} 2>/dev/null)
  logit "INFO" "Got new jmeter file - ${curl}"
fi


echo "Installing needed plugins for master"
cd ${JMETER_HOME}/bin
sh PluginsManagerCMD.sh install-for-jmx ${jmx}

## Starting Jmeter load test
source "scenario/${jmx_dir}/.env"

param_host="-Ghost=${host} -Gport=${port} -Gprotocol=${protocol}"
param_user="-Gthreads=${threads} -Gduration=${duration} -Grampup=${rampup}"


if [ -n "${enable_report}" ]; then
    report_command_line="--reportatendofloadtests --reportoutputfolder /report/report-${jmx}-${NOW}"
fi

logit "INFO" "Starting the performance test"
jmeter ${param_host} ${param_user} ${report_command_line} --logfile /report/${jmx}_${NOW}.jtl --nongui --testfile ${jmx} -Dserver.rmi.ssl.disable=true --remoteexit >> jmeter-master.out 2>> jmeter-master.err &
trap 'kill -10 1' EXIT INT TERM
java -jar ${JMETER_HOME}/lib/jolokia-java-agent.jar start JMeter >> jmeter-master.out 2>> jmeter-master.err
wait

trap "sh ${JMETER_HOME}/bin/stoptest.sh" EXIT