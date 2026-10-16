# Shortlink: Operations Engineer Exercise

This is a **fictional URL shortener service** we purpose-built for interviews.
It is not our product, we do not use any part of it, and nothing you write
here goes anywhere. Rest assured, you are not doing work for us.

## The scenario

You are a new member of the team that owns shortlink, a service we are getting
ready to release as a new feature for our customers. It was recently migrated
to Terraform and Kubernetes, and the pipeline's verification gate is passing.
You have been asked to ensure that the service is production-ready before it
ships.

## Time box

**Spend 90 minutes. Please stop when the timer goes off.**

We mean this. We would much rather watch an honest 90 minutes where you got
halfway through than a carefully curated, highly polished session. We are
evaluating how you think, not whether you can finish in record time using as
few commands as possible.

## Recording your submission

Record your screen with audio for the whole session. Loom, QuickTime, OBS, or
whatever you're familiar with is fine.

**Talk through what you are doing and why.** A silent recording of someone
staring at the output of terminal commands gives us far less insight than
hearing you think out loud. We want to understand your reasoning, particularly
every time you form a theory about if/why something is broken, and every time
evidence changes your mind.

**Close the recording by telling us whether you would ship this to production
and why.**

Please send us the recording link when you are done.

## Use your own tools

Use whatever you normally use, **including AI**. Claude Code, Cursor, Copilot,
whatever your setup is. Working alongside AI agents is a core part of this
role, so we are genuinely interested in how you do it: what you ask, what you
accept, what you push back on. Please do not perform a version of yourself
that avoids the tools you would reach for on any given day. Narrate what you
ask them and what you make of the answers.

## The setup (before you start the timer)

You need [Docker](https://docs.docker.com/get-docker/),
[kind](https://kind.sigs.k8s.io/), [kubectl](https://kubernetes.io/docs/tasks/tools/),
[Terraform](https://developer.hashicorp.com/terraform/install) (1.5+), and
`make`. No AWS account is needed: all AWS APIs are served by
[LocalStack](https://www.localstack.cloud/) running inside the local cluster,
so nothing you do here touches real cloud infrastructure.

```bash
make cluster   # creates the kind cluster and starts LocalStack inside it
```

Get this working before you start your timer. Setup should not eat into your
90 minutes. If `make cluster` will not run on your machine, reach out to
whoever sent this to you and we'll sort it out.

When `make cluster` finishes, `curl http://localhost:4566/_localstack/health`
should return JSON.

## The deploy (timer starts here)

Run the same steps the pipeline runs:

```bash
make infra     # terraform apply against LocalStack
make build     # build the app image and load it into the cluster
make deploy    # apply the Kubernetes manifests
make verify    # the pipeline's verification gate — it passes
```

The service is supposed to be reachable at http://localhost:8080 after this.
Start there.

When you are done (or to start over from scratch): `make clean`, then
`make cluster` again.

## What is in here

| Path | What it is |
|---|---|
| `terraform/` | AWS resources for the service (S3 bucket, SSM config, IAM) |
| `k8s/app/` | Kubernetes manifests for the shortlink service |
| `k8s/infra/` | LocalStack, which stands in for AWS. Treat it as given. |
| `app/` | A small FastAPI service. Treat the Python as correct unless you have evidence otherwise. |
| `kind/` | Local cluster config. Treat it as given. |
| `scripts/verify.sh` | The verification gate the pipeline runs |

## What the service is supposed to do

1. On startup it reads an SSM parameter to learn which S3 bucket to use, then
   serves traffic on port 8080.
2. `GET /healthz` returns `200` with `{"status": "ok"}` when the service can
   reach its bucket.
3. `POST /api/links` with `{"url": "https://example.com"}` returns a slug.
4. `GET /r/<slug>` redirects to the original URL.
5. `make verify` passing is supposed to mean all of the above are true.

## What we're evaluating

| Area | What we're looking at |
|---|---|
| **Verification instinct** | What assumptions do you challenge? |
| **Problem solving** | How do you discover and understand issues? |
| **AI collaboration** | How effectively do you work with AI tools? |
| **Judgement** | Does functional mean shippable? How do you differentiate the two? |
| **Communication** | Can you clearly articulate your thought process as you go? |

## Questions

If you have any questions, please don't hesitate to reach out to whoever sent
this to you.
