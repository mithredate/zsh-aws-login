# zsh-aws-login

`aws-login` is an oh-my-zsh plugin. Its `aws-login` command starts an AWS session that only the current terminal and its child processes can use.

## Why

By default, `aws login` keeps the temporary credentials and the refresh token in one fixed directory. Every terminal and every process of your user can then use them. `aws-login` gives each terminal a new directory in `~/.aws`. When the shell that ran `aws-login` exits, the plugin deletes the directory. The plugin also deletes it when you close the terminal window, because the window sends `SIGHUP` to the shell.

A sandbox that hides `~/.aws` also hides the session. An example is the Claude Code sandbox with `~/.aws` in `sandbox.credentials.files`.

## Install

1. Clone the repo into the custom plugins directory of oh-my-zsh:

   ```sh
   git clone https://github.com/mithredate/zsh-aws-login "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/aws-login"
   ```

2. Add `aws-login` after `aws` in `plugins=(...)` in `~/.zshrc`. The plugin uses `asp` and the profile completion from the `aws` plugin.
3. Open a new terminal.

Every new shell runs the plugin. Do not put the clone in a directory that an agent or a sandboxed command can write.

To update, run `git pull` in the plugin directory.

## Configure ~/.aws/config

Every profile must get its keys from the `login` profile. Then every profile needs the session that `aws-login` starts.

```ini
[profile login]
region = eu-central-1

[default]
region = eu-central-1
credential_process = aws configure export-credentials --profile login --format process

[profile staging]
role_arn = arn:aws:iam::<account>:role/<role>
source_profile = default
region = eu-central-1
```

`aws login` writes `login_session` into the `login` profile. Do not write it by hand.

## Use

```sh
aws-login            # Log in.
aws-login staging    # Log in, then run `asp staging`.
```

A second `aws-login` in the same terminal, or in a child shell, uses the same directory.

## Limits

- The AWS CLI keeps the keys of each role in `~/.aws/cli/cache` as plain JSON. Any process that can read the file can use the keys until they expire.
- If the owner shell gets `SIGKILL`, the directory stays.

## Test

```sh
zsh test.zsh
```
