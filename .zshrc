#####################################################################
#           jdong's zshrc file v0.2.1 , based on:
#		      mako's zshrc file, v0.1
#
# 
######################################################################

# next lets set some enviromental/shell pref stuff up
# setopt NOHUP
#setopt NOTIFY
#setopt NO_FLOW_CONTROL
setopt INC_APPEND_HISTORY SHARE_HISTORY
setopt APPEND_HISTORY
# setopt AUTO_LIST		# these two should be turned off
# setopt AUTO_REMOVE_SLASH
# setopt AUTO_RESUME		# tries to resume command of same name
unsetopt BG_NICE		# do NOT nice bg commands
setopt CORRECT			# command CORRECTION
setopt EXTENDED_HISTORY		# puts timestamps in the history
# setopt HASH_CMDS		# turns on hashing
#
setopt MENUCOMPLETE
setopt ALL_EXPORT

# Set/unset  shell options
setopt   notify globdots correct pushdtohome cdablevars autolist
setopt   correctall autocd recexact longlistjobs
setopt   autoresume histignoredups pushdsilent 
setopt   autopushd pushdminus extendedglob rcquotes mailwarning
unsetopt bgnice autoparamslash

# Autoload zsh modules when they are referenced
zmodload -a zsh/stat stat
zmodload -a zsh/zpty zpty
zmodload -a zsh/zprof zprof
#zmodload -ap zsh/mapfile mapfile


######################################################################
#  begin ser defined functions

# add torrents to rtorrent watch folder on seedbox
function bitadd {
	echo "-----------------------------------------------------------------"
	echo "Sending torrents to seedobx..."
	scp $* anonymoose@anonymoose.dyndns.org:/home/anonymoose/torrent/watch/
	echo "Deleting torrents..."
	rm -v $*
	echo "Process Complete."
	echo "-----------------------------------------------------------------"
}

# ssh into seedbox / mediacenter local network
function localseedbox {
	ssh anonymoose@anonymoose-server.local
}

# ssh into seedbox / media center remotely
function remoteseedbox {
	ssh anonymoose@anonymoose.dyndns.org
}

# ssh into linode
function anonymoose.me {
	ssh anonymoose@anonymoose.me
}

function m3ucopy {
	# feedback
	echo "Copying Tracks from $1"
	FILE=$1
	OUTPUT=$(cat $FILE)
	echo $OUTPUT
	#cat $FILE
}


function countargs {
	ARGS=$*
	echo "${$ARGS}"
}

#import into music dir
function musicimport {
	echo "-----------------------------------------------------------------"
	for a in $*; do
		DIR="$HOME/Music/$a"
		if [ -e "$DIR" ] ; then
			
			echo "Already in library, deleting $a..."
			rm -rf $a
		else

			echo "Importing $a to library..."
			mv $a $DIR

		fi
	done
	echo "-----------------------------------------------------------------"
}

