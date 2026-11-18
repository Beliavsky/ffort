import hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parent

def check():
 p=json.loads((ROOT/'provenance.json').read_text());source=(ROOT/p['source']).read_bytes()
 assert hashlib.sha256(source).hexdigest()==p['source_sha256']
 lines=source.splitlines(keepends=True)
 for r in p['bodies']:
  body=b''.join(lines[r['first_line']-1:r['last_line']]);assert hashlib.sha256(body).hexdigest()==r['sha256']
  for name in p['wrappers']:assert (ROOT/name).read_bytes().count(body)==1,(name,r['name'])
 return p
if __name__=='__main__':
 check();print('PASS: three exact original filter dependency bodies in all nine drivers')
