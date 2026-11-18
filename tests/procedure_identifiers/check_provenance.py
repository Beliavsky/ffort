from pathlib import Path
import json,hashlib
ROOT=Path(__file__).resolve().parent
def check():
 p=json.loads((ROOT/'provenance.json').read_text());source=(ROOT/p['source']).read_bytes()
 assert hashlib.sha256(source).hexdigest()==p['source_sha256'],'Original utilities bytes changed'
 lines=source.splitlines(keepends=True);body=b''.join(lines[p['first_line']-1:p['last_line']])
 assert hashlib.sha256(body).hexdigest()==p['body_sha256'],'Original assert_le bytes changed'
 for f in p['fixtures']:
  data=(ROOT/f['path']).read_bytes()
  assert hashlib.sha256(data).hexdigest()==f['sha256'],'Fixture changed'
  assert data.count(body)==1,'Original assert_le missing or changed'
 return p
if __name__=='__main__':
 print('PASS: original assert_le bytes and both wrappers',check()['body_sha256'])
