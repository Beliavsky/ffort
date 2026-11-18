from pathlib import Path
import hashlib,json
root=Path(__file__).resolve().parents[2]; d=root/'tests/random_functions';(d/'cases').mkdir(parents=True,exist_ok=True)
src=(root/'tests/utilities_slices/source/xutilities.f90').read_bytes(); lines=src.splitlines(keepends=True);cases=[];originals=[]
def add(name,body,category='success',baseline='run',expected_stdout='PASS',diag='',args=None):
 if isinstance(body,str):body=body.encode()
 (d/'cases'/f'{name}.f90').write_bytes(body)
 case=dict(name=name,source='cases/'+name+'.f90',category=category,baseline=baseline,expected_stdout=expected_stdout)
 if diag:case['diagnostic']=diag
 if args:case['args']=args
 if baseline=='skip':case['gnu_skip_reason']='SIMPLE is Fortran 2023 and not supported by this GNU oracle'
 cases.append(case)
def program(decl,body,procs):
 return f'program p\nimplicit none\n{decl}\n{body}\nprint *, "PASS"\ncontains\n{procs}\nend program\n'
def original(name,a,b,decl,body):
 part=b''.join(lines[a-1:b]);prefix=b'module m\nimplicit none\ninteger,parameter::dp=kind(0d0)\ncontains\n'
 wrapper=prefix+part+b'end module\nprogram p\nuse m\nimplicit none\n'+decl.encode()+b'\n'+body.encode()+b'\nprint *, "PASS"\nend program\n'
 add('original_'+name,wrapper);originals.append(dict(name=name,start_line=a,end_line=b,body_sha256=hashlib.sha256(part).hexdigest(),body_bytes=len(part),crlf_lines=part.count(b'\r\n'),source='cases/original_'+name+'.f90'))
for name,a,b in [('ran_uni_vec',510,514),('runif_vec',2651,2658),('random_matrix',7847,7851)]:
 dims='4096' if name!='random_matrix' else '64,64';arg=dims;empty='0' if name!='random_matrix' else '0,3'
 body=f'x={name}({arg})\nif(any(x<0d0).or.any(x>=1d0)) error stop 1\nif(abs(sum(x)/4096d0-0.5d0)>0.05d0) error stop 2\nif(abs(sum((x-0.5d0)**2)/4096d0-1d0/12d0)>0.025d0) error stop 3\ny={name}({arg})\nif(all(x==y)) error stop 4\nif(size({name}({empty}))/=0) error stop 5'
 if name=='runif_vec':body+='\nx=runif_vec(4096,3d0)\nif(any(x<2.5d0).or.any(x>=3.5d0)) error stop 6\nif(abs(sum(x)/4096d0-3d0)>0.05d0) error stop 7'
 original(name,a,b,f'real(dp)::x({dims}),y({dims})',body)
for name,a,b,dims,empty in [('random_logical_vec',6192,6200,'4096','0'),('random_logical_matrix',6202,6210,'64,64','0,3'),('random_logical_3d',6212,6220,'16,16,16','2,0,3')]:
 body=f'x={name}({dims},0.25d0)\nif(abs(count(x)/4096d0-0.25d0)>0.05d0) error stop 1\nx={name}({dims},0d0)\nif(any(x)) error stop 2\nx={name}({dims},1d0)\nif(.not.all(x)) error stop 3\nif(size({name}({empty},0.5d0))/=0) error stop 4'
 decl=f'logical::x({dims})'
 if name=='random_logical_3d':
  decl+='\ninteger::j,nt'
  body=body.replace('if(abs(count(x)/4096d0-0.25d0)>0.05d0) error stop 1','nt=0\ndo j=1,16\nnt=nt+count(x(:,:,j))\nend do\nif(abs(nt/4096d0-0.25d0)>0.05d0) error stop 1').replace('if(any(x)) error stop 2','do j=1,16\nif(any(x(:,:,j))) error stop 2\nend do').replace('if(.not.all(x)) error stop 3','do j=1,16\nif(.not.all(x(:,:,j))) error stop 3\nend do')
 original(name,a,b,decl,body)
