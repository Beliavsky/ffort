from pathlib import Path
import hashlib,json,re
def require(ok,message):
 if not ok:raise ValueError(message)
import argparse
P=Path(__file__).resolve().parent
parser=argparse.ArgumentParser();parser.add_argument('--upstream',type=Path,default=P.parent/'utilities_slices/source/xutilities.f90');parser.add_argument('--output',type=Path,required=True);args=parser.parse_args()
R=args.output.resolve();R.mkdir(parents=True,exist_ok=False);(R/'cases').mkdir();(R/'source').mkdir()
source=args.upstream.read_bytes();require(hashlib.sha256(source).hexdigest()=='c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883','original source hash differs')
bodies=[];meta=[]
for name in ['unique_vec_int','unique_int','set_alloc_int_vec']:
 pat=rb'(?mi)^(?:(?:pure|recursive|elemental)\s+)*(?:subroutine|function) '+name.encode()+rb'\b.*?^end (?:subroutine|function) '+name.encode()+rb'[^\r\n]*\r?\n';m=re.search(pat,source,re.S);require(m is not None,'missing original body '+name);bodies.append(m.group());meta.append(dict(name=name,sha256=hashlib.sha256(m.group()).hexdigest(),bytes=len(m.group()),start_line=source[:m.start()].count(b'\n')+1))
closure=b'module utility_closure\r\nimplicit none\r\ncharacter(*),parameter::mod_str="utilities, "\r\ninterface set_alloc\r\nmodule procedure set_alloc_int_vec\r\nend interface\r\ncontains\r\n'+b'\r\n'.join(bodies)+b'end module\r\n';(R/'source/exact_closure.f90').write_bytes(closure)
(R/'provenance.json').write_text(json.dumps(dict(upstream='tests/utilities_slices/source/xutilities.f90',upstream_sha256=hashlib.sha256(source).hexdigest(),bodies=meta,driver='Synthetic module generic interface and drivers; all three original bodies byte-identical',full_source_success=False),indent=2)+'\n')
rows=[]
def add(name,s,stage='success',gnu='run',expected='1\n',note=None):
 f=R/'cases'/(name+'.f90');f.write_bytes(s if isinstance(s,bytes) else s.encode());r=dict(name=name,source='cases/'+f.name,sha256=hashlib.sha256(f.read_bytes()).hexdigest(),stage=stage,gnu=gnu,expected=expected,diagnostic=None)
 if note:r['note']=note
 rows.append(r)
def prog(decl,body):return 'program p\nimplicit none\n'+decl+'\n'+body+'\nend program\n'
def ok(s):return s+"\nprint '(i0)',1"
for typ,k in [('integer',4),('integer',8),('real',4),('real',8)]:
 label=typ+str(k);t=f'{typ}({k})';vals='1,2,3,4' if typ=='integer' else '1.,2.,3.,4.'
 add(label+'_order_lower',prog(t+'::a(-2:1),b(4)\ninteger(8)::idx(4)','a=['+vals+']\nidx=[1_8,-2_8,1_8,-1_8]\nb=a(idx)\n'+ok('if(any(b/=[4,1,4,2]))error stop 1')))
 add(label+'_empty',prog(t+'::a(4),b(0)\ninteger::idx(0)',ok('b=a(idx)\nif(size(b)/=0)error stop 1')))
 add(label+'_kind_undefined',prog(t+',allocatable::a(:)\ninteger::idx(2)',ok('if(kind(a(idx))/='+str(k)+')error stop 1')))
 add(label+'_parameter',prog(t+',parameter::a(4)=['+vals+']\n'+t+'::b(3)',ok('b=a([4,1,4])\nif(any(b/=[4,1,4]))error stop 1')))
 add(label+'_self_reallocate',prog(t+',allocatable::a(:)',ok('a=['+vals+']\na=a([4,2,2])\nif(size(a)/=3.or.any(a/=[4,2,2]))error stop 1')))
 add(label+'_bare_actual',prog(t+'::a(4)','a=['+vals+']\ncall inspect(a([4,1,4]))\n'+ok('')+'\ncontains\nsubroutine inspect(x)\n'+t+',intent(in)::x(:)\nif(size(x)/=3.or.any(x/=[4,1,4]))error stop 1\nend subroutine'))
 add(label+'_parenthesized_reallocate',prog(t+',allocatable::a(:)','a=['+vals+']\ncall replace((a([4,1,4])),a)\n'+ok('if(size(a)/=3.or.any(a/=[4,1,4]))error stop 1')+'\ncontains\nsubroutine replace(x,y)\n'+t+',intent(in)::x(:)\n'+t+',allocatable,intent(out)::y(:)\nallocate(y(size(x)))\ny=x\nend subroutine'))
 add(label+'_selected_only',prog(t+'::a(4),b(3)',ok('a(2)=9\nb=a([2,2,2])\nif(any(b/=9))error stop 1')))
 add(label+'_function_result',prog(t+'::a(4),b(3)','a=['+vals+']\nb=pick(a)\n'+ok('if(any(b/=[4,1,4]))error stop 1')+'\ncontains\nfunction pick(x) result(y)\n'+t+',intent(in)::x(:)\n'+t+'::y(3)\ny=x([4,1,4])\nend function'))
