#!/bin/bash

#set -x

TMPDIR="tmp"

if ! [[ -d $TMPDIR ]]; then
	mkdir -p $TMPDIR
fi

function msg {
	MSG=$1
	whiptail --title "Message" --msgbox "$MSG" 8 78
}

function red_text {
	echo -e "\e[101m$1\e[0m"
}

function die {
	red_text $1
	exit
}

function convert_to_text {
	for FILENAME in $@; do
		pdftotext -layout -nopgbrk -enc UTF-8 $FILENAME - > $FILENAME.txt
		FILENAME_WITHOUT_EXTENSION=$(echo "$FILENAME" | sed -e 's/\.pdf$//')

		TMPFILE=${FILENAME}_corrected.txt
		cat $FILENAME.txt | uconv -f utf8 -t utf8 -x Any-NFKC > $TMPFILE
		mv "$FILENAME.txt" $TMPDIR

		mv "$TMPFILE" "$FILENAME_WITHOUT_EXTENSION.txt"
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
		sudo apt-get -y install $INSTALL
	fi
}

function main {
	FILES=()

	FILES=$(perl -le '
	$str = "";
while (my $filename = <*.pdf>) {
	if($filename =~ m#\s#) {
		warn qq#Die Datei "$filename" beinhaltet ein Leerzeichen. Leerzeichen machen Probleme. Daher kann ich sie nicht bearbeiten. Benenne die Datei um.\n#;
	} else {
		$filename_without_extension = $filename;
		$filename_without_extension =~ s#\.pdf$##g;
		$on = "ON";
		if(-e "$filename_without_extension.txt") {
			$on = "OFF";
		}
		$str .= qq#"$filename" "$filename_without_extension.txt" $on #;
	}
}
print $str
')

	if [[ $FILES ]]; then
		STR='whiptail --title "Dateien zum Konvertieren" --checklist "Welche Dateien sollen konvertiert werden?" 20 78 4 '
		STR+="$FILES"

		FILESTOCONVERT=$(eval $STR 3>&1 1>&2 2>&3)

		eval "convert_to_text $(echo $FILESTOCONVERT)"
	else
		msg "There are no *.pdf-files in the current folder ($(pwd))"
	fi
}

install_if_not_exists "whiptail"
install_if_not_exists "pdftotext" "poppler-utils"
install_if_not_exists "perl" "perl"
install_if_not_exists "uconv" "icu-devtools"

main
