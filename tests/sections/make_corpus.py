#!/usr/bin/env python3
"""Reproduce independently modeled rank-one array-section CLI fixtures."""
from pathlib import Path
import json
import random

ROOT = Path(__file__).resolve().parent
SEED = 20261115
CASES = []


def tokens(values):
    return ' '.join('T' if v is True else 'F' if v is False else str(v) for v in values)


def add(name, body, expected='', category='success', baseline=None, note='', **extra):
    baseline = baseline or ('run' if category == 'success' else 'reject' if category == 'invalid' else 'skip')
    text = 'program probe\nimplicit none\n' + body.strip() + '\nend program probe\n'
    (ROOT/'cases'/f'{name}.f90').write_text(text)
    CASES.append(dict(name=name, category=category, source=f'cases/{name}.f90',
                      baseline=baseline, expected_stdout=expected, note=note, **extra))


def setup(values, lower=1, kind='integer', name='a'):
    text = f'{kind} :: {name}({lower}:{lower + len(values)-1})\n'
    return text + '\n'.join(f'{name}({i})={".true." if v is True else ".false." if v is False else v}'
                            for i, v in enumerate(values, lower))


def selected(lower, upper, start=None, stop=None, step=1):
    """Inclusive Fortran triplet modeled without the interpreter or a compiler."""
    start = lower if start is None else start
    stop = upper if stop is None else stop
    return list(range(start, stop + (1 if step > 0 else -1), step))


def section(start=None, stop=None, step=None):
    return ('' if start is None else str(start)) + ':' + ('' if stop is None else str(stop)) + ('' if step is None else ':' + str(step))


(ROOT/'cases').mkdir(parents=True, exist_ok=True)
values = [-30, -20, -10, 0, 10, 20, 30]
base = setup(values, -3)
triplets = [(-3,3,None), (None,None,None), (None,0,None), (0,None,None),
            (None,None,2), (None,None,-1), (None,None,-2), (None,0,-1),
            (0,None,-1), (3,-3,-3), (-3,3,3), (3,3,1), (3,3,-1),
            (-3,3,-1), (3,-3,1), (-3,4,2), (3,-4,-2),
            (-3,3,2147483647), (3,-3,-2147483647)]
for n, (start, stop, step) in enumerate(triplets):
    inds = selected(-3,3,start,stop,1 if step is None else step)
    add(f'triplet_{n:02d}', base + f'\nprint *, 91,a({section(start,stop,step)}),92',
        tokens([91]+[values[i+3] for i in inds]+[92]))

