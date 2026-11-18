from pathlib import Path
import argparse,hashlib,json
R=Path(__file__).resolve().parent
def require(ok,message):
 if not ok:raise SystemExit(message)
p=argparse.ArgumentParser();p.add_argument('--original',type=Path,default=R.parent/'utilities_slices/source/xutilities.f90');args=p.parse_args();m=json.loads((R/'manifest.json').read_text());raw=args.original.read_bytes();require(hashlib.sha256(raw).hexdigest()==m['source_sha256'],'Original source identity differs');lines=raw.splitlines(keepends=True);h=(R/'cases/original_select_match_vec_char.f90').read_bytes()
require(len(m['cases'])==50 and len({c['name']for c in m['cases']})==50,'Fixture count/uniqueness differs')
require({p.name for p in(R/'cases').glob('*.f90')}=={Path(c['source']).name for c in m['cases']},'Fixture inventory differs')
for c in m['cases']:require(hashlib.sha256((R/c['source']).read_bytes()).hexdigest()==c['sha256'],'Fixture identity differs: '+c['name'])
require(m['raw_body_ranges']==[[2496,2515],[2517,2524],[2626,2634]] and len(m['raw_body_sha256'])==3,'Original body map differs')
for (first,last),expected in zip(m['raw_body_ranges'],m['raw_body_sha256']):
 body=b''.join(lines[first-1:last]);require(hashlib.sha256(body).hexdigest()==expected and h.count(body)==1,'Raw CRLF utility body differs')
print('PASS:50 source identities and three untouched original CRLF procedure bodies')
