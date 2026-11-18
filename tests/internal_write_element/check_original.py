#!/usr/bin/env python3
"""Check complete fixture inventory and raw untouched utility-body provenance."""
from pathlib import Path
import argparse,hashlib,json
ROOT=Path(__file__).resolve().parent

def main():
 p=argparse.ArgumentParser();p.add_argument('--original',type=Path,default=ROOT.parent/'utilities_slices/source/xutilities.f90');a=p.parse_args();m=json.loads((ROOT/'manifest.json').read_text());expected={c['name']+'.f90'for c in m['cases']};actual={p.name for p in (ROOT/'cases').glob('*.f90')}
 if len(expected)!=len(m['cases'])or expected!=actual:raise SystemExit('Fixture inventory differs')
 for c in m['cases']:
  p=ROOT/'cases'/(c['name']+'.f90')
  if hashlib.sha256(p.read_bytes()).hexdigest()!=c['source_sha256']:raise SystemExit('Fixture SHA-256 differs: '+c['name'])
 raw=a.original.read_bytes()
 if hashlib.sha256(raw).hexdigest()!=m['original_source_sha256']:raise SystemExit('Original utility SHA-256 differs')
 lines=raw.splitlines(keepends=True);fixture=(ROOT/'cases/original_integer_labels.f90').read_bytes()
 for (start,end),wanted in zip(m['raw_body_line_ranges'],m['raw_body_sha256']):
  body=b''.join(lines[start-1:end])
  if hashlib.sha256(body).hexdigest()!=wanted or fixture.count(body)!=1:raise SystemExit('Raw utility body or CRLF differs')
 print('PASS:44 fixture hashes/inventory and two exact original CRLF procedure bodies')
if __name__=='__main__':main()
