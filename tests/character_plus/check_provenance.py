#!/usr/bin/env python3
"""Verify unchanged original routine bytes within the maintained closure."""
from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parent

def check(source=None):
 p=json.loads((ROOT/'provenance.json').read_text());b=(ROOT/p['wrapper']).read_bytes()
 assert hashlib.sha256(b).hexdigest()==p['wrapper_sha256']
 for routine in p['routines']:
  start=b.index(('elemental function '+routine['name']+'(').encode())
  marker=('end function '+routine['name']).encode();end=b.index(marker,start)+len(marker)+2
  raw=b[start:end];assert raw.endswith(b'\r\n')
  assert len(raw)==routine['bytes'] and hashlib.sha256(raw).hexdigest()==routine['sha256']
 if source:
  raw=Path(source).read_bytes();assert hashlib.sha256(raw).hexdigest()==p['source_sha256']
  lines=raw.splitlines(keepends=True)
  for routine in p['routines']:
   part=b''.join(lines[routine['start_line']-1:routine['end_line']]);assert hashlib.sha256(part).hexdigest()==routine['sha256'];assert part in b
 return len(p['routines'])
if __name__=='__main__':
 import sys
 print('PASS: exact original routines:',check(sys.argv[1] if len(sys.argv)>1 else None))
