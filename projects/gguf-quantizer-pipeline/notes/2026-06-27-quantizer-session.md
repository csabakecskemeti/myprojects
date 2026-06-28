---
date: 2026-06-27
tags: [quantizer, v4, reorganizer, validator, session-notes]
---

# Session: quantizer v4, hf_repo_reorganizer, hf_quant_validator_v2

## What was built

### quantizer_v3.1.py
- Based on v3.0, adds `--no-mtp` flag to main model conversion only
- Bugfix: removed `--no-mtp` from mmproj (vision head) conversion — it uses `--mmproj` only

### quantizer_v4.py (new)
Key additions over v3.1:
- **Parallel quant+upload**: while uploading current quant, starts next if free space > 4x file size
- **Per-quant HF subfolders**: each quant uploaded to `Q4_K_M/<filename>`, not root
- **Split threshold raised to 49 GB** (HF XET supports large files; old 39 GB limit was conservative)
- **`--keepquant/-kq TYPE`**: re-runs one quant at end, keeps file locally (excluded from main loop)
- **`--smoketest/-st`**: runs `./build/bin/llama-simple -m <file> -ngl 0 -n 32` on kept file
- **`--targetquants/-tq LIST`**: subset of quants, e.g. `2,3,5` maps via QUANT_MAP
- **`--continue`**: calls check_completed_quants() via HF API, skips already-uploaded types
- **Lock file** `/tmp/quantizer_v4.lock`: warns if another instance is running
- **Disk space** reported at startup; checked before each quant for overlap decision

### hf_repo_reorganizer.py (new)
- Moves flat HF repos into per-quant subfolders via CommitOperationCopy+Delete (server-side, zero bytes)
- QUANT_RE covers Q2-Q8, IQ1-IQ4, TQ1/TQ2, MXFP4_MOE, BF16/F16/F32
- `--org ORG` mode: scans all GGUF repos, finds flat ones, reorganizes interactively
- DevQuasar scan result (2026-06-27): 1087 total, 1042 GGUF, 0 needed reorganization

### hf_quant_validator_v2.py (new, in sandbox)
- v2 of the validator with folder-aware parsing
- `_layout()` returns 'flat' or 'folder' based on file paths
- `parse_gguf_files()`: uses folder name as authoritative quant key when it matches FOLDER_RE
- `--needs-reorg` flag (org mode): lists repos still using flat layout
- Reports layout type in output

## Bugs fixed during session

1. **--no-mtp on mmproj**: v3.1 initially added --no-mtp to mmproj command. Removed — mmproj is `--mmproj` only.
2. **Double upload of keepquant type**: keepquant was processed in both the main loop (split→upload→delete) AND do_keepquant (single file→upload→keep). Fixed: exclude keepquant from main loop's effective_quant_types.
3. **-h treated as model name**: `-h` fell through positional arg parser. Fixed: check for -h/--help before acquire_lock().
4. **Org scan 0 repos**: user tried non-existent org names. Fixed: added total model count display, clear error, tag-based GGUF detection.
5. **MXFP4_MOE not matched**: added to QUANT_RE in both reorganizer and validator v2.
6. **--dryrun before repo_id**: sys.argv[1] was --dryrun, not repo_id. Fixed: find first non-flag positional arg.

## Key design decisions

- **SPACE_MULTIPLIER=4**: split temporarily doubles size, two simultaneous quants = 4x worst case
- **49 GB threshold**: HF XET storage (content-addressed chunked) supports 100GB+ files; 49 GB is conservative for older client compat
- **keepquant excluded from main loop**: prevents double-upload (split parts + full file in same folder)
- **CommitOperationCopy is server-side**: for XET/LFS files it's pure metadata — reorganizer downloads nothing