add('nested_indices',prog('integer::a(4),map(4),idx(3),b(3)',ok('a=[10,20,30,40]\nmap=[4,1,3,2]\nidx=[2,1,2]\nb=a(map(idx))\nif(any(b/=[10,40,10]))error stop 1')))
add('selector_section',prog('integer::a(4),idx(4),b(2)',ok('a=[10,20,30,40]\nidx=[4,1,3,2]\nb=a(idx(4:2:-2))\nif(any(b/=[20,10]))error stop 1')))
add('index_once','module m\nimplicit none\ninteger::calls=0\ncontains\nimpure elemental function pick(i) result(j)\ninteger,intent(in)::i\ninteger::j\ncalls=calls+1\nj=i\nend function\nend module\nprogram p\nuse m\nimplicit none\ninteger::a(4),b(3)\na=[10,20,30,40]\nb=a(pick([4,1,4]))\nif(calls/=3.or.any(b/=[40,10,40]))error stop 1\nprint \'(i0)\',1\nend program\n')
for kind in [4,8]:
 suffix='_8' if kind==8 else ''
 add('real'+str(kind)+'_tiny_signed_zero',prog(f'real({kind})::a(3),b(3)',ok(f'a=[-0.0{suffix},tiny(0.0{suffix}),0.0{suffix}]\nb=a([2,3,1])\nif(b(1)/=tiny(0.0{suffix}).or.sign(1.0{suffix},b(2))/=1.or.sign(1.0{suffix},b(3))/=-1)error stop 1')))
add('integer8_extremes',prog('integer(8)::a(3),b(3)',ok('a=[-huge(0_8)-1_8,huge(0_8),9007199254740993_8]\nb=a([3,1,2])\nif(any(b/=[9007199254740993_8,-huge(0_8)-1_8,huge(0_8)]))error stop 1')))
# Original exact closure drivers: preserve ordinary, all duplicate, empty and recursive filter behavior.
for name,values,expected in [('mixed','[3,1,3,2,1,-5,2]','[3,1,2,-5]'),('all_equal','[8,8,8,8]','[8]'),('all_unique','[3,-1,0,2]','[3,-1,0,2]')]:
 driver='program p\nuse utility_closure\nimplicit none\ninteger,allocatable::x(:)\nx=unique_vec_int('+values+')\nif(size(x)/=size('+expected+').or.any(x/='+expected+'))error stop 1\nx=unique_vec_int(x)\nif(any(x/='+expected+'))error stop 2\nprint \'(i0)\',1\nend program\n';add('original_'+name,closure+driver.encode())