f='real(8) function draw() result(r)\ncall random_number(r)\nend function'
add('scalar_broadcast',program('real(8)::a(3,4),b(3,4)','a=draw()\nb=draw()\nif(any(a/=a(1,1)).or.any(b/=b(1,1))) error stop 1\nif(a(1,1)==b(1,1)) error stop 2',f))
add('scalar_occurrences',program('real(8)::a(8),b(8)','a=[draw(),draw(),draw(),draw(),draw(),draw(),draw(),draw()]\nif(all(a==a(1))) error stop 1\nb=draw()+draw()\nif(any(b/=b(1))) error stop 2',f))
add('scalar_loop_refresh',program('real(8)::a(8)\ninteger::j','do j=1,8\na(j)=draw()\nend do\nif(all(a==a(1))) error stop 1',f))
add('real_kinds_sections',program('real(8)::x(3,4,2)\nreal::y(9)\ninteger::j','x=wide()\ny=narrow()\ndo j=1,2\nif(any(x(:,:,j)<0d0).or.any(x(:,:,j)>=1d0)) error stop 1\nend do\nif(any(y<0.0).or.any(y>=1.0)) error stop 2',f+'\nfunction wide() result(r)\nreal(8)::r(3,4,2)\ncall random_number(r(:,4:1:-1,:))\nend function\nfunction narrow() result(r)\nreal::r(9)\ncall random_number(harvest=r)\nend function'))
add('transitive_subroutine',program('real(8)::a(20)','a=draw()\nif(any(a/=a(1))) error stop 1', 'real(8) function draw() result(r)\ncall helper(r)\nend function\nsubroutine helper(x)\nreal(8),intent(out)::x\ncall random_number(x)\nend subroutine'))
add('recursive_scalar',program('real(8)::x','x=draw(12)\nif(x<0d0.or.x>=13d0) error stop 1','recursive function draw(n) result(r)\ninteger,intent(in)::n\nreal(8)::r,t\ncall random_number(t)\nr=t\nif(n>0) r=r+draw(n-1)\nend function'))
add('recursive_array',program('real(8)::x(5)','x=draw(5,3)\nif(any(x<0d0).or.any(x>=4d0)) error stop 1','recursive function draw(n,k) result(r)\ninteger,intent(in)::n,k\nreal(8)::r(n)\ncall random_number(r)\nif(k>0) r=r+draw(n,k-1)\nend function'))
add('kind_unevaluated',program('integer::k','k=kind(draw())\nif(k/=8) error stop 1','real(8) function draw() result(r)\ncall random_number(r)\nerror stop "KIND evaluated function"\nend function'))
add('array_actual_once',program('real(8)::x(16)','call inspect(draw())','real(8) function draw() result(r)\ncall random_number(r)\nend function\nsubroutine inspect(a)\nreal(8),intent(in)::a\nreal(8)::x(16)\nx=a\nif(any(x/=a)) error stop 1\nend subroutine'))
# Module-scoped sibling functions and nested procedure share a stream without external storage writes.
add('nested_local_rng','module m\ncontains\nfunction outer() result(r)\nreal(8)::r\nr=inner()\ncontains\nreal(8) function inner() result(x)\ncall random_number(x)\nend function\nend function\nend module\nprogram p\nuse m\nreal(8)::x\nx=outer()\nif(x<0d0.or.x>=1d0) error stop 1\nprint *,"PASS"\nend program\n')
add('allocatable_result_usage',program('real(8),allocatable::x(:)','allocate(x(7))\nx=draw()\nif(any(x/=x(1))) error stop 1\ndeallocate(x)',f))
for prefix in ['pure','elemental','simple']:
 add(prefix+'_reject',program('real(8)::x','x=draw(1)',prefix+' real(8) function draw(n) result(r)\ninteger,intent(in)::n\ncall random_number(r)\nend function'),'reject','skip' if prefix=='simple' else 'reject','')
add('pure_transitive_reject',program('real(8)::x','x=pure_draw()','pure real(8) function pure_draw() result(r)\nr=draw()\nend function\n'+f),'reject','reject','')
for name,procs in [
 ('direct_io','real(8) function draw() result(r)\ncall random_number(r)\nprint *,r\nend function'),
 ('transitive_io','real(8) function draw() result(r)\ncall helper(r)\nend function\nsubroutine helper(r)\nreal(8),intent(out)::r\ncall random_number(r)\nprint *,r\nend subroutine'),
 ('saved_harvest','real(8) function draw() result(r)\nreal(8),save::x\ncall random_number(x)\nr=x\nend function'),
 ('saved_transitive','real(8) function draw() result(r)\nreal(8),save::x\ncall helper(x)\nr=x\nend function\nsubroutine helper(x)\nreal(8),intent(out)::x\ncall random_number(x)\nend subroutine'),
 ('explicit_impure_nonelemental','impure real(8) function draw() result(r)\ncall random_number(r)\nend function')]:
 add(name,program('real(8)::x','x=draw()',procs),'reject','compile','')