add('whitespace_semicolon_case', 'INTEGER :: A(3); A=2\nPRINT *, A( : : - 1 )', '', expected_stdout_lines=1)
add('negative_default_first_singleton', base+'\nprint *, a(:-3:-1)', '-30')
add('negative_default_last_singleton', base+'\nprint *, a(3::-1)', '30')
add('singleton_negative_defaults', 'integer :: a(-3:-3)\na=7\nprint *, a(::-1)', '7')
add('scalar_broadcast_selected_only', base+'\na(-2:2:2)=7\nprint *, a', '-30 7 -10 7 10 7 30')
add('reverse_broadcast', base+'\na(3:-3:-2)=8\nprint *, a', '8 -20 8 0 8 20 8')
add('section_to_whole_different_bounds', 'integer :: b(8:10)\n'+base+'\nb=a(-3:1:2)\nprint *, b', '-30 -10 10')
add('whole_to_section_different_bounds', 'integer :: b(8:10)\n'+base+'\nb=7\na(3:-1:-2)=b\nprint *, a', '-30 -20 7 0 7 20 7')
add('sections_different_base_bounds', 'integer :: b(8:10)\n'+base+'\nb=1\nb(10:8:-1)=a(-3:1:2)\nprint *, b', '10 -10 -30')
add('overlap_shift_right', setup([1,2,3,4,5])+'\na(2:5)=a(1:4)\nprint *, a', '1 1 2 3 4')
add('overlap_shift_left', setup([1,2,3,4,5])+'\na(1:4)=a(2:5)\nprint *, a', '2 3 4 5 5')
add('overlap_reverse', setup([1,2,3,4,5])+'\na(:)=a(5:1:-1)\nprint *, a', '5 4 3 2 1')
add('overlap_reverse_target', setup([1,2,3,4,5])+'\na(5:1:-1)=a(:)\nprint *, a', '5 4 3 2 1')
add('overlap_interleaved', setup([1,2,3,4,5,6])+'\na(2:6:2)=a(1:5:2)+a(2)\nprint *, a', '1 3 3 5 5 7')
add('overlap_scalar_snapshot', setup([1,2,3,4,5])+'\na(1:4)=a(1:4)+a(1)\nprint *, a', '2 3 4 5 5')
add('target_bounds_snapshot', setup([2,4,9,8,7])+'\na(a(1):a(2))=6\nprint *, a', '2 6 6 6 7')
add('target_stride_snapshot', setup([2,10,20,30,40])+'\na(1:5:a(1))=a(1:5:a(1))+1\nprint *, a', '3 10 21 30 41')
add('element_subscripts_as_endpoints', setup([2,4,6,8,10])+'\nprint *, a(a(1):a(2):a(1))', '4 8')
add('other_array_endpoint_expressions', 'integer :: indexes(3)\n'+setup([1,2,3,4,5])+
    '\nindexes(1)=5\nindexes(2)=1\nindexes(3)=-2\nprint *, a(indexes(1):indexes(2):indexes(3))', '5 3 1')
add('nested_element_endpoints', 'integer :: indexes(2)\n'+setup([2,4,6,8,10])+
    '\nindexes(1)=1\nindexes(2)=2\nprint *, a(a(indexes(1)):a(indexes(2)))', '4 6 8')
add('loop_refreshes_element_bound', 'integer :: i\n'+setup([1,20,30,40])+
    '\ndo i=1,3\nprint *, a(1:a(1))\na(1)=a(1)+1\nend do', '1 2 20 3 20 30')
add('intrinsics_as_endpoints', base+'\nprint *, a(min(-2,-1):max(1,2):abs(-2))', '-20 0 20')
add('precedence_in_endpoints', base+'\nprint *, a(-2**1:2**1:1+1)', '-20 0 20')
add('parameter_endpoints', 'integer, parameter :: low=-3, high=3, stride=2\n'+base+
    '\nprint *, a(low:high:stride)', '-30 -10 10 30')
add('dynamic_loop_sections', 'integer :: i, j, s\n'+setup([1,2,3,4,5])+
    '\ndo s=-2,2,4\ni=3\nj=5\nprint *, a(i:j:s)\nprint *, a(::s)\nend do',
    '3 5 1 3 5', expected_stdout_lines=4)
add('section_bounds_change_between_statements', 'integer :: lo,hi,s\n'+setup([1,2,3,4,5])+
    '\nlo=1\nhi=5\ns=2\nprint *, a(lo:hi:s)\nlo=5\nhi=1\ns=-2\nprint *, a(lo:hi:s)', '1 3 5 5 3 1')
add('numeric_conversions', 'integer :: b(3)\n'+setup([1.5,-2.5,3.5,4.5],kind='real')+
    '\nb=a(4:2:-1)\na(1:3)=b\nprint *, a,b', '4 3 -2 4.5 4 3 -2')
add('integer_to_real_section', 'real :: b(-1:1)\n'+setup([1,2,3,4,5])+
    '\nb(1:-1:-1)=a(1:5:2)\nprint *, b', '5 3 1')
add('logical_sections', setup([True,False,False,True],kind='logical')+
    '\na(4:1:-1)=.not.a(:)\nprint *, a,a(1:3:2).eqv..true.', 'F T T F F T')
