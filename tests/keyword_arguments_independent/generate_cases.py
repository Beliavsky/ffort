#!/usr/bin/env python3
"""Independent reproducible keyword-association, oracle, and safety fixtures."""
from pathlib import Path
from itertools import permutations
from functools import reduce
from operator import mul
from textwrap import dedent
import json

ROOT = Path(__file__).resolve().parent
CASES = []


def add(name, source, expected='', category='success', baseline=None, diagnostic=None, **kw):
    if baseline is None:
        baseline = 'run' if category == 'success' else 'compile' if category in ('runtime', 'unsupported') else 'reject'
    (ROOT/'cases').mkdir(exist_ok=True)
    (ROOT/'cases'/f'{name}.f90').write_text(dedent(source).strip()+'\n')
    if not isinstance(expected, str):
        expected = ' '.join(str(x) for x in expected) if isinstance(expected, (list, tuple)) else str(expected)
    case = dict(name=name, source=f'cases/{name}.f90', category=category,
                baseline=baseline, expected_stdout=expected, **kw)
    if diagnostic:
        case['diagnostic'] = diagnostic
    CASES.append(case)


def prog(decl, body, procedures=''):
    return 'program keyword_oracle\nimplicit none\n'+decl+'\n'+body+'\n'+(
        'contains\n'+procedures+'\n' if procedures else '')+'end program\n'


def sub(args, decl, body, name='transform'):
    return f'subroutine {name}({args})\n{decl}\n{body}\nend subroutine {name}\n'


def fun(args, decl, body, name='combine', typ='integer'):
    return f'{typ} function {name}({args}) result(result_value)\n{decl}\n{body}\nend function {name}\n'


def opval(op, seq, kind='integer'):
    huge = {'integer':2147483647,'real':3.4028234663852886e38,'real(8)':1.7976931348623157e308}[kind]
    return {'sum':lambda:sum(seq),'product':lambda:reduce(mul,seq,1),
            'minval':lambda:min(seq,default=huge),
            'maxval':lambda:max(seq,default=(-2147483648 if kind=='integer' else -huge))}[op]()


# Every permutation has distinct reduction-axis and mask behavior. Expectations
# are Python arithmetic over declared coordinates, not candidate outputs.
for kind, tag, scale in [('integer','integer',1),('real','real32',0.5),('real(8)','real64',0.5)]:
    vals={(i,j):scale*(i+2*j) for j in range(3,6) for i in range(-1,1)}
    choose={key:(key[0]+key[1])%2==0 for key in vals}
    init='\n'.join(f'aa({i},{j})={v}'+('d0' if kind=='real(8)' else '')+
                   f'\nmm({i},{j})='+('.true.' if choose[i,j] else '.false.') for (i,j),v in vals.items())
    for op in ('sum','product','minval','maxval'):
        for dim in (1,2):
            expected=[opval(op,[v for key,v in vals.items() if key[1 if dim==1 else 0]==index and choose[key]],kind)
                      for index in (range(3,6) if dim==1 else range(-1,1))]
            for perm in permutations(('array','dim','mask')):
                mapping={'array':'aa','dim':str(dim),'mask':'mm'}
                args=','.join(k+'='+mapping[k] for k in perm)
                add(f'{op}_{tag}_dim{dim}_'+''.join(k[0] for k in perm),
                    prog(f'{kind} :: aa(-1:0,3:5)\nlogical :: mm(-1:0,3:5)',init+f'\nprint *,{op}({args})'),
                    expected,rel_tol=1e-13 if kind=='real(8)' else 2e-6,abs_tol=1e-14)
        for tag2,args,selected,dim in [
            ('array_only','array=aa',True,None),
            ('mask_before_array','mask=mm,array=aa',False,None),
            ('pos_array_keyword_mask','aa,mask=mm',False,None),
            ('pos_array_keyword_dim_mask','aa,mask=mm,dim=2',False,2),
            ('pos_array_dim_keyword_mask','aa,2,mask=mm',False,2),
            ('mask_false','array=aa,mask=.false.',False,0),
            ('case_insensitive','MaSk=mm,ArRaY=aa,DiM=1',False,1)]:
            indices=[None] if dim in (None,0) else range(3,6) if dim==1 else range(-1,1)
            expected=[opval(op,[v for key,v in vals.items() if dim!=0 and (selected or choose[key]) and
                                   (index is None or key[1 if dim==1 else 0]==index)],kind) for index in indices]
            add(f'{op}_{tag}_{tag2}',prog(f'{kind} :: aa(-1:0,3:5)\nlogical :: mm(-1:0,3:5)',init+f'\nprint *,{op}({args})'),
                expected,rel_tol=1e-13 if kind=='real(8)' else 2e-6)

