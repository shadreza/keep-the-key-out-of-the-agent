# Part 3: What AWS's Strands Box changes

Part 2's plan kept the real keys on servers, but the coding agent itself still ran with whatever the laptop could reach. [Strands Box](https://github.com/strands-agents/box) goes at that gap. It's open source (Apache 2.0) from Strands Agents, the AWS open-source agent project, and in preview.

Two ideas carry it:

1. **Rules the agent can't change.** The agent runs in an operating-system sandbox. Its own file tools reach only what the profile grants. Every shell command, network request and MCP tool call goes through a policy check that runs outside the model, so nothing the agent reads can change the answer.
2. **The agent never holds the key.** A route in the profile names the hosts a key may go to and where the key comes from, such as a variable in your shell. Inside the box, the agent sees a placeholder. Box puts the real key in as the request leaves for one of those hosts.

![The coding agent in an OS sandbox sees a placeholder; the real key sits in a file outside, read by a Box route, and is added at the edge on the way to the model provider.](../docs/diagrams/part-3-placeholder-key.png)

## Try it with no model

[`probe/`](probe/) runs a plain shell in a box instead of a coding agent. It needs no model, no account and no key, and costs nothing. It shows both ideas, and the gap Box's own docs warn about.

Install Box first ([Part 4, step 1](../part-4-hands-on/README.md#1-install-box)). Then:

```sh
sh part-3-what-strands-box-changes/probe/run-probe.sh
```

It makes a throwaway project with a fake canary key in `.env`, puts a fake "real" key in your shell, and runs the probe twice: once with [`probe-open.toml`](probe/probe-open.toml), once with [`probe-deny.toml`](probe/probe-deny.toml), which adds three lines to keep the `.env` out. On a Linux laptop with box 0.3.0 on 24 November 2026 it printed:

```text
Your shell holds: sk-ant-stand-in-for-your-real-key
The project's .env holds a fake canary key.

== box run probe-open.toml
1. ANTHROPIC_API_KEY inside the box: sk-ant-f5856750f730cf325b377b945d4ec96ab8f6c5317c2fafb4423026c07db62ab1
2. .env in the project: readable: ANTHROPIC_API_KEY=sk-ant-fake-canary-not-a-real-key
3. write hello.txt in the project: ok
4. write ~/outside-the-box.txt: refused

== box run probe-deny.toml
1. ANTHROPIC_API_KEY inside the box: sk-ant-59ed1ca18aceac041e2d0c284ac02d7158d07ba10c982d697b55385736253fcd
2. .env in the project: nothing could be read
3. write hello.txt in the project: ok
4. write ~/outside-the-box.txt: refused
```

Read it line by line:

1. The key in your shell never entered the box. The agent got a placeholder that starts with `sk-ant-`, and a new one each run.
2. **The gap.** Without the deny, the `.env` in the project was readable, canary and all. The box limits the agent to the project, and the `.env` was in the project. With the deny, nothing could be read.
3. The project is the agent's to write in.
4. Your home folder isn't.

If the box doesn't start, see [known gaps](../part-4-hands-on/known-gaps.md). On a laptop whose home folder is on btrfs, a new box stopped once and ran when started again with its box ID (known gap 5).

## Box against the plan

![The things Box doesn't do, below the laptop: spending caps, key expiry, browser paste, GitHub and the fleet.](../docs/diagrams/part-3-box-against-the-plan.png)

| Part of the plan | Does Box cover it? | Why |
| --- | --- | --- |
| An AI gateway with personal, capped keys that expire within 2, 4 or 8 hours | No | Box adds a key; it doesn't cap spending or expire keys |
| A zero-trust layer that blocks direct calls to AI providers | On the laptop, for the agent | Scoped and Locked policies reach only allowed hosts, but only inside the box |
| A small CLI: short-lived AWS sign-in, secrets at run time, no `.env` | Partly | Routes pass secrets in at run time; the sign-in is still yours to set up |
| A laptop checker | No | Box guards one run, it doesn't report on the laptop |
| Desktop AI app checks | No | Box runs terminal agents |
| A browser extension against pasted secrets | No | Nothing a browser does goes through the box |
| A control plane and dashboard | No | Run history is per machine |
| Automated key rotation | No | A route reads the key; it doesn't rotate it |
| Device management | No | Box has starters for one standard setup, but something still has to install them |
| GitHub guardrails | No | Commits and repository settings are outside the run |
| Full traffic inspection, later | No | Box sees the agent's requests, not the laptop's |

Box covers one thing well, the thing the plan only watched from the side: what the agent itself can do while it works.

## What Box's docs say it doesn't protect

From [What a box does not protect](https://github.com/strands-agents/box/blob/main/docs/cli/limitations.md), in plain words:

- The project folder is open to the agent by default, `.env` files included. The probe above shows it.
- A policy rule like "never read `.env`" decides only the box's shell and Python. The agent's own file tools follow the profile, so the deny goes in the profile's `[filesystem]` table, as in `probe-deny.toml`.
- The agent can write files that run later, outside the box: a git hook, `.claude/settings.json`, a `package.json` script, an `.envrc`. Part 4's `after-run-check.sh` checks for them.
- One profile is shared by every project you run it in.
- Run records are a plain file, not a tamper-proof log.

So, the `.env`: keep it out of the project, and let Box add the key on the way out. That closes the agent's path to the key, not every path on the laptop, which is why the rest of the plan stays.

Next: [Part 4, Claude Code in a box](../part-4-hands-on/).

## Sources

- Strands Box: <https://strandsagents.com/box/> and <https://github.com/strands-agents/box>
- How Box works: <https://github.com/strands-agents/box/blob/main/docs/cli/how-box-works.md>
- What a box does not protect: <https://github.com/strands-agents/box/blob/main/docs/cli/limitations.md>
- AWS Developers video, "Sandbox Your AI Agents in One Command with Strands Box": <https://www.youtube.com/watch?v=Z18kFF3uhSA>
