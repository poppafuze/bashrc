# .bashrc

# "This is my rifle.  There are many like it, but this one is mine..."
# (c) 2014-2016 Red Hat, Inc.
#
# Like many bashrc files, this is a highly customized set of personal quirks 
# and generally not formatted or annotated for distribution.  For example,
# this was plagiarized from so many sources that I'm ashamed to use an attribution line...

# CREDITS:
# ...However, this particular plagiarism was performed in 2014-2015 by bbenson@redhat.com,
# with interaction/input from Emmanuel Rouat and Grendel Cooper of the 
# Advanced Bash Scripting Guide at http://tldp.org/LDP/abs/html/sample-bashrc.html
# Many thanks to all the people whose code this is sourced from.  Please message me 
# if you notice a contribution you made and I will be happy to add your name.

# LICENSE: GPLv3

# TODO ##########
# - detect it was run from cli and not installed, and offer to install 
#  -- i.e. self-deployment, perhaps with an augeas shellvar import of existing ~/.bashrc
#
# - test for very simplistic terminal call (i.e. serial) and prompt accordingly
#
# - need a switch for brackets and choice of bracket symbol (lots of ppl like brackets)
#
# - light up on unreadable/untouchable path (costs a conditional)
#
# - Change connection symbol for successful ssh -X
#
# - When the user su's to another (and maybe isn't already root), merge the Xauthority
# 
# - part 1a - light up for keystonerc items
#  
# - test if 'prod' is somewhere in the FQDN, and light the host part up
#
# - Really know if the session is remote, i.e. is it (
# -- sshd, 
# -- dropbear, 
# -- spice
# -- vnc
# -- telnet [xinetd as a parent to in.telnetd], 
# -- or rsh)
# ...ok this is looking to be more unreliable than just "who -m"
# # Look up the top-level parent Process ID (PID) of the given PID, or the current
# # process if unspecified.
#
#      ##########
#
# function top_level_parent_pid {
#   Look up the parent of the given PID.
#   pid=${1:-$$}
#   stat=($(</proc/${pid}/stat))
#   ppid=${stat[3]}
#
#   # /sbin/init always has a PID of 1, so if you reach that, the current PID is
#   # the top-level parent. Otherwise, keep looking.
#   if [[ ${ppid} -eq 1 ]] ; then
#       echo ${pid}
#   else
#       top_level_parent_pid ${ppid}
#   fi
# }

# Methodology and Design Philosophy
#
# - a colored prompt can bring attention to input prompts of other programs due to their plainness
# - a colored prompt can indicate beginning of user input when editing
# - prompt designed to be simple and consume 1 line, the same line as the input
# - prompt on left side, and all empty space on the right
# - typed input overruns on the next line (i.e. "normal"), not a side-scroll
# - heavy CPU consumers are left for PROMPT_COMMAND.  This includes 
# -- per-prompt xterm titles
# -- sophisticated date prompts
# -- PROMPT_COMMAND may break up-arrow (not counted on redraws)

# Features/Design constraints
#
# depend on bash package only, which fairly precludes tput (in ncurses)


# strategic places to put this file
# - ~/.bashrc?
# - /root/.bashrc?
# /etc/profile.d/ ?

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# If not running interactively, don't do anything
# ...although /etc/bashrc (above) generally checks this, it doesn't do it in a robust way
# case $- in
#     *i*) ;;
#           *) return;;
#           esac

# prompt stuff
#
# general strategy: colorize each part for a good reason, without running too many tests each time
# effect0 = 
# 0th part - brackets around everything or not
# 1st part - user - colorized for id, su, and root, maybe keystonerc
# 2nd part - @ - colorized for connection/encryption type, -X/-Y
# 3rd part - host - colorized for local/remote, xauth merge works/broken
# 4th part - pwd - don't run expensive disk size tests here, maybe something about writability
# 5th part - the prompt sign $, or # for EUID0
#
# tests inside $PS1 (consumes CPU at each prompt):
# [[ $? != 0 ]]