# Rank-one DIM collapse, reversed sections, and empty retained/reduced axes.
for op in ('sum','product','minval','maxval'):
    add(op+'_rankone_reversed',prog('integer :: aa(-2:2)',
        '\n'.join(f'aa({i-2})={v}' for i,v in enumerate([1,2,3,4,5]))+
        f'\nprint *,{op}(dim=1,mask=aa(2:-2:-2)>1,array=aa(2:-2:-2))'),[opval(op,[5,3])])
    identity=opval(op,[])
    add(op+'_empty_axes',prog('integer :: aa(0,3),bb(2,0)',
        f'print *,{op}(dim=1,array=aa),{op}(array=bb,dim=2)\n'
        f'print *,size(array={op}(dim=2,array=aa)),size(array={op}(array=bb,dim=1))'),[identity]*5+[0,0])
    add(op+'_runtime_dim',prog('integer :: aa(2,3),dd\nlogical :: mm(2,3)',
        f'aa=2\nmm=.true.\ndd=2\nprint *,{op}(mask=mm,array=aa,dim=dd)'),[opval(op,[2,2,2])]*2)

# Inquiries must retain declared/expression bounds, not read undefined data.
for intrinsic,expected in [('size',[6,2,3]),('lbound',[-1,4]),('ubound',[0,6])]:
    body=[]
    values=[]
    if intrinsic=='size':
        body.append('print *,size(array=aa)');values.append(6)
    for dim in (1,2):
        for args in (f'array=aa,dim={dim}',f'dim={dim},array=aa',f'aa,dim={dim}',f'DiM={dim},ArRaY=aa'):
            body.append(f'print *,{intrinsic}({args})')
            values.append({'size':[2,3],'lbound':[-1,4],'ubound':[0,6]}[intrinsic][dim-1])
    add(intrinsic+'_undefined_array_metadata',prog('integer :: aa(-1:0,4:6)','\n'.join(body)),values)
add('inquiry_expression_bounds',prog('integer :: aa(-1:1,4:5)',
    'aa=2\nprint *,size(dim=1,array=aa(1:-1:-1,:)),lbound(dim=2,array=aa+1),ubound(array=aa+1,dim=2)'),[3,1,2])

# Products use the standard distinct dummy names, not generic ARRAY/A/B aliases.
for kind,tag,init1,init2,result in [
    ('integer','integer','aa=2','bb=3','24'),
    ('real(8)','real64','aa=0.5d0','bb=0.25d0','0.5'),
    ('logical','logical','aa=.true.','bb=.true.','T')]:
    for label,args in [('forward','vector_a=aa,vector_b=bb'),('reverse','vector_b=bb,vector_a=aa'),
                       ('mixed','aa,vector_b=bb'),('case','VeCtOr_B=bb,VeCtOr_A=aa')]:
        add('dot_'+tag+'_'+label,prog(f'{kind} :: aa(4),bb(-2:1)',init1+'\n'+init2+f'\nprint *,dot_product({args})'),result)
for label,args in [('forward','matrix_a=aa,matrix_b=bb'),('reverse','matrix_b=bb,matrix_a=aa'),
                   ('mixed','aa,matrix_b=bb'),('case','MaTrIx_B=bb,MaTrIx_A=aa')]:
    add('matmul_'+label,prog('integer :: aa(2,3),bb(3,2)',
        '\n'.join(f'aa({i},{j})={i+2*j}' for j in range(1,4) for i in range(1,3))+'\n'+
        '\n'.join(f'bb({i},{j})={i-j}' for j in range(1,3) for i in range(1,4))+f'\nprint *,matmul({args})'),
        [sum((i+2*k)*(k-j) for k in range(1,4)) for j in range(1,3) for i in range(1,3)])
