export LC_ALL="en_US.UTF-8"
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="bira"
source ~/.config/zshrc.d/dots-hyprland.zsh

plugins=(aliases git archlinux command-not-found kitty)
source $ZSH/oh-my-zsh.sh

zstyle ':omz:update' mode auto      # update automatically without asking
setopt autocd                       # change directory just by typing its name
#setopt correct                     # auto correct mistakes
setopt interactivecomments          # allow comments in interactive mode
setopt magicequalsubst              # enable filename expansion for arguments of the form ‘anything=expression’
setopt nonomatch                    # hide error message if there is no match for the pattern
setopt notify                       # report the status of background jobs immediately
setopt numericglobsort              # sort filenames numerically when it makes sense
setopt promptsubst                  # enable command substitution in prompt

CASE_SENSITIVE="true"
WORDCHARS=${WORDCHARS//\/}          # Don't consider certain characters part of the word
PROMPT_EOL_MARK=""                  # hide EOL sign ('%')
TIMEFMT=$'\nreal\t%E\nuser\t%U\nsys\t%S\ncpu\t%P' # configure `time` format

# configure key keybindings
bindkey -e                                        # emacs key bindings
bindkey ' ' magic-space                           # do history expansion on space
bindkey '^U' backward-kill-line                   # ctrl + U
bindkey '^[[3;5~' kill-word                       # ctrl + Supr
bindkey '^[[3~' delete-char                       # delete
bindkey '^[[1;5C' forward-word                    # ctrl + ->
bindkey '^[[1;5D' backward-word                   # ctrl + <-
bindkey '^[[5~' beginning-of-buffer-or-history    # page up
bindkey '^[[6~' end-of-buffer-or-history          # page down
bindkey '^[[H' beginning-of-line                  # home
bindkey '^[[F' end-of-line                        # end
bindkey '^[[Z' undo                               # shift + tab undo last action

# enable completion features
autoload -Uz compinit
compinit -d ~/.cache/zcompdump
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' rehash true
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# History configurations
HIST_STAMPS="dd/mm/yyyy"
HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=2000
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups       # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_verify            # show command with history expansion to user before running it
alias history="history 0"     # force zsh to show the complete history

# enable color support of ls, less and man, and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    export LS_COLORS="$LS_COLORS:ow=30;44:" # fix ls color for folders with 777 permissions

    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    alias diff='diff --color=auto'
    alias ip='ip --color=auto'

    export LESS_TERMCAP_mb=$'\E[1;31m'     # begin blink
    export LESS_TERMCAP_md=$'\E[1;36m'     # begin bold
    export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
    export LESS_TERMCAP_so=$'\E[01;33m'    # begin reverse video
    export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
    export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline
    export LESS_TERMCAP_ue=$'\E[0m'        # reset underline

    # Take advantage of $LS_COLORS for completion as well
    zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
    zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'

    # More ls aliases
    alias ll='ls -l'
    alias la='ls -A'
    alias l='ls -CF'
fi

# Easier navigation: .., ..., ...., .....
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

# Shortcuts
alias dl="cd ~/Downloads"
alias dt="cd ~/Desktop"
alias update-grub="sudo grub-mkconfig -o /boot/grub/grub.cfg"
alias dotsupdate="cd ~/.cache/dots-hyprland && git stash && git pull && ./setup install"

# Download Znap, if it's not there yet.
[[ -r ~/.config/zsh/custom/znap/znap.zsh ]] ||
    git clone --depth 1 -- \
        https://github.com/marlonrichert/zsh-snap.git ~/.config/zsh/custom/znap
source ~/.config/zsh/custom/znap.zsh  # Start Znap
znap source marlonrichert/zsh-autocomplete    # Autocomplete
znap source zsh-users/zsh-autosuggestions     # Autosuggestions
znap source zsh-users/zsh-syntax-highlighting # Highlighting

# Auto launching Hyprland
source ~/.config/zshrc.d/auto-Hypr.sh
