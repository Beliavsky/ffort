#!/usr/bin/env python3
"""Independent explicit-shape rank-one array acceptance cases and oracles."""
from pathlib import Path
import json
import random
import textwrap

ROOT = Path(__file__).resolve().parent
CASES = []

def case(name, category, declarations, statements, expected='', *, baseline=None, diagnostic=None, note=''):
    source = 'program probe\nimplicit none\n' + textwrap.dedent(declarations).strip() + '\n' + textwrap.dedent(statements).strip() + '\nend program probe\n'
    row = dict(name=name, category=category, source=f'cases/{name}.f90', note=note)
    row['baseline'] = baseline or {'success':'run', 'semantic':'reject', 'syntax':'reject', 'unsupported':'compile', 'runtime':'skip', 'static_safety':'skip'}[category]
    if category in ('success', 'runtime'):
        row['expected_stdout'] = expected
    if diagnostic:
        row['diagnostic'] = diagnostic
    (ROOT / row['source']).write_text(source)
    CASES.append(row)

case('integer_elements', 'success', 'integer :: a(3)', 'a(1)=7\na(2)=-4\na(3)=a(1)+a(2)\nprint *,a(1),a(2),a(3)', '7 -4 3')
case('real_elements', 'success', 'real :: a(3)', 'a(1)=1.25\na(2)=-2.5\na(3)=a(1)*a(2)\nprint *,a(1),a(2),a(3)', '1.25 -2.5 -3.125')
case('logical_elements', 'success', 'logical :: a(3)', 'a(1)=.true.\na(2)=.false.\na(3)=a(1).and..not.a(2)\nprint *,a(1),a(2),a(3)', 'T F T')
case('explicit_positive_lower', 'success', 'integer :: a(5:7)', 'a(5)=50\na(6)=60\na(7)=70\nprint *,a(7),a(5),a(6)', '70 50 60')
case('negative_lower', 'success', 'integer :: a(-3:-1)', 'a(-3)=30\na(-2)=20\na(-1)=10\nprint *,a(-3),a(-2),a(-1)', '30 20 10')
case('cross_zero', 'success', 'integer :: a(-1:1)', 'a(-1)=4\na(0)=5\na(1)=6\nprint *,a(-1)+a(0)+a(1)', '15')
case('one_element', 'success', 'logical :: a(-7:-7)', 'a(-7)=.true.\nprint *,a(-7)', 'T')
case('zero_default_extent', 'success', 'integer :: a(0)\ninteger :: n=5', 'print *,n', '5')
case('negative_default_extent', 'success', 'real :: a(-4)', 'print *,7', '7')
case('zero_explicit_extent', 'success', 'logical :: a(8:3)', 'print *,.true.', 'T')
case('zero_extents_all_types', 'success', 'integer :: a(2:1)\nreal :: b(0)\nlogical :: c(-5)', 'print *,9', '9')
case('zero_extent_skipped_access', 'success', 'integer :: a(3:2)\ninteger :: i', 'do i=3,2\n a(i)=1\nend do\nif(.false.) then\n print *,a(3)\nend if\nprint *,i', '3')
case('constant_arithmetic_bounds', 'success', 'integer :: a(-2*2:2**2-1)', 'a(-4)=8\na(3)=9\nprint *,a(-4),a(3)', '8 9')
case('constant_intrinsic_bounds', 'success', 'integer :: a(-abs(2):max(1,3))', 'a(-2)=11\na(3)=22\nprint *,a(-2),a(3)', '11 22')
case('constant_conversion_bounds', 'success', 'integer :: a(int(-2.9):int(2.9))', 'a(-2)=8\na(2)=9\nprint *,a(-2),a(2)', '8 9')
case('huge_positive_lower', 'success', 'integer :: a(2147483646:2147483647)', 'a(2147483646)=8\na(2147483647)=9\nprint *,a(2147483646),a(2147483647)', '8 9')
case('minimum_integer_lower', 'success', 'integer :: a(-2147483647-1:-2147483647)', 'a(-2147483647-1)=8\na(-2147483647)=9\nprint *,a(-2147483647-1),a(-2147483647)', '8 9')
case('wide_reversed_extent', 'success', 'integer :: a(2147483647:-2147483647-1)', 'print *,6', '6', baseline='skip', note='The interpreter handles zero extent without overflowing subtraction; compiler dimension-size implementation limits vary.')
case('mixed_declarators', 'success', 'integer :: a(2),x,b(-1:0),y', 'x=7\ny=9\na(1)=x\na(2)=y\nb(-1)=a(2)\nb(0)=a(1)\nprint *,a(1),a(2),b(-1),b(0),x,y', '7 9 9 7 7 9')
case('same_declaration_different_bounds', 'success', 'integer :: a(2),b(0:3),c(-2:-1)', 'a(2)=2\nb(0)=3\nb(3)=4\nc(-2)=5\nc(-1)=6\nprint *,a(2),b(0),b(3),c(-2),c(-1)', '2 3 4 5 6')
case('mixed_scalar_initializer', 'success', 'integer :: x=3,a(2),y=-2', 'a(1)=x\na(2)=y\nprint *,x,a(1),a(2),y', '3 3 -2 -2')
case('case_insensitive_arrays', 'success', 'INTEGER :: Values(-1:0)', 'vALues(-1)=7\nVALUES(0)=9\nPRINT *,values(-1),VaLuEs(0)', '7 9')
case('same_line_writes', 'success', 'integer :: a(2)', 'a(1)=1; a(2)=2; a(1)=a(2)+3; print *,a(1),a(2)', '5 2')
case('self_update', 'success', 'integer :: a(2)', 'a(1)=2\na(2)=4\na(1)=a(1)*a(2)\nprint *,a(1),a(2)', '8 4')
case('numeric_assignment_conversions', 'success', 'integer :: a(2)\nreal :: b(2)', 'a(1)=-3.75\na(2)=3.75\nb(1)=a(1)\nb(2)=5/2\nprint *,a(1),a(2),b(1),b(2)', '-3 3 -3 2')
case('array_expression_subscript', 'success', 'integer :: a(5),i', 'i=2\na(i*2-1)=8\na(1)=3\nprint *,a(a(1)),a(i+1)', '8 8')
case('nested_subscripts', 'success', 'integer :: a(3),b(3),c(3)', 'a(1)=2\nb(2)=3\nc(3)=17\nprint *,c(b(a(1)))', '17')
case('intrinsic_subscript', 'success', 'integer :: a(-2:2)', 'a(mod(5,3))=19\na(-abs(2))=7\nprint *,a(min(-2,-1)),a(int(2.8))', '7 19')
case('intrinsics_with_elements', 'success', 'integer :: a(2)\nreal :: b(2)', 'a(1)=-7\na(2)=3\nb(1)=-2.5\nb(2)=1.25\nprint *,abs(a(1)),mod(a(1),a(2)),min(a(1),a(2)),max(b(1),b(2)),int(b(1)),real(a(2))', '7 -1 -7 1.25 -2 3')
case('logical_expression_elements', 'success', 'logical :: a(2)\ninteger :: b(2)', 'a(1)=.true.\na(2)=.false.\nb(1)=3\nb(2)=5\nprint *,a(1).neqv.a(2),.not.a(1),b(1)<b(2),(a(1).and.b(2)==5)', 'T F T T')
case('array_if_condition', 'success', 'logical :: flag(2)\ninteger :: a(2)', 'flag(1)=.true.\nflag(2)=.false.\na(1)=1\na(2)=2\nif(flag(1)) then\n a(1)=7\nelse\n a(1)=9\nend if\nif(flag(2)) then\n a(2)=9\nend if\nprint *,a(1),a(2)', '7 2')
case('loop_array_accumulation', 'success', 'integer :: a(-3:3),i,s', 's=0\ndo i=-3,3\n a(i)=i*i\n s=s+a(i)\nend do\nprint *,s,a(-3),a(0),a(3),i', '28 9 0 9 4')
case('descending_array_loop', 'success', 'integer :: a(1:5),i', 'do i=5,1,-1\n a(i)=i*3\nend do\nprint *,a(1),a(2),a(3),a(4),a(5),i', '3 6 9 12 15 0')
case('nested_loops_one_array', 'success', 'integer :: a(6),i,j', 'do i=1,2\n do j=1,3\n  a((i-1)*3+j)=10*i+j\n end do\nend do\nprint *,a(1),a(2),a(3),a(4),a(5),a(6)', '11 12 13 21 22 23')
case('array_do_bounds_snapshot', 'success', 'integer :: limits(3),i,s', 'limits(1)=1\nlimits(2)=5\nlimits(3)=2\ns=0\ndo i=limits(1),limits(2),limits(3)\n s=s+i\n limits(1)=0\n limits(2)=0\n limits(3)=0\nend do\nprint *,s,i,limits(2)', '9 7 0')
case('selectively_initialized', 'success', 'integer :: a(9)', 'a(3)=21\nprint *,a(3)', '21')
case('uninitialized_unselected_branch', 'success', 'integer :: a(2)', 'a(1)=11\nif(.false.) then\n print *,a(2)\nend if\nprint *,a(1)', '11')
case('array_storage_limit_exact', 'success', 'integer :: a(65536)', 'a(1)=4\na(65536)=5\nprint *,a(1),a(65536)', '4 5')
case('array_storage_limit_aggregate_exact', 'success', 'integer :: a(32768),b(32768),x', 'a(32768)=4\nb(32768)=5\nx=6\nprint *,a(32768),b(32768),x', '4 5 6')
case('all_type_storage_isolation', 'success', 'integer :: a(-1:0)\nreal :: b(3:4)\nlogical :: c(-3:-2)', 'a(-1)=5\na(0)=7\nb(3)=0.25\nb(4)=1.75\nc(-3)=.true.\nc(-2)=.false.\na(-1)=a(0)+1\nb(3)=b(4)-0.5\nc(-2)=.not.c(-3)\nprint *,a(-1),a(0),b(3),b(4),c(-3),c(-2)', '8 7 1.25 1.75 T F')
case('aliasing_assignment_subscript', 'success', 'integer :: a(2)', 'a(1)=1\na(2)=7\na(a(1))=2\nprint *,a(1),a(2)\na(a(1))=a(1)+3\nprint *,a(1),a(2)', '2 7 2 5')
case('all_types_loop_fill', 'success', 'integer :: a(-2:2),i\nreal :: b(-2:2)\nlogical :: c(-2:2)', 'do i=-2,2\n a(i)=i*2\n b(i)=real(a(i))/4.0\n c(i)=a(i)>0\nend do\nprint *,a(-2),b(-2),c(-2),a(0),b(0),c(0),a(2),b(2),c(2)', '-4 -1 F 0 0 F 4 1 T')
case('comments_and_semicolons', 'success', 'integer :: a(2) ! dimensions\nreal :: b(-1:0)', 'a(1)=5 ! first value\na(2)=9; b(-1)=0.5; b(0)=a(2)/2.0\nprint *,"array!",a(1),a(2),b(-1),b(0)', 'array! 5 9 0.5 4.5')

