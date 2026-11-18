from pathlib import Path
import json,hashlib
ROOT=Path(__file__).resolve().parent
def check():
 p=json.loads((ROOT/'provenance.json').read_text());raw=(ROOT/p['wrapper']).read_bytes()
 assert hashlib.sha256(raw).hexdigest()==p['wrapper_sha256']
 for r in p['routines']:
  body=raw[r['wrapper_byte_offset']:r['wrapper_byte_offset']+r['bytes']]
  assert hashlib.sha256(body).hexdigest()==r['sha256'],r['name']
  assert b'\r\n' in body and body.count(b'\n')==r['end_line']-r['start_line']+1
 assert hashlib.sha256((ROOT/'demo_matmul.f90').read_bytes()).hexdigest()==p['matmul']['sha256']
 assert hashlib.sha256((ROOT/'M_INTRINSICS_LICENSE').read_bytes()).hexdigest()==p['matmul']['license_sha256']
 return p
if __name__=='__main__':check();print('PASS: four exact original utility bodies and complete MATMUL source/license')
