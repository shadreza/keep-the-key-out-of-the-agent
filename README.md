# Keep the key out of the agent

The code, exercises and tested steps for a four-part series on AI keys and coding agents.

A leaked AI key once ran up about $8,000 on a project's bill, and we never found out how it leaked. This series follows what came after: where a key can sit on a laptop that runs a coding agent, the plan we wrote to keep real keys off laptops, what AWS's open-source [Strands Box](https://github.com/strands-agents/box) changes, and a hands-on where Claude Code runs in a box and never holds the real key.

The articles and videos explain the why. This repo holds everything you run. Clone it once and follow the parts in order, or jump to the one you need.

```sh
git clone https://github.com/shadreza/keep-the-key-out-of-the-agent.git
cd keep-the-key-out-of-the-agent
```

## The parts

| Part | Folder | What you do there | Needs |
| --- | --- | --- | --- |
| 1. The $8,000 key | [`part-1-the-8000-key/`](part-1-the-8000-key/) | Find every key a coding agent can see in one of your projects, including the ones Git still remembers | git |
| 2. Keep the real key off the laptop | [`part-2-keep-the-real-key-off-the-laptop/`](part-2-keep-the-real-key-off-the-laptop/) | Audit one laptop against the plan, on paper | nothing |
| 3. What AWS's Strands Box changes | [`part-3-what-strands-box-changes/`](part-3-what-strands-box-changes/) | Run a probe in a box and see the placeholder key and the `.env` gap, with no model and no cost | Box |
| 4. Hands-on: Claude Code in a box | [`part-4-hands-on/`](part-4-hands-on/) | Move the `.env` out, give Box a route for the key, run Claude Code, break it on purpose, check the project after, and write your own Dogwood policy rules | Box, Claude Code, a model key or Amazon Bedrock |

![Before and after: the .env with the real key sits inside the project and the box, then it moves outside and the agent sends a placeholder that Box swaps for the real key on the way to api.anthropic.com.](docs/diagrams/part-4-env-route.png)

## Where to start

- You have ten minutes: run Part 1's `find-keys.sh` on a project you work on.
- You want to see a box work without paying for anything: install Box ([Part 4, step 1](part-4-hands-on/README.md#1-install-box)), then run [Part 3's probe](part-3-what-strands-box-changes/README.md#try-it-with-no-model).
- You're setting this up for real: Part 4, from the top.
- You want to write policy rules: [Part 4, step 12](part-4-hands-on/README.md#12-write-your-own-rules-dogwood).

## What was tested, and where

Box is in preview, and v0.3.0 came out on 23 November 2026, the day these steps were first tested. Everything here says what ran and what didn't.

| What | Where it ran | Result |
| --- | --- | --- |
| Install, profiles, the key route, the `.env` deny in the profile | Debian 12, x86_64, box 0.3.0 (23 Nov 2026), and again on an Arch-based Linux laptop, x86_64, box 0.3.0 (24 Nov 2026) | As shown in [`part-4-hands-on/captured/`](part-4-hands-on/captured/) |
| A box starting, the placeholder key, the `.env` gap and the deny (Part 3's probe) | The Arch-based laptop | Ran; on the btrfs home folder each new box needed a second start ([known gap 5](part-4-hands-on/known-gaps.md#5-a-new-box-stops-once-when-its-home-is-on-btrfs)) |
| Four Dogwood rules of your own (a forbid, a no-delete, GET only, a count over ten minutes), with a shell in place of the agent | The Arch-based laptop | Each refused what it should, and the run history named the rule ([`captured/10-policy-probe.txt`](part-4-hands-on/captured/10-policy-probe.txt)) |
| `find-keys.sh`, `move-env-out.sh`, `after-run-check.sh` | Both machines, on clean and planted test repos | Ran |
| Claude Code starting in a box, its request going through the key route | The Arch-based laptop, Claude Code 2.1.330 | Started; with a fake key, Anthropic answered `Invalid API key`, so the route reached it ([`captured/11`](part-4-hands-on/captured/11-claude-in-a-box-fake-key.txt)) |
| Claude Code answering with a real key inside a box | Not yet | Steps 8 to 10 of Part 4 come from Box's docs until then |

If you see something different, open an issue with the command and what it printed. Known differences go in [`part-4-hands-on/known-gaps.md`](part-4-hands-on/known-gaps.md).

## Safety

- Every key in this repo is fake on purpose (`sk-ant-fake-canary-not-a-real-key`, `sk-ant-stand-in-for-your-real-key`). Never commit a real one, here or anywhere.
- Use a throwaway project for Parts 3 and 4, not one with real client data.
- Box is free. The model isn't. Before Part 4, set a spending limit on the key or a budget on the AWS account you use.

## Read and watch

The articles are on [devops-stories.hashnode.dev](https://devops-stories.hashnode.dev) and the videos on [YouTube @nocturops](https://www.youtube.com/@nocturops), in the series *Keep the key out of the agent*. By [Shad](https://www.linkedin.com/in/shadreza100).

Strands Box is an AWS open-source project, Apache 2.0: <https://github.com/strands-agents/box>. This repo isn't part of it and isn't affiliated with AWS. Every Box command here comes from Box's own docs, which are the source of truth when they change.