add('binary_all_numeric_ops', setup([1,2,3,4,5])+
    '\nprint *, a(1:3)+a(5:3:-1),a(1:3)-a(5:3:-1),a(1:3)*a(5:3:-1)\n'
    'print *, 12/a(1:3),2**a(1:3),-a(1:3)**2', '6 6 6 -4 -2 0 5 8 9 12 6 4 2 4 8 -1 -4 -9')
add('binary_all_comparisons', setup([1,2,3])+
    '\nprint *, a(:)<a(3:1:-1),a(:)<=a(3:1:-1),a(:)==a(3:1:-1)\n'
    'print *, a(:)/=a(3:1:-1),a(:)>a(3:1:-1),a(:)>=a(3:1:-1)',
    'T F F T T F F T F T F T F F T F T T')
add('six_intrinsics_sections', setup([-3,-2,-1,0,1])+
    '\nprint *, abs(a(::2)),int(real(a(2:4))),real(a(5:1:-2))\n'
    'print *, mod(a(1:3),2),min(2,a(::2)),max(a(::2),-1)',
    '3 1 1 -2 -1 0 1 -1 -3 -1 0 -1 -3 -1 1 -1 -1 1')
add('mixed_item_character_concatenation', base+'\nprint *, "ab",a(3:-3),"cd",a(1:3:2),"ef"', 'abcd 10 30 ef')
add('section_partial_initialization', 'integer :: a(6)\na(2:6:2)=7\nprint *, a(6:2:-2)', '7 7 7')
add('one_selected_element_minimum_stride', base+'\nprint *, a(3:-3:(-2147483647-1))', '30')
add('empty_extreme_endpoints', base+'\nprint *, 1,a(2147483647:(-2147483647-1)),2\n'
    'print *, 3,a((-2147483647-1):2147483647:-1),4', '1 2 3 4')
add('large_section_print', 'integer :: a(200)\na=7\nprint *, a(200:2:-2)', tokens([7]*100))
add('empty_reverse_scalar_expansion', base+'\na(::-1)=8\nprint *, a', tokens(values))
add('empty_reverse_array_assignment', base+'\na(::-1)=a(3:-3)\nprint *, a', tokens(values))
add('extreme_bounds_inclusive_range', 'integer :: a(-2147483647:(-2147483647+2)),b(2147483645:2147483647)\n'
    'a=3\nb(2147483647:2147483645:-1)=a(:)\nprint *, a(::2),b(2147483647:2147483645:-2)', '3 3 3 3')

# Empty selections have no selected indices, even when their endpoint expressions
# lie outside the parent array. Omitted endpoints never swap with stride sign.
for n, expr in enumerate(['9:8','-8:-9','0:6:-1','6:0','3:2','2:3:-1']):
    add(f'empty_outside_{n}', base+f'\nprint *, 31,a({expr}),32\na({expr})=9\nprint *, a',
        tokens([31,32]+values))
add('empty_sections_conform', base+'\na(3:-3)=a(-3:3:-1)\nprint *, a', tokens(values))
add('empty_declared_positive', 'integer :: a(5:3),b(0),c(-2:-3)\nprint *, 1,a(:),2,b(:),3,c(:),4', '1 2 3 4')
add('empty_declared_explicit_reverse', 'integer :: a(5:3),b(0),c(-2:-3)\nprint *, 1,a(3:5:-1),2,b(0:1:-1),3,c(-3:-2:-1),4', '1 2 3 4')
add('empty_array_expression_skips_values', 'integer :: a(3),x\nprint *, 1,a(3:2)+x,2', '1 2', baseline='skip',
    note='No element evaluation for a zero-extent array expression is the deterministic interpreter safety policy.')
add('empty_array_expression_skips_bad_element', 'integer :: a(3)\nprint *, 1,a(3:2)+a(9),2', '1 2', baseline='skip')

def runtime(name, body, diagnostic, expected='', baseline='skip', **extra):
    add(name,body,expected,'runtime',baseline,diagnostic=diagnostic,**extra)

