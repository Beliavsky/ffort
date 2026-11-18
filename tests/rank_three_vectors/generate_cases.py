from pathlib import Path
import hashlib,json
R=Path(__file__).resolve().parent;rows=[]
def add(name,source,stage='success',gnu='run',expected='1\n'):
 p=R/'cases'/(name+'.f90');p.write_bytes(source.encode());rows.append(dict(name=name,source='cases/'+p.name,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),stage=stage,gnu=gnu,expected=expected,diagnostic=None))
def prog(decl,body):return 'program p\nimplicit none\n'+decl+'\n'+body+'\nend program\n'
def expr(axis,idx='idx',base='a'):
 selectors=[':']*3;selectors[axis-1]=idx;return base+'('+','.join(selectors)+')'
def assert_success(body):return body+"\nprint '(i0)',1"
# Literal integer data also exactly representable in both supported real kinds.
for typ,kind in [('integer',4),('integer',8),('real',4),('real',8)]:
 for axis in [1,2,3]:
  dims=[3,3,3];out=dims.copy();out[axis-1]=2;shape=','.join(map(str,out));loop=[]
  for k in range(1,out[2]+1):
   for j in range(1,out[1]+1):
    for i in range(1,out[0]+1):
     coords=[i,j,k];coords[axis-1]=[3,1][coords[axis-1]-1];loop.append(coords[0]+3*(coords[1]-1)+9*(coords[2]-1))
  values=','.join(str(v)+('_8' if typ=='integer' and kind==8 else '') for v in loop)
  add(f'{typ}{kind}_axis{axis}',prog(f'{typ}({kind})::a(3,3,3),b({shape})\ninteger::i,idx(2)',assert_success('a=reshape([(i,i=1,27)],[3,3,3])\nidx=[3,1]\nb='+expr(axis)+'\nif(any(b/=reshape(['+values+'],['+shape+'])))error stop 1')))
