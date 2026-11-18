#!/usr/bin/env python3
"""Independent decomposition reproducibility and corrupt-partition checks."""
import hashlib,json,shutil,tempfile
from pathlib import Path
import split_source as partition
ROOT=Path(__file__).resolve().parent

def main():
 source=ROOT/'source/xutilities.f90';checks=0
 with tempfile.TemporaryDirectory(prefix='utilities-partition-') as tmp:
  tmp=Path(tmp);clean=tmp/'clean';other=tmp/'other';manifest=partition.split(source,clean)
  assert (manifest['top_level_procedures'],manifest['internal_procedures'],manifest['total_procedures'])==(549,2,551)
  assert partition.check(source,clean)==manifest;checks+=1
  partition.split(source,other)
  assert {p.relative_to(clean):p.read_bytes() for p in clean.rglob('*') if p.is_file()}=={p.relative_to(other):p.read_bytes() for p in other.rglob('*') if p.is_file()};checks+=1
  for mutation in ('extra','missing','line','offset','hash','split_internal'):
   bad=tmp/mutation;shutil.copytree(clean,bad);m=json.loads((bad/'source-map.json').read_text());record=m['parts'][2]
   if mutation=='extra':(bad/'routines/extra.f90').write_text('! orphan\n')
   elif mutation=='missing':(bad/record['file']).unlink()
   elif mutation=='line':record['first_line']+=1
   elif mutation=='offset':record['byte_offset']+=1
   elif mutation=='hash':record['sha256']='0'*64
   else:
    pos=next(i for i,r in enumerate(m['parts']) if r.get('procedure')=='quick_sort');record=m['parts'][pos]
    path=bad/record['file'];data=path.read_bytes();at=data.index(b'subroutine interchange_sort(');left,right=data[:at],data[at:]
    nleft=len(left.splitlines(keepends=True));old_last=record['last_line'];path.write_bytes(left)
    record.update(last_line=record['first_line']+nleft-1,line_count=nleft,byte_length=len(left),sha256=hashlib.sha256(left).hexdigest())
    new={'file':'routines/507b_interchange_sort.f90','procedure':'interchange_sort','kind':'routine_fragment','first_line':record['last_line']+1,'last_line':old_last,'line_count':len(right.splitlines(keepends=True)),'byte_offset':record['byte_offset']+len(left),'byte_length':len(right),'sha256':hashlib.sha256(right).hexdigest()}
    (bad/new['file']).write_bytes(right);m['parts'].insert(pos+1,new)
    # The invalid partition still reconstructs the exact original bytes.
    assert b''.join((bad/r['file']).read_bytes() for r in m['parts'])==source.read_bytes()
   (bad/'source-map.json').write_text(json.dumps(m,indent=2)+'\n')
   try:partition.check(source,bad)
   except (AssertionError,ValueError):pass
   else:raise AssertionError('Corrupt partition accepted: '+mutation)
   checks+=1
 print('PASS: %d partition checks, including exact-byte internal-procedure split rejection'%checks)
if __name__=='__main__':main()