add('nested_array_calls',prog('integer :: aa(2,3),bb(3,2)',
    'aa=2\nbb=3\nprint *,sum(dim=1,array=matmul(matrix_b=bb,matrix_a=aa))\n'
    'print *,dot_product(vector_b=sum(dim=2,array=aa),vector_a=sum(dim=1,array=bb))'),[36,36,108])

# Dummy order is header order, not declaration order or source actual order.
for perm in permutations(('first','second','third')):
    args=','.join(k+'='+{'first':'2','second':'3','third':'4'}[k] for k in perm)
    add('function_order_'+''.join(k[0] for k in perm),prog('',f'print *,combine({args})',
        fun('first,second,third','integer, intent(in) :: third,first,second',
            'result_value=100*first+10*second+third')),234)
for label,args in [('mixed','2,third=4,second=3'),('two_pos','2,3,third=4'),
                   ('case','ThIrD=4,FiRsT=2,SeCoNd=3'),('equality','first=2,second=int(3.0),third=4')]:
    add('function_'+label,prog('',f'print *,combine({args})',
        fun('first,second,third','integer, intent(in) :: second,third,first',
            'result_value=100*first+10*second+third')),234)
add('nested_function_keywords',prog('',
    'print *,combine(second=combine(first=3,second=4),first=combine(second=2,first=1))',
    fun('first,second','integer, intent(in) :: first,second','result_value=10*first+second')),154)
add('logical_equality_keyword',prog('logical :: aa','aa=.true.\nprint *,combine(flag=aa.eqv..true.)',
    fun('flag','logical,intent(in) :: flag','result_value=flag',typ='logical')),'T')
add('array_function_keyword',prog('integer :: aa(-2:2)','aa=3\nprint *,combine(scale=2,values=aa(2:-2:-2))',
    fun('values,scale','integer,intent(in) :: values(0:),scale',
        'result_value=scale*sum(array=values)+lbound(dim=1,array=values)')),18)
add('module_import_keyword', '''
module work
implicit none
contains
integer function compute(alpha,beta) result(rr)
integer,intent(in) :: beta,alpha
rr=alpha-2*beta
end function
end module
program main
use work,only:compute
implicit none
print *,compute(beta=3,alpha=10)
end program
''',4)
add('shadow_reduction_name',prog('', 'print *,sum(right=2,left=8)',
    fun('left,right','integer,intent(in) :: left,right','result_value=left-right',name='sum')),6)
add('keyword_name_same_as_variable',prog('integer :: value','value=7\nprint *,combine(value=value)',
    fun('value','integer,intent(in) :: value','result_value=value+1')),8)
add('continuation_keywords',prog('', 'print *,combine( &\n ! complete-token continuation\n & second = 3, &\n & first = 2)',
    fun('first,second','integer,intent(in) :: first,second','result_value=10*first+second')),23)

# Observable OUT/INOUT effects, definedness, snapshots, sections and forwarding.
add('scalar_out_reordered',prog('integer :: aa,bb','call transform(second=bb,first=aa)\nprint *,aa,bb',
    sub('first,second','integer,intent(out) :: first,second','first=17\nsecond=23')),[17,23])
add('scalar_inout_reordered',prog('integer :: aa,bb','aa=2\nbb=3\ncall transform(second=bb,first=aa)\nprint *,aa,bb',
    sub('first,second','integer,intent(inout) :: first,second','first=first*10\nsecond=second+7')),[20,10])
add('frozen_element_subscripts',prog('integer :: aa(4),ii','aa=0\nii=2\ncall transform(index_value=ii,value=aa(ii))\nprint *,aa,ii',
    sub('value,index_value','integer,intent(out) :: value,index_value','index_value=4\nvalue=7')),[0,7,0,0,4])
add('expression_before_out_entry',prog('integer :: aa','aa=4\ncall transform(value=aa,old_value=aa+3)\nprint *,aa',
    sub('old_value,value','integer,intent(in) :: old_value\ninteger,intent(out) :: value','value=old_value*2')),14)
add('section_out_disjoint',prog('integer :: aa(6)','aa=1\ncall transform(second=aa(6:2:-2),first=aa(1:5:2))\nprint *,aa',
    sub('first,second','integer,intent(out) :: first(:),second(:)','first=3\nsecond=7')),[3,7,3,7,3,7])