# Runtime safety, with independently specified output before the failing statement.
for name, decl, stmt, diagnostic in [
 ('uninitialized_integer_element','integer :: a(2)','print *,a(1)','uninitialized'),
 ('uninitialized_real_element','real :: a(2)','print *,a(1)','uninitialized'),
 ('uninitialized_logical_element','logical :: a(2)','print *,a(1)','uninitialized'),
 ('partially_initialized_array','integer :: a(2)','a(1)=7\nprint *,a(2)','uninitialized'),
 ('uninitialized_subscript','integer :: a(2),i','a(i)=7','uninitialized'),
 ('uninitialized_index_element','integer :: a(2),b(2)','a(b(1))=7','uninitialized'),
 ('uninitialized_rhs_element','integer :: a(2)','a(1)=a(2)+1','uninitialized'),
 ('separate_arrays_not_initialized','integer :: a(2),b(2)','a(1)=7\nprint *,b(1)','uninitialized'),
 ('uninitialized_do_bound_element','integer :: a(2),i','do i=1,a(2)\nend do','uninitialized'),
 ('integer_element_overflow','integer :: a(1)','a(1)=2147483647\na(1)=a(1)+1','overflow'),
 ('integer_element_divide_zero','integer :: a(2)','a(1)=7\na(2)=0\nprint *,a(1)/a(2)','zero'),
 ('real_element_nonfinite','real :: a(1)','a(1)=1.0e30\na(1)=a(1)*a(1)','finite'),
 ('real_to_integer_element_overflow','integer :: a(1)','a(1)=1.0e30','overflow'),
 ('subscript_expression_overflow','integer :: a(2),i','i=2147483647\na(i+1)=8','overflow'),
 ('subscript_expression_divide_zero','integer :: a(2),i','i=0\na(1/i)=8','zero'),
]:
    case(name,'runtime',decl,stmt,diagnostic=diagnostic)
