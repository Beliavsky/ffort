#!/usr/bin/env python3
"""Independent acceptance oracles, deliberately separate from the implementation."""
from pathlib import Path
import json, textwrap
ROOT = Path(__file__).resolve().parent
CASES = []
def add(name, category, body, expected=None, *, baseline=None, note='', tags=None, output_lines=None):
    source = textwrap.dedent(body).strip() + '\n'
    case = dict(name=name, category=category, source=f'cases/{name}.f90', note=note)
    if expected is not None: case['expected_stdout'] = expected
    if baseline is None: baseline = 'run' if category == 'success' else ('reject' if category in ('syntax', 'semantic') else 'compile' if category == 'unsupported' else 'skip')
    case['baseline'] = baseline
    if tags: case['tags'] = tags
    if output_lines is not None: case['expected_stdout_lines'] = output_lines
    (ROOT / case['source']).write_text(source)
    CASES.append(case)
def program(declarations, statements):
    return 'program probe\n  implicit none\n' + textwrap.indent(textwrap.dedent(declarations).strip(), '  ') + '\n' + textwrap.indent(textwrap.dedent(statements).strip(), '  ') + '\nend program probe\n'
def case(name, category, declarations, statements, expected=None, **kw):
    add(name, category, program(declarations, statements), expected, **kw)

case('integer_arithmetic','success','integer :: a, b, c','a=7\nb=3\nc=a+b*2\nprint *, c, (a+b)*2, a/b, (-a)/b, a/(-b)', '13 20 2 -2 -2')
case('power_precedence','success','integer :: a, b, c, d','a=-2**2\nb=(-2)**2\nc=2**3**2\nd=2**(-2)\nprint *, a,b,c,d','-4 4 512 0')
case('mixed_numeric','success','integer :: i\nreal :: x, y','i=-3.75\nx=5/2\ny=5.0/2\nprint *, i, x, y, 2+0.5, 2**3.0','-3 2 2.5 2.5 8')
case('real_literals','success','real :: a, b, c','a=.5\nb=2.\nc=1.25e-2\nprint *, a, b, c, -c','0.5 2 0.0125 -0.0125')
case('declaration_initializers','success','integer :: a=5, b=-2\nreal :: r=0.25\nlogical :: yes=.true.','print *, a, b, r, yes','5 -2 0.25 T')
case('case_insensitivity','success','INTEGER :: Value','vAlUe=4\nPRINT *, VALUE','4')
case('relational_operators','success','integer :: a, b\nlogical :: flag','a=2\nb=3\nflag=a < b\nprint *, flag, a<=b, a>b, a>=b, a==b, a/=b','T T F F F T')
case('dotted_relations','success','integer :: a, b','a=2\nb=3\nprint *, a.lt.b, a.le.b, a.gt.b, a.ge.b, a.eq.b, a.ne.b','T T F F F T')
case('logical_operators','success','logical :: a, b','a=.true.\nb=.false.\nprint *, a.and.b, a.or.b, .not.a, .not.b','F T F T')
case('logical_precedence','success','logical :: a','a=.true..or..false..and..false.\nprint *, a, .not.1==2','T T')
case('if_else','success','integer :: x, y','x=3\nif (x>2) then\n y=10\nelse\n y=20\nend if\nprint *, y','10')
case('if_false_branch','success','integer :: x, y','x=0\ny=3\nif (x>2) then\n y=10\nelse\n y=y+1\nend if\nprint *, y','4')
case('nested_if','success','integer :: x','x=2\nif (.true.) then\n if (x==2) then\n  x=9\n else\n  x=8\n end if\nelse\n x=7\nend if\nprint *, x','9')
case('unexecuted_uninitialized_read','success','integer :: x, y','y=5\nif (.false.) then\n print *, x\nend if\nprint *, y','5')
case('do_sum_final','success','integer :: i, s','s=0\ndo i=1,5\n s=s+i\nend do\nprint *, s, i','15 6')
case('do_descending_final','success','integer :: i, s','s=0\ndo i=5,1,-2\n s=s+i\nend do\nprint *, s, i','9 -1')
case('do_zero_trip','success','integer :: i, s','s=7\ndo i=5,1\n s=0\nend do\nprint *, s, i','7 5')
case('do_zero_trip_descending','success','integer :: i, s','s=7\ndo i=1,5,-1\n s=0\nend do\nprint *, s, i','7 1')
case('do_overshoot_final','success','integer :: i, s','s=0\ndo i=1,8,3\n s=s+i\nend do\nprint *, s, i','12 10')
case('do_bounds_snapshot','success','integer :: i, s, upper, stride','s=0\nupper=5\nstride=2\ndo i=1,upper,stride\n s=s+i\n upper=1\n stride=1\nend do\nprint *, s, i, upper, stride','9 7 1 1')
case('do_nested','success','integer :: i, j, s','s=0\ndo i=1,2\n do j=1,3\n  s=s+10*i+j\n end do\nend do\nprint *, s, i, j','102 3 4')
case('do_sequential_reuse','success','integer :: i, s','s=0\ndo i=1,2\n s=s+i\nend do\ndo i=2,1,-1\n s=s+i\nend do\nprint *, s, i','6 0')
case('comments_and_strings','success','integer :: x','x=4 ! ignore this + )\nprint *, "hello!", x, \'it\'\'s\'','hello! 4 it\'s')
case('integer_boundary_valid','success','integer :: x','x=-2147483647-1\nprint *, x, x+1, 2147483647','-2147483648 -2147483647 2147483647')