# The crayon box
#
# Normal Colors
Black='\e[0;30m'        # Black
Red='\e[0;31m'          # Red
Green='\e[0;32m'        # Green
Yellow='\e[0;33m'       # Yellow
Blue='\e[0;34m'         # Blue
Purple='\e[0;35m'       # Purple
Cyan='\e[0;36m'         # Cyan
White='\e[0;37m'        # White
#
# # Bold
BBlack='\e[1;30m'       # Black
BRed='\e[1;31m'         # Red
BGreen='\e[1;32m'       # Green
BYellow='\e[1;33m'      # Yellow
BBlue='\e[1;34m'        # Blue
BPurple='\e[1;35m'      # Purple
BCyan='\e[1;36m'        # Cyan
BWhite='\e[1;37m'       # White
#
# # Background
On_Black='\e[40m'       # Black
On_Red='\e[41m'         # Red
On_Green='\e[42m'       # Green
On_Yellow='\e[43m'      # Yellow
On_Blue='\e[44m'        # Blue
On_Purple='\e[45m'      # Purple
On_Cyan='\e[46m'        # Cyan
On_White='\e[47m'       # White
#
NC="\e[m"               # Color Reset
#
ALERT=${BWhite}${On_Red} # Bold White on red background

## the following are samples of interactive CLI commands to see the 
## desired login states, which used to create the prompt
#
## what's my PPID...
# ps -p $$ -o ppid=   # number of my ppid
# ps -o ppid= -p $PPID # number of my ppid's ppid
## what's my PPID's PPID's name
# ps -o comm= -p `ps -o ppid= -p $PPID`
#
## where did i really come from
# who -m
# bbenson  pts/6        2014-12-03 15:16 (:0.0)  # local, after sudo su then su foxtest
# bbenson  pts/7        2014-12-03 16:54 (192.168.122.46)  # ssh, after sudo su -
# bbenson  pts/0        2014-12-04 00:06 (localhost)  # telnet to localhost
# bbenson  pts/0        2014-12-04 00:06 (localhost)  # ssh to localhost
# bbenson  tty1         2014-12-04 00:06              # a real virtual console
# bbenson  pts/2        2014-12-22 12:04 (:11.0)      # this is a local X to xrdp
## TODO need test for a serial console
## TODO need test for remote X


### TODO BAKE THIS TEST IN:  w (or who or id) vs logname. if diff, this shows at
#least sudo

# Test user type:
if [[ ${USER} == "root" ]]; then
    SU=${BRed}           # User is root.
    elif [[ ${USER} != $(logname) ]]; then
        SU=${BYellow}          # User is not login user.
        else
            SU=${Green}         # User is normal (well ... most of us are).
            fi

# Test: Connection Type
# TODO: if tty # tty depends on coreutils
if [ -n "${SSH_CONNECTION}" ]; then
    CNX=${BGreen}        # Connected on remote machine, via ssh (good).
    elif [[ "${DISPLAY%%:0*}" != "" ]]; then  # annoying
        CNX=${ALERT}        # wants to say it's unencrypted X, but too dumb to realize it's a local su
        else
            CNX=${BBlack}        # Connected on local machine.
            fi

# Test: Local Or Remote
# TODO: also want to test SSH_TTY
if [ -n "${SSH_CONNECTION}" ]; then
    LOR=${BCyan}        # Connected on remote machine, via ssh (good).
    elif [[ "${DISPLAY%%:0*}" != "" ]]; then
        LOR=${BBlue}        # Connected on remote machine, not via ssh (bad).
        else
            LOR=${Green}        # Connected on local machine.
            fi

