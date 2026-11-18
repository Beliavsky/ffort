from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parent
def check():
 p=json.loads((ROOT/'provenance.json').read_text())
 assert hashlib.sha256((ROOT/p['file']).read_bytes()).hexdigest()==p['sha256']
 assert hashlib.sha256((ROOT/p['license']).read_bytes()).hexdigest()==p['license_sha256']
 return p
if __name__=='__main__':
 check();print('PASS: complete unchanged M_intrinsics demo_erfc_scaled and MIT license')