add('original_empty',closure+b"program p\nuse utility_closure\nimplicit none\ninteger::empty(0)\ninteger,allocatable::x(:)\nx=unique_vec_int(empty)\nif(size(x)/=0)error stop 1\nx=unique_vec_int(x)\nif(size(x)/=0)error stop 2\nprint '(i0)',1\nend program\n")
add('original_recursive_filter',closure+b"program p\nuse utility_closure\nimplicit none\ninteger::a(6)\ninteger,allocatable::b(:)\na=[3,-1,2,3,7,0]\ncall set_alloc(a([2,1,3,4,5,6]),b,jmin=0,jmax=3)\nif(any(b/=[3,2,3,0]))error stop 1\nprint '(i0)',1\nend program\n")
for name,decl,body in [
 ('bad_low','integer::a(2),b(1)','a=1\nb=a([0])'),
 ('bad_high','integer::a(2),b(1)','a=1\nb=a([3])'),
 ('bad_int64','integer::a(2),b(1)','a=1\nb=a([huge(0_8)])'),
 ('undefined_index','integer::a(2),b(1),idx(1)','a=1\nb=a(idx)'),
 ('undefined_selected','integer::a(2),b(1)','a(1)=4\nb=a([2])'),
 ('unallocated','integer,allocatable::a(:)\ninteger::b(1)','b=a([1])'),
 ('unallocated_empty','integer,allocatable::a(:)\ninteger::b(0),idx(0)','b=a(idx)'),
 ('empty_base_bad_index','integer::a(0),b(1)','b=a([1])'),
 ('temporary_cap','integer::a(1)\ninteger,allocatable::idx(:),b(:)','a=1\nallocate(idx(500001))\nidx=1\nb=a(idx)'),
 ('size_undefined','integer::a(2)','print *,size(a([1]))')]:add(name,prog(decl,body),stage='runtime',gnu='compile',expected='')
for name,decl,body,gnu in [
 ('logical_base','logical::a(2),b(1)','a=.true.\nb=a([1])','compile'),
 ('pointer_base','integer,target::t(2)\ninteger,pointer::a(:)\ninteger::b(1)','t=1\na=>t\nb=a([1])','compile'),
 ('matrix_column','integer::a(2,2),b(2,1)','a=1\nb=a(:,[1])','compile'),
 ('scatter','integer::a(3)','a=1\na([3,1])=2','compile'),
 ('vector_triplet','integer::a(3),b(2)','a=1\nb=a([1,2]:)','reject'),
 ('real_indices','integer::a(3),b(1)','a=1\nb=a([1.0])','reject'),
 ('rank2_indices','integer::a(3),b(2),idx(2,1)','a=1\nidx=1\nb=a(idx)','reject')]:add(name,prog(decl,body),stage='compile',gnu=gnu,expected='')
# Bare array-section actuals are only ordinary assumed-shape INTENT(IN), and retain base identity.
for name,attrs,rank in [('out','intent(out)',':'),('inout','intent(inout)',':'),('allocatable','allocatable,intent(in)',':'),('pointer','pointer,intent(in)',':'),('target','target,intent(in)',':'),('explicit_shape','intent(in)','2')]:
 add('bare_'+name,prog('integer::a(3)','a=1\ncall take(a([3,1]))\ncontains\nsubroutine take(x)\ninteger,'+attrs+'::x('+rank+')\nend subroutine'),stage='compile',gnu='reject' if name in ['out','inout','allocatable','pointer'] else 'compile',expected='')
add('matrix_bare_retained',prog('integer::a(3,2)','a=1\ncall take(a([3,1],:))\ncontains\nsubroutine take(x)\ninteger,intent(in)::x(:,:)\nend subroutine'),stage='compile',gnu='compile',expected='')
for name,selector,outactual in [('same_base','[3,1]','a'),('empty_same_base','empty','a'),('disjoint_base_guard','[1]','a(3:3)')]:
 add('bare_alias_'+name,prog('integer::a(3),empty(0)','a=[1,2,3]\ncall take(a('+selector+'),'+outactual+')\ncontains\nsubroutine take(x,y)\ninteger,intent(in)::x(:)\ninteger,intent(out)::y(:)\ny=9\nend subroutine'),stage='runtime',gnu='compile',expected='',note='Conservative whole-base alias guard; not a GNU execution oracle.')
