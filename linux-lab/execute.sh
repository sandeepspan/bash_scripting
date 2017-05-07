#!/bin/bash
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
dt=`date +%Y-%m-%d-%H-%M-%S`
scriptsdir="${dir}/scripts"
configsdir="${dir}/configs"
questionsdir="${dir}/questions"
commondir="${dir}/common"
outlogsdir="${dir}/logs"
errlogsdir="${dir}/errors"
tempdir="/tmp"
logfile="${dir}/logs/execution_${dt}.log"
runtimecfg="/tmp/exconfig"

rm -f ${outlogsdir}/* ${errlogsdir}/*
> ${runtimecfg}
> ${logfile}

. ${commondir}/common_functions

function evaluate_remote ()
{ 
  . ${1} 
 for scriptname in $(echo ${scripts})
 do
  echo -n "||   INFO   || Evaluating configuration for ${name} with ${ip} ."
  echo -n "."; rputfile "${sdir}/${scriptname}" "root@${ip}" "${tempdir}" 1>> ${logfile} 2>&1 
  echo -n "."; rputfile "${cfile}" "root@${ip}" "${tempdir}" 1>> ${logfile} 2>&1
  echo -n "."; rputfile "${runtimecfg}" "root@${ip}" "${tempdir}" 1>> ${logfile} 2>&1
  echo -n "."; rcmd "root@${ip}" "bash ${tdir}/${scriptname}" 1> ${tdir}/${scriptname}.log 2> ${tdir}/${scriptname}.err |tee -a  ${logfile} 
  echo -n "."; lgetfile "${tdir}/${scriptname}.log" "${dir}/logs/" 1>> ${logfile} 2>&1
  echo -n "."; lgetfile "${tdir}/${scriptname}.err" "${dir}/errors/" 1>> ${logfile} 2>&1
  echo -n "."; rrmfile "root@${ip}" "${tdir}/${scriptname}" 1>> ${logfile} 2>&1
  echo -n "."; rrmfile "root@${ip}" "${tdir}/$(echo ${cfile}|cut -d '/' -f 2)" 1>> ${logfile} 2>&1
  echo -n "."; rrmfile "root@${ip}" "${runtimecfg}" 1>> ${logfile} 2>&1
  echo -n "."; lrmfile "root@${ip}" "${tdir}/${scriptname}.log" 1>> ${logfile} 2>&1
  echo -n "."; lrmfile "root@${ip}" "${tdir}/${scriptname}.err" 1>> ${logfile} 2>&1
  echo " done !!"
  cat ${dir}/logs/${scriptname}.log
 done 
}

function evaluate_local ()
{
  . ${1}
 for scriptname in $(echo ${scripts})
 do 
  echo -n "||   INFO   || Evaluating configuration for ${name} with ${ip} ."
  echo -n "."; lputfile "${sdir}/${scriptname}" "${tempdir}" 1>> ${logfile} 2>&1
  echo -n "."; lputfile "${cfile}" "${tempdir}" 1>> ${logfile} 2>&1
  echo -n "."; lcmd "bash ${tdir}/${scriptname}" 1> ${tdir}/${scriptname}.log 2> ${tdir}/${scriptname}.err |tee -a ${logfile} 
  echo -n "."; lgetfile "${tdir}/${scriptname}.log" "${dir}/logs/" 1>> ${logfile} 2>&1
  echo -n "."; lgetfile "${tdir}/${scriptname}.err" "${dir}/errors/" 1>> ${logfile} 2>&1
  echo -n "."; lrmfile "${tdir}/${scriptname}" 1> ${tdir}/${scriptname}.log 1>> ${logfile} 2>&1
  echo -n "."; lrmfile "${tdir}/$(echo ${cfile}|cut -d '/' -f 2)" 1>> ${logfile} 2>&1
  echo -n "."; lrmfile "${tdir}/${scriptname}.log" 1>> ${logfile} 2>&1
  echo -n "."; lrmfile "${tdir}/${scriptname}.err" 1>> ${logfile} 2>&1
  echo " done !!"
  cat ${dir}/logs/${scriptname}.log
 done 
}


for filename in $( ls ${questionsdir} )
do
 clientip=${1}
 serverip=${2}
 . ${questionsdir}/${filename}
 echo ""
 echo "|| QUESTION || ${question}"
 ptr="$(echo ${filename}|awk -F '-' '{print $1}')"
 curconfig="$(cd ${configsdir} ; ls  ${ptr}* ; cd ..)"
 . ${configsdir}/${curconfig}
 if [ "${TARGET}" ==  "CLIENT" ] 
 then
  ips="${clientip}"
  curlocalscript="$(cd ${scriptsdir} ; ls  ${ptr}*_lc ; cd ..)"
  curremotescript="$(cd ${scriptsdir} ; ls  ${ptr}*_rc ; cd ..)"
 elif [ "${TARGET}" ==  "SERVER" ] 
 then 
  ips="${serverip}"
  curlocalscript="$(cd ${scriptsdir} ; ls  ${ptr}*_ls ; cd ..)"
  curremotescript="$(cd ${scriptsdir} ; ls  ${ptr}*_rs ; cd ..)"
 elif [ "${TARGET}" ==  "CLIENT+SERVER" ] 
 then
  ips="$( echo ${clientip}' '${serverip} )"
  curlocalscript="$(cd ${scriptsdir} ; ls  ${ptr}*_l ; cd ..)"
  curremotescript="$(cd ${scriptsdir} ; ls  ${ptr}*_r ; cd ..)"
 fi
 for currentip in $( echo ${ips} )
 do
  echo "sdir=${scriptsdir}" >> ${runtimecfg}
  echo "tdir=${tempdir}" >> ${runtimecfg}
  echo "ip=${currentip}" >> ${runtimecfg}
  echo "name=HOST" >> ${runtimecfg}
  echo "cfile=${configsdir}/${curconfig}" >> ${runtimecfg}
  if [ "${LOCALCHECK}" == "true" ]
  then
   echo "scripts=${curlocalscript}" >> ${runtimecfg}
   evaluate_local "${runtimecfg}"
  fi
  if [ "${REMOTECHECK}" == "true" ]
  then
   echo "scripts=${curremotescript}" >> ${runtimecfg}
   evaluate_remote "${runtimecfg}"
  fi
 done
 rm -f /tmp/exconfig
done


function main ()
{
 echo -n "Enter Exam Paper Type (LEVEL0/LEVEL1) : "
 read exam
 case "${exam}" in 
  'LEVEL0') 
   echo -n "Enter Server IP address : "
   read server
   echo "You entered ${server}"
   evaluate ${server} "SERVER"
  ;;
  'LEVEL1') 
   echo -n "Enter Server IP address : "
   read server
   echo "You entered ${server}"
   echo -n "Enter Client IP address : "
   read client
   echo "You entered ${client}"
   evaluate ${server} "SERVER"
   evaluate ${client} "CLIENT"
  ;;
  *) 
   echo "$(date).... Invlid Input." 
  ;;
 esac 
}

#main "$@" 
#evaluate "${1}" "SERVER"



