# Enable colors and change prompt:
autoload -U colors && colors	# Load colors
PS1="%B%{$fg[red]%}[%{$fg[yellow]%}%n%{$fg[green]%}@%{$fg[blue]%}%M %{$fg[magenta]%}%~%{$fg[red]%}]%{$reset_color%}$%b "
setopt autocd		# Automatically cd into typed directory.
stty stop undef		# Disable ctrl-s to freeze terminal.

# History in cache directory:
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.cache/zsh/history

# Load aliases and shortcuts if existent.
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/shortcutrc" ] && source "${XDG_CONFIG_HOME:-$HOME/.config}/shortcutrc"
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/aliasrc" ] && source "${XDG_CONFIG_HOME:-$HOME/.config}/aliasrc"
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/zshnameddirrc" ] && source "${XDG_CONFIG_HOME:-$HOME/.config}/zshnameddirrc"

# Basic auto/tab complete:
autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
compinit
_comp_options+=(globdots)		# Include hidden files.

# vi mode
bindkey -v
export KEYTIMEOUT=1

# Use vim keys in tab complete menu:
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -v '^?' backward-delete-char

# Change cursor shape for different vi modes.
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] ||
     [[ $1 = 'block' ]]; then
    echo -ne '\e[1 q'
  elif [[ ${KEYMAP} == main ]] ||
       [[ ${KEYMAP} == viins ]] ||
       [[ ${KEYMAP} = '' ]] ||
       [[ $1 = 'beam' ]]; then
    echo -ne '\e[5 q'
  fi
}
zle -N zle-keymap-select
zle-line-init() {
    zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
    echo -ne "\e[5 q"
}
zle -N zle-line-init
echo -ne '\e[5 q' # Use beam shape cursor on startup.
preexec() { echo -ne '\e[5 q' ;} # Use beam shape cursor for each new prompt.

# Use lf to switch directories and bind it to ctrl-o
lfcd () {
    tmp="$(mktemp)"
    lf -last-dir-path="$tmp" "$@"
    if [ -f "$tmp" ]; then
        dir="$(cat "$tmp")"
        rm -f "$tmp" >/dev/null
        [ -d "$dir" ] && [ "$dir" != "$(pwd)" ] && cd "$dir"
    fi
}
bindkey -s '^o' 'lfcd\n'

bindkey -s '^a' 'bc -l\n'

bindkey -s '^f' 'cd "$(dirname "$(fzf)")"\n'

bindkey '^[[P' delete-char

# Edit line in vim with ctrl-e:
autoload edit-command-line; zle -N edit-command-line
bindkey '^e' edit-command-line


plugins=(git zsh-completions zsh-autosuggestions zsh-syntax-highlighting git)
autoload -U compinit && compinit
source ~/.oh-my-zsh/oh-my-zsh.sh
setopt HIST_IGNORE_SPACE
export VAULT_SKIP_VERIFY=tru
# Efficient and fairly portable way to display the current iface.
[ -x /sbin/ip ] && alias iface='X=(`/sbin/ip route`) && echo ${X[4]}'

# Fix all CWD file and directory permissions to match the safer 0077 umask.
if [ -x /bin/chmod ]; then
	alias fixperms='\
		/usr/bin/find -xdev \( -type f -exec /bin/chmod 600 "{}" \+ -o\
			-type d -exec /bin/chmod 700 "{}" \+ \)\
			-printf "FIXING: %p\n" 2> /dev/null
	'
fi

# A more descriptive, yet concise lsblk; you'll miss it when it's gone.
if [ -x /bin/lsblk ]; then
	alias lsblkid='\
		/bin/lsblk -o name,label,fstype,size,uuid,mountpoint --noheadings
	'
fi

# Just return the disk name sda,sdb etc, nothing more
if [ -x /bin/lsblk ]; then
	alias lsblkds="/bin/lsblk | grep disk | awk '{print $1}'"
fi

# Ease-of-use youtube-dl aliases; these save typing!
if type -fP youtube-dl > /dev/null 2>&1; then
	alias ytdlv="youtube-dl -c --yes-playlist --sleep-interval 5 --format best --no-call-home --console-title --quiet --ignore-errors" #: Download HQ videos from YouTube, using youtube-dl.
	alias ytdla="youtube-dl -cx --yes-playlist --audio-format mp3 --sleep-interval 5 --max-sleep-interval 5 --no-call-home --console-title --quiet --ignore-errors" #: Download HQ audio from YouTube, using youtube-dl.
	alias ytpla="youtube-dl -cix --audio-format mp3 --sleep-interval 5 --yes-playlist --no-call-home --console-title --quiet --ignore-errors" #: Download HQ videos from YouTube playlist, using youtube-dl.
	alias ytplv="youtube-dl -ci --yes-playlist --sleep-interval 5 --format best --no-call-home --console-title --quiet --ignore-errors" #: Download HQ audio from YouTube playlist, using youtube-dl.
fi

###############################<-Git Prompt->#############################
# enable substitution for prompt
setopt prompt_subst
# Modify the colors and symbols in these variables as desired.
GIT_PROMPT_SYMBOL="%{$fg[blue]%}±"                              # plus/minus     - clean repo
GIT_PROMPT_PREFIX="%{$fg[green]%}[%{$reset_color%}"
GIT_PROMPT_SUFFIX="%{$fg[green]%}]%{$reset_color%}"
GIT_PROMPT_AHEAD="%{$fg[red]%}ANUM%{$reset_color%}"             # A"NUM"         - ahead by "NUM" commits
GIT_PROMPT_BEHIND="%{$fg[cyan]%}BNUM%{$reset_color%}"           # B"NUM"         - behind by "NUM" commits
GIT_PROMPT_MERGING="%{$fg_bold[magenta]%}⚡︎%{$reset_color%}"     # lightning bolt - merge conflict
GIT_PROMPT_UNTRACKED="%{$fg_bold[red]%}●%{$reset_color%}"       # red circle     - untracked files
GIT_PROMPT_MODIFIED="%{$fg_bold[yellow]%}●%{$reset_color%}"     # yellow circle  - tracked files modified
GIT_PROMPT_STAGED="%{$fg_bold[green]%}●%{$reset_color%}"        # green circle   - staged changes present = ready for "git push"