for name, decl, stmt in [
 ('read_below_default','integer :: a(3)','print *,a(0)'),
 ('read_above_default','integer :: a(3)','print *,a(4)'),
 ('write_below_default','integer :: a(3)','a(0)=7'),
 ('write_above_default','integer :: a(3)','a(4)=7'),
 ('read_below_negative_lower','integer :: a(-3:-1)','print *,a(-4)'),
 ('write_above_negative_upper','integer :: a(-3:-1)','a(0)=7'),
 ('zero_extent_read','integer :: a(0)','print *,a(1)'),
 ('zero_extent_write','integer :: a(8:3)','a(8)=7'),
 ('minimum_index_oob','integer :: a(2)','print *,a(-2147483647-1)'),
 ('maximum_index_oob','integer :: a(2)','a(2147483647)=7'),
 ('loop_runs_past_array','integer :: a(2),i','do i=1,3\n a(i)=i\nend do'),
]:
    case(name,'runtime',decl,stmt,baseline='bounds_runtime',diagnostic='bound')
case('print_atomic_uninitialized','runtime','integer :: a(2)','a(1)=7\nprint *,99\nprint *,"partial",a(1),a(2)','99',diagnostic='uninitialized')
case('print_atomic_oob','runtime','integer :: a(2)','a(1)=7\nprint *,99\nprint *,"partial",a(1),a(3)','99',baseline='bounds_runtime',diagnostic='bound')

