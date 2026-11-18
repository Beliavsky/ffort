#!/usr/bin/env python3
"""Generate independent, standard-grounded PURE/SIMPLE regression fixtures."""
from pathlib import Path
from textwrap import dedent
import json
import re
from itertools import permutations

ROOT = Path(__file__).resolve().parent
CASES = []


def lower_simple(source):
    # Match only the supported header prefix, never identifiers or body text.
    # This is a weakened PURE oracle, not a Fortran source-to-source compiler.
    pattern = re.compile(r'^(\s*(?:(?:pure|simple|impure|recursive|non_recursive|elemental|integer|logical|real(?:\([^)]*\))?)\s+)*)'
                         r'((?:function|subroutine)\s+[a-z]\w*\s*\()', re.I)
    lines = []
    for line in source.splitlines(keepends=True):
        match = pattern.match(line)
        if match:
            prefix = match.group(1)
            if len(re.findall(r'\bsimple\b',prefix,re.I)) == 1 and re.search(r'\bpure\b',prefix,re.I):
                prefix = re.sub(r'\bsimple\b', '', prefix, flags=re.I)
            else:
                prefix = re.sub(r'\bsimple\b', 'pure', prefix, flags=re.I)
            line = prefix + line[len(match.group(1)):]
        lines.append(line)
    return ''.join(lines)


def add(name, source, expected='', category='success', baseline=None, diagnostic=None, **kw):
    source = dedent(source).strip() + '\n'
    has_simple = lower_simple(source) != source
    if baseline is None:
        baseline = 'run' if category == 'success' else 'compile' if category in ('runtime', 'unsupported') else 'reject'
    (ROOT/'cases').mkdir(exist_ok=True)
    (ROOT/'cases'/f'{name}.f90').write_text(source)
    case = dict(name=name, source=f'cases/{name}.f90', category=category,
                baseline=baseline, has_simple=has_simple,
                expected_stdout=' '.join(map(str,expected)) if isinstance(expected,(list,tuple)) else str(expected), **kw)
    if has_simple:
        (ROOT/'pure_references').mkdir(exist_ok=True)
        (ROOT/'pure_references'/f'{name}.f90').write_text(lower_simple(source))
        case['pure_reference'] = f'pure_references/{name}.f90'
    if diagnostic:
        case['diagnostic'] = diagnostic
    CASES.append(case)


def program(decl, body, procedures=''):
    return 'program purity_test\nimplicit none\n'+decl+'\n'+body+'\n'+(
        'contains\n'+procedures+'\n' if procedures else '')+'end program\n'


def fun(prefix='pure', name='compute', decl='integer, intent(in) :: xx', body='rr=xx*xx+1', typed='integer'):
    header = (prefix+' '+typed).strip()
    return f'{header} function {name}(xx) result(rr)\n{decl}\n{body}\nend function {name}\n'


def sub(prefix='pure', name='adjust', decl='integer, intent(inout) :: xx', body='xx=xx+7'):
    return f'{prefix} subroutine {name}(xx)\n{decl}\n{body}\nend subroutine {name}\n'