for axis in [1,2,3]:
 selectors=expr(axis);lower=[-2,4,-5];upper=[0,6,-3];v=[upper[axis-1],lower[axis-1],upper[axis-1]]
 add(f'lower_bounds_axis{axis}',prog('integer::a(-2:0,4:6,-5:-3),b(3,3,3),idx(3),i,j,k',assert_success('do k=-5,-3\ndo j=4,6\ndo i=-2,0\na(i,j,k)=i+10*j+100*k\nend do\nend do\nend do\nidx=['+','.join(map(str,v))+']\nb='+selectors+'\ndo k=1,3\ndo j=1,3\ndo i=1,3\nif(b(i,j,k)/='+['idx(i)+10*(j+3)+100*(k-6)','(i-3)+10*idx(j)+100*(k-6)','(i-3)+10*(j+3)+100*idx(k)'][axis-1]+')error stop 1\nend do\nend do\nend do')))
 shape=[3,3,3];shape[axis-1]=0;dims=','.join(map(str,shape))
 add(f'empty_indices_axis{axis}',prog(f'integer::a(3,3,3),idx(0),b({dims})',assert_success('b='+selectors+'\nif(size(b)/=0.or.any(shape(b)/=['+dims+']))error stop 1')))
 shape=[3,3,3];shape[axis%3]=0;dims=','.join(map(str,shape))
 add(f'empty_other_axis{axis}',prog(f'integer::a({dims}),idx(2)\ninteger,allocatable::b(:,:,:)',assert_success('idx=[3,1]\nb='+selectors+'\nif(size(b)/=0)error stop 1')))
 add(f'empty_other_bad_index_axis{axis}',prog(f'integer::a({dims}),idx(1)\ninteger,allocatable::b(:,:,:)', 'idx=[4]\nb='+selectors),stage='runtime',gnu='compile',expected='')
 add(f'empty_other_undefined_index_axis{axis}',prog(f'integer::a({dims}),idx(1)\ninteger,allocatable::b(:,:,:)', 'b='+selectors),stage='runtime',gnu='compile',expected='')
 add(f'alias_assignment_axis{axis}',prog('integer::a(3,3,3),before(3,3,3),idx(3),i',assert_success('a=reshape([(i,i=1,27)],[3,3,3])\nbefore=a\nidx=[3,1,1]\na='+selectors+'\nif(any(a/='+expr(axis,base='before')+'))error stop 1')))
 for name,val in [('low',0),('high',4),('huge',9223372036854775807)]:
  add(f'{name}_index_axis{axis}',prog('integer::a(3,3,3)\ninteger(8)::idx(1)\ninteger,allocatable::b(:,:,:)', 'a=1\nidx=['+str(val)+'_8]\nb='+selectors),stage='runtime',gnu='compile',expected='')
 add(f'kind_undefined_axis{axis}',prog('real(8),allocatable::a(:,:,:)\ninteger::idx(2)',assert_success('if(kind('+selectors+')/=8)error stop 1')))
 add(f'selected_only_axis{axis}',prog('integer::a(3,3,3),idx(1)\ninteger,allocatable::b(:,:,:)',assert_success(expr(axis,'2')+'=9\nidx=[2]\nb='+selectors+'\nif(any(b/=9))error stop 1')))
 add(f'undefined_selected_axis{axis}',prog('integer::a(3,3,3),idx(1)\ninteger,allocatable::b(:,:,:)', 'idx=[2]\nb='+selectors),stage='runtime',gnu='compile',expected='')
 # Count actual calls without requiring an evaluation order among vector elements.
 source='module m\nimplicit none\ninteger::calls=0\ncontains\nimpure elemental integer function pick(i) result(v)\ninteger,intent(in)::i\ncalls=calls+1\nv=i\nend function\nend module\nprogram p\nuse m\nimplicit none\ninteger::a(3,3,3),idx(2)\ninteger,allocatable::b(:,:,:)\na=1\nidx=[3,1]\nb='+expr(axis,'pick(idx)')+"\nif(calls/=2.or.sum(b)/=18)error stop 1\nprint '(i0)',1\nend program\n"
 add(f'index_once_axis{axis}',source)
 add(f'parenthesized_actual_axis{axis}','program p\nimplicit none\ninteger::a(3,3,3),idx(2)\na=1\nidx=[3,1]\ncall inspect(('+selectors+"))\nprint '(i0)',1\ncontains\nsubroutine inspect(x)\ninteger,intent(in)::x(:,:,:)\nif(sum(x)/=18)error stop 1\nend subroutine\nend program\n")
for name,sel,decl in [('multiple_vectors','a(idx,idx,:)','integer::a(3,3,3),idx(2)'),('scalar_other','a(idx,1,:)','integer::a(3,3,3),idx(2)'),('partial_other','a(idx,1:2,:)','integer::a(3,3,3),idx(2)'),('strided_other','a(idx,::1,:)','integer::a(3,3,3),idx(2)'),('logical_base','a(idx,:,:)','logical::a(3,3,3)\ninteger::idx(2)'),('character_base','a(idx,:,:)','character(2)::a(3,3,3)\ninteger::idx(2)'),('matrix_columns_retained','a(:,idx)','integer::a(3,3),idx(2)'),('rank_one_retained','a(idx)','integer::a(3),idx(2)')]:
 add(name,prog(decl,'idx=[3,1]\nprint *,size('+sel+')'),stage='compile',gnu='compile',expected='')
