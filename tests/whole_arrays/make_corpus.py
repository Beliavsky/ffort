#!/usr/bin/env python3
"""Regenerate independent rank-one whole-array source and expected-value fixtures."""
from pathlib import Path
import json
import random

ROOT = Path(__file__).resolve().parent
CASES = []


def add(name, body, expected='', category='success', baseline=None, note='', **extra):
    if baseline is None:
        baseline = 'run' if category == 'success' else 'reject' if category == 'invalid' else 'skip'
    source = 'program probe\nimplicit none\n' + body.strip() + '\nend program probe\n'
    path = ROOT / 'cases' / (name + '.f90')
    path.write_text(source)
    case = dict(name=name, category=category, source='cases/' + path.name,
                baseline=baseline, expected_stdout=expected, note=note)
    case.update(extra)
    CASES.append(case)


def initialized(name, values, lower=1):
    return '\n'.join(f'{name}({i})={v}' for i, v in enumerate(values, lower))


def tokens(values):
    return ' '.join('T' if v is True else 'F' if v is False else str(v) for v in values)


(ROOT / 'cases').mkdir(parents=True, exist_ok=True)
add('broadcast_integer', '''integer :: a(3)
a=7
print *, a''', '7 7 7')
add('broadcast_real', '''real :: a(-1:1)
a=1.25
print *, a''', '1.25 1.25 1.25')
add('broadcast_logical', '''logical :: a(0:2)
a=.true.
print *, a''', 'T T T')
add('broadcast_integer_to_real', '''real :: a(3)
a=-3
print *, a''', '-3 -3 -3')
add('broadcast_real_to_integer', '''integer :: a(2), b(2)
a=-3.9
b=3.9
print *, a,b''', '-3 -3 3 3')
add('broadcast_parameter', '''integer, parameter :: n=4, value=3**2
integer :: a(-2:n-3)
a=value
print *, a''', '9 9 9 9')
add('copy_different_lower_bounds', '''integer :: a(-2:1), b(7:10)
a(-2)=2
a(-1)=-3
a(0)=7
a(1)=0
b=a
print *, b,b(7),b(10)''', '2 -3 7 0 2 0')
add('self_copy', '''integer :: a(3)
a(1)=2
a(2)=3
a(3)=4
a=a
print *, a''', '2 3 4')
add('self_scalar_reference_snapshot', '''integer :: a(3)
a(1)=2
a(2)=3
a(3)=4
a=a+a(1)
print *, a''', '4 5 6', note='The scalar a(1) must retain its pre-assignment value for all elements.')
add('self_last_scalar_reference_snapshot', '''integer :: a(3)
a(1)=2
a(2)=3
a(3)=4
a=a(3)-a
print *, a''', '2 1 0')
add('self_scalar_broadcast_snapshot', '''integer :: a(3)
a(1)=8
a(2)=3
a(3)=4
a=a(1)+1
print *, a''', '9 9 9')
add('self_nested_scalar_subscript_snapshot', '''integer :: a(3)
a(1)=2
a(2)=3
a(3)=5
a=a+a(a(1))
print *, a''', '5 6 8')
add('element_assignment_after_whole_update', '''integer :: a(3)
a=2
a=a+3
a(2)=a(1)*a(3)
print *, a''', '5 25 5')
add('overwrites_partial_initialization', '''integer :: a(3)
a(2)=9
a=4
print *, a''', '4 4 4')
add('scalar_left_noncommutative', '''integer :: a(3), b(3), c(3)
a(1)=1
a(2)=2
a(3)=4
b=12/a
c=10-a
print *, b,c,2**a''', '12 6 3 9 8 6 2 4 16')
add('array_integer_arithmetic', '''integer :: a(3), b(-1:1), c(3)
a(1)=-7
a(2)=8
a(3)=-9
b(-1)=2
b(0)=-3
b(1)=-4
c=a/b
print *, a+b,a-b,a*b,c''', '-5 5 -13 -9 11 -5 -14 -24 36 -3 -2 2')
add('mixed_numeric_arrays', '''integer :: a(3), c(3)
real :: b(3), d(3)
a(1)=1
a(2)=-3
a(3)=7
b(1)=0.5
b(2)=-1.5
b(3)=2.25
d=a+b*2
c=d
print *, d,c,b/a''', '2 -6 11.5 2 -6 11 0.5 0.5 0.321428571')
add('unary_and_power_precedence', '''integer :: a(3), b(3)
a(1)=-2
a(2)=0
a(3)=3
b=-a**2
print *, b,(-a)**2,+a,2**a**2''', '-4 0 -9 4 0 9 -2 0 3 16 1 512')
add('array_negative_integer_power', '''integer :: a(3), b(3)
a(1)=2
a(2)=-1
a(3)=1
b(1)=-2
b(2)=-3
b(3)=-4
print *, a**b''', '0 -1 1')
add('array_real_power', '''real :: a(3)
integer :: n(3)
a(1)=4.0
a(2)=9.0
a(3)=16.0
n(1)=1
n(2)=2
n(3)=3
print *, a**0.5,2.0**n,a**n''', '2 3 4 2 4 8 4 81 4096')
add('numeric_comparison_arrays', '''integer :: a(3), b(3)
logical :: c(3)
a(1)=1
a(2)=2
a(3)=3
b(1)=3
b(2)=2
b(3)=1
c=a<b
print *, c,a<=b,a==b,a/=b,a>b,a>=b''', 'T F F T T F F T F T F T F F T F T T')
add('scalar_comparison_both_sides', '''integer :: a(3)
a(1)=1
a(2)=2
a(3)=3
print *, a>2,2<a,a<=2,2>=a''', 'F F T F F T T T F T T F')
add('logical_array_operators', '''logical :: a(3), b(3)
a(1)=.true.
a(2)=.false.
a(3)=.true.
b(1)=.false.
b(2)=.false.
b(3)=.true.
print *, .not.a,a.and.b,a.or.b,a.eqv.b,a.neqv.b''', 'F T F F F T T F T F T T T F F')
add('logical_scalar_both_sides', '''logical :: a(3), b(3)
a(1)=.true.
a(2)=.false.
a(3)=.true.
b=.false..neqv.a
print *, b,a.and..true.,.false..or.a,.true..eqv.a''', 'T F T T F T T F T T F T')
add('logical_array_assignment_from_comparison', '''integer :: a(3)
logical :: b(3)
a(1)=-1
a(2)=0
a(3)=1
b=.not.(a<0).and.(a/=0)
print *, b''', 'F F T')
add('intrinsic_abs_conversion', '''integer :: a(3), b(3)
real :: r(3)
a(1)=-3
a(2)=0
a(3)=5
r=real(a)/2.0
b=int(r)
print *, abs(a),abs(r),b,real(b)''', '3 0 5 1.5 0 2.5 -1 0 2 -1 0 2')
add('intrinsic_mod_array_arguments', '''integer :: a(3), b(3)
a(1)=-7
a(2)=8
a(3)=9
b(1)=3
b(2)=-3
b(3)=4
print *, mod(a,b),mod(a,3),mod(10,b)''', '-1 2 1 -1 2 0 1 1 2')
add('intrinsic_min_max_scalar_expansion', '''integer :: a(3), b(3), c(3)
a(1)=-3
a(2)=4
a(3)=5
b(1)=2
b(2)=-5
b(3)=8
c=min(1,a,b)
print *, c,max(a,3,b),min(a,b,0,7),max(-9,a,b,6)''', '-3 -5 1 3 4 8 -3 -5 0 6 6 8')
add('nested_elemental_intrinsics', '''integer :: a(3)
real :: r(3)
a(1)=-3
a(2)=4
a(3)=-7
r=max(abs(real(a)/2.0),1.0)
print *, r,int(r),min(abs(a),5)''', '1.5 2 3.5 1 2 3 3 4 5')
add('whole_print_mixed_items', '''integer :: a(-1:1)
a(-1)=2
a(0)=3
a(1)=4
print *, 'start',a,'middle',a+1,'end' ''', 'start 2 3 4 middle 3 4 5 end')
add('print_array_expression_values', '''integer :: a(2)
a(1)=3
a(2)=4
print *, a+a(1),a,a(2)''', '6 7 3 4 4')
add('whole_assign_in_loops_and_branches', '''integer :: a(3), i
a=0
do i=1,4
if (i<3) then
a=a+i
else
a=a*2
end if
end do
print *, a,i''', '12 12 12 5')
add('minimum_and_maximum_bounds', '''integer :: a(-2147483647-1:-2147483647), b(2147483646:2147483647)
a=5
b=a+2
print *, a,b,b(2147483647)''', '5 5 7 7 7')
add('single_element_array_is_rank_one', '''integer :: a(-7:-7), b(4:4)
a=6
b=a*2
print *, b,a''', '12 6')
add('empty_broadcast_and_print', '''integer :: a(0)
real :: b(2:1)
logical :: c(-1:-2)
a=7
b=2.5
c=.true.
print *, a,b,c
print *, 8''', '8', expected_stdout_lines=2)
add('empty_copy_different_bounds', '''integer :: a(3:1), b(-2:-4)
a=b
print *, 7,a,b,8''', '7 8')
add('empty_array_expression_no_element_reads', '''integer :: a(0), b(0), c
logical :: l(0)
a=b+c
l=a>c
print *, a,l,7''', '7', baseline='skip', note='Interpreter policy: zero-extent array expressions perform no element evaluation, including scalar leaves.')
add('empty_intrinsics_no_element_reads', '''integer :: a(0), b(0), c
real :: r(0)
a=min(b,c)
r=real(a)/real(c)
print *, a,r,9''', '9', baseline='skip', note='Interpreter-specific deterministic zero-extent evaluation contract.')
add('unreachable_uninitialized_whole_read', '''integer :: a(3), b(3)
if (.false.) then
b=a+1
print *, b
end if
a=2
print *, a''', '2 2 2')
add('whole_array_source_case_insensitive', '''integer :: ArrayA(2), arrayB(-1:0)
ARRAYa=3
ARRAYB=arraya+4
print *, ArrayB''', '7 7')
add('broadcast_exact_aggregate_limit', '''integer :: a(65536)
a=7
print *, a(1),a(32768),a(65536)''', '7 7 7')

