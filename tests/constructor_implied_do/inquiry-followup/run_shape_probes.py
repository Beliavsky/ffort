from pathlib import Path
import subprocess,json,hashlib,argparse
R=Path(__file__).resolve().parent
parser=argparse.ArgumentParser();parser.add_argument('--gfortran',default='gfortran')
GF=parser.parse_args().gfortran
CASES={
'parameter_integer_constructor':('integer::i\ninteger,parameter::a(3)=[(i,i=1,3)]','print *,a',True,'numeric_records'),
'initialized_saved_constructor':('integer::i\ninteger::a(3)=[(i,i=1,3)]','print *,a',True,'numeric_records'),
'parameter_real_constructor':('integer::i\nreal(8),parameter::a(3)=[(0.25_8*i,i=1,3)]','print *,a',True,'numeric_records'),
'parameter_character_constructor':('integer::i\ncharacter(3),parameter::a(2)=[("ab ",i=1,2)]','print \'(2("[",a,"]"))\',a',True,'exact'),
'len_constructor_nonempty':('integer::i\ncharacter(3)::x','print *,len([(x,i=1,3)])',True,'numeric_records'),
'len_constructor_empty':('integer::i','print *,len([("ab",i=2,1)]),size([("ab",i=2,1)])',True,'numeric_records'),
'len_constructor_element':('integer::i\ncharacter(3)::x(3)','print *,len([(x(i),i=1,3)])',True,'numeric_records'),
'nested_size_own_kind':('integer::i,j,a(4)','a=[(i,i=1,size([(j,j=1,kind(i))]))]\nprint *,a',True,'numeric_records'),
'nested_kind_own_extent':('integer::i,j,a(4)','a=[(i,i=1,kind([(j,j=1,i)]))]\nprint *,a',True,'numeric_records'),
'nested_len_own_extent':('integer::i,j,a(2)','a=[(i,i=1,len([("ab",j=1,i)]))]\nprint *,a',True,'numeric_records'),
'nested_control_index_reuse':('integer::i,a(3)','a=[(i,i=1,size([(i,i=1,3)]))]',False,'numeric_records'),
'nested_size_own_value':('integer::i,j,a(3)','a=[(i,i=1,size([(j,j=1,i)]))]',False,'numeric_records'),
}
rows=[]
for name,(decl,body,run,mode) in CASES.items():
 src=R/(name+'.f90');src.write_text('program main\nimplicit none\n'+decl+'\n'+body+'\nend program\n');exe=R/(name+'.exe')
 argv=[GF,'-std=f2018','-pedantic-errors','-fcheck=all','-O0',str(src)]+(['-o',str(exe)] if run else ['-fsyntax-only'])
 p=subprocess.run(argv,capture_output=True,cwd=R);row={'name':name,'sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'command':argv,'run_allowed':run,'compare_mode':mode,'compile_code':p.returncode,'compile_stdout':p.stdout.decode(),'compile_stderr':p.stderr.decode()}
 if p.returncode==0 and run:
  z=subprocess.run([str(exe)],cwd=R,capture_output=True,timeout=5);row.update(run_code=z.returncode,stdout=z.stdout.decode(),stderr=z.stderr.decode())
 rows.append(row);print(name,p.returncode,repr(row.get('stdout','')),row['compile_stderr'][:80])
(R/'gnu-shape-results.json').write_text(json.dumps(rows,indent=2)+'\n')