# this is an alternative thing I keep around as an example but don't use
# anymore...
## crazy colors gened from mod of hostname
# hostnamecolor=$(hostname | od | tr ' ' '\n' | awk '{total = total + $1}END{print 30 + (total % 6)}')
#
# PS1='\[\e]0;\w\a\]\n\[\e[32m\]\u@\[\e[${hostnamecolor}m\]\]\h \[\e[32m\]\w\[\e[0m\]\n$ '

## this was a nice basic starter for a while, but now I do it with 'the train'
#PS1=""    # zap it at start
#PS1="$(if [[ ${EUID} == 0 ]]; then echo '\[\033[01;31m\]\h\[\033[01;34m\] \W'; else echo '\[\033[01;32m\]\u@\h\[\033[01;34m\] \w'; fi) \$([[ \$? != 0 ]] && echo \"\[\033[01;31m\]:(\[\033[01;34m\] \")\\$\[\033[00m\] "

#### The Train begins
# OK kids this is where the train is put together...
# ..it's called The Train because you can comment out a part and it still
# works.
#
# general prompt format description:
# User[connection-type-char]Host[extra-string][prompt-level-char]:
#
#
#  part 0 = how to start off, and bracket selection effect
#  (no bracket selection code currently)
NPS1=""    # zap it at start
#
#  part 1: user effect
NPS1=${NPS1}"\[${SU}\]\u"
#
#  part 2: connection effect
NPS1=${NPS1}"\[${CNX}\]@\[${NC}\]"
#NPS1=${NPS1}"\[${BBlack}\]\l^"   # adds the tty number, but a bit busy-looking
#
#  part 3 = host effect
NPS1=${NPS1}"\[${LOR}\]\h\[${NC}\]"
#
# part 4: pwd
# PWD (no other info):
NPS1=${NPS1}"\[${BBlue}\] \w"
#
# part 5: return code
# NPS1=${NPS1}" \$([[ \$? != 0 ]] && echo \"\[${BRed}\]!0\[${BBlue}\] \")\\$"  # shorthand, works, injects non-zero
NPS1=${NPS1}"\[${BGreen}\] \$([[ \$? != 0 ]] && echo \"\[${BRed}\]\")\\$"  # shorthand, works, just change the prompt
#
# return to normal for actual user input
# this is always the caboose
NPS1=${NPS1}"\[${NC}\] "
#### The Train ends.

# ...another optional end item
#Set title of current xterm, although PROMPT_COMMAND is the preferred design:
#NPS1=${NPS1}"\[\e]0;[\u@\h] \w\a\]"

# an older alternative shortie for the above system
# this is a bit of a mash between two systems to determine the full user status
# == Put the prompt together here ==
#PS1="$(if [[ ${EUID} == 0 ]]; then echo "\[${SU}\]\u\[${CNX}\]@\[${LOR}\]\h"; else echo "\[${SU}\]\u\[${CNX}\]@\[${LOR}\]\h"; fi)\[${BBlue}\] \w \$([[ \$? != 0 ]] && echo \"\[${BRed}\]:(\[${BBlue}\] \")\\$\[\033[00m\] "

# ...a final word of caution...
# ...adding cluttered conditional junk, code repo checks, and file reads 
# ...to PROMPT_COMMAND/PS1 
# ...has a profound effect on the time it takes to return to a prompt 
# ...after each interactive command
# ...and most especially on things that can time out
# ...which is everywhere
# ......so consider how much stuff to put in, and put in less than that.
#
# test NPS1 here, and if ok, set it
# that way it can be tested live by disabling the line below 
# and running 'PS1=$NPS1' interactively
PS1=$NPS1

# unlimited data plan
# no limit to bash history
export HISTSIZE=
export HISTFILESIZE=

# place timestamp in history
# i.e. when support asks "did you run that command before?"
export HISTTIMEFORMAT="%F-%H%M%S%Z "

# User specific aliases and functions
alias vless='vim -u /usr/share/vim/vim72/macros/less.vim'

# root safety stuff, needs to go in "if USER=root" section
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# # export SYSTEMD_PAGER=
#