# Invalid expressions remain static failures, even following reachable output.
invalid = {
 'mismatched_assignment_extent': 'integer :: a(2),b(3)\nprint *,99\na=b',
 'mismatched_binary_extent': 'integer :: a(2),b(3),c(2)\nprint *,99\nc=a+b',
 'mismatched_nested_extent': 'integer :: a(2),b(3),c(2)\nc=(a+1)*(b-2)',
 'mismatched_logical_extent': 'logical :: a(2),b(3),c(2)\nc=a.and.b',
 'mismatched_comparison_extent': 'integer :: a(2),b(3)\nlogical :: c(2)\nc=a<b',
 'mismatched_intrinsic_extent': 'integer :: a(2),b(3),c(2)\nc=max(1,a,b)',
 'mismatched_mod_extent': 'integer :: a(2),b(3),c(2)\nc=mod(a,b)',
 'mismatched_empty_nonempty': 'integer :: a(0),b(1)\na=b',
 'scalar_target_array_source': 'integer :: a(1),x\nx=a',
 'element_target_array_source': 'integer :: a(2),b(2)\na(1)=b',
 'whole_array_if_condition': 'logical :: a(1)\nif(a) then\nprint *,1\nend if',
 'whole_array_do_start': 'integer :: a(1),i\ndo i=a,2\nprint *,i\nend do',
 'whole_array_do_end': 'integer :: a(1),i\ndo i=1,a\nprint *,i\nend do',
 'whole_array_do_step': 'integer :: a(1),i\ndo i=1,2,a\nprint *,i\nend do',
 'whole_array_do_variable': 'integer :: a(1)\ndo a=1,2\nprint *,1\nend do',
 'logical_array_from_integer': 'integer :: a(2)\nlogical :: b(2)\nb=a',
 'integer_array_from_logical': 'integer :: a(2)\nlogical :: b(2)\na=b',
 'logical_array_arithmetic': 'logical :: a(2),b(2)\na=b+1',
 'numeric_array_logical_operator': 'integer :: a(2)\nlogical :: b(2)\nb=a.and..true.',
 'mixed_type_min_array': 'integer :: a(2)\nreal :: b(2)\nb=min(a,1.0)',
 'logical_array_abs': 'logical :: a(2)\nprint *,abs(a)',
 'whole_array_declaration_initializer': 'integer :: a(2),x=a',
 'whole_array_parameter_initializer': 'integer :: a(2)\ninteger,parameter :: x=a',
 'whole_array_bound': 'integer :: a(2)\ninteger :: b(a)',
 'nonconformable_dead_branch': 'integer :: a(2),b(3)\nif(.false.)then\na=b\nend if\nprint *,1',
}
for name, body in invalid.items():
    add(name, body, category='invalid')

