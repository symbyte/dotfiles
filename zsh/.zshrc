export HOME="/Users/steve"

if [ -r ~/.aliases ]; then
    source ~/.aliases
fi

if [ -r ~/.env ]; then
    source ~/.env
fi

[ -f /home/linuxbrew/.linuxbrew/bin/brew ] && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

eval "$(starship init zsh)"

eval "$(zoxide init --cmd=cd zsh)"

[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

export PATH="$HOME/.local/bin:$PATH"

# pnpm
export PNPM_HOME="/Users/steve/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
export PATH=$PATH:$(go env GOPATH)/bin
export PATH="$HOME/.local/bin:$PATH"

DISABLE_AUTO_TITLE="true"

# Function to set Ghostty tab title to the current directory name only
set_tab_name() {
  # Use %C to show the basename of the current directory.
  # %1d can also be used but %C is generally preferred for titles.
  print -Pn "\e]0;%C\a"
}

# Add the function to the precmd hook, which runs before each prompt
autoload -Uz add-zsh-hook
add-zsh-hook precmd set_tab_name
alias c='claude --dangerously-skip-permissions'
source /Users/steve/.config/op/plugins.sh
source ~/.config/op/plugins.sh
alias z="zellij"
# Zellij attach with fzf session picker
a() {
  local sessions
  sessions=$(zellij list-sessions -n 2>/dev/null)

  [[ -z "$sessions" ]] && { echo "No Zellij sessions found"; return 1; }

  local selected
  selected=$(echo "$sessions" | awk '{
    name = $1
    # Extract time from [Created Xh Ym Zs ago]
    time = ""
    for (i = 2; i <= NF; i++) {
      if ($i == "[Created") {
        for (j = i+1; j <= NF; j++) {
          if ($j == "ago]") break
          time = time $j " "
        }
        break
      }
    }
    gsub(/ $/, "", time)

    # Check if EXITED
    status = (index($0, "EXITED") > 0) ? "⏸ " : "● "

    printf "%s%-25s %s\n", status, name, time
  }' | fzf \
    --height=50% \
    --reverse \
    --ansi \
    --header="  SESSION                   AGE" \
    --no-info)

  [[ -z "$selected" ]] && return 0

  local session_name
  session_name=$(echo "$selected" | awk '{print $2}')
  zellij attach "$session_name"
}