# Invalid source and deliberately unsupported legal Fortran.
for name, decl, stmt in [
 ('real_read_subscript','integer :: a(2)','print *,a(1.0)'),
 ('real_write_subscript','integer :: a(2)','a(1.5)=3'),
 ('logical_subscript','integer :: a(2)','a(.true.)=3'),
 ('scalar_with_subscript_read','integer :: x','x=3\nprint *,x(1)'),
 ('scalar_with_subscript_write','integer :: x','x(1)=3'),
 ('too_many_subscripts','integer :: a(2)','print *,a(1,1)'),
 ('too_many_lhs_subscripts','integer :: a(2)','a(1,1)=3'),
 ('logical_to_integer_element','integer :: a(2)','a(1)=.true.'),
 ('integer_to_logical_element','logical :: a(2)','a(1)=1'),
 ('character_to_real_element','real :: a(2)','a(1)="x"'),
 ('nonlogical_element_condition','integer :: a(2)','a(1)=1\nif(a(1)) then\n print *,1\nend if'),
 ('duplicate_array_declaration','integer :: a(2)\nreal :: A(3)','print *,1'),
 ('duplicate_mixed_declaration','integer :: a,a(2)','print *,1'),
 ('array_as_do_variable','integer :: a(2)','do a=1,2\nend do'),
 ('element_as_do_variable','integer :: a(2)','do a(1)=1,2\nend do'),
 ('real_declared_bound','integer :: a(2.5)','print *,1'),
 ('logical_declared_bound','integer :: a(.true.)','print *,1'),
 ('nonconstant_declared_bound','integer :: n=3\ninteger :: a(n)','print *,1'),
 ('array_bound_reads_element','integer :: a(2)\ninteger :: b(a(1))','print *,1'),
 ('initializer_reads_element','integer :: a(2),x=a(1)','print *,1'),
 ('undeclared_array','integer :: x','print *,missing(1)'),
 ('undeclared_subscript','integer :: a(2)','a(missing)=3'),
 ('unreachable_bad_element_assignment','integer :: a(2)','print *,7\nif(.false.) then\n a(1)=.true.\nend if'),
]:
    case(name,'semantic',decl,stmt)
for name, decl, stmt in [
 ('missing_upper_bound','integer :: a(1:)','print *,1'),
 ('empty_shape','integer :: a()','print *,1'),
 ('trailing_shape_comma','integer :: a(2,)','print *,1'),
 ('missing_shape_paren','integer :: a(2','print *,1'),
 ('malformed_bound_expression','integer :: a(1+)','print *,1'),
 ('empty_read_subscript','integer :: a(2)','print *,a()'),
 ('empty_write_subscript','integer :: a(2)','a()=1'),
 ('malformed_read_subscript','integer :: a(2)','print *,a(1+)'),
 ('malformed_write_subscript','integer :: a(2)','a(1+)=1'),
 ('missing_read_subscript_paren','integer :: a(2)','print *,a(1'),
 ('missing_write_subscript_paren','integer :: a(2)','a(1=2'),
 ('trailing_subscript_comma','integer :: a(2)','print *,a(1,)'),
]:
    case(name,'syntax',decl,stmt)