add('scatter_retained',prog('integer::a(3,3,3),idx(2)','idx=[3,1]\na(idx,:,:)=1'),stage='compile',gnu='compile',expected='')
add('result_cap',prog('integer,allocatable::a(:,:,:),b(:,:,:)\ninteger::idx(2)','allocate(a(1,600000,1))\na=1\nidx=[1,1]\nb=a(idx,:,:)'),stage='runtime',gnu='compile',expected='')
add('size_undefined_retained',prog('integer::a(3,3,3),idx(2)','idx=[3,1]\nprint *,size(a(idx,:,:))'),stage='runtime',gnu='compile',expected='')
# Additional direct allocatable assignment and retained context boundaries.
for axis in [1,2,3]:
 dims=[3,3,3];dims[axis-1]=2;values=[]
 for k in range(1,dims[2]+1):
  for j in range(1,dims[1]+1):
   for i in range(1,dims[0]+1):
    coords=[i,j,k];coords[axis-1]=[3,1][coords[axis-1]-1];values.append(coords[0]+3*(coords[1]-1)+9*(coords[2]-1))
 shape=','.join(map(str,dims))
 add(f'allocatable_self_reallocate_axis{axis}',prog('integer,allocatable::a(:,:,:)\ninteger::idx(2),i',assert_success('allocate(a(3,3,3))\na=reshape([(i,i=1,27)],[3,3,3])\nidx=[3,1]\na='+expr(axis)+'\nif(any(shape(a)/=['+shape+']))error stop 1\nif(any(a/=reshape(['+','.join(map(str,values))+'],['+shape+'])))error stop 2')))
add('pointer_base_retained',prog('integer,target::storage(3,3,3)\ninteger,pointer::a(:,:,:)\ninteger::idx(2)','storage=1\na=>storage\nidx=[3,1]\nprint *,sum(a(:,idx,:))'),stage='compile',gnu='compile',expected='')
add('where_retained',prog('integer::a(3,3,3),idx(3)','a=1\nidx=[3,1,2]\nwhere(a>0)a=a(:,:,idx)'),stage='compile',gnu='compile',expected='')
add('forall_retained',prog('integer::a(3,3,3),b(3,3,3),idx(3),i','b=1\nidx=[3,1,2]\nforall(i=1:3)a(i,1,1)=sum(b(:,idx,:))'),stage='compile',gnu='compile',expected='')
# FORALL is standard in F2008; F2018 adds an obsolescence warning, not a rejection.
rows[-1]['gnu_flags']=['-std=f2008','-pedantic-errors','-fcheck=all','-O0']
add('unparenthesized_actual_retained','program p\nimplicit none\ninteger::a(3,3,3),idx(2)\na=1\nidx=[3,1]\ncall inspect(a(:,:,idx))\ncontains\nsubroutine inspect(x)\ninteger,intent(in)::x(:,:,:)\nend subroutine\nend program\n',stage='compile',gnu='compile',expected='')
add('writable_actual_retained','program p\nimplicit none\ninteger::a(3,3,3),idx(2)\na=1\nidx=[3,1]\ncall change((a(:,idx,:)))\ncontains\nsubroutine change(x)\ninteger,intent(out)::x(:,:,:)\nx=1\nend subroutine\nend program\n',stage='compile',gnu='reject',expected='')
# The closure contains byte-exact original CRLF routine bodies. Only drivers vary.
closure=(R/'source/exact_closure.f90').read_bytes().decode()
for axis in [1,2,3]:
 vals=[]
 for k in range(1,4):
  for j in range(1,4):
   for i in range(1,4):
    coords=[i,j,k];coords[axis-1]=[3,1,3][coords[axis-1]-1];vals.append(coords[0]+3*(coords[1]-1)+9*(coords[2]-1))
 driver='program p\nuse utility_closure\nimplicit none\nreal(dp),allocatable::a(:,:,:)\ninteger::i\nallocate(a(3,3,3))\na=reshape([(i,i=1,27)],[3,3,3])\ncall select_tensor_real([3,1,3],a'+('' if axis==1 else ','+str(axis))+')\nif(any(shape(a)/=[3,3,3]))error stop 1\nif(any(a/=reshape(['+','.join(map(str,vals))+"],[3,3,3])))error stop 2\nprint '(i0)',1\nend program\n"
 add(f'original_select_axis{axis}',closure+driver)
driver="program p\nuse utility_closure\nimplicit none\nreal(dp),allocatable::a(:,:,:)\ninteger::axis,empty(0),expected(3)\ndo axis=1,3\nallocate(a(3,3,3))\na=1\ncall select_tensor_real(empty,a,axis)\nexpected=[3,3,3]\nexpected(axis)=0\nif(any(shape(a)/=expected))error stop 1\ncall select_tensor_real(empty,a,axis)\nif(any(shape(a)/=expected))error stop 2\ndeallocate(a)\nend do\nprint '(i0)',1\nend program\n"
add('original_select_empty_repeated',closure+driver)

