#!/usr/bin/env python3
"""Audit raw original bodies; never normalize CRLF or rewrite either source."""
import argparse,hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parent

def main():
 p=argparse.ArgumentParser();p.add_argument('--original',type=Path,default=ROOT.parent/'utilities_slices/source/xutilities.f90');a=p.parse_args()
 m=json.loads((ROOT/'manifest.json').read_text());raw=a.original.read_bytes();lines=raw.splitlines(keepends=True);fixture=(ROOT/'cases/original_repeat_and_str_int.f90').read_bytes()
 if hashlib.sha256(raw).hexdigest()!=m['original_source_sha256']:raise SystemExit('Original source SHA-256 differs')
 bodies=[b''.join(lines[s-1:e]) for s,e in m['exact_body_line_ranges']]
 for body,h in zip(bodies,m['individual_body_sha256']):
  if hashlib.sha256(body).hexdigest()!=h:raise SystemExit('Original procedure SHA-256 differs')
  if fixture.count(body)!=1:raise SystemExit('Exact original procedure missing or duplicated in harness')
 joined=bytes.fromhex(m['exact_body_separator_hex']).join(bodies)
 if hashlib.sha256(joined).hexdigest()!=m['exact_body_sha256']:raise SystemExit('Joined-body SHA-256 differs')
 if joined not in fixture:raise SystemExit('Joined raw body sequence differs')
 print('PASS: both original procedure bodies preserved byte-for-byte, including CRLF')
if __name__=='__main__':main()