case('malformed_missing_rhs','syntax','integer :: x','x=(1+)\nprint *, x', note='Regression for upstream silent syntax repair; the original invalid source must be rejected before output.')
case('malformed_missing_lhs','syntax','integer :: x','x=(*2)')
case('malformed_empty_parentheses','syntax','integer :: x','x=()')
case('malformed_extra_rparen','syntax','integer :: x','x=(1+2))')
case('malformed_missing_rparen','syntax','integer :: x','x=(1+2')
case('malformed_trailing_tokens','syntax','integer :: x','x=1 2')
case('malformed_missing_assignment_rhs','syntax','integer :: x','x=')
case('malformed_missing_if_condition','syntax','integer :: x','if () then\n x=2\nend if')
case('malformed_unmatched_else','syntax','integer :: x','else\nx=1')
case('malformed_unclosed_if','syntax','integer :: x','if (.true.) then\n x=1')
case('malformed_unclosed_do','syntax','integer :: i','do i=1,2\n print *, i')
case('malformed_do_missing_bound','syntax','integer :: i','do i=1,\n print *, i\nend do')
case('malformed_unterminated_string','syntax','integer :: x','print *, "oops')
case('malformed_trailing_print_comma','syntax','integer :: x','x=1\nprint *, x,')
add('malformed_end_name','syntax','program probe\nimplicit none\ninteger :: x\nx=1\nend program other')
add('malformed_garbage_after_end','syntax','program probe\nimplicit none\ninteger :: x\nx=1\nend program probe\nthis is not fortran')

case('undeclared_assignment','semantic','integer :: x','y=1')
case('undeclared_expression','semantic','integer :: x','x=y+1')
case('duplicate_declaration','semantic','integer :: x\nreal :: X','x=1')
case('logical_to_integer','semantic','integer :: x','x=.true.')
case('integer_to_logical','semantic','logical :: x','x=1')
case('string_to_integer','semantic','integer :: x','x="abc"')
case('logical_arithmetic','semantic','integer :: x','x=.true.+1')
case('numeric_logical_operator','semantic','logical :: x','x=1.and.2')
case('logical_ordering','semantic','logical :: x','x=.true.<.false.')
case('logical_numeric_equality','semantic','logical :: x','x=.true.==.false.')
case('nonlogical_if','semantic','integer :: x','x=1\nif (x) then\n print *, x\nend if')
case('unreachable_type_error','semantic','integer :: x','if (.false.) then\n x=.true.\nend if')
case('unreachable_undeclared','semantic','integer :: x','if (.false.) then\n print *, missing\nend if')
case('nonconstant_initializer','semantic','integer :: x, y=x','x=1\nprint *, y')
case('declaration_after_execution','semantic','integer :: x','x=1\ninteger :: y\ny=2\nprint *, y')
case('do_real_control','semantic','real :: i','do i=1,3\n print *, i\nend do')
case('do_real_bound','semantic','integer :: i','do i=1,3.5\n print *, i\nend do')
case('do_logical_bound','semantic','integer :: i','do i=.true.,3\n print *, i\nend do')
case('do_variable_assignment','semantic','integer :: i','do i=1,3\n i=2\nend do')
case('do_variable_assignment_dead','semantic','integer :: i','do i=1,3\n if (.false.) then\n  i=2\n end if\nend do')
case('do_nested_same_variable','semantic','integer :: i','do i=1,3\n do i=1,2\n  print *, i\n end do\nend do')