# Retain all initial synthetic fixtures unchanged. Their rank-three RESHAPE,
# ANY and SUM oracles are outside the existing subset, unrelated to gathering.
# Separately named scalar-loop variants test the same values without that dependency.
def loops(body,dims=('3','3','3')):
 return 'do k=1,'+str(dims[2])+'\ndo j=1,'+str(dims[1])+'\ndo i=1,'+str(dims[0])+'\n'+body+'\nend do\nend do\nend do'
def ordinal(axis,idx='idx'):
 coords=['i','j','k'];coords[axis-1]=idx+'('+coords[axis-1]+')'
 return coords[0]+'+3*('+coords[1]+'-1)+9*('+coords[2]+'-1)'
def corrected(old,source):
 row=next(x for x in rows if x['name']==old)
 row['stage']='compile';row['gnu']='compile';row['expected']=''
 row['boundary']='Original synthetic oracle uses an unrelated unsupported rank-three array intrinsic; bytes retained.'
 add(old+'_direct',source);rows[-1]['oracle_variant_of']=old
for typ,kind in [('integer',4),('integer',8),('real',4),('real',8)]:
 for axis in [1,2,3]:
  dims=[3,3,3];dims[axis-1]=2;shape=','.join(map(str,dims))
  decl=f'{typ}({kind})::a(3,3,3),b({shape})\ninteger::i,j,k,idx(2)'
  body=loops('a(i,j,k)=i+3*(j-1)+9*(k-1)')+'\nidx=[3,1]\nb='+expr(axis)+'\n'+loops('if(b(i,j,k)/=('+ordinal(axis)+'))error stop 1',dims)
  corrected(f'{typ}{kind}_axis{axis}',prog(decl,assert_success(body)))
for axis in [1,2,3]:
 decl='integer::a(3,3,3),before(3,3,3),idx(3),i,j,k'
 body=loops('a(i,j,k)=i+3*(j-1)+9*(k-1)')+'\nbefore=a\nidx=[3,1,1]\na='+expr(axis)+'\n'+loops('if(a(i,j,k)/=('+ordinal(axis)+'))error stop 1')
 corrected(f'alias_assignment_axis{axis}',prog(decl,assert_success(body)))
 dims=[3,3,3];dims[axis-1]=1
 decl='integer::a(3,3,3),idx(1),i,j,k\ninteger,allocatable::b(:,:,:)'
 body=expr(axis,'2')+'=9\nidx=[2]\nb='+expr(axis)+'\n'+loops('if(b(i,j,k)/=9)error stop 1',dims)
 corrected(f'selected_only_axis{axis}',prog(decl,assert_success(body)))
 old=next(x for x in rows if x['name']==f'index_once_axis{axis}')
 src=(R/old['source']).read_text().replace('integer::a(3,3,3),idx(2)','integer::a(3,3,3),idx(2),i,j,k')
 dims=[3,3,3];dims[axis-1]=2
 src=src.replace('if(calls/=2.or.sum(b)/=18)error stop 1','if(calls/=2.or.size(b)/=18)error stop 1\n'+loops('if(b(i,j,k)/=1)error stop 2',dims))
 corrected(f'index_once_axis{axis}',src)
 old=next(x for x in rows if x['name']==f'parenthesized_actual_axis{axis}')
 src=(R/old['source']).read_text().replace('if(sum(x)/=18)error stop 1','integer::i,j,k\nif(size(x)/=18)error stop 1\n'+loops('if(x(i,j,k)/=1)error stop 2',('size(x,1)','size(x,2)','size(x,3)')))
 corrected(f'parenthesized_actual_axis{axis}',src)
 dims=[3,3,3];dims[axis-1]=2;shape=','.join(map(str,dims))
 decl='integer,allocatable::a(:,:,:)\ninteger::idx(2),i,j,k'
 body='allocate(a(3,3,3))\n'+loops('a(i,j,k)=i+3*(j-1)+9*(k-1)')+'\nidx=[3,1]\na='+expr(axis)+'\nif(any(shape(a)/=['+shape+']))error stop 1\n'+loops('if(a(i,j,k)/=('+ordinal(axis)+'))error stop 2',dims)
 corrected(f'allocatable_self_reallocate_axis{axis}',prog(decl,assert_success(body)))
 driver='program p\nuse utility_closure\nimplicit none\nreal(dp),allocatable::a(:,:,:)\ninteger::i,j,k,idx(3)\nallocate(a(3,3,3))\n'+loops('a(i,j,k)=i+3*(j-1)+9*(k-1)')+'\nidx=[3,1,3]\ncall select_tensor_real(idx,a'+('' if axis==1 else ','+str(axis))+')\nif(any(shape(a)/=[3,3,3]))error stop 1\n'+loops('if(a(i,j,k)/=('+ordinal(axis)+'))error stop 2')+"\nprint '(i0)',1\nend program\n"
 corrected(f'original_select_axis{axis}',closure+driver)


