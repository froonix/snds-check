#!/usr/bin/env bash
########################################################################
#                                                                      #
#                              SNDS-CHECK                              #
# -------------------------------------------------------------------- #
#                         v1.1.1 (2016-11-18)                          #
#                                                                      #
# Author:  Christian Schrötter <cs@fnx.li>                             #
# License: GNU GENERAL PUBLIC LICENSE (Version 3)                      #
# Website: https://github.com/froonix/snds-check                       #
#                                                                      #
########################################################################
#                                                                      #
# Überprüft den Status des SNDS-Programms von Microsoft.               #
# Die E-Mail Benachrichtigung übernimmt der Cron-Daemon.               #
#                                                                      #
# Hinweis: "Automated Data Access" muss dafür aktiviert sein.          #
#                                                                      #
#   KEYS = Liste von Zugangsschlüsseln                                 #
#                                                                      #
########################################################################

KEYS=""

cd "$(dirname "$(readlink -f "$0")")"
config_file="./snds-check.cfg"
if [[ -f "$config_file" ]]
then . "$config_file"; fi

if [[ "$1" == "dbg" ]]
then dbg=1; else dbg=0; fi

function dataCheck
{
	key="$1"
	if [[ "$dbg" == "1" ]]; then echo "Debug: Fetching data for key $key …" 1>&2; fi
	result=`wget -q -O - "https://postmaster.live.com/snds/data.aspx?key=${key}" | sort`
	status="$?"

	if [[ "$status" == "0" ]]
	then
		while read -r line
		do
			if [[ "$line" != "" ]]
			then
				ipAddress=`cut -d"," -f1 <<< "$line"`
				ipStatus=`cut -d"," -f7 <<< "$line"`

				#dateFrom=`cut -d"," -f2 <<< "$line"`
				#dateTo=`cut -d"," -f3 <<< "$line"`
				#mailHost=`cut -d"," -f12 <<< "$line"`
				#mailAddress=`cut -d"," -f13 <<< "$line"`

				file=`mktemp`
				dig -x "$ipAddress" +short 1>"$file" 2>/dev/null
				status=$?; rdns=`cat "$file"`; rm "$file"

				if [[ "$rdns" != "$ipAddress" ]]
				then
					#echo "IP $ipAddress ($rdns): Status $ipStatus for $mailAddress at $mailHost."
					echo "IP $ipAddress ($rdns): Status $ipStatus!"
				else
					#echo "IP $ipAddress: Status $ipStatus for $mailAddress at $mailHost."
					echo "IP $ipAddress: Status $ipStatus!"
				fi
			fi
		done <<< "$result"
	else
		echo "[  ERR  ] data/$key ($status)" 1>&2
	fi
}

function ipStatusCheck
{
	key="$1"
	if [[ "$dbg" == "1" ]]; then echo "Debug: Fetching ipStatus for key $key …" 1>&2; fi
	result=`wget -q -O - "https://postmaster.live.com/snds/ipStatus.aspx?key=$key" | sort`
	status="$?"

	if [[ "$status" == "0" ]]
	then
		while read -r line
		do
			if [[ "$line" != "" ]]
			then
				ipStart=`cut -d"," -f1 <<< "$line"`
				ipEnd=`cut -d"," -f2 <<< "$line"`
				#ipBlocked=`cut -d"," -f3 <<< "$line"`
				ipReason=`cut -d"," -f4 <<< "$line"`

				if [[ "$ipStart" == "$ipEnd" ]]
				then
					file=`mktemp`
					dig -x "$ipStart" +short 1>"$file" 2>/dev/null
					status=$?; rdns=`cat "$file"`; rm "$file"

					if [[ "$rdns" != "$ipStart" ]]
					then
						echo "IP $ipStart ($rdns): $ipReason"
					else
						echo "IP $ipStart: $ipReason"
					fi
				else
					echo "IP's $ipStart-$ipEnd: $ipReason"
				fi
			fi
		done <<< "$result"
	else
		echo "[  ERR  ] ipStatus/$key ($status)" 1>&2
	fi
}

for i in $KEYS
do
	dataCheck "$i"
	ipStatusCheck "$i"
done