case('runtime_uninitialized_read','runtime','integer :: x','print *, x')
case('runtime_uninitialized_rhs','runtime','integer :: x, y','y=x+1\nprint *, y')
case('runtime_integer_zero_divide','runtime','integer :: x, y','x=1\ny=0\nx=x/y\nprint *, x')
case('runtime_real_zero_divide','runtime','real :: x, y','x=1.0\ny=0.0\nx=x/y\nprint *, x')
case('runtime_integer_add_overflow','runtime','integer :: x','x=2147483647\nx=x+1\nprint *, x')
case('runtime_integer_multiply_overflow','runtime','integer :: x','x=50000\nx=x*x\nprint *, x')
case('runtime_integer_power_overflow','runtime','integer :: x, y','x=2\ny=31\nx=x**y\nprint *, x')
case('runtime_integer_min_divide','runtime','integer :: x, y','x=-2147483647-1\ny=-1\nx=x/y\nprint *, x')
case('runtime_integer_min_negate','runtime','integer :: x','x=-2147483647-1\nx=-x\nprint *, x')
case('runtime_zero_negative_power','runtime','integer :: x, y','x=0\ny=-1\nx=x**y\nprint *, x')
case('runtime_real_nonfinite','runtime','real :: x','x=1.0e30\nx=x*x\nprint *, x')
case('runtime_real_to_integer_range','runtime','real :: x\ninteger :: y','x=1.0e30\ny=x\nprint *, y')
case('runtime_do_zero_step','runtime','integer :: i, stride','stride=0\ndo i=1,2,stride\n print *, i\nend do')
case('runtime_do_uninitialized_bound','runtime','integer :: i, upper','do i=1,upper\n print *, i\nend do')
case('runtime_do_terminal_overflow','runtime','integer :: i','do i=2147483647,2147483647\nend do')
case('runtime_step_budget','runtime','integer :: i, x','x=0\ndo i=1,2147483646\n x=1\nend do',note='Must terminate via the documented execution budget, not loop for billions of steps.')

case('unsupported_array','success','integer :: x(2)','x=1\nprint *, x','1 1', note='Whole arrays supported since 0.4.0; source unchanged.')
case('unsupported_character_variable','unsupported','character(len=3) :: x','x="abc"\nprint *, x')
case('unsupported_integer_kind','unsupported','integer(kind=8) :: x','x=1\nprint *, x')
case('unsupported_complex','unsupported','complex :: x','x=(1.0,2.0)\nprint *, x')
case('unsupported_do_while','success','integer :: x','x=0\ndo while (x<2)\n x=x+1\nend do\nprint *, x','2')
case('unsupported_select_case','unsupported','integer :: x','x=1\nselect case (x)\ncase (1)\n print *, x\nend select')
case('unsupported_write','success','integer :: x','x=1\nwrite (*,*) x','1',note='Historical WRITE rejection fixture promoted without changing source; positional stdout WRITE is now supported.')
case('unsupported_read','unsupported','integer :: x','read (*,*) x\nprint *, x')
case('unsupported_fail_closed','success','integer :: x','x=1\nprint *, "SHOULD_NOT_EXECUTE"\nwrite (*,*) x','SHOULD_NOT_EXECUTE 1',note='Historical WRITE rejection fixture promoted without changing source; positional stdout WRITE is now supported.')
add('unsupported_no_implicit_none','success','program probe\ninteger :: x\nx=1\nprint *, x\nend program probe', '1', note='Promoted to supported in 0.3.0: IMPLICIT NONE is optional; fixture and legacy name retained unchanged.')
add('unsupported_multiple_programs','unsupported','program one\nimplicit none\nprint *, 1\nend program one\nprogram two\nimplicit none\nprint *, 2\nend program two',baseline='reject')
add('unsupported_module','success','module values\nimplicit none\ninteger :: x=1\nend module values\nprogram probe\nuse values\nimplicit none\nprint *, x\nend program probe', '1')
add('unsupported_internal_procedure','unsupported','program probe\nimplicit none\nprint *, twice(2)\ncontains\ninteger function twice(x)\ninteger, intent(in) :: x\ntwice=2*x\nend function twice\nend program probe')