for name, decl, stmt in [
 ('rank_two_declaration','integer :: a(2,2)','print *,1'),
 ('dimension_attribute','integer,dimension(2) :: a','print *,1'),
 ('scalar_array_initializer','integer :: a(2)=7','print *,1'),
 ('constructor_initializer','integer :: a(2)=[1,2]','print *,1'),
 ('array_section_read','integer :: a(2)','print *,a(1:2)'),
 ('array_section_write','integer :: a(2)','a(1:2)=7'),
 ('array_vector_subscript','integer :: a(2)','print *,a([1,2])'),
 ('array_constructor_assignment','integer :: a(2)','a=[1,2]'),
 ('allocatable_array','integer,allocatable :: a(:)','print *,1'),
 ('pointer_array','integer,pointer :: a(:)','print *,1'),
 ('parameter_array','integer,parameter :: a(2)=[1,2]','print *,1'),
]:
    case(name,'unsupported',decl,stmt)
# Former 0.2/0.3 unsupported fixtures are unchanged; their 0.4 expectations
# move to supported execution or checked uninitialized reads.
case('whole_array_assignment','success','integer :: a(2)','a=7')
case('whole_array_copy','success','integer :: a(2),b(2)','a=7\nb=a')
case('whole_array_expression','success','integer :: a(2),b(2)','a=7\nb=a+1')
case('unsupported_after_print','success','integer :: a(2)','print *,99\na=3','99')
case('whole_array_print','runtime','integer :: a(2)','print *,a',diagnostic='uninitialized')
case('whole_array_intrinsic','runtime','integer :: a(2)','print *,abs(a)',diagnostic='uninitialized')
case('whole_array_arithmetic_print','runtime','integer :: a(2)','print *,a+1',diagnostic='uninitialized')

for name, decl in [
 ('oversized_single_array','integer :: a(65537)'),
 ('oversized_aggregate_arrays','integer :: a(40000),b(30000)'),
 ('huge_declared_extent','integer :: a(-2147483647:2147483647)'),
 ('overflowing_bound','integer :: a(2147483647+1)'),
 ('zero_divide_bound','integer :: a(1/0)'),
 ('nonfinite_converted_bound','integer :: a(int(1.0e30))'),
]:
    case(name,'static_safety',decl,'print *,99')

# Fixed-seed independent state model: writes, reads, aliasing, expressions and loops.
rng = random.Random(20261114)
for n in range(25):
    lo=rng.randint(-7,4); extent=rng.randint(2,9); hi=lo+extent-1
    values={j:rng.randint(-20,20) for j in range(lo,hi+1)}
    body=[f'a({j})={v}' for j,v in values.items()]
    for _ in range(15):
        target,x,y=[rng.randint(lo,hi) for _ in range(3)]
        c=rng.randint(-3,3)
        body.append(f'a({target})=a({x})+a({y})*({c})')
        values[target]=values[x]+values[y]*c
    indices=list(values)
    body.append('print *,'+','.join(f'a({j})' for j in indices))
    case(f'generated_integer_state_{n:02d}','success',f'integer :: a({lo}:{hi})','\n'.join(body),' '.join(str(values[j]) for j in indices))

for n in range(12):
    lo=rng.randint(-5,3); hi=lo+4
    # Dyadic fractions and bounded addition remain exactly representable in
    # REAL32 here, so the Python model is not a floating-point approximation.
    values={j:rng.randint(-16,16)/8 for j in range(lo,hi+1)}
    body=[f'a({j})={v}' for j,v in values.items()]
    for _ in range(12):
        target,x,y=[rng.randint(lo,hi) for _ in range(3)]
        body.append(f'a({target})=a({x})-a({y})/2.0')
        values[target]=values[x]-values[y]/2
    body.append('print *,'+','.join(f'a({j})' for j in values))
    case(f'generated_real_state_{n:02d}','success',f'real :: a({lo}:{hi})','\n'.join(body),' '.join(str(v) for v in values.values()))