runtime('empty_declared_reverse_defaults', 'integer :: a(5:3)\nprint *, a(::-1)', 'bound', baseline='checked_runtime', baseline_diagnostic='outside of expected range')
runtime('zero_stride_dynamic', 'integer :: a(3),s\na=1\ns=0\nprint *, a(::s)', 'stride', baseline='checked_runtime', baseline_diagnostic='stride')
runtime('zero_stride_dynamic_empty', 'integer :: a(3),s\na=1\ns=0\na(3:2:s)=4', 'stride', baseline='checked_runtime', baseline_diagnostic='stride')
runtime('zero_stride_literal', 'integer :: a(3)\na=1\nprint *, a(::0)', 'stride', baseline='reject')
runtime('zero_stride_empty_array', 'integer :: a(0),s\ns=0\nprint *, a(::s)', 'stride', baseline='checked_runtime', baseline_diagnostic='stride')
for name, bounds in [('low','0:2'),('high','2:4'),('reverse_low','3:0:-1'),('reverse_high','4:2:-1')]:
    runtime('bounds_'+name, 'integer :: a(3)\na=1\nprint *, a('+bounds+')', 'bound', baseline='bounds_runtime')
runtime('bounds_dynamic', 'integer :: a(3),lo,hi,s\na=1\nlo=3\nhi=0\ns=-1\nprint *, a(lo:hi:s)', 'bound', baseline='bounds_runtime')
runtime('bounds_target', 'integer :: a(3),lo\na=1\nlo=0\na(lo:2)=2', 'bound', baseline='bounds_runtime')
runtime('huge_positive_section_extent', 'integer :: a(3)\na=1\nprint *, a(1:2147483647)', 'bound', baseline='bounds_runtime')
runtime('huge_negative_section_extent', 'integer :: a(3)\na=1\nprint *, a(3:(-2147483647-1):-1)', 'bound', baseline='bounds_runtime')
runtime('minimum_stride_outside_selected', 'integer :: a(3)\na=1\nprint *, a(3:(-2147483647-1):(-2147483647-1))', 'bound', baseline='bounds_runtime')
runtime('bounds_atomic_print', 'integer :: a(3)\na=1\nprint *, 71\nprint *, 72,a(0:2),73', 'bound', expected='71', baseline='bounds_runtime')
runtime('uninitialized_bound', 'integer :: a(3),lo\na=1\nprint *, a(lo:3)', 'uninitialized')
runtime('uninitialized_stride', 'integer :: a(3),s\na=1\nprint *, a(::s)', 'uninitialized')
runtime('uninitialized_selected', 'integer :: a(3)\na(1)=9\nprint *, a(1:3:2)', 'uninitialized')
runtime('partial_initialization_preserved', 'integer :: a(5)\na(1:5:2)=8\nprint *, a(2:4:2)', 'uninitialized')
runtime('uninitialized_empty_scalar_rhs', 'integer :: a(3),x\na(3:2)=x', 'uninitialized')
runtime('empty_section_evaluates_bound', 'integer :: a(3),hi\nprint *, a(4:hi)', 'uninitialized')
runtime('empty_operand_still_checks_shape', 'integer :: a(3),b(3),n\nn=1\nprint *, a(3:2)+b(:n)', 'conform', baseline='checked_runtime', baseline_diagnostic='mismatch')
runtime('empty_operand_still_checks_stride', 'integer :: a(3),b(3),s\ns=0\nprint *, a(3:2)+b(3:2:s)', 'stride')
runtime('empty_rhs_still_checks_conformity', 'integer :: a(3),b(0)\na(:)=b(:)', 'conform', baseline='reject')
runtime('dynamic_assignment_conformity', 'integer :: a(4),b(5),n\na=1\nb=2\nn=3\na(:n)=b(:)', 'conform', baseline='checked_runtime', baseline_diagnostic='mismatch')
runtime('dynamic_expression_conformity', 'integer :: a(4),b(5),n\na=1\nb=2\nn=3\nprint *, a(:n)+b(:)', 'conform', baseline='checked_runtime', baseline_diagnostic='mismatch')
runtime('dynamic_intrinsic_conformity', 'integer :: a(4),b(5),n\na=1\nb=2\nn=3\nprint *, max(a(:n),b(:))', 'conform', baseline='checked_runtime', baseline_diagnostic='mismatch')
runtime('constant_section_conformity', 'integer :: a(4),b(5)\na=1\nb=2\na(:)=b(:)', 'conform', baseline='reject')
runtime('section_division_by_zero', 'integer :: a(3),b(3)\na=2\nb=1\nb(2)=0\nprint *, 71\nprint *, a(:)/b(3:1:-1)', 'zero', expected='71')
runtime('section_overflow', 'integer :: a(3)\na=2147483647\na(1:3:2)=a(1:3:2)+1', 'overflow')
runtime('bound_expression_overflow', 'integer :: a(3),n\na=1\nn=2147483647\nprint *, a(:n+1)', 'overflow')
runtime('section_real_to_integer_overflow', 'integer :: a(3)\nreal :: b(3)\nb=1.0e20\na(3:1:-1)=b(:)', 'overflow')
runtime('section_budget', 'integer :: a(1000)\na=1\nprint *, 71\nprint *, a(1000:1:-1)', 'limit', expected='71', candidate_args=['--max-steps','1200'])
runtime('section_print_expansion_limit', 'integer :: a(65536)\nprint *, a(:),1', 'limit')

