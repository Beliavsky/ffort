from pathlib import Path
import json,hashlib
ROOT=Path(__file__).resolve().parent
CASES=[]
def program(decl,body,procedures=''):
 return 'program p\nimplicit none\n'+decl+'\n'+body+'\n'+('contains\n'+procedures+'\n' if procedures else '')+'end program\n'
def add(name,source,output,category='success',gnu='run',diagnostic=None,numeric_lines=None,oracle_diagnostic=None,features=None):
 p=ROOT/'cases'/(name+'.f90');p.write_bytes(source.encode());c=dict(name=name,source='cases/'+p.name,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),category=category,gnu=gnu,expected_stdout=output,features=features or [])
 if diagnostic:c['diagnostic']=diagnostic
 if numeric_lines:c['numeric_lines']=numeric_lines
 if oracle_diagnostic:c['gnu_compile_diagnostic']=oracle_diagnostic
 CASES.append(c)
add('constructor_norm_scalar_expansion',program('integer::i\nreal::a(3)',"i=99\na=[(real(i),i=1,3)]+norm2([3.,4.])\nprint '(3f4.1,i4)',a,i"),' 6.0 7.0 8.0  99\n',features=['constructor index isolation','NORM2 scalar expansion'])
add('reverse_constructor_whole_bounds',program('integer::i,a(-2:0)',"i=77\na=[(i,i=3,1,-1)]\nprint '(6i4)',lbound(a),ubound(a),a,i"),'  -2   0   3   2   1  77\n',features=['negative stride','vector bounds'])
add('transpose_constructor_bounds',program('integer::i\nreal::a(-1:0,4:6)\nreal,allocatable::b(:,:)',"a=reshape([(real(i),i=1,6)],[2,3])\nb=transpose(a)+norm2([3.,4.])\nprint '(4i3)',lbound(b),ubound(b)\nprint '(6f5.1)',b"),'  1  1  3  2\n  6.0  8.0 10.0  7.0  9.0 11.0\n',features=['constructor RESHAPE','TRANSPOSE','scalar norm expansion','allocated bounds'])
add('nested_outer_dependent_controls',program('integer::i,j,a(6)',"i=77\nj=88\na=[((10*i+j,j=1,i),i=1,3)]\nprint '(10i4)',lbound(a,kind=8),ubound(a,kind=8),a,i,j"),'   1   6  11  21  22  31  32  33  77  88\n',features=['nested ownership','outer-dependent control','KIND8 bounds'])
add('character_min_constructor',program('integer::i\ncharacter(2)::pool(3),words(3)',"pool=['b ','a ','c ']\ni=9\nwords=[(min(pool(i),'bb'),i=1,3)]\nprint '(*(a))','[',words(1),'][',words(2),'][',words(3),']'\nprint '(i0)',i"),'[b ][a ][bb]\n9\n',features=['CHARACTER MIN','constructor values','outer index preservation'])
add('typed_character_max_expansion',program('integer::i\ncharacter(2)::pool(3)\ncharacter(4)::words(3),other(3)',"pool=['b ','a ','z ']\nwords=[character(4)::(min(pool(i),'bb'),i=1,3)]\nother=max(words,'c')\nprint '(*(a))','[',other(1),'][',other(2),'][',other(3),']'"),'[c   ][c   ][c   ]\n',features=['typed CHARACTER constructor','unequal length MIN','MAX scalar expansion'])
add('read_character_max_reverse',program('integer::i,s\ncharacter(40)::line\ncharacter(2)::pool(3),words(3)',"line='z a m'\nread(line,*,iostat=s)pool\nif(s/=0)error stop 1\nwords=[(max(pool(i),'b '),i=3,1,-1)]\nprint '(*(a))','[',words(1),'][',words(2),'][',words(3),']'"),'[m ][b ][z ]\n',features=['internal CHARACTER READ','reverse constructor','MAX'])
add('allocated_character_result_length',program('integer::i\ncharacter(:),allocatable::a,b,c\ncharacter(4)::words(2)',"a='a'\nb='bbbb'\nc=min(a,b)\nwords=[(c,i=1,2)]\nprint '(i0,a,a,a,a,a)',len(c),'[',words(1),'][',words(2),']'"),'4[a   ][a   ]\n',features=['scalar allocated CHARACTER','maximum result length','constructor snapshot'])
add('character_keywords_and_bounds',program('character(3)::a(2),b(2)\ninteger(8)::bounds(2)',"a=['aaa','zzz']\nb=max(a3='mmm',a1=a,a2='bb')\nbounds=[lbound(b,kind=8),ubound(b,kind=8)]\nprint '(2i3,a,a,a,a,a)',bounds,'[',b(1),'][',b(2),']'"),'  1  2[mmm][zzz]\n',features=['reordered MIN/MAX keywords','scalar expansion','bounds vector leaves'])
add('matrix_character_padding_bounds',program('character(3)::a(-1:0,2:3),b(2,2)',"a=reshape(['a  ','z  ','b  ','y  '],[2,2])\nb=max(a,'m')\nprint '(4i4)',lbound(a,kind=8),ubound(a,kind=8)\nprint '(*(a))','[',b(1,1),'][',b(2,1),'][',b(1,2),'][',b(2,2),']'"),'  -1   2   0   3\n[m  ][z  ][m  ][y  ]\n',features=['rank-two CHARACTER expansion','whole nonunit bounds'])
add('empty_axis_bounds_norm',program('real::a(-1:-2,4:6)',"print '(4i3,f4.1)',lbound(a),ubound(a),norm2(a)"),'  1  4  0  6 0.0\n',features=['per-axis zero extent','vector bounds','empty NORM2'])
add('empty_expression_bounds',program('real::a(0,3)',"print '(4i3)',lbound(a+norm2([3.,4.])),ubound(a+norm2([3.,4.]))"),'  1  1  0  3\n',features=['empty surrounding array','scalar NORM2','expression normalization'])
add('undefined_values_metadata_bounds',program('integer::i\nreal::a(-2:0)',"print '(3i4)',lbound(a,kind=8),ubound(a),kind(lbound(a,kind=8))\nprint '(3i4)',[(i,i=lbound(a,1),ubound(a,1))]"),'  -2   0   8\n  -2  -1   0\n',features=['metadata-only undefined data','bounds-driven constructor'])
add('zero_trip_undefined_norm',program('integer::i\nreal::v(2)\nreal,allocatable::a(:)',"a=[(norm2(v),i=1,0)]\nprint '(3i3)',size(a),lbound(a),ubound(a)"),'  0  1  0\n',features=['zero-trip body non-evaluation','NORM2 undefined operand','allocated zero bounds'])
add('zero_trip_undefined_character_min',program('integer::i\ncharacter(3)::x\ncharacter(3),allocatable::a(:)',"a=[(min(x,'b'),i=1,0)]\nprint '(3i3)',size(a),lbound(a),ubound(a)"),'  0  1  0\n',features=['zero-trip CHARACTER metadata','MIN length','empty bounds'])
add('callee_reads_host_not_index',program('integer::i,a(3)',"i=40\na=[(i+observe(),i=1,3)]\nprint '(4i4)',a,i",'''integer function observe()
observe=i
end function'''),'  41  42  43  40\n',features=['constructor overlay not inherited by callee','host variable'])
add('optional_dummy_index_overlay',program('',"call build()",'''subroutine build(k)
integer,optional,intent(in)::k
integer::a(3)
a=[(k,k=1,3)]
print '(3i3,l2,2i3)',a,present(k),lbound(a),ubound(a)
end subroutine'''),'  1  2  3 F  1  3\n',features=['absent OPTIONAL outer index','independent ownership','bounds'])
add('active_outer_do_isolation',program('integer::i,a(2)',"do i=7,8\na=[(i,i=1,2)]\nprint '(3i3)',a,i\nend do"),'  1  2  7\n  1  2  8\n',features=['active DO variable shadowing','separate constructor index'])
add('sibling_index_reuse_bounds',program('integer::i,a(4)',"i=50\na=[(i,i=1,2),(i,i=4,5)]\nprint '(7i3)',a,lbound((a)),ubound((a)),i"),'  1  2  4  5  1  4 50\n',features=['sibling index owner reuse','parenthesized bounds normalization'])
add('kind8_runtime_constructor_controls',program('integer(8)::i,lo,hi,a(3)',"i=77\nlo=9007199254740993_8\nhi=9007199254740997_8\na=[(i,i=lo,hi,2_8)]\nprint '(5i22)',a,lbound(a,kind=8),ubound(a,kind=8)\nprint '(i0)',i"),'9007199254740993 9007199254740995 9007199254740997 1 3\n77\n',numeric_lines=[0],features=['INTEGER8 runtime controls','exact large integer comparator','KIND8 bounds'])
add('norm_scalar_rank_three_context',program('integer::i\nreal(8)::a(2,1,2),b(2,1,2)',"a=reshape([(real(i,8),i=1,4)],[2,1,2])\nb=norm2([3d0,4d0])+a+norm2([0d0,-0d0])\nprint '(4f5.1)',b\nprint '(6i3)',lbound(b),ubound(b)"),'  6.0  7.0  8.0  9.0\n  1  1  1  2  1  2\n',features=['rank-three scalar expansion','constructor REAL8','zero norm','bounds'])
add('own_index_kind_metadata_control',program('integer::i,a(4)',"a=[(i,i=1,kind(i+1))]\nprint '(4i3)',a"),'  1  2  3  4\n',features=['own control index metadata inquiry','constructor control ownership'])
add('norm_scalar_dim_and_signed_zero',program('real(8)::a(2),b(2)',"a=[1d0,2d0]\nb=a+norm2([3d0,4d0],dim=1)\nprint '(4es25.17)',b,norm2([-0d0]),-0d0"),'6.0 7.0 0.0 -0.0\n',numeric_lines=[0],features=['rank-one DIM scalar norm','surrounding array positions','signed zero'])
add('dynamic_zero_constructor_step',program('integer::i,step\nreal::a(2),v(-1:0)',"step=0\nprint '(a)','SAFE'\na=[(norm2([real(i),0.]),i=lbound(v,1),ubound(v,1),step)]"),'SAFE\n',category='runtime',gnu='compile',diagnostic='constructor implied-DO step is zero',features=['bounds controls','dynamic zero step','atomic failure'])
add('unallocated_vector_bounds',program('real,allocatable::a(:,:)',"print '(a)','SAFE'\nprint '(2i3)',lbound(a,kind=8)"),'SAFE\n',category='runtime',gnu='compile',diagnostic='reference to unallocated array a',features=['evaluated descriptor availability','vector bounds','atomic output'])
add('undefined_character_min_pending_output',program('character(2)::a,b',"b='zz'\nwrite(*,'(a,t2,a)',advance='no')'ABCD','x'\nprint '(a)',min(a,b)"),'AxCD',category='runtime',gnu='compile',diagnostic='read of uninitialized variable a',features=['CHARACTER MIN data guard','nonadvancing atomicity'])
add('rank_two_constructor_leaf_boundary',program('integer::i,a(2,2),b(8)',"a=1\nb=[(transpose(a),i=1,2)]\nprint '(8i2)',b"),'',category='reject',gnu='compile',diagnostic='Constructor implied-DO items must be intrinsic scalars or rank-one arrays',features=['bounded rank-one constructor leaves','TRANSPOSE boundary'])
add('constant_character_min_gnu_rejection',program('character(2)::a(2)',"a=min(['Z','A'],['YY','B '])\nprint '(*(a))','[',a(1),'][',a(2),']'"),'[YY][A ]\n',gnu='known-reject',oracle_diagnostic='same length',features=['independent CHARACTER padding oracle','explicit GNU14 constant-array limitation'])
# Separate supported variants. The three original failed-source fixtures above
# remain byte-identical and explicitly document their pre-existing boundaries.
add('typed_allocated_character_result_length',program('integer::i\ncharacter(:),allocatable::a,b,c\ncharacter(4)::words(2)',"a='a'\nb='bbbb'\nc=min(a,b)\nwords=[character(4)::(c,i=1,2)]\nprint '(i0,a,a,a,a,a)',len(c),'[',words(1),'][',words(2),']'"),'4[a   ][a   ]\n',features=['allocated scalar MIN length','typed CHARACTER constructor'])
add('module_callee_reads_host_not_index','''module values
implicit none
integer::i
contains
integer function observe()
observe=i
end function
subroutine show()
integer::a(3)
i=40
a=[(i+observe(),i=1,3)]
print '(4i4)',a,i
end subroutine
end module
program p
use values,only:show
implicit none
call show()
end program
''','  41  42  43  40\n',features=['module mutable host','constructor overlay not inherited by callee'])
add('direct_rank_three_norm_context',program('integer::i\nreal(8)::a(2,1,2),b(2,1,2)',"a(:,1,1)=[(real(i,8),i=1,2)]\na(:,1,2)=[(real(i,8),i=3,4)]\nb=norm2([3d0,4d0])+a+norm2([0d0,-0d0])\nprint '(4f5.1)',b\nprint '(6i3)',lbound(b),ubound(b)"),'  6.0  7.0  8.0  9.0\n  1  1  1  2  1  2\n',features=['rank-three surrounding array','rank-one slice setup','scalar NORM2 broadcast','vector bounds'])
LOCATIONS={
 'dynamic_zero_constructor_step':(7,4),
 'unallocated_vector_bounds':(5,22),
 'undefined_character_min_pending_output':(6,17),
 'rank_two_constructor_leaf_boundary':(5,17),
}
# Deliberate boundaries confirmed by the corresponding feature owner. GNU
# compiles the preserved valid sources; candidate execution is not claimed.
BOUNDARIES={
 'callee_reads_host_not_index':(9,10,'Undeclared variable: i'),
 'norm_scalar_rank_three_context':(5,39,'RESHAPE SHAPE must be an INTEGER vector of known size 1 or 2'),
}
for c in CASES:
 if c['name'] in BOUNDARIES:
  line,column,message=BOUNDARIES[c['name']]
  c.update(category='reject',gnu='compile',expected_stdout='',diagnostic=message,diagnostic_line=line,diagnostic_column=column)
 elif c['name'] in LOCATIONS:
  line,column=LOCATIONS[c['name']];c.update(diagnostic_line=line,diagnostic_column=column)
(ROOT/'manifest.json').write_text(json.dumps(dict(schema=1,cases=CASES),indent=2)+'\n')
print(len(CASES))