# Producer CASE-header semicolon regression: original routines use this syntax.
add('case_inline_assignments',prog('integer::n,v','v=0\ndo n=1,4\nselect case(n)\ncase(1);v=v+1\ncase(2:3);v=v+n\ncase default;v=v+4\nend select\nend do\n'+assert_success('if(v/=10)error stop 1')))
add('case_inline_calls','program p\nimplicit none\ninteger::n,v\nv=0\ndo n=1,4\nselect case(n)\ncase(1);call bump(v,1)\ncase(2,3);call bump(v,n)\ncase default;call bump(v,4)\nend select\nend do\nif(v/=10)error stop 1\nprint \'(i0)\',1\ncontains\nsubroutine bump(v,n)\ninteger,intent(inout)::v\ninteger,intent(in)::n\nv=v+n\nend subroutine\nend program\n')
add('case_inline_if',prog('integer::v','v=0\nselect case(1)\ncase(1);if(.true.)v=7\ncase default;v=9\nend select\n'+assert_success('if(v/=7)error stop 1')))
add('case_inline_do',prog('integer::v,j','v=0\nselect case(1)\ncase(1);do j=1,3\nv=v+j\nend do\ncase default;v=9\nend select\n'+assert_success('if(v/=6)error stop 1')))
add('case_same_line_arms',prog('integer::v','v=0\nselect case(2);case(1);v=1;case(2);v=2;case default;v=3;end select\n'+assert_success('if(v/=2)error stop 1')))
add('case_literal_semicolon',prog('character(3)::s',"select case('x')\ncase('x');s='a;b'\ncase default;s='no!'\nend select\n"+assert_success("if(s/='a;b')error stop 1")))
add('case_continued_header',prog('integer::v','v=0\nselect case(1)\ncase (&\n 1);v=7\ncase default;v=9\nend select\n'+assert_success('if(v/=7)error stop 1')))
add('case_newline_comment',prog('integer::v','v=0\nselect case(1)\ncase(1) ! ordinary multiline body\nv=7\ncase default ! not selected\nv=9\nend select\n'+assert_success('if(v/=7)error stop 1')))
add('case_default_first',prog('integer::v','v=0\nselect case(1)\ncase default;v=9\ncase(1);v=7\nend select\n'+assert_success('if(v/=7)error stop 1')))
add('case_logical_inline',prog('integer::v','v=0\nselect case(.false.)\ncase(.true.);v=9\ncase(.false.);v=7\nend select\n'+assert_success('if(v/=7)error stop 1')))


# Exact unchanged historical fixture: now a runtime safety boundary, never a GNU execution oracle.
add("historical_rank3_uninitialized",'program p\nimplicit none\ninteger::a(3,2,1),b(2,2,1)\nb=a([1,2],:,:)\nend program\n',stage="runtime",gnu="compile",expected="")