# These remain outside the explicitly supported rank-one whole-array subset.
unsupported = {
 'unsupported_section_assignment': 'integer :: a(3)\na=1\na(2:3)=a(1:2)\nprint *,a',
 'unsupported_section_expression': 'integer :: a(3),b(2)\na=1\nb=a(1:2)\nprint *,b',
 'unsupported_vector_subscript': 'integer :: a(3),ix(2),b(2)\na=1\nix=1\nb=a(ix)\nprint *,b',
 'unsupported_array_constructor': 'integer :: a(3)\na=[1,2,3]\nprint *,a',
 'unsupported_rank_two': 'integer :: a(2,2)\na=1\nprint *,a',
 'unsupported_array_size_intrinsic': 'integer :: a(3)\na=1\nprint *,size(a)',
}
for name, body in unsupported.items():
    add(name, body, category='unsupported', baseline='compile')

# Runtime-only contract: uninitialized reads and arithmetic safety are stronger
# than GNU's portable checks, so no execution oracle is claimed for those cases.
runtime = {
 'uninitialized_whole_copy': ('integer :: a(3),b(3)\nb=1\nprint *,99\nb=a', 'uninitialized'),
 'uninitialized_partial_source': ('integer :: a(3),b(3)\na(1)=1\na(3)=3\nprint *,99\nb=a+1', 'uninitialized'),
 'uninitialized_whole_print': ('integer :: a(2)\na(1)=1\nprint *,99\nprint *,"partial",a', 'uninitialized'),
 'uninitialized_late_print_item': ('integer :: a(2),b(2)\na=3\nb(1)=1\nprint *,99\nprint *,a,"partial",b', 'uninitialized'),
 'uninitialized_scalar_broadcast': ('integer :: a(3),x\nprint *,99\na=x', 'uninitialized'),
 'uninitialized_scalar_in_array_expr': ('integer :: a(3),b(3),x\na=1\nprint *,99\nb=a+x', 'uninitialized'),
 'uninitialized_empty_scalar_broadcast': ('integer :: a(0),x\nprint *,99\na=x', 'uninitialized'),
 'uninitialized_self_scalar_broadcast': ('integer :: a(3)\na(2)=3\nprint *,99\na=a(1)', 'uninitialized'),
 'uninitialized_eager_logical_array': ('logical :: a(2),b(2)\nb=.false.\nprint *,99\nb=b.and.a', 'uninitialized'),
 'integer_array_add_overflow': ('integer :: a(2)\na(1)=2\na(2)=2147483647\nprint *,99\na=a+1', 'overflow'),
 'integer_array_multiply_overflow': ('integer :: a(2)\na(1)=2\na(2)=1073741824\nprint *,99\na=a*2', 'overflow'),
 'integer_array_divide_zero': ('integer :: a(2),b(2)\na=1\nb(1)=1\nb(2)=0\nprint *,99\na=a/b', 'zero'),
 'real_array_divide_zero': ('real :: a(2),b(2)\na=1.0\nb(1)=1.0\nb(2)=0.0\nprint *,99\na=a/b', 'zero'),
 'array_conversion_overflow': ('integer :: a(2)\nreal :: b(2)\nb(1)=1.0\nb(2)=3.0e9\nprint *,99\na=b', 'overflow'),
 'array_intrinsic_int_overflow': ('integer :: a(2)\nreal :: b(2)\nb(1)=1.0\nb(2)=3.0e9\nprint *,99\na=int(b)', 'overflow'),
 'array_abs_minimum_integer': ('integer :: a(2)\na(1)=2\na(2)=-2147483647-1\nprint *,99\na=abs(a)', 'overflow'),
 'array_nonfinite_real_result': ('real :: a(2)\na(1)=1.0\na(2)=3.0e38\nprint *,99\na=a*2.0', 'non-finite'),
 'array_power_overflow': ('integer :: a(2)\na(1)=2\na(2)=31\nprint *,99\na=2**a', 'overflow'),
 'array_print_atomic_arithmetic_failure': ('integer :: a(2),b(2)\na=1\nb(1)=1\nb(2)=0\nprint *,99\nprint *,"partial",a,a/b', 'zero'),
}
for name, (body, diagnostic) in runtime.items():
    add(name, body, '99', category='runtime', diagnostic=diagnostic)

