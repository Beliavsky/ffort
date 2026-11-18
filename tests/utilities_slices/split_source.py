#!/usr/bin/env python3
"""Partition original bytes without separating internal procedures from their host.

Reference fragments preserve dependencies and are not standalone modules. Run the
small *.f90 harnesses in this directory for executable feature tests.
"""
import argparse,hashlib,json,re
from pathlib import Path,PurePosixPath
ROOT=Path(__file__).resolve().parent
START=re.compile(r'^(?:(?:pure|impure|recursive|elemental|module|integer|real|logical|complex|character|double\s+precision|type)(?:\s*\([^)]*\))?\s+)*(function|subroutine)\s+(\w+)\s*\(')
END=re.compile(r'^end\s*(function|subroutine)\b(?:\s+(\w+))?')

def digest(data):return hashlib.sha256(data).hexdigest()
def clean(line):return line.decode('ascii').split('!')[0].strip().lower()
def procedures(lines):
 """Return top-level and internal procedure ranges, with checked nesting."""
 stack=[];all_procs=[]
 for i,line in enumerate(lines):
  text=clean(line);end=END.match(text)
  if end:
   if not stack:raise ValueError('Unmatched procedure ending at line %d'%(i+1))
   entry=stack.pop()
   if end.group(1)!=entry['kind'] or (end.group(2) and end.group(2)!=entry['name']):
    raise ValueError('Mismatched procedure ending at line %d'%(i+1))
   entry['last_line']=i+1;all_procs.append(entry);continue
  begin=START.match(text)
  if begin:
   stack.append({'name':begin.group(2),'kind':begin.group(1),'first_line':i+1,
                 'depth':len(stack),'parent':stack[-1]['name'] if stack else None,
                 'host':stack[0]['name'] if stack else None})
 if stack:raise ValueError('Unclosed procedure: '+stack[-1]['name'])
 all_procs.sort(key=lambda entry:entry['first_line'])
 return [entry for entry in all_procs if entry['depth']==0],all_procs

def expected_parts(lines):
 top,all_procs=procedures(lines);parts=[]
 module_end=next(i+1 for i,line in enumerate(lines) if clean(line)=='end module kind_mod')
 driver=next(i for i,line in enumerate(lines) if clean(line)=='program xutil')
 driver_end=next(i for i,line in enumerate(lines) if clean(line)=='end program xutil')
 first_exec=next(i for i in range(driver,driver_end) if clean(lines[i]).startswith('print'))
 def part(name,a,b,kind,procedure=None):
  if b>a:parts.append({'file':name,'first_line':a+1,'last_line':b,'kind':kind,**({'procedure':procedure} if procedure else {})})
 part('001_kind_mod.f90',0,module_end,'module')
 part('002_util_mod_spec.f90',module_end,top[0]['first_line']-1,'module_specification')
 for number,entry in enumerate(top,1):
  end=top[number]['first_line']-1 if number<len(top) else entry['last_line']
  part('routines/%03d_%s.f90'%(number,entry['name']),entry['first_line']-1,end,'routine_fragment',entry['name'])
 part('003_util_mod_end.f90',top[-1]['last_line'],driver,'module_end')
 part('main/000_declarations.f90',driver,first_exec,'program_specification')
 # Group top-level statements, never cut a continued statement or a DO loop.
 start=first_exec;depth=0;count=0;number=0;continuing=False
 for i in range(first_exec,driver_end):
  text=clean(lines[i])
  if not text:continue
  if not continuing and re.match(r'do\b',text):depth+=1
  if re.match(r'end\s*do\b',text):depth-=1
  continuing=text.endswith('&')
  if depth<0:raise ValueError('Unmatched driver DO ending')
  if not continuing and depth==0:
   count+=1
   if count>=12:
    number+=1;part('main/%03d_statements.f90'%number,start,i+1,'program_statements');start=i+1;count=0
 if depth!=0 or continuing:raise ValueError('Unclosed driver construct')
 if start<driver_end:
  number+=1;part('main/%03d_statements.f90'%number,start,driver_end,'program_statements')
 part('main/999_end_program.f90',driver_end,len(lines),'program_end')
 return parts,top,all_procs,number