for name,decl,body in [('intent_in','real(8),intent(in)::n','call random_number(n)'),('parenthesized','real(8),intent(in)::n','call random_number((r))'),('nonreal','integer,intent(in)::n','call random_number(i)')]:
 add('invalid_'+name,program('real(8)::x','x=draw(1)' if name=='nonreal' else 'x=draw(1d0)','real(8) function draw(n) result(r)\n'+decl+'\ninteger::i\n'+body+'\nr=0d0\nend function'),'reject','reject','')
add('module_harvest','module m\nreal(8)::x\ncontains\nreal(8) function draw() result(r)\ncall random_number(x)\nr=x\nend function\nend module\nprogram p\nuse m\nprint *,draw()\nend program\n','reject','compile','')
add('host_harvest','module m\ncontains\nfunction outer() result(r)\nreal(8)::r,x\nr=inner()\ncontains\nreal(8) function inner() result(y)\ncall random_number(x)\ny=x\nend function\nend function\nend module\nprogram p\nuse m\nprint *,outer()\nend program\n','reject','compile','')
add('oversized_result',program('real(8)::x','x=sum(draw(1000001))','function draw(n) result(r)\ninteger,intent(in)::n\nreal(8)::r(n)\ncall random_number(r)\nend function'),'runtime','compile','',diag='limit')
add('budget_exhaustion',program('real(8)::x(100)','x=draw(100)','function draw(n) result(r)\ninteger,intent(in)::n\nreal(8)::r(n)\ncall random_number(r)\nend function'),'runtime','compile','',diag='step limit',args=['--max-steps','50'])
add('recursion_depth',program('real(8)::x','x=draw(70)','recursive function draw(n) result(r)\ninteger,intent(in)::n\nreal(8)::r\ncall random_number(r)\nif(n>0) r=r+draw(n-1)\nend function'),'runtime','compile','',diag='depth')
add('specification_impure', 'module m\ncontains\ninteger function width() result(r)\nreal::x\ncall random_number(x)\nr=3\nend function\nsubroutine fill(n)\ninteger,intent(in)::n\nreal::x(width())\nx=0\nend subroutine\nend module\nprogram p\nuse m\ncall fill(1)\nend program\n','reject','reject','')
add('where_impure_reject',program('real(8)::x(3)','x=-1d0\nwhere([.true.,.false.,.true.])\nx=draw()\nend where\nif(x(1)/=x(3).or.x(2)/=-1d0) error stop 1',f),'reject','compile','')
add('kind_array_unevaluated',program('integer::k','k=kind(draw(3))\nif(k/=8) error stop 1','function draw(n) result(r)\ninteger,intent(in)::n\nreal(8)::r(n)\ncall random_number(r)\nerror stop "KIND evaluated array function"\nend function'))
add('inquiry_result',program('integer::n','n=size(draw(3))\nif(n/=3) error stop 1','function draw(n) result(r)\ninteger,intent(in)::n\nreal(8)::r(n)\ncall random_number(r)\nend function'))
add('empty_scalar_suppression',program('real(8)::x(0)','x=0d0\nx=x+draw()','real(8) function draw() result(r)\ncall random_number(r)\nerror stop "empty path evaluated"\nend function'),baseline='compile')
add('unbounded_loop_budget',program('real(8)::x','x=draw()','real(8) function draw() result(r)\ndo\ncall random_number(r)\nend do\nend function'),'runtime','compile','',diag='step limit',args=['--max-steps','1000'])
manifest=dict(description='Bounded RANDOM_NUMBER effects in ordinary functions; invariant oracles, never matching GNU sequences.',original=dict(source='tests/utilities_slices/source/xutilities.f90',sha256=hashlib.sha256(src).hexdigest(),routines=originals),cases=cases)
(d/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('generated',len(cases),'cases')
