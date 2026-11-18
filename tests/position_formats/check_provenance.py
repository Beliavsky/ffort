from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parent
def check():
 p=json.loads((ROOT/'upstream.json').read_text())
 for f in p['files']:
  raw=(ROOT/f['file']).read_bytes();assert len(raw)==f['bytes'] and hashlib.sha256(raw).hexdigest()==f['sha256'],f['file']
 assert hashlib.sha256((ROOT/p['license_file']).read_bytes()).hexdigest()==p['license_sha256']
 return p
if __name__=='__main__':check();print('PASS: unchanged complete COS/COSD programs and license')