# Exact stage/location/message observations from immutable corrected3e9c191d.
PINNED_DIAGNOSTICS = {'integer4_axis1': '5:32: RESHAPE SHAPE must be an INTEGER vector of known size 1 or 2', 'integer4_axis2': '5:32: RESHAPE SHAPE must be an INTEGER vector of known size 1 or 2', 'integer4_axis3': '5:32: RESHAPE SHAPE must be an INTEGER vector of known size 1 or 2', 'integer8_axis1': '5:32: RESHAPE SHAPE must be an INTEGER vector of known size 1 or 2', 'integer8_axis2': '5:32: RESHAPE SHAPE must be an INTEGER vector of known size 1 or 2', 'integer8_axis3': '5:32: RESHAPE SHAPE must be an INTEGER vector of known size 1 or 2', 'real4_axis1': '5:32: RESHAPE SHAPE must be an INTEGER vector of known size 1 or 2', 'real4_axis2': '5:32: RESHAPE SHAPE must be an INTEGER vector of known size 1 or 2', 'real4_axis3': '5:32: RESHAPE SHAPE must be an INTEGER vector of known size 1 or 2', 'real8_axis1': '5:32: RESHAPE SHAPE must be an INTEGER vector of known size 1 or 2', 'real8_axis2': '5:32: RESHAPE SHAPE must be an INTEGER vector of known size 1 or 2', 'real8_axis3': '5:32: RESHAPE SHAPE must be an INTEGER vector of known size 1 or 2', 'empty_other_bad_index_axis1': '6:5: vector row index out of bounds', 'empty_other_undefined_index_axis1': '5:5: read of uninitialized array element idx', 'alias_assignment_axis1': '4:32: RESHAPE SHAPE must be an INTEGER vector of known size 1 or 2', 'low_index_axis1': '8:5: vector row index out of bounds', 'high_index_axis1': '8:5: vector row index out of bounds', 'huge_index_axis1': '8:5: vector row index out of bounds', 'selected_only_axis1': '8:13: Array intrinsic requires a rank-one or rank-two array', 'undefined_selected_axis1': '6:5: read of uninitialized gathered array element', 'index_once_axis1': '19:22: Array intrinsic requires a rank-one or rank-two array', 'parenthesized_actual_axis1': '11:10: Array intrinsic requires a rank-one or rank-two array', 'empty_other_bad_index_axis2': '6:5: vector row index out of bounds', 'empty_other_undefined_index_axis2': '5:7: read of uninitialized array element idx', 'alias_assignment_axis2': '4:32: RESHAPE SHAPE must be an INTEGER vector of known size 1 or 2', 'low_index_axis2': '8:5: vector row index out of bounds', 'high_index_axis2': '8:5: vector row index out of bounds', 'huge_index_axis2': '8:5: vector row index out of bounds', 'selected_only_axis2': '8:13: Array intrinsic requires a rank-one or rank-two array', 'undefined_selected_axis2': '6:5: read of uninitialized gathered array element', 'index_once_axis2': '19:22: Array intrinsic requires a rank-one or rank-two array', 'parenthesized_actual_axis2': '11:10: Array intrinsic requires a rank-one or rank-two array', 'empty_other_bad_index_axis3': '6:5: vector row index out of bounds', 'empty_other_undefined_index_axis3': '5:9: read of uninitialized array element idx', 'alias_assignment_axis3': '4:32: RESHAPE SHAPE must be an INTEGER vector of known size 1 or 2', 'low_index_axis3': '8:5: vector row index out of bounds', 'high_index_axis3': '8:5: vector row index out of bounds', 'huge_index_axis3': '8:5: vector row index out of bounds', 'selected_only_axis3': '8:13: Array intrinsic requires a rank-one or rank-two array', 'undefined_selected_axis3': '6:5: read of uninitialized gathered array element', 'index_once_axis3': '19:22: Array intrinsic requires a rank-one or rank-two array', 'parenthesized_actual_axis3': '11:10: Array intrinsic requires a rank-one or rank-two array', 'multiple_vectors': '5:23: Rank-three vector subscripts support exactly one rank-one INTEGER vector', 'scalar_other': '5:24: Rank-three vector gathering requires bare colons on all other axes', 'partial_other': '5:26: Rank-three vector gathering requires bare colons on all other axes', 'strided_other': '5:26: Rank-three vector gathering requires bare colons on all other axes', 'logical_base': '6:24: Rank-three vector gathering requires a numeric non-POINTER array', 'character_base': '6:24: Rank-three vector gathering requires a numeric non-POINTER array', 'matrix_columns_retained': '5:21: Vector subscripts support only rank-one INTEGER row indices of a matrix', 'rank_one_retained': '5:16: read of uninitialized gathered array element', 'scatter_retained': '5:11: Vector row gathering is read-only; scatter assignment is unsupported', 'result_cap': '8:5: row gather result element limit exceeded', 'size_undefined_retained': '5:16: read of uninitialized gathered array element', 'allocatable_self_reallocate_axis1': '6:32: RESHAPE SHAPE must be an INTEGER vector of known size 1 or 2', 'allocatable_self_reallocate_axis2': '6:32: RESHAPE SHAPE must be an INTEGER vector of known size 1 or 2', 'allocatable_self_reallocate_axis3': '6:32: RESHAPE SHAPE must be an INTEGER vector of known size 1 or 2', 'pointer_base_retained': '4:26: POINTER requires deferred-shape rank-one array', 'where_retained': '6:11: WHERE mask must be a LOGICAL array', 'forall_retained': '6:38: Array intrinsic requires a rank-one or rank-two array', 'unparenthesized_actual_retained': '6:25: Parenthesize a gathered row value when passing it to a user procedure', 'writable_actual_retained': '6:26: Parenthesize a gathered row value when passing it to a user procedure', 'original_select_axis1': '56:32: RESHAPE SHAPE must be an INTEGER vector of known size 1 or 2', 'original_select_axis2': '56:32: RESHAPE SHAPE must be an INTEGER vector of known size 1 or 2', 'original_select_axis3': '56:32: RESHAPE SHAPE must be an INTEGER vector of known size 1 or 2', 'historical_rank3_uninitialized': '4:5: read of uninitialized gathered array element'}
for row in rows:
 if row["name"] in PINNED_DIAGNOSTICS:row["diagnostic"]=PINNED_DIAGNOSTICS[row["name"]]