for name, body in {
 'bounds_error_scalar_broadcast': 'integer :: a(2),i=3\na=1\nprint *,99\na=a(i)',
 'bounds_error_scalar_array_leaf': 'integer :: a(2),i=0\na=1\nprint *,99\na=a+a(i)',
 'bounds_error_print_after_assignment': 'integer :: a(-1:1),i=2\na=3\nprint *,99\nprint *,a,a(i)',
}.items():
    add(name, body, '99', category='runtime', baseline='bounds_runtime', diagnostic='bound')
add('broadcast_work_budget', 'integer :: a(100)\na=7\nprint *,a(1)', '',
    category='runtime', diagnostic='step limit', candidate_args=['--max-steps', '25'])

# Deterministic independent small-value model; expected values are never obtained
# from either interpreter. Scalar references in RHS intentionally alias the LHS.
rng = random.Random(20261114)
for number in range(20):
    size = rng.randrange(1, 8)
    lower_a, lower_b = rng.randrange(-5, 5), rng.randrange(5, 15)
    a = [rng.randrange(-9, 10) for _ in range(size)]
    b = [rng.randrange(-9, 10) for _ in range(size)]
    body = f'integer :: a({lower_a}:{lower_a+size-1}),b({lower_b}:{lower_b+size-1})\n'
    body += initialized('a', a, lower_a) + '\n' + initialized('b', b, lower_b) + '\n'
    for step in range(6):
        op = rng.randrange(4)
        if op == 0:
            k = rng.randrange(-3, 4)
            body += f'a=a+({k})*b\n'
            a = [x + k*y for x, y in zip(a, b)]
        elif op == 1:
            idx = rng.randrange(size)
            scalar = a[idx]
            body += f'a=a+a({lower_a+idx})\n'
            a = [x + scalar for x in a]
        elif op == 2:
            k = rng.randrange(-4, 5)
            body += f'b=({k})-a\n'
            b = [k-x for x in a]
        else:
            body += 'b=min(abs(a),17)\n'
            b = [min(abs(x), 17) for x in a]
    body += 'print *,a,b,a>=b'
    add(f'generated_integer_snapshot_{number:02d}', body, tokens(a+b+[x>=y for x,y in zip(a,b)]))

