autoload -Uz add-zsh-hook

# The cache dir is under ~/.aws, so a sandbox that hides ~/.aws hides the session too.
aws-login() {
  if [[ -z "$AWS_LOGIN_CACHE_DIRECTORY" ]]; then
    local cache_dir
    cache_dir="$(mktemp -d "$HOME/.aws/aws-login.XXXXXX")" || return
    export AWS_LOGIN_CACHE_DIRECTORY="$cache_dir" AWS_LOGIN_CACHE_OWNER_PID=$$
  fi
  aws login --profile login || return
  [[ -n "$1" ]] && asp "$1"
}
compctl -K _aws_profiles aws-login

# Child shells inherit the variables. Only the shell that made the dir may delete it.
_aws_login_delete_cache() {
  [[ "$AWS_LOGIN_CACHE_OWNER_PID" == "$$" ]] && rm -rf "$AWS_LOGIN_CACHE_DIRECTORY"
}
add-zsh-hook zshexit _aws_login_delete_cache