add('rank_two_section_inout',prog('integer :: aa(2,3)','aa=1\ncall transform(delta=4,values=aa(2:1:-1,3:1:-2))\nprint *,aa',
    sub('values,delta','integer,intent(inout) :: values(:,:)\ninteger,intent(in) :: delta','values=values+delta')),[5,5,1,1,5,5])
add('nested_keyword_forwarding',prog('integer :: aa,bb','aa=2\ncall transform(result_arg=bb,input_arg=aa)\nprint *,aa,bb',
    sub('input_arg,result_arg','integer,intent(inout) :: input_arg\ninteger,intent(out) :: result_arg',
        'call next_step(output_value=result_arg,input_value=input_arg)\ninput_arg=input_arg+1')+
    sub('input_value,output_value','integer,intent(in) :: input_value\ninteger,intent(out) :: output_value',
        'output_value=input_value*3',name='next_step')),[3,6])
add('character_input_keyword',prog('', 'call transform(count=2,message="test=word")',
    sub('message,count','character(len=*),intent(in) :: message\ninteger,intent(in) :: count','print *,message,count')),'test=word 2')
add('unused_undefined_named_in',prog('integer :: aa','call transform(unused=aa)\nprint *,7',
    sub('unused','integer,intent(in) :: unused','return')),7)
add('undefined_inout_defined_before_read',prog('integer :: aa','call transform(value=aa)\nprint *,aa',
    sub('value','integer,intent(inout) :: value','value=8')),8)

# Fail before output even if the malformed call is in unreachable code.
RED_BAD=[('unknown','array=aa,bogus=1'),('duplicate','array=aa,array=aa'),
         ('case_duplicate','array=aa,ArRaY=aa'),('collision','aa,array=aa'),
         ('missing_array','mask=mm'),('pos_after_key','array=aa,1'),
         ('missing_dim_value','array=aa,dim='),('logical_dim','array=aa,dim=.true.'),
         ('integer_mask','array=aa,mask=1'),('rank_dim','array=aa,dim=aa'),
         ('too_many','aa,1,mm,1'),('duplicate_mask','aa,mask=mm,mask=mm'),
         ('mask_positional_collision','aa,mm,mask=mm'),('positional_mask_then_dim','aa,mm,dim=1')]
for op in ('sum','product','minval','maxval'):
    for label,args in RED_BAD:
        add(op+'_invalid_'+label,prog('integer :: aa(2)\nlogical :: mm(2)',
            f'aa=1\nmm=.true.\nprint *,777\nif (.false.) then\nprint *,{op}({args})\nend if'),category='invalid')
for intrinsic,keywords in [('size',('array','dim')),('lbound',('array','dim')),('ubound',('array','dim')),
                           ('dot_product',('vector_a','vector_b')),('matmul',('matrix_a','matrix_b'))]:
    a,b=keywords
    decl='integer :: aa(2),bb(2)' if intrinsic!='matmul' else 'integer :: aa(2,2),bb(2,2)'
    second='1' if intrinsic in ('size','lbound','ubound') else 'bb'
    invalid=[('unknown',f'{a}=aa,no_such_keyword={second}'),
             ('duplicate',f'{a}=aa,{a}=aa'),('collision',f'aa,{a}=aa'),
             ('missing_required',f'{b}={second}'),('pos_after_key',f'{a}=aa,{second}')]
    for label,args in invalid:
        add(intrinsic+'_invalid_'+label,prog(decl,f'aa=1\nbb=1\nprint *,777\nprint *,{intrinsic}({args})'),category='invalid')
for label,args in [('unknown','first=1,wrong=2'),('duplicate','first=1,first=2'),
                   ('case_duplicate','first=1,FiRsT=2'),('collision','1,first=2'),
                   ('missing','second=2'),('pos_after_key','first=1,2'),
                   ('too_many','first=1,second=2,third=3'),('wrong_type','first=.true.,second=2'),
                   ('wrong_rank','first=aa,second=2')]:
    add('function_invalid_'+label,prog('integer :: aa(2)',f'print *,777\nprint *,combine({args})',
        fun('first,second','integer,intent(in) :: first,second','result_value=first-second')),category='invalid')