# Fail-closed parser/rank/type checks, with an early output sentinel that must
# never appear because static validation precedes all execution.
invalids = {
 'real_lower': ('integer :: a(3)', 'print *, a(1.0:3)'),
 'real_upper': ('integer :: a(3)', 'print *, a(1:3.0)'),
 'real_stride': ('integer :: a(3)', 'print *, a(::1.0)'),
 'logical_lower': ('integer :: a(3)', 'print *, a(.true.:3)'),
 'logical_stride': ('integer :: a(3)', 'print *, a(::.true.)'),
 'array_lower': ('integer :: a(3),b(2)', 'print *, a(b:3)'),
 'section_lower': ('integer :: a(3),b(2)', 'print *, a(b(:):3)'),
 'array_stride': ('integer :: a(3),b(2)', 'print *, a(::b)'),
 'scalar_section': ('integer :: a', 'print *, a(:)'),
 'scalar_assignment_section': ('integer :: a(3),b', 'b=a(:)'),
 'section_to_element': ('integer :: a(3)', 'a(1)=a(:)'),
 'section_if': ('logical :: a(3)', 'if (a(:)) then\nprint *, 1\nend if'),
 'section_do_bound': ('integer :: a(3),i', 'do i=1,a(:)\nprint *, i\nend do'),
 'section_element_index': ('integer :: a(3)', 'print *, a(a(:))'),
 'logical_numeric_assignment': ('integer :: a(3)', 'a(:)=.true.'),
 'numeric_logical_assignment': ('logical :: a(3)', 'a(:)=2'),
 'triplet_extra_colon': ('integer :: a(3)', 'print *, a(1:3:1:1)'),
 'omitted_stride_after_colon': ('integer :: a(3)', 'print *, a(1:3:)'),
 'omitted_stride_after_double_colon': ('integer :: a(3)', 'print *, a(::)'),
 'triplet_extra_comma': ('integer :: a(3)', 'print *, a(1:3,)'),
 'triplet_missing_close': ('integer :: a(3)', 'print *, a(1:3'),
 'triplet_operator_endpoint': ('integer :: a(3)', 'print *, a(1:+)'),
 'triplet_empty_parentheses': ('integer :: a(3)', 'print *, a()'),
 'triplet_in_intrinsic': ('integer :: a(3)', 'print *, abs(1:3)'),
 'rank_two_subscript': ('integer :: a(3)', 'print *, a(:,1)'),
 'unknown_section_name': ('integer :: a(3)', 'print *, unknown(:)'),
}
for name,(decl,stmt) in invalids.items():
    # GNU accepts a one-element section as a vector subscript. Keep vector
    # subscripts as supported-language unsupported boundaries, not invalid.
    if name == 'section_element_index':
        add(name,decl+'\nprint *, 7654\n'+stmt,category='unsupported',baseline='compile')
    else:
        add(name,decl+'\nprint *, 7654\n'+stmt,category='invalid')
