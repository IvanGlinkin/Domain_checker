#!/bin/bash

############################################################################
# Domain_checker application is the trial/demo version for the new EASM    #
# (External Attack Surface Management) system called HydrAttack		   #
# (hydrattack.com), the main idea of which is, based only on the domain    #
# name, find almost all of the subdomains and their top 100 open ports     #
############################################################################
# Author:   Ivan Glinkin                                                   #
# Contact:  mail@ivanglinkin.com                                           #
# Twitter:  https://twitter.com/glinkinivan                                #
# LinkedIn: https://www.linkedin.com/in/ivanglinkin/                       #
############################################################################

# Variables
version="0.003"
releasedate="March 11, 2023"

# Colors
RED=`echo -n '\e[00;31m'`;
RED_BOLD=`echo -n '\e[01;31m'`;
GREEN=`echo -n '\e[00;32m'`;
GREEN_BOLD=`echo -n '\e[01;32m'`;
ORANGE=`echo -n '\e[00;33m'`;
BLUE=`echo -n '\e[01;36m'`;
WHITE=`echo -n '\e[00;37m'`;
CLEAR_FONT=`echo -n '\e[00m'`;

# Header
echo -e "";
echo -e "$ORANGE╔═══════════════════════════════════════════════════════════════════════════╗$CLEAR_FONT";
echo -e "$ORANGE║\t\t\t\t\t\t\t\t\t    ║$CLEAR_FONT";
echo -e "$ORANGE║$CLEAR_FONT$GREEN_BOLD\t\t\t\tDomain checker\t\t\t\t    $CLEAR_FONT$ORANGE║$CLEAR_FONT";
echo -e "$ORANGE║\t\t\t\t\t\t\t\t\t    ║\e[00m";
echo -e "$ORANGE╚═══════════════════════════════════════════════════════════════════════════╝$CLEAR_FONT";
echo -e "";
echo -e "$ORANGE[ ! ] https://www.linkedin.com/in/IvanGlinkin/ | @glinkinivan$CLEAR_FONT";
echo -e "$ORANGE[ ! ] Trial/Demo version for the new EASM system$CLEAR_FONT$GREEN_BOLD hydrattack.com$CLEAR_FONT";
echo -e "";

# Check if need apps exist
apps=("jq nmap host")
for app in $apps; do
 	if ! which $app &> /dev/null; then
		echo -e "$RED_BOLD[ - ]$CLEAR_FONT Error: "$app" app is not installed. Execute \"sudo apt-get install $app\""
		exit 1
	fi
done

# Fixed. Thanks t.me/@VladimirM89 and GitHub/@MustaphaDouch 
if ! which geoiplookup &> /dev/null; then
echo -e "$RED_BOLD[ - ]$CLEAR_FONT Error: "geoiplookup" app is not installed. Execute \"sudo apt-get install geoip-bin\""
exit 1
fi

# Function - Check if the domain is valid
function is_valid_domain() {
	local domain="$1"
	if [[ ! "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z]{2,})+$ ]]; then
		echo -e "$RED_BOLD[ - ]$CLEAR_FONT Error:$RED_BOLD $domain$CLEAR_FONT is not a proper domain name"
		exit 1
	fi
}

# Get the domain name from user input
read -p "[ < ] Enter the domain name: " domain

# Check if the domain is valid
is_valid_domain "$domain";

# Get an IP address of the domain
ip=$(host "$domain" | awk '/has address/ { print $4 }' | head -n 1)

# Check if the domain exists
if [ -z "$ip" ] ; then
	echo -e "$RED_BOLD[ - ]$CLEAR_FONT Error: Domain$RED_BOLD $domain$CLEAR_FONT does not exist"
	exit 1
fi

echo -e "$GREEN_BOLD[ + ]$CLEAR_FONT Domain name$GREEN_BOLD $domain$CLEAR_FONT exists. Start enumerating...\n"
echo -e "$GREEN_BOLD[ + ]$CLEAR_FONT IP address is$GREEN_BOLD $ip$CLEAR_FONT"
echo -e "$BLUE[ > ]$CLEAR_FONT Checking for subdomains..."

# Get subdomains of the domain
#subdomains=$(curl -s "https://crt.sh/?q=%25.$domain&output=json" | jq -r '.[].name_value' | sed 's/\*\.//g' | uniq | sort -u)
subdomains=$(curl -s "https://api.hackertarget.com/hostsearch/?q=$domain" | cut -d "," -f 1 | uniq | sort -u)
readarray -t subdomains_array <<< "$subdomains"

for subdomain in "${subdomains_array[@]}"; do
	if [[ "$subdomain" == "$domain" || "$subdomain" == www*"$domain" ]]; then
	continue
	fi
	# Get the IP addresses of the subdomains
		ips=$(host "$subdomain" | awk '/has address/ { print $4 }' | head -n 1)
		echo -e "\t$GREEN_BOLD[ + ]$CLEAR_FONT $subdomain | $ips"
		ip+=" $ips "
		clean_subdomains+="$subdomain ";
done

# Check if subdomains exist
if [ -z "$clean_subdomains" ] ; then
	echo -e "\t$RED_BOLD[ - ]$CLEAR_FONT Subdomains do not exist"
fi

#Sort IP
echo -e "$ORANGE[ ! ]$CLEAR_FONT Cleaning up IP addresses...";
sort_ip=$(echo $ip | sed 's/ /\n/g' | uniq | sort -u)

# Check the top 100 ports of each IP address
echo -e "$BLUE[ > ]$CLEAR_FONT Checking for Top 100 ports and output results..."
for ip in $sort_ip; do
  ports=$(nmap --top-ports 100 "$ip" | grep '^[0-9]' | awk '{ print $1 }' | tr '\n' ', ' | sed 's/,$//')
  country=$(geoiplookup "$ip" | cut -d ":" -f 2)
  echo -e "\t$GREEN_BOLD[ + ]$CLEAR_FONT $ip |$country | $ports"
done
