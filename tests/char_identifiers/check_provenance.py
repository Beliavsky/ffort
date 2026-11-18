#!/usr/bin/env python3
"""Verify original utility body bytes, not normalized source text."""
import hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parent

def check():
 p=json.loads((ROOT/'provenance.json').read_text())
 source=(ROOT/p['source']).read_bytes()
 assert hashlib.sha256(source).hexdigest()==p['source_sha256'],'source hash mismatch'
 wrapper=(ROOT/p['wrapper']).read_bytes()
 assert hashlib.sha256(wrapper).hexdigest()==p['wrapper_sha256'],'wrapper hash mismatch'
 lines=source.splitlines(keepends=True)
 for r in p['bodies']:
  body=b''.join(lines[r['first_line']-1:r['last_line']])
  assert len(body)==r['bytes'] and hashlib.sha256(body).hexdigest()==r['sha256'],r['name']+' body mismatch'
  assert wrapper.count(body)==1,r['name']+' exact body missing/duplicated'
 return p
if __name__=='__main__':
 check();print('PASS: original positions_char_string and two original helper bodies')
