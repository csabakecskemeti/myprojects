# My Projects

Git-based project tracker and knowledge base.

## Quick Start

```bash
# Scan local repos
./scripts/scan-repos.sh ~/Documents/workspace ~/code

# Analyze a specific repo
./scripts/analyze-repo.sh /path/to/repo
```

## Computers

See [computers/](computers/) for registered machines and their local paths, plus the
fleet config and secret distribution mechanism ([FLEET-MANAGEMENT.md](computers/FLEET-MANAGEMENT.md)).

## AI Infra

See [ai-infra/](ai-infra/) for the DGX Spark cluster, how it is served (vLLM + LiteLLM),
how it is reached from anywhere (`spark.devquasar.com`), auth and key rotation, and the
operational runbook.

## Projects

See [projects/](projects/) for tracked projects and their metadata.
