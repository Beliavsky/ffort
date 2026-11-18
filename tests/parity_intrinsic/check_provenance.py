from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parent
def check():
 p=json.loads((ROOT/'provenance.json').read_text());data=(ROOT/p['local_file']).read_bytes()
 assert len(data)==p['bytes'] and hashlib.sha256(data).hexdigest()==p['sha256'],'Original M_intrinsics PARITY example changed'
 return p
if __name__=='__main__':print('PASS unchanged demo_parity:',check()['sha256'])
