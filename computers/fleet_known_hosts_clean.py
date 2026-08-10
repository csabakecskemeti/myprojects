import os, re, shutil, time
p = os.path.expanduser('~/.ssh/known_hosts')
if not os.path.isfile(p):
    print("no known_hosts"); raise SystemExit
KEY = re.compile(r'^(ssh-rsa|ssh-dss|ssh-ed25519|ecdsa-sha2-\S+|sk-ssh-ed25519@\S+|sk-ecdsa-sha2-\S+)$')
lines = open(p).read().split('\n')
good, bad = [], 0
for l in lines:
    if not l.strip() or l.lstrip().startswith('#'):
        good.append(l); continue
    f = l.split()
    if len(f) >= 3 and KEY.match(f[1]):
        good.append(l)
    else:
        bad += 1
if bad:
    shutil.copy2(p, f"{p}.bak.{time.strftime('%Y%m%d-%H%M%S')}")
    open(p, 'w').write('\n'.join(good))
    os.chmod(p, 0o600)
print(f"removed {bad} malformed line(s); {len([l for l in good if l.strip() and not l.lstrip().startswith('#')])} valid remain")