# import into dj library create artist dir if not in existence
# todo: 
###### Add meta data importing
function libraryimport {
	clear
	echo "-----------------------------------------------------------------"
	echo "Library Import"
	echo "-----------------------------------------------------------------"
	
	# Prompt the user for an artist name
	echo "Reading metadata for the following releases:"
	for a in $*; do
		#echo "$a"
		if [ -d "$a" ]; then
			cd "$a"
			for FILE in *; do
				EXTENSION=`echo "$FILE"|awk -F . '{print $NF}'`
				if [[ $EXTENSION = "mp3" ]]; then
					ARTISTOUT=`exiftool -ARTIST "$FILE"`
					TITLEOUT=`exiftool -TITLE "$FILE"`
					ALBUMOUT=`exiftool -ALBUM "$FILE"`
					ARTIST=`echo "$ARTISTOUT"|awk -F ": " '{print $NF}'`
					ALBUM=`echo "$ALBUMOUT"|awk -F ": " '{print $NF}'`
					TITLE=`echo "$TITLEOUT"|awk -F ": " '{print $NF}'`
					break
				fi
                                if [[ $EXTENSION = "flac" ]]; then
					ARTIST=$(metaflac "$FILE" --show-tag=ARTIST | sed "s/.*=//g")
					TITLE=$(metaflac "$FILE" --show-tag=TITLE | sed "s/.*=//g")
					ALBUM=$(metaflac "$FILE" --show-tag=ALBUM | sed "s/.*=//g")
                                	break
				fi 

			done
			# print the metadata for this release
			echo "$ARTIST - $ALBUM location($a)"
			# return to parent dir
			cd ..
		else
		#	exiftool -ARTIST -TITLE "$a"

			ARTISTOUT=`exiftool -ARTIST "$a"`
			ALBUMOUT=`exiftool -ALBUM "$a"`
			TITLEOUT=`exiftool -TITLE "$a"`
			
			ARTIST=`echo "$ARTISTOUT"|awk -F ": " '{print $NF}'`
			ALBUM=`echo "$ALBUMOUT"|awk -F ": " '{print $NF}'`
			TITLE=`echo "$TITLEOUT"|awk -F ": " '{print $NF}'`
		
			echo "$ARTIST - $ALBUM location($a)"
		
		fi
	done
	echo "Import using metatags as artist '$ARTIST'? Y/n"
	read USEMETA
	if [[ $USEMETA == "n" ]]; then
		echo "Artist name:"
		read ARTIST
	fi
	
	if [[ $USEMETA != "Y" ]]; then
		echo "You did not seem to understand the question, terminating script"
		exit
	fi
		
	# run the import
	for a in $*; do
		DIR="$HOME/DJ/Library/$ARTIST"
		if [ ! -e "$DIR" ] ; then
			echo "Creating directory: $DIR"
			mkdir $DIR
			echo "Moving $a to $DIR"
			mv $a "$DIR/"
		else
			if [ ! -e "$DIR/$a" ]; then
				echo "Moving $a to $DIR"
				mv $a "$DIR/"
			else 
				echo "$a already exists in library, Deleting..."
				rm -rf $a
			fi
		fi
	done
	echo "Process complete, cheers then.."
	echo "-----------------------------------------------------------------"
}

function playaudio {

	open -a /Applications/Decibel.app $*

}

flactomp3(){
	QUALITY="$1"
	TOTALTRACKS="`ls *flac | wc -l`"
	echo "Found $TOTALTRACKS files to convert"
	for f in *.flac; do
		echo $f
	done	
	read -p "Would you like to continue?"
	for f in *.flac; do
		OUT=$(echo "$f" | sed s/\.flac$/.mp3/g)
		ARTIST=$(metaflac "$f" --show-tag=ARTIST | sed "s/.*=//g")
		TITLE=$(metaflac "$f" --show-tag=TITLE | sed "s/.*=//g")
		ALBUM=$(metaflac "$f" --show-tag=ALBUM | sed "s/.*=//g")
		GENRE=$(metaflac "$f" --show-tag=GENRE | sed "s/.*=//g")
		TRACK=$(metaflac "$f" --show-tag=TRACKNUMBER | sed "s/.*=//g")
		DATE=$(metaflac "$f" --show-tag=DATE | sed "s/.*=//g")
		echo "Converting $f to $OUT"
		flac -c -d "$f" | lame -mj -q0 -s44.1 $QUALITY - "$OUT"
		echo "Tagging $OUT with id3v1 and then id3v2"
		#id3 -t "$TITLE" -T "$TRACK" -A "$ALBUM" -y "$DATE" -g "$GENRE" "$OUT"
		#id3v2 -t "$TITLE" -T "${TRACK:-0}" -a "$ARTIST" -A "$ALBUM" -y "$DATE" -g "${GENRE:-12}" "$OUT"
		echo "Updating the tags for $OUT with a more modern track and genre (id3v2.4)"
		#mid3v2 -T "${TRACK:-0}/$TOTALTRACKS" -g "$GENRE" "$OUT" # Add the genre and track in a more modern fashion
	done
}
flac-to-v0(){
	flac-to-mp3 "-V0"
}
flac-to-v2(){
	flac-to-mp3 "-V2"
}