case('logical_equivalence','success','logical :: a, b','a=.true.\nb=.false.\nprint *, a.eqv.b, a.neqv.b, a.eqv..true., a.or.b.eqv.a','F T T T')
case('intrinsic_abs_min_max','success','integer :: x\nreal :: y','x=-3\ny=-2.5\nprint *, abs(x), abs(y), min(9,2,5), max(9,2,5), min(1.5,2.5), max(1.5,2.5)','3 2.5 2 9 1.5 2.5')
case('intrinsic_conversions','success','integer :: x\nreal :: y','x=int(-3.75)\ny=real(7)\nprint *, x, y, mod(-7,3), mod(7,-3), mod(-7.5,3.0)','-3 7 -1 1 -1.5')
case('intrinsic_wrong_count','semantic','integer :: x','x=abs(1,2)')
case('intrinsic_wrong_type','semantic','integer :: x','x=abs(.true.)')
case('intrinsic_mixed_min','semantic','real :: x','x=min(1,2.5)')
case('runtime_abs_min_integer','runtime','integer :: x','x=-2147483647-1\nx=abs(x)\nprint *, x')
case('runtime_mod_zero','runtime','integer :: x, y','x=3\ny=0\nx=mod(x,y)\nprint *, x')
case('unsupported_single_line_if','success','integer :: x','x=1\nif (x==1) print *, x','1', note='Single-line IF is supported from 0.7.0; source retained as a regression.')
case('unsupported_else_if','success','integer :: x','x=1\nif (x==0) then\n print *, 0\nelse if (x==1) then\n print *, 1\nend if','1',note='Historical boundary fixture, supported by the control-flow extension.')

case('real32_expression_rounding','success','real :: x','x=16777216.0\nx=x+1.0\nprint *, x','16777216')
case('real32_literal_rounding','success','real :: x','x=16777217.0\nprint *, x','16777216')
case('integer_negative_powers','success','integer :: x, y','x=-1\ny=-3\nprint *, x**y, 1**y, 2**y, (-2)**y, 0**0','-1 1 0 0 1')
case('numeric_dotted_relations','success','integer :: x','x=1\nprint *, 1.lt.2, 1.eq.1, 2.ge.1, .5.eq.0.5','T T T T')
case('unusual_real_literals','success','real :: x','x=1.e2\nprint *, x, 1E2, 1.e+2, .5e1, 1e-2','100 100 100 5 0.01')
case('semicolon_statements','success','integer :: x; real :: y; logical :: yes','x=2; y=0.5; yes=x==2; print *, x,y,yes','2 0.5 T')
case('semicolon_control_flow','success','integer :: i, s','s=0; do i=1,3; if (i>1) then; s=s+i; else; s=s+10; end if; end do; print *,s,i','15 4')
case('empty_nested_blocks','success','integer :: i, x','x=7\nif (.true.) then\n do i=1,2\n  if (.false.) then\n  else\n  end if\n end do\nelse\nend if\nprint *, x,i','7 3')
case('empty_print','success','','print *\nprint *','',output_lines=2)
case('malformed_empty_print_comma','syntax','','print *,')
case('malformed_adjacent_multiply_sign','syntax','integer :: x','x=2*-3')
case('malformed_adjacent_power_sign','syntax','integer :: x','x=2**-3')
case('malformed_adjacent_add_sign','syntax','integer :: x','x=2+-3')
case('malformed_adjacent_unary_signs','syntax','integer :: x','x=--3')
case('initializer_integer_zero_divide','semantic','integer :: x=1/0','print *,x')
case('initializer_real_zero_divide','semantic','real :: x=1.0/0.0','print *,x')
case('initializer_integer_overflow','safety_static','integer :: x=2147483647+1','print *,x',baseline='skip',note='Interpreter safety contract requires static rejection of an overflowing constant initializer. GNU folds this expression to INT_MIN even under strict standard flags, so no compiler-rejection oracle is claimed.')
case('initializer_real_overflow','safety_static','real :: x=1.0e30*1.0e30','print *,x',baseline='skip')
case('unsupported_keyword_identifier','unsupported','integer :: print','print=3\nprint *,print',note='Fortran has no reserved keywords; rejecting these names is an explicit prototype boundary, not a Fortran semantic error.')
case('unsupported_intrinsic_identifier','unsupported','integer :: abs','abs=3\nprint *,abs',note='Intrinsic names can be ordinary variable names in Fortran; this prototype explicitly reserves its intrinsic allowlist.')

