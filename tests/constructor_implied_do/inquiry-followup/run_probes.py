from pathlib import Path
import subprocess,json,hashlib,argparse
R=Path(__file__).resolve().parent
parser=argparse.ArgumentParser();parser.add_argument('--gfortran',default='gfortran')
GF=parser.parse_args().gfortran
CASES={
'own_kind':('integer::i,a(4)','a=[(i,i=1,kind(i))]\nprint *,a'),
'own_digits':('integer::i,a(3)','a=[(i,i=digits(i)-2,digits(i))]\nprint *,a'),
'own_huge':('integer::i,a(2)','a=[(i,i=huge(i)-2,huge(i)-1)]\nprint *,a'),
'own_kind_nested_expression':('integer::i,a(4)','a=[(i,i=1,kind(i+1))]\nprint *,a'),
'own_digits_nested_expression':('integer::i,a(3)','a=[(i,i=digits(i+1)-2,digits(i+1))]\nprint *,a'),
'own_huge_nested_expression':('integer::i,a(2)','a=[(i,i=huge(i+1)-2,huge(i+1)-1)]\nprint *,a'),
'own_kind8':('integer(8)::i,a(8)','a=[(i,i=1,kind(i))]\nprint *,a,kind(a)'),
'own_digits8':('integer(8)::i,a(3)','a=[(i,i=digits(i)-2,digits(i))]\nprint *,a'),
'own_kind_start_step':('integer::i,a(3)','a=[(i,i=kind(i),3*kind(i),kind(i))]\nprint *,a'),
'own_inquiry_with_value':('integer::i,a(3)','a=[(i,i=1,kind(i)+i)]\nprint *,a'),
}
rows=[]
for name,(decl,body) in CASES.items():
 src=R/(name+'.f90');src.write_text('program main\nimplicit none\n'+decl+'\n'+body+'\nend program\n');exe=R/(name+'.exe')
 argv=[GF,'-std=f2018','-pedantic-errors','-fcheck=all','-O0',str(src),'-o',str(exe)]
 p=subprocess.run(argv,capture_output=True,cwd=R);row={'name':name,'sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'command':argv,'compile_code':p.returncode,'compile_stdout':p.stdout.decode(),'compile_stderr':p.stderr.decode()}
 if p.returncode==0 and name!='own_inquiry_with_value':
  z=subprocess.run([str(exe)],cwd=R,capture_output=True,timeout=5);row.update(run_code=z.returncode,stdout=z.stdout.decode(),stderr=z.stderr.decode())
 rows.append(row);print(name,p.returncode,repr(row.get('stdout','')))
(R/'gnu-results.json').write_text(json.dumps(rows,indent=2)+'\n')
