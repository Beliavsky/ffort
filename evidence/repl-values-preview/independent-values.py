import subprocess,pathlib,tempfile,json,hashlib,math
R=pathlib.Path(__file__).resolve().parents[1];C=R/'057-repl-values-evidence/final-candidate';results=[]
def need(c):
 if not c:raise AssertionError('condition failed')
def run(name,body,check,defer=False):
 with tempfile.TemporaryDirectory() as d:
  p=subprocess.run([str(C),'--repl','--nologo','--prompt','']+(['--defer-check'] if defer else []),input=body+'\n.quit!\n',text=True,capture_output=True,timeout=20,cwd=d)
 try:check(p);results.append(dict(name=name,passed=True))
 except Exception as e:results.append(dict(name=name,passed=False,stdout=p.stdout,stderr=p.stderr,returncode=p.returncode,error=str(e)))
def eq(expected):return lambda p:need(p.returncode==0 and not p.stderr and p.stdout.split()==expected)
for decl,expr,expect in [('integer,parameter :: n=5','n',['5']),('integer(8),parameter :: n=2147483648_8','n',['2147483648']),('logical,parameter :: yes=.true.','yes',['T']),('character(3),parameter :: s="abc"','s',['abc']),('integer,parameter :: n=2+3','n',['5']),('integer,parameter :: n=5,m=n+2','m',['7'])]:
 run(decl,decl+'\n'+expr,eq(expect))
for kind in ['','(8)']:
 run('real'+kind,'real'+kind+',parameter :: r=2.5\nr',lambda p:need(p.returncode==0 and not p.stderr and float(p.stdout.strip())==2.5))
run('mutable scalar','integer :: n\nn=5\nn\nn=7\nn',eq(['5','7']))
run('mutable element','integer :: a(3)\na=4\na(2)\na(2)=7\na(2)',eq(['4','7']))
run('parameter dimension/index','integer,parameter :: n=3\ninteger :: a(n)\na=4\na(n)\na(n)=7\na(n)',eq(['4','7']))
run('pending no replay','integer,parameter :: n=5\ninteger :: x\nx=0\nx=x+1\nprint *, "ONCE"\nn\nx\nn\nx',eq(['ONCE','5','1','5','1']),True)
run('query then append','integer,parameter :: n=5\ninteger :: x\nx=2\nn\nx=x+n\nx\nn',eq(['5','7','5']))
run('undefined element','integer,parameter :: n=2\ninteger :: a(n)\na(1)=4\na(2)',lambda p:need(p.returncode!=0 and not p.stdout and 'uninitialized' in p.stderr))
run('parameter assignment','integer,parameter :: n=5\nn=9\nn',lambda p:need(p.returncode!=0 and '9' not in p.stdout))
run('query source stays clean','integer,parameter :: n=5\nn\n.list',lambda p:need(p.returncode==0 and p.stdout.count('integer,parameter :: n=5')==1 and 'print *' not in p.stdout))
run('RNG survives queries','integer,parameter :: n=5\nreal :: r\ncall random_seed()\ncall random_number(r)\nr\nn\nr\nn\nr',lambda p:need(p.returncode==0 and not p.stderr and len(p.stdout.split())==5 and p.stdout.split()[0]==p.stdout.split()[2]==p.stdout.split()[4] and p.stdout.split()[1::2]==['5','5']))
run('parameter inspection cache','integer,parameter :: n=5\nn\n.vars n\n.info n',lambda p:need(p.returncode==0 and not p.stderr and p.stdout.count('n = 5')==2 and 'n : INTEGER kind=4 rank=0' in p.stdout and 'undefined' not in p.stdout))
r=dict(status='passed' if all(x['passed'] for x in results) else 'failed',tests=len(results),candidate_sha256=hashlib.sha256(C.read_bytes()).hexdigest(),results=results)
(R/'057-repl-values-evidence/independent-values.json').write_text(json.dumps(r,indent=2)+'\n');print(json.dumps(r,indent=2));raise SystemExit(r['status']!='passed')
