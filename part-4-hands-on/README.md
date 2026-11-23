# Part 4, hands-on: run Claude Code in a Strands Box, with the key outside

Part 4 of 4 in *Keep the key out of the agent*. You move a project's `.env` out of the project, give Box a route for the model key, and run Claude Code in a box. Then you leave a fake key in the project on purpose and see what the box does and doesn't stop.

Run every command from this folder:

```sh
git clone https://github.com/shadreza/keep-the-key-out-of-the-agent.git
cd keep-the-key-out-of-the-agent/part-4-hands-on
```

## What was tested

- **2026-11-23**, box 0.3.0 on Debian GNU/Linux 12 (x86_64, glibc 2.36), git 2.39.5, Claude Code 2.1.325: steps 1 to 7 and step 11. Output in [`captured/`](captured/). The box itself didn't start there ([known gap 3](known-gaps.md#3-the-box-didnt-start-on-the-test-machine)).
- **2026-11-24**, box 0.3.0 on an Arch-based Linux laptop (x86_64, glibc 2.44), git 2.56.0: steps 1 to 7 again, and a box started with a plain shell in place of Claude Code. The shell saw a placeholder instead of the key, read the `.env` without the deny, and read nothing with it ([`captured/08-probe-on-a-laptop.txt`](captured/08-probe-on-a-laptop.txt), and [Part 3's probe](../part-3-what-strands-box-changes/README.md#try-it-with-no-model) to run it yourself). On the btrfs home folder each new box stopped once and ran when started again with its box ID ([known gap 5](known-gaps.md#5-a-new-box-stops-once-when-its-home-is-on-btrfs)).
- **2026-11-24**, same laptop: step 12's rules, with a shell in place of the agent ([`captured/10-policy-probe.txt`](captured/10-policy-probe.txt)).
- **2026-11-24**, same laptop, Claude Code 2.1.330: Claude Code started in a box, and with a fake key its request reached `api.anthropic.com` through the route, which answered `Invalid API key` ([`captured/11-claude-in-a-box-fake-key.txt`](captured/11-claude-in-a-box-fake-key.txt)). So the route works end to end; only the real key is missing.
- **Not run yet:** Claude Code answering with a real key inside a box (steps 8 to 10). Those steps come from Box's docs. If what you see differs, open an issue.

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

It prints the paths on your machine (here, a home folder of `/home/you`):

```text
moved /home/you/src/my-app/.env
   to /home/you/.config/agent-secrets/my-app.env (mode 600)
load it in the terminal you run box from:
   set -a; . "/home/you/.config/agent-secrets/my-app.env"; set +a
```

Now put your **real** key in that file, in place of the fake one. The project no longer holds any key.

Then load it into this terminal. Copy the `set -a` line *your* terminal printed, not the one above, or use `~`:

```sh
set -a; . ~/.config/agent-secrets/my-app.env; set +a
```

Box reads the key from this terminal, in step 5 as well as in step 8. Without it, step 5 stops with `credential variable ANTHROPIC_API_KEY is not set` (path A only).

### Check this machine

[`scripts/preflight.sh`](scripts/preflight.sh) checks what tripped people up: `box` on the path, the `claude` that Box will start, the key in this terminal, and the file system Box keeps its boxes on. It changes nothing and never prints the key.

```sh
sh scripts/preflight.sh
```

Each line starts with `ok`, `note` (read it, it changes a later step) or `FIX` (do it, then run the check again). It ends with `Ready for step 5.` when there's nothing to fix.

## 5. Create the profile

A profile tells Box which agent to run, which model service it may reach, and which policy it starts from. Pick the Scoped policy: the agent reaches only the hosts your packs and profile allow.

**Path A, Anthropic API key:**

```sh
box profile create claude-api --with claude,anthropic --policy scoped
```

If you installed Claude Code with **mise** (or another version manager), `claude` on your path is the manager's wrapper, and Box would start that instead of Claude Code (the check above says so). Name the real program:

```sh
box profile create claude-api --with claude,anthropic --policy scoped --option claude.path="$(mise which claude)"
```

The path has the version in it, so after you upgrade Claude Code, run this again with `--force` and add step 7's table back ([known gap 6](known-gaps.md#6-a-version-managers-claude-isnt-claude-code)). To change a profile that already exists, add `--force`: it writes a new `profile.toml`, so step 7's lines go too.

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

## 8. Run Claude Code in the box (tested up to the model's answer)

Start the agent from the project, in the terminal that holds the key. In a new terminal, run step 4's `set -a` line first, or `box run` stops with `credential setup failed: credential variable ANTHROPIC_API_KEY is not set`.

```sh
cd ~/src/my-app
box run claude-api
```

If the box stops at once with `its first-use contents changed before the record write`, your home folder is probably on btrfs. Start it again with the box ID it printed on its `reuse` line ([known gap 5](known-gaps.md#5-a-new-box-stops-once-when-its-home-is-on-btrfs)):

```sh
box run claude-api --box-id b-…        # the ID from the reuse line
```

If it stops with `unexpected argument '--append-system-prompt-file'` and a `mise` usage line, Box started mise's wrapper: make the profile again with step 5's mise line.

On the laptop, Claude Code started in the box (`box run claude-api -- --version` printed `2.1.330 (Claude Code)`). With the fake canary still in the key file, a prompt went through the route to `api.anthropic.com`, which turned the canary down:

```text
$ box run claude-api --no-banner -- -p "say hi"
Invalid API key · Fix external API key
```

`box runs history` showed the route at work, `permit` with the rule `route_anthropic_request` ([`captured/11-claude-in-a-box-fake-key.txt`](captured/11-claude-in-a-box-fake-key.txt)). With your real key in the file, the same request gets an answer.

Started from the project, it looks like this. The bottom line is Box's banner: the profile, the project, and how many operations it has refused so far.

![Claude Code 2.1.330 open in ~/src/my-app inside a box. The bottom line reads: box, claude-api, ~/src/my-app, 10 operations denied, with Ctrl+\\ for policy on or off and Ctrl+] to expand.](../docs/images/claude-in-box.png)

The 10 refusals came before any prompt. `box runs history <box ID> --deny` listed them:

```text
6  http:request  api.anthropic.com:443/api/event_logging/v2/batch  enforcement:egress
1  http:request  api.anthropic.com:443/api/directory/server-urls   enforcement:egress
2  net:connect   downloads.claude.ai:443                           <default-deny>
1  net:connect   raw.githubusercontent.com:443                     <default-deny>
```

Two kinds, both the box doing its job:

- **`enforcement:egress`**: the request went to the right host but carried no placeholder key, so Box wouldn't add the real one (`refusing to attach a secret to a request that presents no placeholder`). Box adds your key only where the agent presented the placeholder. Later requests to the same address that did carry it went through.
- **`<default-deny>`**: hosts that no pack allows. Here Claude Code's updater (`downloads.claude.ai`) and a file from GitHub. The Scoped policy keeps the agent to the hosts your packs name.

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

Run it from this folder (if you're still in `~/src/my-app`, `cd -` brings you back):

```sh
sh scripts/after-run-check.sh ~/src/my-app
```

Tested on both machines with a clean repo (exit 0) and with a planted `pre-commit` hook and `core.fsmonitor` (it stops with `STOP: read the lines above before running git here.` and exit 2).

## 12. Write your own rules (Dogwood)

Steps 5 to 7 used rules that `box` writes for you. This step writes your own. You'll run them with a plain shell in place of Claude Code, so it needs no model and costs nothing.

### Two places decide what the agent can touch

Before the language, the thing that trips people up. A box has two layers ([AWS's launch post](https://aws.amazon.com/blogs/opensource/introducing-strands-box-ai-agent-sandboxes-powered-by-dogwood/) calls them containment and policy):

| Layer | Set in | Decides | Example |
| --- | --- | --- | --- |
| Containment, the operating-system sandbox | `profile.toml`: `[project] access`, `[filesystem] deny`, `[agent.filesystem]` | What every process in the box can reach at all, the agent's own Read and Edit tools included | Step 7's `[filesystem] deny` for `.env` |
| Policy, Dogwood rules | `policy.dw` and any `.dw` file in the profile's `policies` list | Each command the box's shell or Python runs, each file those commands touch, each network connection and HTTP request, each MCP tool call | `forbid` reading `.env` from the shell |

Box's policies page puts it plainly: a rule that forbids reading `.env` stops `cat .env`, but not the agent's Read tool or `git diff`. The probe below shows that too (line 6). So keep secrets out with the profile, and use rules for what the agent *does*.

### How a rule reads

Dogwood uses [Cedar](https://www.cedarpolicy.com/)'s syntax. Each rule is a `permit` or a `forbid` over a principal, an action and a resource, with conditions in `when`. In Box, the principal is always the agent and the resource is fixed, so a rule matches on the action, and the details of each request are in `context.input`:

```text
@id("no_env_in_shell")                                          // its name in the run history
@description("Reading .env from the shell is blocked. Ask the person for the value you need.")
forbid (principal, action == Box::Action::"fs:read", resource)  // what kind of action
when { context.input.path like "*/.env" };                      // which ones
```

Three things to know:

- **Nothing is allowed unless a rule permits it** (`<default-deny>` in the history), and **a `forbid` always wins** over a `permit`. So a `forbid` in your file beats anything a pack allows.
- **The `@description` goes to the agent.** When a rule refuses something, the agent gets the rule's `@id` and description, so write the description as an instruction: what to do instead.
- **`like` matches with `*`**, and `*` matches any text, slashes and dots included.

The actions you'll use most (Box's policy guide lists every field):

| Action | Raised when | Fields in `context.input` |
| --- | --- | --- |
| `shell:exec` | the box's shell runs a command | `program` |
| `shell:spawn` | the shell starts a program on your machine | `program_path` |
| `fs:read`, `fs:write`, `fs:delete`, `fs:move` | a shell command or Python touches a file | `path` |
| `net:connect` | anything in the box opens a connection | `host`, `port` |
| `http:request` | anything in the box sends an HTTP request | `host`, `port`, `method`, `path` |

### Rules that remember

A rule can also depend on what already happened in the run, with a `when temporal` clause: a count, a cooldown or an order. This one allows two successful requests to a host in any ten minutes:

```text
@id("example_two_per_10m")
@description("At most two requests to example.com every 10 minutes. Wait before you try again.")
forbid (principal, action == Box::Action::"http:request", resource)
when { context.input.host == "example.com" }
when temporal {
  (count for (t: Timepoint). where (
      formerly within 10m (
          Box::Action::"http:request"::response{
              input.host: "example.com",
              output.status: 200
          } && tp(t)
      )
  )) >= 2
};
```

Read the temporal part from the inside out. The `::response{...}` pattern matches a recorded request that returned 200. `formerly within 10m` keeps those from the last ten minutes. `count for (t: Timepoint)` counts the moments, bound by `tp(t)`, when one happened. It binds on the response, so refused requests don't count; bind on `::request` to count attempts instead. AWS's launch post uses the same shape to cap an on-call agent's Slack posts at three every ten minutes.

### Try them

[`policies/examples.dw`](policies/examples.dw) has four rules, each commented: no `.env` from the shell, no deletes, one host with GET only, and the count above. [`policies/policy-probe.toml`](policies/policy-probe.toml) runs a shell in a box with them and [`policies/base.dw`](policies/base.dw), the two rules Box's starters begin with.

```sh
sh policies/run-policy-probe.sh
```

On the laptop it printed (all of it in [`captured/10-policy-probe.txt`](captured/10-policy-probe.txt)):

```text
1. shell reads notes.txt: ok
2. shell reads .env: refused
3. shell deletes notes.txt: refused
4. POST example.com: refused
5.1 GET example.com: ok
5.2 GET example.com: ok
5.3 GET example.com: refused
6. a program outside the box's shell reads .env: ok
```

Line by line: the shell reads an ordinary file (1), but not `.env` (2). No deletes (3). The POST is refused because no rule permits it, only GET (4). Two GETs go through and the third hits the count (5). And a program that isn't the box's shell, standing in for the agent's own Read tool, still reads `.env` (6): that's why step 7 keeps the file out with the profile.

The refusals carry the rule's name and description, which is what the agent sees:

```text
rm: notes.txt: policy denied this operation on '~/src/my-app/notes.txt' [policy: no_deletes]: Deleting files is blocked in this box. Say which file should go and why.
```

And `box runs history <box ID> --deny` lists each one with its rule:

```text
TIME (UTC)	RESULT	ACTION	RESOURCE	RULE	REASON
2026-11-23T20:55:26Z	deny	fs:read	~/src/my-app/.env	no_env_in_shell	a forbid rule matched
2026-11-23T20:55:26Z	deny	fs:delete	~/src/my-app/notes.txt	no_deletes	a forbid rule matched
2026-11-23T20:55:26Z	deny	http:request	example.com:443/	<default-deny>	no permit matched
2026-11-23T20:55:26Z	deny	http:request	example.com:443/	example_two_per_10m	a forbid rule matched
```

### Add rules to your own profile

Put them in a file of their own beside `profile.toml`, and list it after `policy.dw`, so Box's copied starter stays as it was:

```toml
policies = ["policy.dw", "examples.dw"]
```

Then `box profile show claude-api --full` checks the whole policy the way `box run` does: a broken rule or a clashing `@id` fails there, before a box starts. Keep write rules narrow: a rule that lets the shell write anywhere under `~/` lets it change your other tools' settings, and Box's docs warn there's no warning when a run starts with one.

To have a coding agent outside the box write rules for you, run `box help agent`; AWS also publishes a policy-authoring skill for agents. The full language guide is at <https://dogwood-policy.github.io/dogwood/>.

## 13. Clean up

```sh
box profile clean --all            # removes the run records; asks first
rm -rf ~/src/my-app                # the throwaway project
rm ~/.config/agent-secrets/my-app.env
```

To remove Box itself (from its install page): `rm -rf ~/.strands/box/packages` and `rm ~/.local/bin/box`, or delete `~/.strands/box` to drop profiles and records too.

## What this doesn't cover

Box limits what the agent reaches. It doesn't cap what a key can spend, expire keys, or see what someone pastes into a browser. [Part 2](../part-2-keep-the-real-key-off-the-laptop/) and [Part 3](../part-3-what-strands-box-changes/) cover those.

Something different on your machine? See [`known-gaps.md`](known-gaps.md), and open an issue if it isn't there.