# Separator/layout edge cases requested by independent producer review.
add('case_comment_semicolon',prog('integer::v','v=0\nselect case(1)\ncase(1) ! ; this is only a comment\nv=7\ncase default;v=9\nend select\n'+assert_success('if(v/=7)error stop 1')))
add('case_repeated_semicolons',prog('integer::v','v=0\nselect case(1)\ncase(1);;v=7;;\ncase default;;v=9\nend select\n'+assert_success('if(v/=7)error stop 1')))
add('case_nested_select',prog('integer::v','v=0\nselect case(1)\ncase(1);select case(2)\ncase(1);v=4\ncase(2);v=7\ncase default;v=6\nend select\ncase default;v=9\nend select\n'+assert_success('if(v/=7)error stop 1')))
add('case_after_end_select',prog('integer::v','v=0\nselect case(1)\ncase(1);v=7\ncase default;v=9\nend select;v=v+1\n'+assert_success('if(v/=8)error stop 1')))

# This valid GNU source retains a pre-existing physical-location subset boundary.
# No original body uses a continued CASE header. Keep GNU execution independent.
row=next(x for x in rows if x['name']=='case_continued_header')
row.update(stage='compile',expected='',gnu_expected='1\n',
 diagnostic='6:5: FortFront adapter disagreement: assignment is absent from IR',
 boundary='GNU-valid continued CASE header: producer action physical-location mapping remains unsupported; confirmed before this feature.')
# 0.53: numeric rank-one parsing is supported; this unchanged source reads undefined data.
row=next(x for x in rows if x['name']=='rank_one_retained');row.update(stage='runtime')
(R/'manifest.json').write_text(json.dumps({'status':'Observed exact negative contracts; supported candidates require exact silent check and execution agreement','cases':rows},indent=2)+'\n');print(len(rows),'cases')
