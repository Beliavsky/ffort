import hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parent
def check():
 p=json.loads((ROOT/'provenance.json').read_text());raw=(ROOT/p['source']).read_bytes()
 assert hashlib.sha256(raw).hexdigest()==p['source_sha256']
 body=b''.join(raw.splitlines(keepends=True)[p['first_line']-1:p['last_line']])
 assert hashlib.sha256(body).hexdigest()==p['body_sha256']
 for name in p['wrappers']:
  data=(ROOT/name).read_bytes();assert data.count(body)==1,name
  assert b'isnan_real' not in data and b'interface isnan' not in data
 return p
if __name__=='__main__':
 check();print('PASS: exact full quick_sort with original nested procedures and no ISNAN replacement')