# Prefix order, explicit/typed result, kinds, case and ordinary invocation.
for attr in ('pure','simple'):
    for order,prefix,typ in [('attr_type',attr,'integer'),('type_attr','integer '+attr,''),('untyped',attr,'')]:
        decl='integer, intent(in) :: xx'+ ('\ninteger :: rr' if order=='untyped' else '')
        add(f'{attr}_{order}_function',program('', 'print *,compute(xx=4)',fun(prefix,decl=decl,typed=typ)),17)
    add(attr+'_mixed_case',program('', 'print *,compute(3)',fun(attr.upper(),body='rr=xx*2')),6)
    add(attr+'_real64',program('',
        'print *,compute(0.5d0)',fun(attr,decl='real(8), intent(in) :: xx',body='rr=exp(xx*0.0d0)+sqrt(xx*xx)',typed='real(8)')),1.5)
    add(attr+'_subroutine_inout',program('integer :: aa','aa=8\ncall adjust(xx=aa)\nprint *,aa',sub(attr)),15)
    add(attr+'_subroutine_out',program('integer :: aa','call adjust(aa)\nprint *,aa',sub(attr,decl='integer, intent(out) :: xx',body='xx=23')),23)
    add(attr+'_local_parameter',program('', 'print *,compute(5)',fun(attr,decl='integer, intent(in) :: xx\ninteger, parameter :: scale=3',body='rr=scale*xx')),15)
    add(attr+'_host_parameter',program('integer, parameter :: factor=4', 'print *,compute(5)',fun(attr,body='rr=factor*xx')),20)
    add(attr+'_local_mutation',program('', 'print *,compute(4)',fun(attr,decl='integer, intent(in) :: xx\ninteger :: ii,acc',body='acc=0\ndo ii=1,xx\nacc=acc+ii*ii\nend do\nrr=acc')),30)
    add(attr+'_read_only_alias',program('integer :: aa', 'aa=9\nprint *,combine(aa,aa)',f'{attr} integer function combine(xx,yy) result(rr)\ninteger,intent(in)::xx,yy\nrr=xx+yy\nend function\n'),18)
    add(attr+'_array_reduction',program('integer :: aa(-2:2)','aa=3\nprint *,compute(aa(2:-2:-2))',fun(attr,decl='integer,intent(in)::xx(:)',body='rr=sum(array=xx)+product(xx)+size(xx)')),39)
    add(attr+'_rank_two_writes',program('integer :: aa(2,3)','aa=1\ncall adjust(aa(:,3:1:-1))\nprint *,aa',sub(attr,decl='integer,intent(inout)::xx(:,:)\ninteger::ii,jj',body='do jj=1,size(xx,2)\ndo ii=1,size(xx,1)\nxx(ii,jj)=10*jj+ii\nend do\nend do')),[31,32,21,22,11,12])
    add(attr+'_disjoint_output_sections',program('integer :: aa(4)','aa=0\ncall separate(aa(1:2),aa(3:4))\nprint *,aa',f'{attr} subroutine separate(xx,yy)\ninteger,intent(out)::xx(:),yy(:)\nxx=2\nyy=7\nend subroutine\n'),[2,2,7,7])
    add(attr+'_error_stop_unreached',program('', 'print *,compute(3)',fun(attr,body='if(xx<0) error stop 77\nrr=xx+1')),4)
    add(attr+'_function_calls_subroutine',program('', 'print *,compute(3)',fun(attr,body='rr=xx\ncall adjust(rr)')+sub(attr)),10)
    add(attr+'_char_dummy',program('', '! simple subroutine bogus(xx)\ncall accept("simple subroutine adjust(xx)")\nprint *,42',f'{attr} subroutine accept(txt)\ncharacter(len=*),intent(in)::txt\nend subroutine\n'),42)
    # User procedures are not automatically PURE/SIMPLE just because their bodies look harmless.
    for callee in ('ordinary','pure','simple'):
        cp='' if callee=='ordinary' else callee
        category='success' if (callee=='simple' or (attr=='pure' and callee=='pure')) else 'invalid'
        baseline=None if not (attr=='simple' and callee=='pure') else 'compile'
        for kind in ('function','subroutine'):
            proc = fun(attr,body='rr=helper(xx)')+fun(cp,name='helper',body='rr=xx+7') if kind=='function' else sub(attr,body='call helper(xx)')+sub(cp,name='helper')
            body='print *,compute(5)' if kind=='function' else 'aa=5\ncall adjust(aa)\nprint *,aa'
            add(f'{attr}_calls_{callee}_{kind}',program('integer :: aa',body,proc),12 if category=='success' else '',category,baseline=baseline,
                diagnostic=None if category=='success' else attr)
    # Forbidden output and dummy writes must fail statically, even if never called.
    for tag,decl,body in [('print','integer,intent(in)::xx','print *,xx\nrr=xx'),
                         ('conditional_print','integer,intent(in)::xx','if(.false.) print *,xx\nrr=xx'),
                         ('intent_out_function','integer,intent(out)::xx','xx=1\nrr=xx'),
                         ('intent_inout_function','integer,intent(inout)::xx','xx=xx+1\nrr=xx'),
                         ('missing_intent','integer::xx','rr=xx'),
                         ('write_input','integer,intent(in)::xx','xx=2\nrr=xx'),
                         ('input_loop','integer,intent(in)::xx','do xx=1,3\nend do\nrr=xx'),
                         ('saved_local','integer,intent(in)::xx\ninteger,save::state','rr=xx'),
                         ('initialized_local','integer,intent(in)::xx\ninteger::state=3','rr=xx+state'),
                         ('ordinary_stop','integer,intent(in)::xx','stop 5\nrr=xx')]:
        add(attr+'_'+tag,program('', 'print *,991',fun(attr,decl=decl,body=body)),category='invalid')
    add(attr+'_input_passed_out',program('', 'print *,991',fun(attr,body='call set_value(xx)\nrr=xx')+sub(attr,'set_value','integer,intent(out)::xx','xx=9')),category='invalid')
    add(attr+'_subroutine_print',program('', 'print *,991',sub(attr,body='print *,xx')),category='invalid')
    # Standard-valid programs outside the deliberately smaller interpreter subset.
    add(attr+'_recursive_unsupported',program('', 'print *,compute(4)',fun('recursive '+attr,body='if(xx==0) then\nrr=1\nelse\nrr=xx*compute(xx-1)\nend if')),expected='24')
    add(attr+'_value_dummy_unsupported',program('', 'print *,compute(4)',fun(attr,decl='integer,value::xx')),category='unsupported')
    add(attr+'_internal_io_unsupported',program('', 'print *,compute(4)',fun(attr,decl='integer,intent(in)::xx\ncharacter(len=8)::buffer',body='write(buffer,"(I8)") xx\nrr=xx')),expected='4\n')
    add(attr+'_error_stop_runtime',program('', 'print *,112\nprint *,compute(-1)',fun(attr,body='if(xx<0) error stop 77\nrr=xx')),expected=112,category='runtime',diagnostic='77')
    add(attr+'_uninitialized_result',program('', 'print *,compute(1)',fun(attr,body='if(xx<0) rr=xx')),category='runtime',diagnostic='uninitialized')

