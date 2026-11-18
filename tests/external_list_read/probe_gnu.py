from pathlib import Path
import argparse,subprocess,tempfile,json
ROOT=Path(__file__).resolve().parent
ap=argparse.ArgumentParser();ap.add_argument('--gfortran',required=True,type=Path);ap.add_argument('--result',default='gnu-semantics.json');args=ap.parse_args()
FC=args.gfortran.resolve()
probes={
'leading_comma_next_record':('integer::a(3),b,s\na=9\nread(u,*,iostat=s) a\nprint *,s,a\nread(u,*,iostat=s)b\nprint *,s,b','1\n,2,3\n4\n'),
'comma_end_then_comma_next':('integer::a(4),b,s\na=9\nread(u,*,iostat=s)a\nprint *,s,a\nread(u,*,iostat=s)b\nprint *,s,b','1,\n,2,3\n4\n'),
'quote_continuation':('character(12)::x,y\ninteger::s\nread(u,*,iostat=s)x,y\nprint *,s\nprint "(a)","["//x//"]","["//y//"]"',"'ab\ncd', 'e\nf'\n"),
'quote_continuation_spaces':('character(12)::x\ninteger::s\nread(u,*,iostat=s)x\nprint *,s\nprint "(a)","["//x//"]"',"'ab  \n  cd'\n"),
'zero_size_then_read':('integer::a(0),b,s\nread(u,*,iostat=s)a\nprint *,s\nread(u,*,iostat=s)b\nprint *,s,b','11\n22\n'),
'zero_size_empty_file':('integer::a(0),s\nread(u,*,iostat=s)a\nprint *,s\nread(u,*,iostat=s)a\nprint *,s',''),
'empty_list_then_read':('integer::b,s\nread(u,*,iostat=s)\nprint *,s\nread(u,*,iostat=s)b\nprint *,s,b','11\n22\n'),
'backspace_initial':('integer::b,s\nbackspace(u,iostat=s)\nprint *,s\nread(u,*,iostat=s)b\nprint *,s,b','11\n22\n'),
'backspace_eof':('integer::b,s\nread(u,*,iostat=s)b\nprint *,s,b\nread(u,*,iostat=s)b\nprint *,s\nbackspace(u,iostat=s)\nprint *,s\nread(u,*,iostat=s)b\nprint *,s\nbackspace(u,iostat=s)\nbackspace(u,iostat=s)\nread(u,*,iostat=s)b\nprint *,s,b','11\n'),
'backspace_last_no_lf':('integer::b,s\nread(u,*,iostat=s)b\nprint *,s,b\nbackspace(u,iostat=s)\nprint *,s\nread(u,*,iostat=s)b\nprint *,s,b','11'),
'backspace_spanning':('integer::a(2),b,s\nread(u,*,iostat=s)a\nprint *,s,a\nbackspace(u,iostat=s)\nread(u,*,iostat=s)b\nprint *,s,b','11\n22\n33\n'),
'null_new_record':('integer::a(3),s\na=9\nread(u,*,iostat=s)a\nprint *,s,a','1\n,2\n'),
'null_leading_blank_record':('integer::a(3),s\na=9\nread(u,*,iostat=s)a\nprint *,s,a','1\n \n,2\n'),
}
rows=[]
for name,(body,data) in probes.items():
 declarations,rest=[],[]
 for line in body.splitlines():
  (declarations if '::' in line else rest).append(line)
 source='program p\nimplicit none\ninteger::u\n'+'\n'.join(declarations)+'\nu=27\n'+'\n'.join(rest)+'\nend program\n'
 with tempfile.TemporaryDirectory(prefix='external-list-probe-') as tmp:
  p=Path(tmp); (p/'probe.f90').write_text(source);(p/'fort.27').write_bytes(data.encode())
  c=subprocess.run([str(FC),'-std=f2018','-pedantic-errors','-fcheck=all','-O0','probe.f90','-o','probe'],cwd=p,capture_output=True)
  row=dict(name=name,source=source,input=data,compile_code=c.returncode,compile_err=c.stderr.decode())
  if c.returncode==0:
   r=subprocess.run([str(p/'probe')],cwd=p,capture_output=True,stdin=subprocess.DEVNULL,timeout=10)
   row.update(code=r.returncode,out=r.stdout.decode(),err=r.stderr.decode())
  rows.append(row); print(name,row.get('code'),repr(row.get('out')),repr(row.get('err') or row.get('compile_err')))
(ROOT/args.result).write_text(json.dumps(rows,indent=2)+'\n')