# PRINT must preserve list-directed adjacent character concatenation when an
# intervening array contributes zero values, and count source items, not elements.
add('empty_array_between_character_items', "integer :: a(0)\nprint *, 'left',a,'right'", 'leftright')
add('multiple_empty_print_records', "integer :: a(0)\nprint *, a\nprint *, a+a\nprint *, 9", '9', expected_stdout_lines=3)
add('print_expands_more_than_64_values', "integer :: a(100)\na=3\nprint *, a", tokens([3]*100))
add('scalar_first_elemental_intrinsic_shape', "integer :: a(3),b(3)\na(1)=2\na(2)=3\na(3)=4\nb=max(1,2,a)\nprint *,b,min(9,8,a),mod(20,a)", '2 3 4 2 3 4 0 2 0')

# Exact binary fractions make the independent REAL oracle insensitive to host
# rounding except at already-toleranced print conversion.
for number in range(12):
    a = [rng.randrange(-16, 17)/4 for _ in range(5)]
    b = [rng.randrange(-16, 17)/4 for _ in range(5)]
    body = 'real :: a(-2:2),b(5:9)\n' + initialized('a', a, -2) + '\n' + initialized('b', b, 5) + '\n'
    for step in range(5):
        idx = rng.randrange(5)
        scalar = a[idx]
        body += f'a=(a+b)*0.5+a({idx-2})\nb=abs(a)-1.25\n'
        a = [(x+y)*0.5+scalar for x,y in zip(a,b)]
        b = [abs(x)-1.25 for x in a]
    body += 'print *,a,b,a>b'
    add(f'generated_real_snapshot_{number:02d}', body, tokens(a+b+[x>y for x,y in zip(a,b)]))