for label,args in [('unknown','first=aa,wrong=bb'),('duplicate','first=aa,first=bb'),
                   ('missing','second=bb'),('pos_after_key','first=aa,bb'),('nondefinable','second=bb,first=1'),
                   ('type_mismatch','second=bb,first=.true.'),('parenthesized_output','second=bb,first=(aa)')]:
    add('subroutine_invalid_'+label,prog('integer :: aa,bb',f'print *,777\ncall transform({args})',
        sub('first,second','integer,intent(out) :: first,second','first=1\nsecond=2')),category='invalid')
add('function_result_not_dummy',prog('', 'print *,combine(result_value=2)',
    fun('first','integer,intent(in) :: first','result_value=first')),category='invalid')
add('array_subscript_not_keyword',prog('integer :: aa(2)','aa=1\nprint *,777\nprint *,aa(index=1)'),category='invalid')
add('write_input_dummy_by_keyword',prog('integer :: aa','aa=1\ncall outer(value=aa)',
    sub('value','integer,intent(in) :: value','call transform(first=value)',name='outer')+
    sub('first','integer,intent(out) :: first','first=2')),category='invalid')
add('write_do_variable_by_keyword',prog('integer :: ii','do ii=1,2\ncall transform(first=ii)\nend do',
    sub('first','integer,intent(out) :: first','first=2')),category='invalid')

# Unsupported standard forms stay explicit, never silently discard KIND or infer
# OPTIONAL behavior. GNU compiles these but is not executed as an oracle.
for expr in ['size(array=aa,kind=8)','lbound(array=aa,dim=1,kind=8)','ubound(array=aa,dim=1,kind=8)',
             'lbound(array=aa)','ubound(array=aa)','abs(a=-3)','real(a=2)','int(a=2.5)','mod(a=7,p=3)']:
    add('unsupported_'+str(len(CASES)),prog('integer :: aa(2)','aa=1\nprint *,777\nprint *,'+expr),category='unsupported')
add('optional_dummy_unsupported',prog('', 'print *,combine(first=2)',
    fun('first,second','integer,intent(in) :: first\ninteger,intent(in),optional :: second',
        'result_value=first')),'2',category='success')

# Runtime safety: association must preserve all old checks and no partial PRINT
# item may escape if evaluating a later item fails.
for op in ('sum','product','minval','maxval'):
    add(op+'_invalid_runtime_dim',prog('integer :: aa(2,2),dd','aa=1\ndd=3\nprint *,777\nprint *,'+op+'(dim=dd,array=aa)'),
        '777',category='runtime',diagnostic='DIM')
    add(op+'_mask_shape_runtime',prog('integer :: aa(2,2),nn,jj\nlogical :: mm(4,2)',
        'aa=1\nmm=.true.\nnn=2\njj=1\nprint *,777\nprint *,'+op+'(array=aa,mask=mm(:nn,:jj))'),
        '777',category='runtime',diagnostic='mask')
    add(op+'_uninitialized_runtime',prog('integer :: aa(2)','aa(1)=1\nprint *,777\nprint *,8,'+op+'(array=aa)'),
        '777',category='runtime',diagnostic='uninitialized')
for intrinsic in ('size','lbound','ubound'):
    add(intrinsic+'_runtime_bad_dim',prog('integer :: aa(2),dd','dd=2\nprint *,777\nprint *,'+intrinsic+'(dim=dd,array=aa)'),
        '777',category='runtime',diagnostic='DIM')
add('keyword_out_undefinition',prog('integer :: aa','aa=9\ncall transform(value=aa)\nprint *,aa',
    sub('value','integer,intent(out) :: value','return')),category='runtime',diagnostic='uninitialized')
add('keyword_alias_scalar',prog('integer :: aa','aa=1\ncall transform(second=aa,first=aa)',
    sub('first,second','integer,intent(out) :: first,second','return')),category='runtime',diagnostic='overlapping')
add('keyword_alias_sections',prog('integer :: aa(5)','aa=1\ncall transform(second=aa(5:1:-2),first=aa(1:3))',
    sub('first,second','integer,intent(out) :: first(:),second(:)','return')),category='runtime',diagnostic='overlapping')