parse_git_branch() {
  # Show Git branch/tag, or name-rev if on detached head
  ( git symbolic-ref -q HEAD || git name-rev --name-only --no-undefined --always HEAD ) 2> /dev/null
}

parse_git_state() {
  # Show different symbols as appropriate for various Git repository states
  # Compose this value via multiple conditional appends.
  local GIT_STATE=""
  local NUM_AHEAD="$(git log --oneline @{u}.. 2> /dev/null | wc -l | tr -d ' ')"
  if [ "$NUM_AHEAD" -gt 0 ]; then
    GIT_STATE=$GIT_STATE${GIT_PROMPT_AHEAD//NUM/$NUM_AHEAD}
  fi
  local NUM_BEHIND="$(git log --oneline ..@{u} 2> /dev/null | wc -l | tr -d ' ')"
  if [ "$NUM_BEHIND" -gt 0 ]; then
    GIT_STATE=$GIT_STATE${GIT_PROMPT_BEHIND//NUM/$NUM_BEHIND}
  fi
  local GIT_DIR="$(git rev-parse --git-dir 2> /dev/null)"
  if [ -n $GIT_DIR ] && test -r $GIT_DIR/MERGE_HEAD; then
    GIT_STATE=$GIT_STATE$GIT_PROMPT_MERGING
  fi
  if [[ -n $(git ls-files --other --exclude-standard 2> /dev/null) ]]; then
    GIT_STATE=$GIT_STATE$GIT_PROMPT_UNTRACKED
  fi
  if ! git diff --quiet 2> /dev/null; then
    GIT_STATE=$GIT_STATE$GIT_PROMPT_MODIFIED
  fi
  if ! git diff --cached --quiet 2> /dev/null; then
    GIT_STATE=$GIT_STATE$GIT_PROMPT_STAGED
  fi
  if [[ -n $GIT_STATE ]]; then
    echo "$GIT_PROMPT_PREFIX$GIT_STATE$GIT_PROMPT_SUFFIX"
  fi
}

git_prompt_string() {
  local git_where="$(parse_git_branch)"

  # If inside a Git repository, print its branch and state
  [ -n "$git_where" ] && echo "$GIT_PROMPT_SYMBOL$(parse_git_state)$GIT_PROMPT_PREFIX%{$fg[yellow]%}${git_where#(refs/heads/|tags/)}$GIT_PROMPT_SUFFIX"

  # If not inside the Git repo, print exit codes of last command (only if it failed)
  [ ! -n "$git_where" ] && echo "%{$fg[red]%} %(?..[%?])"
}
###############################<-Git Prompt->#############################

###############################<-Custom Defined Functions->#############################
# Use skim to fuzzy find files(ignores dotfiles)
skf() {
  mode=$1
  if [ $mode = "nvim" ]; then
     nvim $(find . -not -path '*/\.*'| sk --layout=reverse-list --preview="less {1}" --preview-window=up)
  else
     find . -not -path '*/\.*'| sk --layout=reverse-list --preview="less {1}" --preview-window=up 
  fi
  
}
# Check memory footprint of a program(got from Dash Eclipse's dotfiles)
memu() {
	local CHECK=" $@"
	[ -z $1 ] || [ "${CHECK#* -}" != "$CHECK" ] && { echo "Usage: memu program [program...]"; return 1; }
	local PIDS=$(pidof "$@")
	test -z "$PIDS" && return 0
	echo "$PIDS" \
		| xargs -I{} ps -p "{}" -o size,vsize,rss,cmd \
		| awk 'NR==1; NR>1 {print $1"K", $2"Ki", $3"K", $4}' \
		| numfmt --header --field 1,3 --from=si --to=si --suffix=B --format %.1f \
		| numfmt --header --field 2 --from=iec-i --to=iec-i --suffix=B --format %.1f \
		| sort -hk3,3 \
		| column -t -R1,2,3 \
		| GREP_COLORS='mt=1;94' egrep --color=always '.*SIZE.*VSZ.*RSS.*CMD.*|$' \
		| GREP_COLORS='mt=1;32' egrep --color=always "KB|KiB|$" \
		| GREP_COLORS='mt=0;33' egrep --color=always 'MB|MiB|$' \
		| GREP_COLORS='mt=1;31' egrep --color=always "GB|GiB|$"
}
# driver installation function
dwi(){
    echo "Compiling drivers..."
    cd "$HOME/sourcebuilt/drivers/rtl8188eu" && make clean && make all && sudo make install
    echo "Done"
    echo "Type $(tput bold)Yes$(tput sgr0) to reboot..."; read -r reply
    [ "$reply" = "Yes" ] && sudo reboot || { echo "OK"; exit 0; }
}
###############################<-Custom Defined Functions->#############################
RPROMPT='$(git_prompt_string)'
####################################<-Bloat->####################################
source ~/.local/bin/notifyre.sh
source ~/.local/bin/bash-preexec.sh
if [ -f /etc/bash.command-not-found ]; then
    . /etc/bash.command-not-found
fi
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#ecba0f,bold,underline"
ZSH_AUTOSUGGEST_USE_ASYNC=true
colorscript -r
