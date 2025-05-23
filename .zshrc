export PATH=$HOME/Development/Go/bin:$HOME/bin:/usr/local/bin:$PATH:$HOME/.local/bin

export DEVDIR=$HOME/Development
export GOPATH=$DEVDIR/Go

# Load rbenv automatically by appending
eval "$(rbenv init - zsh)"

if [ $(uname -s) = "Linux" ]; then
  android_home=$HOME/Android/Sdk
elif [ $(uname -s) = "Darwin" ]; then
  android_home=$HOME/Library/Android/sdk
  export GOROOT="$(brew --prefix golang)/libexec"
fi

if [ -d $android_home ]; then
  export ANDROID_HOME=$android_home
  export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:$ANDROID_HOME/emulator:$PATH"
  unset android_home
fi

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh
export ZSH_CUSTOM=$HOME/.oh-my-zsh-custom

# Needed for GnuPG 2
export GPG_TTY=$(tty)

# Vim setup
mkdir -p ~/.vim/undo
mkdir -p ~/.vim/pack/tpope/start

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="sike"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
HIST_STAMPS="yyyy-mm-dd"

# Add wisely, as too many plugins slow down shell startup.

plugins=(git adb yarn gradle golang react-native terraform history-substring-search zsh-autosuggestions asdf direnv)

source $ZSH/oh-my-zsh.sh

export EDITOR='vim'

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory extendedglob nomatch notify HIST_IGNORE_SPACE
unsetopt beep AUTO_CD
bindkey -v

# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '~/.zshrc'

# Stripe CLI completion 
fpath=(~/bin/setup/stripe/stripe-completion.zsh $fpath)

autoload -Uz compinit
compinit -it
# End of lines added by compinstall

# oh-my-zsh plugins
source $ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $ZSH_CUSTOM/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
export HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE="true"

bindkey '^ ' autosuggest-accept

# Base16 Shell
BASE16_SHELL="$HOME/.config/base16-shell/"
[ -n "$PS1" ] && \
    [ -s "$BASE16_SHELL/profile_helper.sh" ] && \
        eval "$("$BASE16_SHELL/profile_helper.sh")"

# Aliases and helper methods

# Commands starting with space are not saved in history
alias {ls,ls}=" ls"
alias {cd,dc}=" cd"
alias zshconfig="vim ~/.zshrc"
alias vimconfig="vim ~/.vimrc"
alias reload="source ~/.zshrc"
alias ohmyzsh="vim ~/.oh-my-zsh"
alias kc="kubectl"
alias c="clipcopy"
alias v="clippaste"
alias cdv="cd $(clippaste)"
alias pwdc="pwd | c"
alias read-certv="clippaste > /tmp/cert.pem && read-cert /tmp/cert.pem"
alias rn="react-native"
# Open up RN menu on Android, works when only one device is connected
alias rnmenu="adb shell input keyevent 82"
alias rntunnel="adb reverse tcp:8081 tcp:8081"

alias {gut,got,gti}="git"
alias gd="git diff"
alias gds="git diff --staged"
# Print git log as a pretty graph
alias gpl="git log --graph --oneline --all"
alias tf="terraform"

alias kc="kubectl"
alias mkc="minikube kubectl --"
alias getidf='. $HOME/Development/esp/esp-idf/export.sh'

# aoways use home alias with git in home dir
alias home='git --work-tree=$HOME --git-dir=$HOME/.homegit'
# excecute last command, usefull for commands that can't pipe inputs like: rm $(lo)
# or you can just use rm $(!!) like a sane person
lo () { echo $(bash -c "$(fc -ln -1)") }

# Parse markdown file and print it man page like
function mdless() {
	pandoc -s -f markdown -t man $1 | groff -T utf8 -man | less
}

# Shorthand for editing notes
umedit() { mkdir -p ~/.notes; vim ~/.notes/$1; }

# Shorthand for viewing notes
um() { mdless ~/.notes/"$1"; }

# See all my notes
umls() { ls ~/.notes }

# Search for files in current dir
ffile() { find . -type f | fzy }

# Cool guys don't look at explosions
# gg() { git commit -am "'$1'" && git push }

gen_passwd () {
	python -c 'from passlib.hash import sha512_crypt; print(sha512_crypt.using(rounds=5000).hash("'"$1"'"))'
}

export VOLTA_HOME="$HOME/.volta"
grep --silent "$VOLTA_HOME/bin" <<< $PATH || export PATH="$VOLTA_HOME/bin:$PATH"

[ -s "$HOME/.jabba/jabba.sh" ] && source "$HOME/.jabba/jabba.sh"

export PATH=$(brew --prefix openvpn)/sbin:$PATH

if command -v pyenv 1>/dev/null 2>&1; then
  export PYENV_ROOT="$HOME/.pyenv"
  [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
fi

if command -v direnv 1>/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

if command -v jabba 1>/dev/null 2>&1; then
	export JABBA_VERSION=0.11.2
	[ -s "$JABBA_HOME/jabba.sh" ] && source "$JABBA_HOME/jabba.sh"
fi

if command -v wmill 1>/dev/null 2>&1; then
	source <(wmill completions zsh)
fi

eval "$(direnv hook zsh)"

# Add OpenVPN and Postgres utils to path
export PATH=$(brew --prefix openvpn)/sbin:$(brew --prefix postgresql@16)/bin:$PATH

# bun completions
[ -s "/Users/antonio/.bun/_bun" ] && source "/Users/antonio/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# pnpm
export PNPM_HOME="/Users/antonio/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# pnpm end