add('vector_subscript_remains_unsupported', 'integer :: a(3),b(2)\nprint *, 7654\nprint *, a(b)', category='unsupported',baseline='compile')
add('constructor_subscript_remains_unsupported', 'integer :: a(3)\nprint *, 7654\nprint *, a([1,3])', category='unsupported',baseline='compile')
add('rank_two_section_now_checked', 'integer :: a(2,2)\nprint *, 7654\nprint *, a(:,1)', expected='7654', category='runtime',baseline='compile',diagnostic='uninitialized')

# Randomized model-derived fixtures include dynamic endpoints, nonunit/negative
# declared bounds, strided overlap, scalar snapshots, and changes of stride.
rng = random.Random(SEED)
for num in range(50):
    lower=rng.randint(-5,3); n=rng.randint(2,12); upper=lower+n-1
    vals=[rng.randint(-20,20) for _ in range(n)]
    starts=[rng.randint(lower,upper) for _ in range(2)]
    steps=[rng.choice([-3,-2,-1,1,2,3]) for _ in range(2)]
    possible=[len(selected(lower,upper,starts[k],upper if steps[k]>0 else lower,steps[k])) for k in range(2)]
    length=rng.randint(0,min(possible))
    ends=[starts[k]+(length-1)*steps[k] for k in range(2)]
    inds=[selected(lower,upper,starts[k],ends[k],steps[k]) for k in range(2)]
    factor=rng.choice([-2,-1,1,2]); offset=vals[rng.randrange(n)]
    source='integer :: lo,hi,s,rlo,rhi,rs\n'+setup(vals,lower)
    source+=f'\nlo={starts[0]}\nhi={ends[0]}\ns={steps[0]}\nrlo={starts[1]}\nrhi={ends[1]}\nrs={steps[1]}'
    source+=f'\na(lo:hi:s)=a(rlo:rhi:rs)*({factor})+({offset})\nprint *, a,a({upper}:{lower}:-1)'
    out=vals.copy()
    for lhs,rhs in zip(*inds): out[lhs-lower]=vals[rhs-lower]*factor+offset
    add(f'model_overlap_{num:02d}', source, tokens(out+out[::-1]), note=f'Independent Python model, seed {SEED}, case {num}.')


# Version 0.53: original numeric vector source bytes stay unchanged.
NUMERIC_VECTOR_MIGRATIONS = {'section_element_index': {'category': 'runtime', 'baseline': 'compile', 'expected_stdout': '7654', 'diagnostic': 'read of uninitialized array element a', 'note': 'Original source retained. Numeric rank-one vector gathering supported in 0.53; the INTEGER section selector is undefined. GNU compile-only.'}, 'vector_subscript_remains_unsupported': {'category': 'runtime', 'baseline': 'compile', 'expected_stdout': '7654', 'diagnostic': 'read of uninitialized array element b', 'note': 'Original source and legacy name retained. Numeric rank-one vector gathering supported in 0.53; selector b is undefined. GNU compile-only.'}, 'constructor_subscript_remains_unsupported': {'category': 'runtime', 'baseline': 'compile', 'expected_stdout': '7654', 'diagnostic': 'read of uninitialized gathered array element', 'note': 'Original source and legacy name retained. Numeric rank-one vector gathering supported in 0.53; gathered base elements are undefined. GNU compile-only.'}}
for row in CASES:
    if row['name'] in NUMERIC_VECTOR_MIGRATIONS:
        row.update(NUMERIC_VECTOR_MIGRATIONS[row['name']])

(ROOT/'manifest.json').write_text(json.dumps(dict(schema_version=1,seed=SEED,cases=CASES),indent=2)+'\n')
print(f'Generated {len(CASES)} section fixtures.')
