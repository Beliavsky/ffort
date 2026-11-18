from pathlib import Path
import json,hashlib
ROOT=Path(__file__).resolve().parent
def check():
 p=json.loads((ROOT/'provenance.json').read_text())
 for f in p['files']:assert hashlib.sha256((ROOT/f['file']).read_bytes()).hexdigest()==f['sha256']
 assert hashlib.sha256((ROOT/p['license']).read_bytes()).hexdigest()==p['license_sha256']
 return p
if __name__=='__main__':check();print('PASS: five complete original programs and MIT license')