add('keyword_bad_subscript',prog('integer :: aa(2),ii','ii=3\ncall transform(value=aa(ii))',
    sub('value','integer,intent(out) :: value','value=2')),category='runtime',diagnostic='bounds')
add('keyword_zero_stride',prog('integer :: aa(2),ss','ss=0\ncall transform(value=aa(::ss))',
    sub('value','integer,intent(out) :: value(:)','value=2')),category='runtime',diagnostic='stride')
add('keyword_shared_step_limit',prog('', 'print *,combine(first=500)',
    fun('first','integer,intent(in) :: first\ninteger :: ii','result_value=0\ndo ii=1,first\nresult_value=result_value+ii\nend do')),
    category='runtime',diagnostic='step limit',args=['--max-steps','40'])
add('keyword_argument_elements_limit',prog('integer :: aa(40000)','aa=1\ncall transform(second=aa+0,first=aa+0)',
    sub('first,second','integer,intent(in) :: first(:),second(:)','return')),
    category='runtime',diagnostic='argument array element limit')

# Mixed types force association before per-dummy type checking.
add('function_mixed_types',prog('', 'print *,combine(factor=2.5d0,enabled=.true.,number=4)',
    fun('number,enabled,factor','integer,intent(in) :: number\nlogical,intent(in) :: enabled\nreal(8),intent(in) :: factor',
        'result_value=0.0d0\nif (enabled) result_value=number+factor',typ='real(8)')),6.5,rel_tol=1e-13)
for label,expr,typ,expected in [('int','int(3.5)','integer',3),('real','real(3)','real',3.0),
                                ('abs','abs(-3)','integer',3),('sqrt','sqrt(4.0)','real',2.0),
                                ('max','max(2,3)','integer',3),('sum','sum(array=aa)','integer',6)]:
    add('function_keyword_intrinsic_'+label,prog('integer :: aa(2)','aa=3\nprint *,combine(value='+expr+')',
        fun('value',typ+',intent(in) :: value','result_value=value',typ=typ)),expected)
add('subroutine_mixed_types',prog('integer :: number\nlogical :: enabled\nreal(8) :: factor',
    'number=4\nenabled=.false.\nfactor=2.5d0\ncall transform(factor=factor,enabled=enabled,number=number)\n'
    'print *,number,enabled,factor',sub('number,enabled,factor',
    'integer,intent(inout) :: number\nlogical,intent(out) :: enabled\nreal(8),intent(inout) :: factor',
    'number=number+2\nenabled=.true.\nfactor=factor*2.0d0')),'6 T 5.0',rel_tol=1e-13)
add('readonly_alias_keywords',prog('integer :: aa(3)','aa=2\nprint *,combine(right=aa,left=aa)',
    fun('left,right','integer,intent(in) :: left(:),right(:)','result_value=sum(array=left)+sum(array=right)')),12)
add('empty_out_sections_keywords',prog('integer :: aa(3)','aa=9\ncall transform(right=aa(3:1),left=aa(2:1))\nprint *,aa',
    sub('left,right','integer,intent(out) :: left(:),right(:)','left=2\nright=3')),[9,9,9])
add('nested_out_undefinition_keywords',prog('integer :: aa','call transform(value=aa)\nprint *,aa',
    sub('value','integer,intent(out) :: value','value=3\ncall clear_value(target=value)')+
    sub('target','integer,intent(out) :: target','return',name='clear_value')),
    category='runtime',diagnostic='uninitialized')
add('function_keyword_wrong_kind',prog('', 'print *,777\nprint *,combine(value=3.0)',
    fun('value','real(8),intent(in) :: value','result_value=value',typ='real(8)')),category='invalid')
add('subroutine_keyword_wrong_rank',prog('integer :: aa','print *,777\ncall transform(value=aa)',
    sub('value','integer,intent(out) :: value(:)','value=3')),category='invalid')
# Exact parameter/name boundaries are independently valid GNU Fortran programs.
params=[f'p{i:02}' for i in range(1,17)]
actuals=', &\n'.join(f'{p}={i}' for i,p in reversed(list(enumerate(params,1))))
decl='integer,intent(in) :: '+','.join(params[:8])+'\ninteger,intent(in) :: '+','.join(params[8:])
add('sixteen_keywords_reordered',prog('',f'print *,combine({actuals})',
    fun(','.join(params),decl,'result_value='+'+'.join(params))),136)