function mp3encode(){

	BITRATE="$1"
	INFILE="$2"
	# run command
	
	FILENAME=${INFILE%.*}
	OUTFILE="$FILENAME.mp3"

#	if [ $BITRATE == "" || $INFILE == "" ]; then
#		echo "Please provide a file to convert"
#		exit
#	fi
	
	if [ -e $BITRATE ]; then
		INFILE="$1"
		FILENAME=${INFILE%.*}
		OUTFILE="$FILENAME.mp3"

		lame -b 320 $INFILE $OUTFILE
	else	
		lame -b $BITRATE $INFILE $OUTFILE
	fi
	

}

function rmemptydirs {

        echo "-----------------------------------------------------------------"
        echo " Remove These empty directories? Y/n"
        for DIR in $*; do
#		ls $DIR | wc -l
                if [ -d $DIR ]; then
                        if [ $( ls $DIR | wc -l) == "1" ]; then
                                echo $DIR
                        fi
                fi
        done
        read -e question

        if [ $question == "Y" ]; then

                for DIR in $*; do
                        if [ "`ls $DIR`" == "" ]; then
                                rm -v $DIR
                        fi
                done
        fi
        echo "Process Complete"
        echo "-----------------------------------------------------------------"

}		


function flac-to-mp3() {


}

# end user defined functions
######################################################################

PATH="/opt/local/bin:/opt/local/sbin:/usr/local/bin:/usr/local/sbin/:/bin:/sbin:/usr/bin:/usr/sbin:$PATH"
TZ="America/New_York"
HISTFILE=$HOME/.zhistory
HISTSIZE=1000
SAVEHIST=1000
HOSTNAME="`hostname`"
PAGER='less'
EDITOR='vim'
    autoload colors zsh/terminfo
    if [[ "$terminfo[colors]" -ge 8 ]]; then
   colors
    fi
    for color in RED GREEN YELLOW BLUE MAGENTA CYAN WHITE; do
   eval PR_$color='%{$terminfo[bold]$fg[${(L)color}]%}'
   eval PR_LIGHT_$color='%{$fg[${(L)color}]%}'
   (( count = $count + 1 ))
    done
    PR_NO_COLOR="%{$terminfo[sgr0]%}"
PS1="[$PR_BLUE%n$PR_WHITE@$PR_GREEN%U%m%u$PR_NO_COLOR:$PR_RED%2c$PR_NO_COLOR]%(!.#.$) "
RPS1="$PR_LIGHT_YELLOW(%D{%m-%d %H:%M})$PR_NO_COLOR"
#LANGUAGE=
LC_ALL='en_US.UTF-8'
LANG='en_US.UTF-8'
LC_CTYPE=C

if [ $SSH_TTY ]; then
  MUTT_EDITOR=vim
else
  MUTT_EDITOR=emacsclient.emacs-snapshot
fi

unsetopt ALL_EXPORT
# # --------------------------------------------------------------------
# # aliases
# # --------------------------------------------------------------------

alias slrn="slrn -n"
alias man='LC_ALL=C LANG=C man'
alias f=finger
alias ll='ls -al'
#alias ls='ls --color=auto '
alias offlineimap-tty='offlineimap -u TTY.TTYUI'
alias hnb-partecs='hnb $HOME/partecs/partecs-hnb.xml'
alias rest2html-css='rst2html --embed-stylesheet --stylesheet-path=/usr/share/python-docutils/s5_html/themes/default/print.css'
alias df='df -h'
alias lsd='ls -latr'
alias gitadd='git add'
#if [[ $HOSTNAME == "kamna" ]] {
#	alias emacs='emacs -l ~/.emacs.kamna'
#}	

# alias	=clear

#chpwd() {
#     [[ -t 1 ]] || return
#     case $TERM in
#     sun-cmd) print -Pn "\e]l%~\e\\"
#     ;;
#    *xterm*|screen|rxvt|(dt|k|E)term) print -Pn "\e]2;%~\a"
#    ;;
#    esac
#}
selfupdate(){
        URL="http://stuff.mit.edu/~jdong/misc/zshrc"
        echo "Updating zshrc from $URL..."
        echo "Press Ctrl+C within 5 seconds to abort..."
        sleep 5
        cp ~/.zshrc ~/.zshrc.old
        wget $URL -O ~/.zshrc
        echo "Done; existing .zshrc saved as .zshrc.old"
}
#chpwd