for number in range(12):
    a = [bool(rng.randrange(2)) for _ in range(5)]
    b = [bool(rng.randrange(2)) for _ in range(5)]
    body = 'logical :: a(-2:2),b(5:9)\n'
    body += initialized('a', ['.true.' if x else '.false.' for x in a], -2) + '\n'
    body += initialized('b', ['.true.' if x else '.false.' for x in b], 5) + '\n'
    for step in range(5):
        idx = rng.randrange(5)
        scalar = a[idx]
        body += f'a=(a.neqv.b).eqv.a({idx-2})\nb=.not.a.or.b\n'
        a = [(x != y) == scalar for x,y in zip(a,b)]
        b = [(not x) or y for x,y in zip(a,b)]
    body += 'print *,a,b'
    add(f'generated_logical_snapshot_{number:02d}', body, tokens(a+b))

# Resource and zero-target policy boundaries have no GNU language oracle.
add('expanded_print_value_limit', 'integer :: a(32768)\na=7\nprint *,99\nprint *,a,a,1', '99',
    category='runtime', diagnostic='PRINT expanded value limit')
add('print_array_work_budget_atomicity', 'integer :: a(100)\na=7\nprint *,99\nprint *,a', '99',
    category='runtime', diagnostic='step limit', candidate_args=['--max-steps','125'])
add('empty_scalar_broadcast_divide_zero', 'integer :: a(0),x=0\nprint *,99\na=1/x', '99',
    category='runtime', diagnostic='zero')
add('empty_scalar_broadcast_conversion_overflow', 'integer :: a(0)\nreal :: x=3.0e9\nprint *,99\na=x', '99',
    category='runtime', diagnostic='overflow')

# Version 0.5.0: keep original fixtures, migrate four newly supported sections.
MIGRATIONS = {'unsupported_section_assignment': {'category': 'success', 'baseline': 'run', 'expected_stdout': '1 1 1', 'note': 'Legacy fixture name retained; section assignment supported in 0.5.0.'}, 'unsupported_section_expression': {'category': 'success', 'baseline': 'run', 'expected_stdout': '1 1', 'note': 'Legacy fixture name retained; section expressions supported in 0.5.0.'}}
# Version 0.8.0: the original SIZE fixture is now supported.
MIGRATIONS['unsupported_array_size_intrinsic'] = dict(category='success', baseline='run',
    expected_stdout='3', note='Legacy fixture name retained; SIZE supported in 0.8.0.')
# Rank-two arrays are supported in 0.9.0; original source bytes are retained.
MIGRATIONS['unsupported_rank_two'] = dict(category='success',baseline='run',expected_stdout='1 1 1 1',
    note='Legacy fixture name retained; rank-two arrays supported in 0.9.0.')
MIGRATIONS['unsupported_array_constructor'] = dict(category='success',baseline='run',expected_stdout='1 2 3',
    note='Legacy fixture retained; constructor and array initialization supported in 0.16.0.')

# Version 0.53: preserve every original source; migrate measured numeric vector behavior.
MIGRATIONS['unsupported_vector_subscript'] = {'category': 'success', 'baseline': 'run', 'expected_stdout': '1 1', 'note': 'Original source and legacy name retained. Numeric rank-one vector gathering supported in 0.53; defined duplicate indices produce 1 1, independently checked with GNU.'}
for row in CASES:
    if row['name'] in MIGRATIONS:
        row.update(MIGRATIONS[row['name']])

(ROOT / 'manifest.json').write_text(json.dumps(dict(schema_version=1, seed=20261114, cases=CASES), indent=2)+'\n')
print(f'Wrote {len(CASES)} whole-array fixtures')
