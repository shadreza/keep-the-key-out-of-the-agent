# Part 4, hands-on: run Claude Code in a Strands Box, with the key outside

Part 4 of 4 in *Keep the key out of the agent*. You move a project's `.env` out of the project, give Box a route for the model key, and run Claude Code in a box. Then you leave a fake key in the project on purpose and see what the box does and doesn't stop.

Run every command from this folder:

```sh
git clone https://github.com/shadreza/keep-the-key-out-of-the-agent.git
cd keep-the-key-out-of-the-agent/part-4-hands-on
```

## What was tested

- **2026-11-23**, box 0.3.0 on Debian GNU/Linux 12 (x86_64, glibc 2.36), git 2.39.5, Claude Code 2.1.325: steps 1 to 7 and step 11. Output in [`captured/`](captured/). The box itself didn't start there ([known gap 3](known-gaps.md#3-the-box-didnt-start-on-the-test-machine)).
- **2026-11-24**, box 0.3.0 on an Arch-based Linux laptop (x86_64, glibc 2.44), git 2.56.0: steps 1 to 7 again, and a box started with a plain shell in place of Claude Code. The shell saw a placeholder instead of the key, read the `.env` without the deny, and read nothing with it ([`captured/08-probe-on-a-laptop.txt`](captured/08-probe-on-a-laptop.txt), and [Part 3's probe](../part-3-what-strands-box-changes/README.md#try-it-with-no-model) to run it yourself). The box started only with `BOX_HOME` off the btrfs home folder ([known gap 5](known-gaps.md#5-box-wouldnt-start-with-its-home-on-btrfs)).
- **Not run yet:** Claude Code talking to a model inside a box (steps 8 to 10). Those steps come from Box's docs. If what you see differs, open an issue.

Box is in preview, and v0.3.0 came out on 23 November 2026. Check the steps against Box's docs on the day you run them.

Box is AWS's open-source Strands Box, in preview: <https://github.com/strands-agents/box>. Its docs are the source for every command here. Where this page says what Box *will* show, it quotes those docs; it doesn't say we saw it.

## What it costs

Box is free (Apache 2.0). The model isn't. With an Anthropic API key, every prompt is billed to that key's account per token; with Bedrock, to your AWS account. Before you start, set a spending limit on the key or a budget on the account. That's the lesson of Part 1.

## Before you start

- An Apple silicon Mac on macOS 15 or later, or Linux on ARM64 or x86_64 (glibc 2.34 or later, Python 3, `curl` and the GNU tools).
- Claude Code from its native installer (`curl -fsSL https://claude.ai/install.sh | bash`). Box starts the native executable, so its docs say to reinstall this way if you installed Claude Code with `npm`.
- One way to reach a model:
  - **An Anthropic API key** (path A below). The clearest way to see the placeholder key.
  - **Amazon Bedrock** in your own AWS account (path B, the default in Box's docs), with the AWS CLI and an AWS profile that can call a Claude model.
- A throwaway project. Don't try this first in a project with real client data.

Mac and Linux differ in a few places, noted at each step.

## 1. Install Box

Read the installer before you run it. It downloads a release from the `strands-agents/box` GitHub releases, checks its checksum (and on a Mac, Apple's signature and notarization) and links `~/.local/bin/box`.

```sh
curl -fsSL https://raw.githubusercontent.com/strands-agents/box/main/install.sh -o install.sh
less install.sh
sh install.sh
```

On the laptop it looked like this:

![A terminal: curl downloads install.sh, less opens it, sh install.sh installs box version 0.3.0 with a full progress bar and "Verified checksum and archive", then prints the Strands box logo, the two main commands (box run and box profile), the example next steps for Claude Code with Bedrock, and the telemetry notice.](../docs/images/install-box.png)

Look for `Verified checksum and archive`. Without a terminal to draw the progress bar in, the installer prints plain lines instead ([`captured/01-install.txt`](captured/01-install.txt)):

```text
Downloading box-cli-v0.3.0-x86_64-unknown-linux-gnu.tar.gz...
Verified checksum and archive
Installed box 0.3.0.
```

On a Mac the second line is `Verified checksum, archive, and Apple signature`. The installer also prints that usage telemetry goes to `telemetry.strandsagents.com`. The screenshot ends with it. To turn it off:

```sh
box telemetry off
```

## 2. Check it runs

Open a new terminal, then:

```console
$ box --version
box 0.3.0
```

## 3. Make a throwaway project with a fake key

The key below is fake on purpose. It's a canary: if it ever shows up somewhere, you know what read it.

```sh
mkdir -p ~/src/my-app && cd ~/src/my-app
git init
printf '.env\n' > .gitignore
printf 'ANTHROPIC_API_KEY=sk-ant-fake-canary-not-a-real-key\n' > .env
```

## 4. Move the `.env` out of the project

[`scripts/move-env-out.sh`](scripts/move-env-out.sh) moves it to `~/.config/agent-secrets/my-app.env`, readable only by you (mode 600). It refuses to overwrite a file that's already there, and refuses a target inside the project.

```sh
sh scripts/move-env-out.sh ~/src/my-app
```

You should see:

```text
moved /home/you/src/my-app/.env
   to /home/you/.config/agent-secrets/my-app.env (mode 600)
load it in the terminal you run box from:
   set -a; . "/home/you/.config/agent-secrets/my-app.env"; set +a
```

Now put your **real** key in that file, in place of the fake one. The project no longer holds any key.

## 5. Create the profile

A profile tells Box which agent to run, which model service it may reach, and which policy it starts from. Pick the Scoped policy: the agent reaches only the hosts your packs and profile allow.

**Path A, Anthropic API key:**

```sh
box profile create claude-api --with claude,anthropic --policy scoped
```

It ends with (captured in [`captured/04-profile-create-anthropic.txt`](captured/04-profile-create-anthropic.txt)):

```text
Next
  1. Put the key for api.anthropic.com in ANTHROPIC_API_KEY.
  2. Start Claude Code in the box, from the project directory:
     box run claude-api
```

**Path B, Amazon Bedrock:**

```sh
box profile create claude --with claude,bedrock --option bedrock.region=us-east-1 --policy scoped
```

It ends with `The bedrock route signs with your default AWS identity.` ([`captured/03-profile-create-bedrock.txt`](captured/03-profile-create-bedrock.txt)). Pick the region your account uses.

Either way, `box` lists the toolchains it found. On the test machine it skipped `cargo` and `pnpm` (not installed) and `yarn` (`it runs /usr/bin/dash, which is the command of no tool table`).

## 6. Look at the route: where the real key goes

```sh
box profile show claude-api --full
```

Find the `[egress.anthropic]` table ([`captured/05-anthropic-route.txt`](captured/05-anthropic-route.txt)):

```toml
[egress.anthropic]
destinations = ["api.anthropic.com"]

[egress.anthropic.secret]
header = "x-api-key"
phantom_prefix = "sk-ant-"
ref = "env://ANTHROPIC_API_KEY"
```

This is the whole idea in six lines. Box reads the real key from `ANTHROPIC_API_KEY` in *your* shell, outside the box, and adds it as the `x-api-key` header only on requests to `api.anthropic.com`. Inside the box, the agent gets a placeholder that starts with `sk-ant-`. For Bedrock, the route signs each request with your AWS credentials, outside the box, in the same way.

## 7. Keep any `.env` that's still in a project away from the box

Moving the file is the fix. This is the seatbelt, for the day someone copies a `.env` back in. Add these lines to the end of the profile (`~/.strands/box/profiles/claude-api/profile.toml`; the full files are in [`profiles/`](profiles/)):

```toml
[filesystem]
deny = [{ path = "${{ workspace }}/.env", optional = true }]
```

`${{ workspace }}` is the project you start `box` from. `optional = true` lets the profile run in a project with no `.env`; on Linux the path must exist without it. Check that it reached every process. Run this from a project that has a `.env`: an `optional` path that doesn't exist isn't listed.

```sh
cd ~/src/my-app
printf 'ANTHROPIC_API_KEY=sk-ant-fake-canary-not-a-real-key\n' > .env   # the canary, for this check
box profile show claude-api --full | grep -n '^deny'
rm .env
```

On the test machine the deny landed in the agent's table and in each tool's (git, node, npm), as [`captured/06-env-deny-resolved.txt`](captured/06-env-deny-resolved.txt) shows. A `forbid` rule in `policy.dw` would not do this: Box's docs say policy file rules decide only the box's own shell, not the agent's file tools.

## 8. Run Claude Code in the box (not run yet: needs a model)

Load the key into this terminal only, then start the agent from the project:

```sh
set -a; . ~/.config/agent-secrets/my-app.env; set +a
cd ~/src/my-app
box run claude-api
```

For path B instead, point the terminal at your AWS profile, set the model in the profile as Box's getting-started page says (`ANTHROPIC_MODEL` under `[agent.env]`, the full Bedrock model ID), and run `box run claude`:

```sh
export AWS_PROFILE=your-profile
aws sts get-caller-identity
box run claude
```

If your AWS profile signs in with IAM Identity Center (SSO), Box's docs say it can't read that yet: run `aws sso login`, then `eval "$(aws configure export-credentials --format env)"` in the same terminal.

## 9. Watch the box work (not run yet with Claude Code)

Box's getting-started page gives two checks. Ask Claude Code to:

1. Create `hello.txt` with the word hi in it. The file shows up in `~/src/my-app`.
2. Run `echo hi > ~/outside.txt` in its shell. The docs say the box stops the command and Claude Code tells you it couldn't write the file. Press **Ctrl+]** to open the banner and see the denial.

Then ask it to print `ANTHROPIC_API_KEY`. Per Box's docs, it holds a placeholder, not your key. The probe in Part 3 saw exactly that from a shell: `sk-ant-` and 64 hex characters, different on each run.

Quit with `/exit`. Box prints the run's box ID and a `history` line.

## 10. The gap, on purpose (not run yet with Claude Code)

Box's limitations page says the project folder, `.env` files included, is readable by the agent by default. Show it:

1. Put the fake canary back in the project: `printf 'ANTHROPIC_API_KEY=sk-ant-fake-canary-not-a-real-key\n' > ~/src/my-app/.env`
2. Comment out the `[filesystem]` table from step 7 and start `box run claude-api` again.
3. Ask Claude Code to show the contents of `.env`. Per the docs, it can read it: the box didn't protect a file you put in its project. Part 3's probe read it from a shell, canary and all.
4. Put the `[filesystem]` table back, start a new run, and ask again. Per the docs, the read is refused. In Part 3's probe, a shell read nothing from the file. When the box's shell is the one refused, its message names the deny list; the docs show it for a denied folder:

   ```text
   strands-shell: cat: policy denied this operation on '~/src/my-app/secrets/key' [policy: filesystem_deny_read_0]: The profile's [filesystem] deny keeps this path out of the box.
   ```

   If Claude Code uses its own Read tool instead, the operating-system sandbox refuses it with an error such as `operation not permitted`.
5. Delete the canary: `rm ~/src/my-app/.env`.

Then list what the box refused in the last run:

```sh
box runs list
box runs history <box ID> --deny
```

Box's docs note that a refusal by the operating-system sandbox (`operation not permitted`) isn't a policy decision, so it doesn't show in the banner or the history. After the probe's denied read, `box runs history <box ID> --deny` printed `No denied policy decisions recorded.`

## 11. Check the project after every run

The agent can't leave the box, but it can write files that run *outside* it later: git hooks, `.git/config`, `.claude/settings.json`, `package.json` scripts, `.envrc`. Box's limitations page gives the check. [`scripts/after-run-check.sh`](scripts/after-run-check.sh) runs it in order and stops before any `git` command when `.git/config` or the hooks hold something to read first (git itself would run a planted `core.fsmonitor`):

```sh
sh scripts/after-run-check.sh ~/src/my-app
```

Tested on both machines with a clean repo (exit 0) and with a planted `pre-commit` hook and `core.fsmonitor` (it stops with `STOP: read the lines above before running git here.` and exit 2).

## 12. Clean up

```sh
box profile clean --all            # removes the run records; asks first
rm -rf ~/src/my-app                # the throwaway project
rm ~/.config/agent-secrets/my-app.env
```

To remove Box itself (from its install page): `rm -rf ~/.strands/box/packages` and `rm ~/.local/bin/box`, or delete `~/.strands/box` to drop profiles and records too.

## What this doesn't cover

Box limits what the agent reaches. It doesn't cap what a key can spend, expire keys, or see what someone pastes into a browser. [Part 2](../part-2-keep-the-real-key-off-the-laptop/) and [Part 3](../part-3-what-strands-box-changes/) cover those.

Something different on your machine? See [`known-gaps.md`](known-gaps.md), and open an issue if it isn't there.
