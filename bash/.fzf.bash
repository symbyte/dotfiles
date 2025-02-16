# Setup fzf
# ---------
if [[ ! "$PATH" == */home/symbyte/.fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/home/symbyte/.fzf/bin"
fi

eval "$(fzf --bash)"