autoload -U compinit
compinit
bindkey "^?" backward-delete-char
bindkey '^[OH' beginning-of-line
bindkey '^[OF' end-of-line
bindkey '^[[5~' up-line-or-history
bindkey '^[[6~' down-line-or-history
bindkey "^r" history-incremental-search-backward
bindkey ' ' magic-space    # also do history expansion on space
bindkey '^I' complete-word # complete on tab, leave expansion to _expand
zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path ~/.zsh/cache/$HOST

zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-prompt '%SAt %p: Hit TAB for more, or the character to insert%s'
zstyle ':completion:*' menu select=1 _complete _ignored _approximate
zstyle -e ':completion:*:approximate:*' max-errors \
    'reply=( $(( ($#PREFIX+$#SUFFIX)/2 )) numeric )'
zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'

# Completion Styles

# list of completers to use
zstyle ':completion:*::::' completer _expand _complete _ignored _approximate

# allow one error for every three characters typed in approximate completer
zstyle -e ':completion:*:approximate:*' max-errors \
    'reply=( $(( ($#PREFIX+$#SUFFIX)/2 )) numeric )'
    
# insert all expansions for expand completer
zstyle ':completion:*:expand:*' tag-order all-expansions

# formatting and messages
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*:corrections' format '%B%d (errors: %e)%b'
zstyle ':completion:*' group-name ''

# match uppercase from lowercase
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# offer indexes before parameters in subscripts
zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

# command for process lists, the local web server details and host completion
# on processes completion complete all user processes
# zstyle ':completion:*:processes' command 'ps -au$USER'

## add colors to processes for kill completion
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'

#zstyle ':completion:*:processes' command 'ps ax -o pid,s,nice,stime,args | sed "/ps/d"'
zstyle ':completion:*:*:kill:*:processes' command 'ps --forest -A -o pid,user,cmd'
zstyle ':completion:*:processes-names' command 'ps axho command' 
#zstyle ':completion:*:urls' local 'www' '/var/www/htdocs' 'public_html'
#
#NEW completion:
# 1. All /etc/hosts hostnames are in autocomplete
# 2. If you have a comment in /etc/hosts like #%foobar.domain,
#    then foobar.domain will show up in autocomplete!
zstyle ':completion:*' hosts $(awk '/^[^#]/ {print $2 $3" "$4" "$5}' /etc/hosts | grep -v ip6- && grep "^#%" /etc/hosts | awk -F% '{print $2}') 
# Filename suffixes to ignore during completion (except after rm command)
zstyle ':completion:*:*:(^rm):*:*files' ignored-patterns '*?.o' '*?.c~' \
    '*?.old' '*?.pro'
# the same for old style completion
#fignore=(.o .c~ .old .pro)

# ignore completion functions (until the _ignored completer)
zstyle ':completion:*:functions' ignored-patterns '_*'
zstyle ':completion:*:*:*:users' ignored-patterns \
        adm apache bin daemon games gdm halt ident junkbust lp mail mailnull \
        named news nfsnobody nobody nscd ntp operator pcap postgres radvd \
        rpc rpcuser rpm shutdown squid sshd sync uucp vcsa xfs avahi-autoipd\
        avahi backup messagebus beagleindex debian-tor dhcp dnsmasq fetchmail\
        firebird gnats haldaemon hplip irc klog list man cupsys postfix\
        proxy syslog www-data mldonkey sys snort
# SSH Completion
zstyle ':completion:*:scp:*' tag-order \
   files users 'hosts:-host hosts:-domain:domain hosts:-ipaddr"IP\ Address *'
zstyle ':completion:*:scp:*' group-order \
   files all-files users hosts-domain hosts-host hosts-ipaddr
zstyle ':completion:*:ssh:*' tag-order \
   users 'hosts:-host hosts:-domain:domain hosts:-ipaddr"IP\ Address *'
zstyle ':completion:*:ssh:*' group-order \
   hosts-domain hosts-host users hosts-ipaddr
zstyle '*' single-ignored show
