#!/bin/zsh

emulate -L zsh -o extendedglob

# Avoid loading this file more than once
if [[ "$__MCFLY_LOADED" == "loaded" ]]; then
  return 0
fi
__MCFLY_LOADED="loaded"

# MCFLY_SESSION_ID is used by McFly internally to keep track of the commands from a particular terminal session.
export MCFLY_SESSION_ID=$RANDOM$$

# Mcfly needs them, though I think they're uncessary for zsh
export MCFLY_HISTORY=$(mktemp /tmp/mcfly.XXXXXX)
export HISTFILE="${HISTFILE:-${ZDOTDIR:-$HOME}/.zsh_history}"

# If it's the first run, try to import history
if [[ ! -d ~/.mcfly ]]; then
  local tmp=$(mktemp /tmp/mcfly.XXXXXX)
  print -rl ${${(f)"$(fc -l 1)"}## #} | cut -d' ' -f3- > $tmp
  HISTFILE=$tmp mcfly add -- ""
fi

# Ignore commands with a leading space
setopt HIST_IGNORE_SPACE

# Append new history items to .zsh_history
setopt INC_APPEND_HISTORY
1
# Setup zshaddhistory hook.
function mcfly_addhistory {
  emulate -L zsh
  # Run mcfly with the saved code.
  mcfly add --exit $? -- ${1%$'\n'}
  return 0
}
autoload -Uz add-zsh-hook
add-zsh-hook zshaddhistory mcfly_addhistory

# Setup widget
mcfly-search() {
    BUFFER="$(mcfly search --print -- "$BUFFER" | fzf --query="$BUFFER")"
}
zle -N mcfly-search

if [[ $- == *i* ]]; then
  bindkey -M emacs "\C-r" mcfly-search
  bindkey -M viins "\C-r" mcfly-search
fi
