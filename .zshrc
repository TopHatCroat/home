# If you come from bash you might have to change your $PATH.
# export PATH=/usr/local/bin:$PATH

export PATH=/home/antonio/Development/Go/bin:$HOME/bin:/usr/local/bin:/home/antonio/Android/Sdk/tools:/home/antonio/Android/Sdk/platform-tools:/home/antonio/Development/Go/src/github.com/hyperledger/fabric/build/bin/:/home/antonio/Development/bin:$PATH

export PATH="$(ruby -e 'print Gem.user_dir')/bin:$PATH"

export DEVDIR=$HOME/Development
export GOPATH=$DEVDIR/Go
export ANDROID_HOME=$HOME/Android/Sdk

export PATH="$PATH:$GOPATH/src/github.com/hyperledger/fabric-samples"

export CDPATH=$CDPATH:$DEVDIR:$GOPATH/src

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib:/home/antonio/Development/Hyperledger/indy-sdk/libindy/target/debug

# Path to your oh-my-zsh installation.
export ZSH=/home/antonio/.oh-my-zsh

# Vim setup
mkdir -p ~/.vim/undo
mkdir -p ~/.vim/pack/tpope/start

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="example"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
HIST_STAMPS="yyyy-mm-dd"

# Add wisely, as too many plugins slow down shell startup.
plugins=(git gradle kubectl golang react-native history-substring-search)

source $ZSH/oh-my-zsh.sh

export EDITOR='vim'

# zsh substring history search
source $ZSH_CUSTOM/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh
export HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE="true"

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases

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
alias rnmenu="adb shell input keyevent 82"


# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory extendedglob nomatch notify
unsetopt beep AUTO_CD
bindkey -v

# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/antonio/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

snitch () { netstat -tulpn | grep $1}

snatch() { kill -9 $(netstat -tulpn 2>/dev/null  | grep $1 | awk '{print $7}' | cut -d / -f 1) }

# excecute last command, usefull for commands that can't pipe inputs like: rm $(lo)
# or you can just use rm $(!!) like a sane person
lo () {echo $(bash -c "$(fc -ln -1)")}

function mdless() {
	pandoc -s -f markdown -t man $1 | groff -T utf8 -man | less
}
    
umedit() { mkdir -p ~/.notes; vim ~/.notes/$1; }

um() { mdless ~/.notes/"$1"; }

umls() { ls ~/.notes }

ffile() { find . -type f | fzy }

publish_blog () {
	ssh root@159.65.194.81 'bash /root/publish_script.sh'
}

gen_passwd () {
	python -c 'from passlib.hash import sha512_crypt; print(sha512_crypt.using(rounds=5000).hash("'"$1"'"))'
}