add('bare_module_conflict','module m\nimplicit none\ninteger::a(3)\ncontains\nsubroutine take(x)\ninteger,intent(in)::x(:)\nprint *,a(1),x(1)\nend subroutine\nend module\nprogram p\nuse m\nimplicit none\na=1\ncall take(a([1]))\nend program\n',stage='compile',gnu='compile',expected='')
# Current CHARACTER and numeric matrix/tensor positive behavior is explicitly preserved.
add('character_preserved',prog('character(2)::a(3),b(2)',ok("a=['aa','bb','cc']\nb=a([3,1])\nif(any(b/=['cc','aa']))error stop 1")))
add('matrix_preserved',prog('integer::a(2,2),b(2,2)',ok('a(:,1)=[1,2]\na(:,2)=[3,4]\nb=a([2,1],:)\nif(any(b(:,1)/=[2,1]).or.any(b(:,2)/=[4,3]))error stop 1')))
add('tensor_preserved',prog('integer::a(2,2,2),b(2,2,2)',ok('a=1\na(2,1,1)=7\nb=a([2,1],:,:)\nif(b(1,1,1)/=7.or.b(2,1,1)/=1)error stop 1')))
# Exact standalone dependency bodies avoid falsely claiming ordinary-function I/O support.
standalone=b'module dependency_closure\r\nimplicit none\r\ncharacter(*),parameter::mod_str="utilities, "\r\ncontains\r\n'+bodies[1]+b'\r\n'+bodies[2]+b'end module\r\n'
(R/'source/dependency_closure.f90').write_bytes(standalone)
add('original_unique_int_standalone',standalone+b"program p\nuse dependency_closure\nimplicit none\ninteger::a(7),ipos(7),n\na=[3,1,3,2,1,-5,2]\ncall unique_int(a,ipos,n)\nif(n/=4.or.any(ipos(:n)/=[1,2,4,6]))error stop 1\nif(any(a(ipos(:n))/=[3,1,2,-5]))error stop 2\nprint '(i0)',1\nend program\n")
add('original_unique_int_empty',standalone+b"program p\nuse dependency_closure\nimplicit none\ninteger::a(0),ipos(0),n\ncall unique_int(a,ipos,n)\nif(n/=0)error stop 1\nprint '(i0)',1\nend program\n")
add('original_set_alloc_filter_standalone',standalone+b"program p\nuse dependency_closure\nimplicit none\ninteger::a(6)\ninteger,allocatable::b(:)\na=[3,-1,2,3,7,0]\ncall set_alloc_int_vec(a([2,1,3,4,5,6]),b,jmin=0,jmax=3)\nif(any(b/=[3,2,3,0]))error stop 1\nprint '(i0)',1\nend program\n")
# Numeric gathered function actuals must retain the final producer closing-parenthesis source anchor.
for typ in ['integer','real']:
 for kind in [4,8]:
  for snapshot in [False,True]:
   name=f'{typ}{kind}_function_actual_'+('snapshot_keyword' if snapshot else 'bare')
   arg='v=(a([3,1]))' if snapshot else 'a([3,1])'
   s='program p\nimplicit none\n'+f'{typ}({kind})::a(3),b\n'+'a=[1,2,3]\nb=total('+arg+')\nif(b/=4)error stop 1\n'+"print '(i0)',1\ncontains\nfunction total(v) result(out)\n"+f'{typ}({kind}),intent(in)::v(:)\n{typ}({kind})::out\n'+'out=sum(v)\nend function\nend program\n'
   add(name,s)
# Add separate supported synthetic names; preserve the first RESULT(out) sources.
for oldcase in list(rows):
 if '_function_actual_' not in oldcase['name']:continue
 raw=(R/oldcase['source']).read_bytes()
 add(oldcase['name']+'_supported_result',re.sub(rb'\bout\b',b'result_value',raw))
add('temporary_cap_high_budget',(R/'cases/temporary_cap.f90').read_bytes(),stage='runtime',gnu='compile',expected='')
contracts=json.loads((P/'contracts.json').read_text())
for row in rows:
 contract=contracts[row['name']];require(contract['sha256']==row['sha256'],'generated source differs: '+row['name']);row.update(contract)
(R/'manifest.json').write_text(json.dumps({'status':'Observed first preview negative pins preserved; additive controls separately validated, no original source edits','cases':rows},indent=2)+'\n');print(len(rows),'source cases')