# Deterministic expressions generated independently of the interpreter. GNU also
# executes every generated source before its result is accepted as a baseline.
import random, struct
rng=random.Random(20261114)
def idiv(a,b): return (abs(a)//abs(b)) * (-1 if (a<0)!=(b<0) else 1)
def integer_tree(depth):
    if not depth or rng.random()<0.25:
        value=rng.randint(-9,9)
        return (f'({value})' if value<0 else str(value)),value
    op=rng.choice(['+','-','*','/','**'])
    left,a=integer_tree(depth-1)
    if op=='**':
        b=rng.randint(-2,3); right=f'({b})' if b<0 else str(b)
        if a==0 and b<0: return integer_tree(depth)
        value=pow(a,b) if b>=0 else (pow(a,b) if abs(a)==1 else 0)
        value=int(value)
    else:
        right,b=integer_tree(depth-1)
        if op=='/' and b==0: return integer_tree(depth)
        value={'+':lambda:a+b,'-':lambda:a-b,'*':lambda:a*b,'/':lambda:idiv(a,b)}[op]()
    if abs(value)>1000000: return integer_tree(depth)
    return f'({left}{op}{right})',value
def f32(value): return struct.unpack('f',struct.pack('f',value))[0]
def real_tree(depth):
    if not depth or rng.random()<0.25:
        value=f32(rng.randint(-36,36)/4)
        literal=f'{value:.2f}'
        return (f'({literal})' if value<0 else literal),value
    left,a=real_tree(depth-1); right,b=real_tree(depth-1)
    op=rng.choice(['+','-','*','/'])
    if op=='/' and b==0: return real_tree(depth)
    value=f32({'+':lambda:a+b,'-':lambda:a-b,'*':lambda:a*b,'/':lambda:a/b}[op]())
    return f'({left}{op}{right})',value
for i in range(60):
    expr,value=integer_tree(3)
    case(f'generated_integer_{i:03d}','success','integer :: x',f'x={expr}\nprint *, x',str(value),tags=['generated','seed:20261114'])
for i in range(40):
    expr,value=real_tree(3)
    case(f'generated_real_{i:03d}','success','real :: x',f'x={expr}\nprint *, x',format(value,'.9g'),tags=['generated','seed:20261114'])

case('adjacent_print_strings','success','','print *, \'a\', \'b\', \'\', \'c\'','abc')
case('adjacent_print_mixed','success','','print *, \'x \', 3, \' y\', \'z\'','x 3 yz')

case('malformed_repeated_not','syntax','logical :: x','x=.not. .not. .true.')
case('parenthesized_double_not','success','logical :: x','x=.not.(.not..true.)\nprint *,x','T')
add('program_name_variable_collision','semantic','program probe\nimplicit none\ninteger :: probe\nprobe=1\nprint *,probe\nend program probe')
add('program_name_intrinsic_collision','semantic','program abs\nimplicit none\nprint *,abs(-2)\nend program abs')

# Features supported in 0.17.0; preserve every original source fixture.
SUPPORTED_017 = {'unsupported_character_variable': 'abc', 'unsupported_integer_kind': '1', 'unsupported_select_case': '1', 'unsupported_internal_procedure': '4'}
for row in CASES:
    if row['name'] in SUPPORTED_017:
        row.update(category='success', baseline='run', expected_stdout=SUPPORTED_017[row['name']])

(ROOT / 'manifest.json').write_text(json.dumps({'schema_version':1, 'cases':CASES},indent=2)+'\n')
print(f'Wrote {len(CASES)} independent cases')