# Call matrix ordinary callers may invoke pure or simple procedures.
for callee in ('ordinary','pure','simple'):
    prefix='' if callee=='ordinary' else callee
    add('ordinary_calls_'+callee,program('integer :: aa','aa=4\ncall driver(aa)\nprint *,aa',sub('',name='driver',body='xx=compute(xx)\ncall adjust(xx)')+fun(prefix)+sub(prefix)),24)

# Imported/module constants and call targets, including forward definitions.
for attr in ('pure','simple'):
    add(attr+'_module_constants',f'''module arithmetic_module
implicit none
integer, parameter :: weight=3
contains
{fun(attr,body='rr=helper(xx)+weight')}
{fun(attr,'helper',body='rr=xx*2')}
end module
program purity_test
use arithmetic_module, only : compute
implicit none
print *,compute(4)
end program
''',11)
    add(attr+'_imported_callee',f'''module arithmetic_module
implicit none
contains
{fun(attr,'helper',body='rr=xx+2')}
end module
program purity_test
use arithmetic_module, only : helper
implicit none
print *,compute(5)
contains
{fun(attr,body='rr=helper(xx)*3')}
end program
''',21)

# PURE module reads are supported; mutable main-program host association remains
# outside this subset and must not be mislabeled as invalid Fortran.
add('pure_host_read_unsupported',program('integer :: scale','scale=6\nprint *,compute(2)',fun('pure',body='rr=scale*xx')),category='unsupported')
add('simple_host_read_invalid',program('integer :: scale','scale=6\nprint *,compute(2)',fun('simple',body='rr=scale*xx')),category='invalid',baseline='compile')
add('pure_host_write_invalid',program('integer :: scale','print *,991',fun('pure',body='scale=xx\nrr=xx')),category='invalid')
add('simple_host_write_invalid',program('integer :: scale','print *,991',fun('simple',body='scale=xx\nrr=xx')),category='invalid')
for attr in ('pure','simple'):
    add(attr+'_module_variable',f'''module arithmetic_module
implicit none
integer :: scale=5
contains
{fun(attr,body='rr=scale*xx')}
end module
program purity_test
use arithmetic_module, only : compute
implicit none
print *,compute(2)
end program
''',10 if attr=='pure' else '',category='success' if attr=='pure' else 'invalid',baseline='run' if attr=='pure' else 'compile')