long_name='argument_'+'x'*54
add('keyword_name_63_characters',prog('',f'print *,combine( &\n{long_name}=7)',
    fun(long_name,'integer,intent(in) :: '+long_name,'result_value='+long_name+'+1')),8)
params17=params+['p17']
actuals17=', &\n'.join(f'{p}=1' for p in reversed(params17))
add('seventeen_arguments_unsupported',prog('',f'print *,777\nprint *,combine({actuals17})',
    fun(','.join(params17),decl+'\ninteger,intent(in) :: p17','result_value=p17')),category='unsupported')
# Whitespace/continuations around '=' are legal, but positional actuals may never
# resume after one named actual, even across continuation/comment boundaries.
add('keyword_equals_continuation',prog('', 'print *,combine(first &\n = &\n 2, second = 3)',
    fun('first,second','integer,intent(in) :: first,second','result_value=10*first+second')),23)
add('keyword_positional_after_continuation',prog('', 'print *,777\nprint *,combine(first=2, &\n ! no positional restart\n 3)',
    fun('first,second','integer,intent(in) :: first,second','result_value=first+second')),category='invalid')

# Conversion calls preserve result type/rank when wrapped in keyword actuals.
for label,kind,init,expression,result_type,expected in [
    ('int_real32','real','3.5','int(aa)','integer',12),
    ('int_real64','real(8)','3.5d0','int(aa)','integer',12),
    ('real_integer','integer','3','real(aa)','real',12.0)]:
    for rank,shape,dummy_shape in [('vector','4',':'),('matrix','2,2',':,:')]:
        add('keyword_array_conversion_'+label+'_'+rank,prog(f'{kind} :: aa({shape})',
            f'aa={init}\nprint *,combine(value={expression})',
            fun('value',f'{result_type},intent(in) :: value({dummy_shape})',
                'result_value=sum(array=value)',typ=result_type)),expected)
add('keyword_conversion_not_definable',prog('integer :: aa(2)',
    'aa=3\nprint *,777\ncall transform(value=real(aa))',
    sub('value','real,intent(out) :: value(:)','value=3.0')),category='invalid')

# Remove obsolete generated fixtures so regeneration reproduces the whole corpus.
known = {case['source'] for case in CASES}
for path in (ROOT/'cases').glob('*.f90'):
    if str(path.relative_to(ROOT)) not in known:
        path.unlink()

# Features supported in 0.17.0; preserve every original source fixture.
SUPPORTED_017 = {'unsupported_396': '777 2'}
for row in CASES:
    if row['name'] in SUPPORTED_017:
        row.update(category='success', baseline='run', expected_stdout=SUPPORTED_017[row['name']])

# REAL named arguments are supported in 0.40.0; retain the historical source.
SUPPORTED_040 = {'unsupported_395': '777 2'}
for row in CASES:
    if row['name'] in SUPPORTED_040:
        row.update(category='success', baseline='run', expected_stdout=SUPPORTED_040[row['name']])

# The array cap is now 131072; retain historical boundary source fixtures.
# Current-cap tests are generated from fi_ir in tests/array_limits/run_tests.py.
ARRAY_LIMIT_MIGRATIONS = {'keyword_argument_elements_limit': ''}
for row in CASES:
    if row['name'] in ARRAY_LIMIT_MIGRATIONS:
        row.update(category='success', baseline='run', expected_stdout=ARRAY_LIMIT_MIGRATIONS[row['name']],
                   note='Historical 65536-element cap probe; legal with the larger cap.')
        row.pop('diagnostic', None)

# Scalar KIND and vector bounds are supported in 0.46.0; retain sources.
SUPPORTED_BOUNDS_046 = {'unsupported_390': '777 1', 'unsupported_391': '777 2',
                        'unsupported_392': '777 1', 'unsupported_393': '777 2'}
for row in CASES:
    if row['name'] in SUPPORTED_BOUNDS_046:
        row.update(category='success', baseline='run', expected_stdout=SUPPORTED_BOUNDS_046[row['name']])

(ROOT/'manifest.json').write_text(json.dumps(dict(cases=CASES),indent=2)+'\n')
print(f'Generated {len(CASES)} reproducible keyword-argument fixtures')
