#!/bin/bash

#set -x

TMPDIR="tmp"

if ! [[ -d $TMPDIR ]]; then
	mkdir -p $TMPDIR
fi

function die {
	red_text $1
	exit
}

function dialog {
	TITLE=$1
	MSG=$2
	whiptail --title "$TITLE" --msgbox "$msg" 8 78
}


function red_text {
	echo -e "\e[101m$1\e[0m"
}

function convert_to_text {
	for FILENAME in $@; do
		set -x
		pdftotext -layout -nopgbrk -enc UTF-8 $FILENAME - > $FILENAME.txt

		cat $FILENAME.txt | uconv -f utf8 -t utf8 -x Any-NFKC > ${FILENAME}_corrected.txt
		mv "$FILENAME.txt" $TMPDIR
		mv "${FILENAME}_corrected.txt" "$FILENAME.txt"
		set +x
	done
}

function install_if_not_exists {
	PROGNAME=$1
	INSTALL=$2

	if [[ -z $INSTALL ]]; then
		INSTALL=$PROGNAME
	fi

	if ! which $PROGNAME >/dev/null; then
		red_text "$1 not found, installing it. Please enter your password for sudo."
		sudo apt-get install $INSTALL
	fi
}

function main {
	FILES=()

	FILES=$(perl -le '
	$str = "";
while (my $filename = <*.pdf>) {
	$on = "ON";
	if(-e "$filename.txt") {
		$on = "OFF";
	}
	$str .= qq#"$filename" "$filename" $on #;
}
print $str
')

	STR='whiptail --title "Dateien zum Konvertieren" --checklist "Welche Dateien sollen konvertiert werden?" 20 78 4 '
	STR+="$FILES"

	FILESTOCONVERT=$(eval $STR 3>&1 1>&2 2>&3)

	eval "convert_to_text $(echo $FILESTOCONVERT)"

}

install_if_not_exists "whiptail"
install_if_not_exists "pdftotext" "poppler-utils"

main