# Context-sensitive call checks must cover uncalled procedures, unreachable
# statements, loop bounds, branches and nested intrinsic expressions.
for attr,callee,cp in [('pure','ordinary',''),('simple','pure','pure')]:
    for tag,body,decl in [('unused','rr=helper(xx)',''),
        ('unreachable','if(.false.) then\nrr=helper(xx)\nelse\nrr=xx\nend if',''),
        ('loop_bound','rr=0\ndo ii=1,helper(xx)\nrr=rr+1\nend do','\ninteger::ii'),
        ('if_condition','if(helper(xx)>0) then\nrr=1\nelse\nrr=0\nend if',''),
        ('intrinsic_nested','rr=abs(helper(xx))',''),
        ('array_subscript','aa=1\nrr=aa(helper(xx))','\ninteger::aa(5)')]:
        add(f'{attr}_bad_call_{tag}',program('', 'print *,991',fun(attr,decl='integer,intent(in)::xx'+decl,body=body)+fun(cp,'helper',body='rr=xx')),category='invalid',baseline='compile' if attr=='simple' else 'reject',diagnostic=attr)

# Prefix syntax constraints, including both orders and repeated keywords.
for tag,prefix in [('duplicate_pure','pure pure'),('duplicate_simple','simple simple'),('impure_pure','impure pure'),('simple_impure','simple impure')]:
    add(tag,program('', 'print *,991',fun(prefix)),category='invalid')

# C1553 excludes IMPURE with PURE/SIMPLE, not the redundant PURE+SIMPLE.
# The March 2023 informal overview differs; these follow J3/23-007r1 and 24-007.
for prefix in permutations(('pure','simple','integer')):
    add('_'.join(prefix),program('', 'print *,compute(4)',fun(' '.join(prefix),typed='')),17)
for prefix in ('pure simple','simple pure'):
    add(prefix.replace(' ','_')+'_subroutine',program('integer::aa','aa=4\ncall adjust(aa)\nprint *,aa',sub(prefix)),11)
for attr in ('pure','simple'):
    add(attr+'_host_constant_inquiry_unsupported',program('integer :: aa(4)', 'print *,compute(2)',fun(attr,body='rr=size(aa)+xx')),category='unsupported')

# All supported intrinsics are SIMPLE: arithmetic plus rank-two products and
# reduction/inquiry keywords. Expectations are hand-derived, not interpreter output.
add('simple_intrinsics',program('real(8)::aa(2,2),bb(2,2)','aa=2.0d0\nbb=3.0d0\nprint *,compute(aa,bb)', '''simple real(8) function compute(xx,yy) result(rr)
real(8),intent(in)::xx(:,:),yy(:,:)
rr=sum(matmul(matrix_b=yy,matrix_a=xx))+real(size(xx))+sqrt(4.0d0)+log(exp(1.0d0))+erfc(0.0d0)
end function
'''),56.0)
add('simple_keyword_named_simple',program('', 'print *,compute(simple=4)', '''simple integer function compute(simple) result(rr)
integer,intent(in)::simple
rr=simple+3
end function
'''),category='unsupported',baseline='compile')

assert len({case['name'] for case in CASES}) == len(CASES)
(ROOT/'manifest.json').write_text(json.dumps(dict(schema=1,cases=CASES),indent=2)+'\n')
print(f'Generated {len(CASES)} PURE/SIMPLE cases')