for n in range(12):
    lo=rng.randint(-5,3); hi=lo+4
    values={j:bool(rng.getrandbits(1)) for j in range(lo,hi+1)}
    body=[f'a({j})={".true." if v else ".false."}' for j,v in values.items()]
    for _ in range(12):
        target,x,y=[rng.randint(lo,hi) for _ in range(3)]
        body.append(f'a({target})=a({x}).neqv.(.not.a({y}))')
        values[target]=values[x] != (not values[y])
    body.append('print *,'+','.join(f'a({j})' for j in values))
    case(f'generated_logical_state_{n:02d}','success',f'logical :: a({lo}:{hi})','\n'.join(body),' '.join('T' if v else 'F' for v in values.values()))

# Version 0.5.0: keep original fixtures, migrate four newly supported sections.
MIGRATIONS = {'array_section_read': {'category': 'runtime', 'baseline': 'skip', 'expected_stdout': '', 'diagnostic': 'uninitialized', 'note': 'Supported in 0.5.0; undefined element reads are checked runtime errors.'}, 'array_section_write': {'category': 'success', 'baseline': 'run', 'expected_stdout': '', 'note': 'Section assignment supported in 0.5.0.'}}
# Rank-two arrays are supported in 0.9.0; original source bytes are retained.
MIGRATIONS['rank_two_declaration'] = dict(category='success',baseline='run',expected_stdout='1',
    note='Legacy fixture name retained; rank-two arrays supported in 0.9.0.')
MIGRATIONS['scalar_array_initializer'] = dict(category='success',baseline='run',expected_stdout='1',
    note='Legacy fixture retained; constructor and array initialization supported in 0.16.0.')
MIGRATIONS['constructor_initializer'] = dict(category='success',baseline='run',expected_stdout='1',
    note='Legacy fixture retained; constructor and array initialization supported in 0.16.0.')
MIGRATIONS['array_constructor_assignment'] = dict(category='success',baseline='run',expected_stdout='',
    note='Legacy fixture retained; constructor and array initialization supported in 0.16.0.')
MIGRATIONS['pointer_array'] = dict(category='success', baseline='run', expected_stdout='1',
    note='Original fixture retained; bounded rank-one numeric POINTER declarations are now supported.')

# Version 0.53: preserve every original source; migrate measured numeric vector behavior.
MIGRATIONS['array_vector_subscript'] = {'category': 'runtime', 'baseline': 'compile', 'expected_stdout': '', 'diagnostic': 'read of uninitialized gathered array element', 'note': 'Original source retained. Numeric rank-one vector gathering is supported in 0.53; undefined gathered elements are checked at runtime. GNU compile-only, never undefined-data execution.'}
# Synchronize a pre-existing 0.24 shipped expectation, without changing that manifest row.
MIGRATIONS['allocatable_array'] = {'category': 'success', 'baseline': 'run', 'expected_stdout': '1', 'note': 'Retained original fixture; numeric deferred-shape allocatable declarations supported in 0.24.'}
for row in CASES:
    if row['name'] in MIGRATIONS:
        row.update(MIGRATIONS[row['name']])

# Features supported in 0.17.0; preserve every original source fixture.
SUPPORTED_017 = {'parameter_array': '1'}
for row in CASES:
    if row['name'] in SUPPORTED_017:
        row.update(category='success', baseline='run', expected_stdout=SUPPORTED_017[row['name']])

# DIMENSION attributes now use the same bounded shape contract as declarators.
for row in CASES:
    if row['name'] == 'dimension_attribute':
        row.update(category='success', baseline='run', expected_stdout='1',
                   note='Original fixture retained; bounded DIMENSION attributes are now supported.')

payload={'schema_version':1,'seed':20261114,'cases':CASES}
# The array cap is now 131072; retain historical boundary source fixtures.
# Current-cap tests are generated from fi_ir in tests/array_limits/run_tests.py.
ARRAY_LIMIT_MIGRATIONS = {'oversized_single_array': '99', 'oversized_aggregate_arrays': '99'}
for row in CASES:
    if row['name'] in ARRAY_LIMIT_MIGRATIONS:
        row.update(category='success', baseline='run', expected_stdout=ARRAY_LIMIT_MIGRATIONS[row['name']],
                   note='Historical 65536-element cap probe; legal with the larger cap.')
        row.pop('diagnostic', None)

(ROOT/'manifest.json').write_text(json.dumps(payload,indent=2)+'\n')
print(f'Generated {len(CASES)} array cases')
