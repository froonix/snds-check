#!/bin/bash
###
#
# Überprüft den Status des SNDS-Programms von Microsoft.
# Die E-Mail Benachrichtigung übernimmt der Cron-Daemon.
# Version 1.1.0 vom 13.08.2015 von Christian Schrötter.
#
# TODO: BT-Kategorie & Wikiseite anlegen und im HAPPYTEC-Blog veröffentlichen!
#
# Hinweis: "Automated Data Access" muss dafür aktiviert sein.
#
#   KEYS = Liste von Zugangsschlüsseln
#
###

KEYS=""

if [[ "$1" == "dbg" ]]
then
	dbg=1
else
	dbg=0
fi

# Das ist nur halbherzig implementiert.
# Siehe Beispieldaten von *********...
function dataCheck
{
	key="$1"
	if [[ "${dbg}" == "1" ]]; then echo "Debug: Fetching data for key ${key} …" 1>&2; fi
	result=`wget -q -O - "https://postmaster.live.com/snds/data.aspx?key=${key}" | sort`
	status="$?"

	if [[ "${status}" == "0" ]]
	then
		while read -r line
		do
			if [[ "${line}" != "" ]]
			then
				ipAddress=`cut -d"," -f1 <<< "${line}"`
				#dateFrom=`cut -d"," -f2 <<< "${line}"`
				#dateTo=`cut -d"," -f3 <<< "${line}"`
				##### Da gäbe es noch mehr! #####
				ipStatus=`cut -d"," -f7 <<< "${line}"`
				#mailHost=`cut -d"," -f12 <<< "${line}"`
				#mailAddress=`cut -d"," -f13 <<< "${line}"`

				file=`mktemp` # <-- siehe rbl-check.org Script
				dig -x "${ipAddress}" +short 1>"${file}" 2>/dev/null
				status=$?; rdns=`cat "${file}"`; rm "${file}"

				if [[ "${rdns}" != "${ipAddress}" ]]
				then
					#echo "IP ${ipAddress} (${rdns}): Status ${ipStatus} for ${mailAddress} at ${mailHost}."
					echo "IP ${ipAddress} (${rdns}): Status ${ipStatus}!"
				else
					#echo "IP ${ipAddress}: Status ${ipStatus} for ${mailAddress} at ${mailHost}."
					echo "IP ${ipAddress}: Status ${ipStatus}!"
				fi
			fi
		done <<< "${result}"
	else
		echo "[  ERR  ] data/${key} (${status})" 1>&2
	fi
}

function ipStatusCheck
{
	key="$1"
	if [[ "${dbg}" == "1" ]]; then echo "Debug: Fetching ipStatus for key ${key} …" 1>&2; fi
	result=`wget -q -O - "https://postmaster.live.com/snds/ipStatus.aspx?key=${key}" | sort`
	status="$?"

	if [[ "${status}" == "0" ]]
	then
		while read -r line
		do
			if [[ "${line}" != "" ]]
			then
				ipStart=`cut -d"," -f1 <<< "${line}"`
				ipEnd=`cut -d"," -f2 <<< "${line}"`
				#ipBlocked=`cut -d"," -f3 <<< "${line}"`
				ipReason=`cut -d"," -f4 <<< "${line}"`

				if [[ "${ipStart}" == "${ipEnd}" ]]
				then
#					# They (EDIS) are blocked, we know it, so shut the fuck up please! ;-)
#					if [[ "$ipStart" != "158.255.212.234" && "$ipStart" != "149.154.159.79" ]]
#					then
						file=`mktemp` # <-- siehe rbl-check.org Script
						dig -x "${ipStart}" +short 1>"${file}" 2>/dev/null
						status=$?; rdns=`cat "${file}"`; rm "${file}"

						if [[ "${rdns}" != "${ipStart}" ]]
						then
							echo "IP ${ipStart} (${rdns}): ${ipReason}"
						else
							echo "IP ${ipStart}: ${ipReason}"
						fi
#					fi
				else
					echo "IP's ${ipStart}-${ipEnd}: ${ipReason}"
				fi
			fi
		done <<< "${result}"
	else
		echo "[  ERR  ] ipStatus/${key} (${status})" 1>&2
	fi
}

for i in $KEYS
do
	dataCheck "${i}"
	ipStatusCheck "${i}"
done
