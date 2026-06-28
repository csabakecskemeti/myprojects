---
slug: gguf-quantizer-pipeline
created: 2026-06-27
---

# GGUF Quantizer Pipeline

Full pipeline for quantizing HuggingFace LLMs to GGUF format and uploading to DevQuasar org on HuggingFace.

## Problem

Manually running llama.cpp's quantization tools across 6+ quant types for large models (70B–400B+) is tedious, error-prone, and disk-space hungry. Need to:
- Manage disk space dynamically (models can be 100–400 GB in fp16)
- Upload to HF DevQuasar org in organized folder structure
- Validate upload completeness across 1000+ repos
- Reorganize legacy flat repos into per-quant subfolders

## Solution

A suite of Python scripts in `/home/kecso/Documents/workspace/llama.cpp/`:

### quantizer_v4.py — Main pipeline script
- Downloads model from HF, converts to fp16 GGUF, quantizes to 6 types, uploads each
- Parallel quant+upload: if free disk > 4x quant size, starts next quant while uploading
- Per-quant HF subfolder: `Q4_K_M/model.Q4_K_M-00001-of-00004.gguf`
- Split large files: anything >49 GB split into 14 GB chunks
- `--keepquant/-kq TYPE`: re-runs one quant at the end, keeps file locally
- `--smoketest/-st`: runs `llama-simple -ngl 0 -n 32` on kept file to verify
- `--continue`: resumes interrupted runs, skips already-uploaded quants
- `--targetquants/-tq LIST`: run only a subset (e.g. `2,3,5`)
- Lock file prevents accidental parallel runs
- Disk space check at startup

### hf_repo_reorganizer.py — Server-side HF repo restructuring
- Moves flat GGUF files into per-quant subfolders using CommitOperationCopy+Delete
- Zero bytes transferred (server-side metadata operation only)
- Single-repo and org-wide modes
- `--org DevQuasar` scans all GGUF repos, finds flat ones, reorganizes

### hf_quant_validator_v2.py — Validation tool
- Validates all quant types in a repo have complete part sets
- Handles both flat (legacy) and folder-based (v4) repo layouts
- Org-wide scan mode with `--needs-reorg` flag for flat repos
- Location: `/home/kecso/Documents/workspace/sandbox/hf_quant_validator_v2.py`

## Tech Stack

- **Language:** Python 3
- **Key libs:** `huggingface_hub`, `tqdm`, `threading`, `shutil`
- **HF API:** `list_repo_files`, `CommitOperationCopy`, `CommitOperationDelete`, `create_commit`
- **llama.cpp tools:** `convert_hf_to_gguf.py`, `llama-quantize`, `llama-gguf-split`, `llama-simple`
- **Upload target:** HuggingFace DevQuasar org

## Current State

- [x] quantizer_v3.1.py — stable, --no-mtp on main model only
- [x] quantizer_v4.py — all features implemented, needs real-model test
- [x] hf_repo_reorganizer.py — working, includes org mode
- [x] hf_quant_validator_v2.py — folder-aware, --needs-reorg flag
- [ ] quantizer_v4.py real-model end-to-end test
- [ ] Check if any DevQuasar repos still need reorganization

## Key Files

- `quantizer_v4.py` — main quantizer (llama.cpp workspace root)
- `quantizer_v3.1.py` — previous stable version
- `hf_repo_reorganizer.py` — HF repo reorganization tool
- `/home/kecso/Documents/workspace/sandbox/hf_quant_validator_v2.py` — validator v2

## Constants & Config

```python
DEFAULT_TEMP_STORAGE = '/media/kecso/8t_nvme'
UPLOAD_PREFIX = 'DevQuasar'
UPLOAD_SUFFIX = '-GGUF'
LOCK_FILE = '/tmp/quantizer_v4.lock'
SPACE_MULTIPLIER = 4       # need 4x free space to overlap quant+upload
MAX_FILE_SIZE = 49 * 1024**3   # 49 GB before splitting
SPLIT_SIZE = '14G'
DEFAULT_QUANT_TYPES = ['Q2_K', 'Q4_K_M', 'Q5_K_M', 'Q3_K_M', 'Q8_0', 'Q6_K']
QUANT_MAP = {'2':'Q2_K', '3':'Q3_K_M', '4':'Q4_K_M', '5':'Q5_K_M', '6':'Q6_K', '8':'Q8_0'}
```

## Example Commands

```bash
# Full run with all quants
python3 quantizer_v4.py deepreinforce-ai/Ornith-1.0-397B

# Only Q2 and Q3, keep Q3 for smoke test
python3 quantizer_v4.py deepreinforce-ai/Ornith-1.0-397B \
    --targetquants 2,3 --keepquant Q3_K_M --smoketest

# Resume interrupted run
python3 quantizer_v4.py deepreinforce-ai/Ornith-1.0-397B --continue

# Dry run to preview
python3 quantizer_v4.py SomeOrg/SomeModel --dryrun --keepquant Q4_K_M --smoketest

# Reorganize a single flat HF repo into subfolders (server-side)
python3 hf_repo_reorganizer.py DevQuasar/nvidia.Llama-3.3-Nemotron-70B-Reward-Principle-GGUF

# Reorganize all flat repos in DevQuasar org
python3 hf_repo_reorganizer.py --org DevQuasar --dryrun

# Validate a repo
python3 /home/kecso/Documents/workspace/sandbox/hf_quant_validator_v2.py \
    DevQuasar/nvidia.Llama-3.3-Nemotron-70B-Reward-Principle-GGUF

# Find flat repos in org that need reorganization
python3 /home/kecso/Documents/workspace/sandbox/hf_quant_validator_v2.py \
    --org DevQuasar --needs-reorg
```

## Key Rules / Gotchas

- `--no-mtp` applies to **main/text model conversion ONLY** — never to mmproj (image head)
- mmproj uses `--mmproj` flag, never `--no-mtp` (they are mutually exclusive)
- `keepquant` type is excluded from the main loop — handled exclusively by `do_keepquant()`
- HuggingFace XET storage: 49 GB soft limit (up from legacy 39 GB LFS limit)
- SPACE_MULTIPLIER=4: split temporarily doubles size, two simultaneous quants = 4x worst case
- CommitOperationCopy is server-side for LFS/XET — no file download needed for repo moves
- DevQuasar org scan (2026-06-27): 1087 total repos, 1042 GGUF, all already folder-organized

## Related

- [Session notes 2026-06-27](./notes/2026-06-27-quantizer-session.md)
