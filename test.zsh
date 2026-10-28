#!/usr/bin/env zsh
# Runs aws-login with a fake HOME and a fake aws command. Run: zsh test.zsh
plugin=${0:A:h}/aws-login.plugin.zsh
failed=0

expect() {
  if eval "$2"; then print "ok    $1"; else print "FAIL  $1"; failed=1; fi
}

# macOS mktemp ignores TMPDIR without a template.
home=$(mktemp -d "${TMPDIR:-/tmp}/aws-login-test.XXXXXX") || exit 1
mkdir -m 700 $home/.aws
cat > $home/session.zsh <<EOF
aws() { print -r -- "\$AWS_LOGIN_CACHE_DIRECTORY \$*" > $home/aws-call }
asp() { print -r -- "\$1" > $home/asp-call }
source $plugin
aws-login staging
print -r -- "\$AWS_LOGIN_CACHE_DIRECTORY" > $home/cache-dir
zsh -f -c "source $plugin"
[[ -d \$AWS_LOGIN_CACHE_DIRECTORY ]] && touch $home/kept-after-child
EOF
HOME=$home zsh -f $home/session.zsh
cache_dir=$(<$home/cache-dir)

expect 'the cache dir is under ~/.aws' '[[ $cache_dir == $home/.aws/aws-login.* ]]'
expect 'aws login gets the cache dir and the login profile' '[[ $(<$home/aws-call) == "$cache_dir login --profile login" ]]'
expect 'asp gets the profile argument' '[[ $(<$home/asp-call) == staging ]]'
expect 'a child shell keeps the cache dir when it exits' '[[ -e $home/kept-after-child ]]'
expect 'the owner shell deletes the cache dir when it exits' '[[ -n $cache_dir && ! -d $cache_dir ]]'

no_aws_home=$(mktemp -d "${TMPDIR:-/tmp}/aws-login-test.XXXXXX") || exit 1
HOME=$no_aws_home zsh -f -c "aws() { touch $no_aws_home/aws-call }; source $plugin; aws-login" 2>/dev/null
expect 'aws login does not run when the cache dir cannot be made' '[[ ! -e $no_aws_home/aws-call ]]'

# A closed window sends SIGHUP. No alive file means the shell ended on the signal, not at the end of its input.
hup_home=$(mktemp -d "${TMPDIR:-/tmp}/aws-login-test.XXXXXX") || exit 1
mkdir -m 700 $hup_home/.aws $hup_home/zdot
cat > $hup_home/zdot/.zshrc <<EOF
aws() { : }
source $plugin
aws-login
print -r -- "\$AWS_LOGIN_CACHE_DIRECTORY" > $hup_home/cache-dir
EOF
printf '%s\n' 'kill -HUP $$' "touch $hup_home/alive" | HOME=$hup_home ZDOTDIR=$hup_home/zdot zsh -i >/dev/null 2>&1
hup_cache_dir=$(<$hup_home/cache-dir)
expect 'the owner shell deletes the cache dir on SIGHUP' '[[ ! -e $hup_home/alive && -n $hup_cache_dir && ! -d $hup_cache_dir ]]'

rm -rf $home $no_aws_home $hup_home
exit $failed
