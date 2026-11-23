# Part 2: Keep the real key off the laptop

After the leak in Part 1, we wrote down what the team would change. The plan fits in three sentences:

> Real keys stay in AWS and never sit on a laptop. Laptops only monitor and report. The servers do the blocking.

It's a proposal. Nothing in it has been built, so this folder has no code for it, only the map and an exercise. The code starts in Part 3, with the one part of the problem the plan didn't reach.

![The plan with all eleven parts: on the laptop a coding agent with a personal, short-lived, capped key, a small CLI, a laptop checker and a browser extension; zero trust in front of an AI gateway on AWS that holds the real keys; automated response, a control plane in its own account, device management and GitHub guardrails; the direct call to the AI providers blocked.](../docs/diagrams/part-2-the-plan.png)

## The eleven parts

| Part | Where it runs | What it fixes |
| --- | --- | --- |
| AI gateway (LiteLLM on AWS) | Server | Holds the real keys. Engineers get a personal key per project that expires within 2, 4 or 8 hours and has a cost cap (the plan's numbers, not measured) |
| Zero trust (Cloudflare Zero Trust) | Network | Blocks direct calls to the AI providers, so the gateway is the only way out |
| A small CLI | Laptop | Short-lived AWS SSO sign-in, secrets passed in at run time, no `.env`, a scan before an agent starts |
| A laptop checker | Laptop | Lists AI tools, checks agent settings, finds secret files, plants fake canary keys. Sends metadata only |
| Desktop AI app checks | Laptop | Unsafe or unapproved settings in desktop AI apps |
| A browser extension | Laptop | Warns or blocks when someone pastes secrets into an AI chat site |
| Control plane | Server, its own AWS account | Collects the reports. Can't read secrets |
| Automated response | Server | Disables or rotates a leaked key |
| Device management | Server | Pushes safe settings to every laptop |
| GitHub guardrails | Server | Secret scan before each commit and in CI, a global `.gitignore` for `.env`, organisation lockdown |
| Traffic inspection | Network | Left for later: it reads people's traffic, so only with approval |

The trade: eleven parts is eleven things the team has to run, update and answer for. Count them before you copy the plan.

## The exercise: audit one laptop against the plan

No cloud account and no cost. Copy [`audit.md`](audit.md) somewhere private and fill it in for one project on your own laptop.

1. Find the keys. Part 1's [`find-keys.sh`](../part-1-the-8000-key/find-keys.sh) lists the `.env` files and what Git remembers. Add any other file that holds a real secret: config files, shell history.
2. Name the owner of each key: a person, a project, or "shared".
3. Find the limits. Does the key's account have a spending limit? Does the key expire? "Unknown" is an answer too.
4. Map each problem to the part of the plan that fixes it.
5. Write one thing your coding agent can reach on this laptop that none of the eleven parts would stop.

The expected result is a one-page table and one line on the gap. Keep it private, or delete it after: it lists where your secrets live.

## The gap the plan left

The gateway, the network layer and the GitHub guardrails protect the key on its way somewhere. None of them changes what the coding agent can do while it runs. It still reaches every file in the project and every host it can connect to.

Next: [Part 3, what AWS's Strands Box changes](../part-3-what-strands-box-changes/).
