
# Color definitions
red=$'\e[31m'
magenta=$'\e[35m'
green=$'\e[32m'
yellow=$'\e[33m'
cyan=$'\e[36m'

bold=$'\e[1m'
reset=$'\e[0m'

_red()     { printf "${red}%s${reset}\n" "$*"; }
_magenta() { printf "${magenta}%s${reset}\n" "$*"; }
_green()   { printf "${green}%s${reset}\n" "$*"; }
_yellow()  { printf "${yellow}%s${reset}\n" "$*"; }
_cyan()    { printf "${cyan}%s${reset}\n" "$*"; }
           
_bold()    { printf "${bold}%s${reset}\n" "$*"; }