def split(source,output):
 if output.exists() and any(output.iterdir()):
  raise ValueError('Output directory must be empty; regenerate into a new directory')
 raw=source.read_bytes();lines=raw.splitlines(keepends=True)
 parts,top,all_procs,number=expected_parts(lines)
 output.mkdir(parents=True,exist_ok=True);records=[];offset=0;line_offset=0
 for part in parts:
  a=part['first_line']-1;b=part['last_line'];data=b''.join(lines[a:b])
  if a!=line_offset:raise ValueError('Noncontiguous source partition')
  path=output/part['file'];path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(data)
  records.append({**part,'line_count':b-a,'byte_offset':offset,'byte_length':len(data),'sha256':digest(data)})
  offset+=len(data);line_offset=b
 manifest={'source_file':source.name,'source_sha256':digest(raw),'source_bytes':len(raw),'source_lines':len(lines),
           'routine_fragments':len(top),'top_level_procedures':len(top),'internal_procedures':len(all_procs)-len(top),
           'total_procedures':len(all_procs),'driver_statement_fragments':number,'parts':records}
 (output/'source-map.json').write_text(json.dumps(manifest,indent=2)+'\n')
 return check(source,output)

def check(source,output):
 raw=source.read_bytes();lines=raw.splitlines(keepends=True)
 manifest=json.loads((output/'source-map.json').read_text());expected,top,all_procs,number=expected_parts(lines)
 assert manifest['source_file']==source.name,'Source filename differs'
 assert manifest['source_bytes']==len(raw) and manifest['source_lines']==len(lines),'Source dimensions differ'
 assert manifest['source_sha256']==digest(raw),'Original hash differs'
 for key,value in [('routine_fragments',len(top)),('top_level_procedures',len(top)),
                   ('internal_procedures',len(all_procs)-len(top)),('total_procedures',len(all_procs)),
                   ('driver_statement_fragments',number)]:
  assert manifest[key]==value,key+' differs'
 records=manifest['parts'];assert len(records)==len(expected),'Partition count differs'
 actual_files={path.relative_to(output).as_posix() for path in output.rglob('*') if path.is_file()}
 expected_files={'source-map.json'}|{part['file'] for part in expected}
 assert actual_files==expected_files,'Extra or missing fragment files'
 pieces=[];offset=0;line_offset=0
 for record,part in zip(records,expected):
  for key,value in part.items():assert record[key]==value,'Partition boundary differs: '+key
  name=PurePosixPath(record['file']);assert not name.is_absolute() and '..' not in name.parts,'Unsafe fragment path'
  a=record['first_line']-1;b=record['last_line'];data=(output/record['file']).read_bytes()
  assert a==line_offset and b>a,'Noncontiguous line boundaries'
  assert record['line_count']==b-a and len(data.splitlines(keepends=True))==b-a,'Line count differs'
  assert record['byte_offset']==offset and record['byte_length']==len(data),'Byte boundaries differ'
  assert digest(data)==record['sha256'],'Fragment hash differs'
  assert data==b''.join(lines[a:b]),'Fragment differs from original line range'
  pieces.append(data);offset+=len(data);line_offset=b
 assert offset==len(raw) and line_offset==len(lines),'Incomplete source coverage'
 assert b''.join(pieces)==raw,'Reconstruction differs'
 # Regression: keep both nested procedures and the outer END inside quick_sort.
 quick=[record for record in records if record.get('procedure')=='quick_sort']
 assert len(quick)==1,'quick_sort host fragment missing'
 host=quick[0];contained=[entry for entry in all_procs if entry['host']=='quick_sort']
 assert {entry['name'] for entry in contained}=={'quick_sort_1','interchange_sort'},'quick_sort internals differ'
 fragment=(output/host['file']).read_bytes()
 roots,nested=procedures(fragment.splitlines(keepends=True))
 assert len(roots)==1 and roots[0]['name']=='quick_sort','quick_sort host was cut'
 assert {entry['name'] for entry in nested}=={'quick_sort','quick_sort_1','interchange_sort'},'quick_sort internals were separated'
 assert all(host['first_line']<=entry['first_line']<=entry['last_line']<=host['last_line'] for entry in contained),'Internal procedure crosses fragment boundary'
 return manifest

def main():
 p=argparse.ArgumentParser();p.add_argument('--source',type=Path,default=ROOT/'source'/'xutilities.f90');p.add_argument('--output',type=Path,default=ROOT/'source_parts');p.add_argument('--check',action='store_true');a=p.parse_args()
 m=check(a.source,a.output) if a.check else split(a.source,a.output)
 print('PASS: %d top-level routines, %d internal procedures, %d main blocks, %d bytes reconstructed exactly; SHA-256 %s'%(m['top_level_procedures'],m['internal_procedures'],m['driver_statement_fragments'],m['source_bytes'],m['source_sha256']))
if __name__=='__main__':main()
