export PATH=/home/antonio/Development/Go/bin:$HOME/bin:/usr/local/bin:/home/antonio/Android/Sdk/tools:/home/antonio/Android/Sdk/platform-tools:/home/antonio/Development/Go/src/github.com/hyperledger/fabric/build/bin/:/home/antonio/Development/bin:$PATH

export PATH="$(ruby -e 'print Gem.user_dir')/bin:$PATH"

export DEVDIR=$HOME/Development
export GOPATH=$DEVDIR/Go
export ANDROID_HOME=$HOME/Android/Sdk

export PATH="$PATH:$GOPATH/src/github.com/hyperledger/fabric-samples"

export CDPATH=$CDPATH:$DEVDIR:$GOPATH/src

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib:/home/antonio/Development/Hyperledger/indy-sdk/libindy/target/debug

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh
export ZSH_CUSTOM=$HOME/.oh-my-zsh-custom

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

plugins=(adb archlinux gradle golang react-native history-substring-search zsh-autosuggestions)

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

autoload -Uz compinit
compinit
# End of lines added by compinstall

# oh-my-zsh plugins
source $ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $ZSH_CUSTOM/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
export HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE="true"

bindkey '^ ' autosuggest-accept


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
alias rn="react-native"
# Open up RN menu on Android, works when only one device is connected
alias rnmenu="adb shell input keyevent 82"

alias {gut,got,gti}="git"
alias gd="git diff"
alias gds="git diff --staged"

# excecute last command, usefull for commands that can't pipe inputs like: rm $(lo)
# or you can just use rm $(!!) like a sane person
lo () {echo $(bash -c "$(fc -ln -1)")}

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

publish_blog () {
	ssh root@159.65.194.81 'bash /root/publish_script.sh'
}

# Cool guys don't look at explosions
gg () {
	git commit -am "'$1'" && git push
}

gen_passwd () {
	python -c 'from passlib.hash import sha512_crypt; print(sha512_crypt.using(rounds=5000).hash("'"$1"'"))'
}
