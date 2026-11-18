#!/usr/bin/env python3
"""Reproducible independent array-intrinsic contract fixtures.

Expected values are calculated without importing interpreter code. Numeric
success cases are also compiled/executed by GNU Fortran as a second oracle.
"""
from pathlib import Path
from textwrap import dedent
from functools import reduce
from operator import mul
import json
import random

ROOT = Path(__file__).resolve().parent
CASES = []
HUGE = {'integer': 2147483647, 'real': 3.4028234663852886e38,
        'real(8)': 1.7976931348623157e308}


def add(name, source, expected='', category='success', baseline=None, diagnostic=None, **kw):
    if baseline is None:
        baseline = ('run' if category == 'success' else
                    'compile' if category in ('runtime', 'unsupported') else 'reject')
    (ROOT / 'cases').mkdir(exist_ok=True)
    (ROOT / 'cases' / f'{name}.f90').write_text(dedent(source).strip() + '\n')
    if not isinstance(expected, str):
        expected = ' '.join(str(x) for x in expected)
    case = dict(name=name, source=f'cases/{name}.f90', category=category,
                baseline=baseline, expected_stdout=expected, **kw)
    if diagnostic:
        case['diagnostic'] = diagnostic
    CASES.append(case)


def prog(decl, body, contained=''):
    return ('program array_intrinsic_oracle\nimplicit none\n' + decl + '\n' + body + '\n' +
            ('contains\n' + contained + '\n' if contained else '') + 'end program\n')


def evaluate(op, values, kind='integer'):
    if op == 'sum':
        return sum(values)
    if op == 'product':
        return reduce(mul, values, 1)
    if op == 'minval':
        return min(values, default=HUGE[kind])
    if op == 'maxval':
        return max(values, default=-2147483648 if kind == 'integer' else -HUGE[kind])
    raise ValueError(op)


OPS = ('sum', 'product', 'minval', 'maxval')

# The first dimension varies fastest. Non-unit lower bounds are deliberate.
for kind, tag, scale in [('integer', 'integer', 1), ('real', 'real32', 0.5),
                         ('real(8)', 'real64', 0.5)]:
    values = {(i, j): scale * (2*i-j) for j in range(4, 7) for i in range(-1, 2)}
    init = '\n'.join(f'aa({i},{j})={v}' + ('d0' if kind == 'real(8)' else '')
                     for (i, j), v in values.items())
    mask = {key: (key[0]+key[1]) % 2 == 0 for key in values}
    init += '\n' + '\n'.join(f'mm({i},{j})={('.true.' if v else '.false.')}'
                              for (i, j), v in mask.items())
    for op in OPS:
        for mask_name, suffix, choose in [
            ('none', '', lambda key: True),
            ('array', ',mm', lambda key: mask[key]),
            ('true', ',.true.', lambda key: True),
            ('false', ',.false.', lambda key: False)]:
            expected = [evaluate(op, [v for key, v in values.items() if choose(key)], kind)]
            body = init + f'\nprint *,{op}(aa{suffix})\n'
            for dim in (1, 2):
                body += f'print *,{op}(aa,{dim}{suffix})\n'
                outer = range(4, 7) if dim == 1 else range(-1, 2)
                for index in outer:
                    expected.append(evaluate(op, [v for key, v in values.items()
                                                   if key[1 if dim == 1 else 0] == index
                                                   and choose(key)], kind))
            add(f'{op}_{tag}_ranktwo_mask_{mask_name}',
                prog(f'{kind} :: aa(-1:1,4:6)\nlogical :: mm(-1:1,4:6)', body), expected,
                rel_tol=2e-6 if kind == 'real' else 1e-13, abs_tol=1e-15)
        # Rank-one DIM=1 returns a scalar; reversed sections retain value order.
        arr = [scale*v for v in (3, -2, 4, 0, 1)]
        init1 = '\n'.join(f'aa({i-2})={v}' + ('d0' if kind == 'real(8)' else '')
                          for i, v in enumerate(arr))
        for suffix in ('', ',1'):
            name = 'plain' if not suffix else 'keyword_dim' if 'dim' in suffix else 'positional_dim'
            add(f'{op}_{tag}_rankone_{name}', prog(f'{kind} :: aa(-2:2)',
                init1+f'\nprint *,{op}(aa{suffix}),{op}(aa(2:-2:-2){suffix})'),
                [evaluate(op, arr, kind), evaluate(op, arr[::-2], kind)])

# Optional argument association, including the no-DIM positional MASK overload.
for op in OPS:
    for label, expr, vals in [
        ('positional_mask', f'{op}(aa,mm)', [2, 4]),
        ('positional_dim_mask', f'{op}(aa,1,mm)', [2, 4]),
        ('keyword_permuted', f'{op}(mask=mm,dim=1,array=aa)', [2, 4]),
        ('keyword_array', f'{op}(array=aa)', [1, 2, 3, 4])]:
        add(f'{op}_{label}', prog('integer :: aa(4)\nlogical :: mm(4)',
            'aa(1)=1\naa(2)=2\naa(3)=3\naa(4)=4\nmm=.false.\nmm(2)=.true.\nmm(4)=.true.\n'+
            f'print *,{expr}'), [evaluate(op, vals)])

# Empty reduction axes and empty retained axes must not be confused.
for kind, tag in [('integer', 'integer'), ('real', 'real32'), ('real(8)', 'real64')]:
    for op in OPS:
        identity = evaluate(op, [], kind)
        add(f'{op}_{tag}_zero_extents', prog(f'{kind} :: aa(0,3),bb(2,0),cc(0)',
            f'print *,{op}(aa),{op}(bb),{op}(cc),{op}(cc,1)\n'
            f'print *,{op}(aa,1),{op}(bb,2)\n'
            f'print *,size({op}(aa,2)),size({op}(bb,1))'),
            [identity]*9+[0, 0], rel_tol=2e-6 if kind == 'real' else 1e-13)

# Deterministic section/mask matrix, independently enumerated in Python.
rng = random.Random(111001)
for case in range(24):
    xs = rng.choice([[-2,-1,0,1,2], [2,0,-2], [-1,1], [1], []])
    ys = rng.choice([[4,5,6,7], [7,5], [4,6], [6], []])
    def triplet(seq):
        return ('1:0' if not seq else f'{seq[0]}:{seq[-1]}:{seq[1]-seq[0] if len(seq)>1 else 1}')
    sx, sy = triplet(xs), triplet(ys)
    values = {(i,j): rng.randint(-2,2) for j in range(4,8) for i in range(-2,3)}
    masks = {key:rng.choice([True,False]) for key in values}
    body = '\n'.join(f'aa({i},{j})={v}\nmm({i},{j})={".true." if masks[i,j] else ".false."}'
                     for (i,j),v in values.items()) + '\n'
    expected=[]
    for op in OPS:
        body += f'print *,{op}(aa({sx},{sy}),mm({sx},{sy}))\n'
        expected.append(evaluate(op,[values[i,j] for j in ys for i in xs if masks[i,j]]))
        for dim, outer in [(1, ys), (2, xs)]:
            body += f'print *,{op}(aa({sx},{sy}),{dim},mm({sx},{sy}))\n'
            for q in outer:
                keys = [(i,q) for i in xs] if dim == 1 else [(q,j) for j in ys]
                expected.append(evaluate(op,[values[key] for key in keys if masks[key]]))
    add(f'random_section_mask_{case:02}', prog('integer :: aa(-2:2,4:7)\nlogical :: mm(-2:2,4:7)',body),expected)

add('reduction_expression_and_nested',prog('integer :: aa(2,3),bb(3)', '''aa(:,1)=1
aa(:,2)=2
aa(:,3)=3
bb=sum(aa,1)+maxval(aa,1)
print *,bb,sum(sum(aa,1)),product(maxval(aa,2))
print *,sum(aa+1,aa>1),maxval(aa*2,2)'''),[3,6,9,12,9,14,6,6])
add('reduction_mask_independent_lower_bounds',prog('integer :: aa(-1:1,4:5)\nlogical :: mm(6:8,-3:-2)',
    'aa(:,4)=2\naa(:,5)=3\nmm=.false.\nmm(6,-3)=.true.\nmm(8,-2)=.true.\n'
    'print *,sum(aa,mm),sum(aa,1,mm),sum(aa,2,mm)'),[5,2,3,2,0,3])
add('reduction_dummies_and_expression_actuals',prog('integer :: aa(-1:1,4:5)',
    'aa(:,4)=2\naa(:,5)=3\nprint *,work(aa),work(aa(1:-1:-1,5:4:-1)+1)', '''integer function work(xx) result(answer)
integer,intent(in) :: xx(-4:,7:)
answer=sum(xx)+sum(maxval(xx,1))+sum(minval(xx,2))
end function'''),[26,37])

for op in OPS:
    add(f'{op}_runtime_dim',prog('integer :: aa(2,3),dd\nlogical :: mm(2,3)',f'''aa(:,1)=1
aa(:,2)=2
aa(:,3)=3
mm=.true.
mm(:,2)=.false.
dd=1
print *,{op}(aa,dd),{op}(aa,dd,mm),size({op}(aa,dd))
dd=2
print *,{op}(aa,dd),{op}(aa,dd,mm),size({op}(aa,dd))'''),
        [evaluate(op,[1,1]),evaluate(op,[2,2]),evaluate(op,[3,3])]+
        [evaluate(op,[1,1]),evaluate(op,[]),evaluate(op,[3,3]),3]+
        [evaluate(op,[1,2,3])]*2+[evaluate(op,[1,3])]*2+[2])

add('real32_rounds_each_accumulation',prog('real :: aa(3),bb(3)\nreal(8) :: cc(3)', '''aa(1)=16777216.0
aa(2)=1.0
aa(3)=-16777216.0
bb=1.0
cc(1)=16777216.0d0
cc(2)=1.0d0
cc(3)=-16777216.0d0
print *,sum(aa),dot_product(aa,bb),sum(cc)'''),[0,0,1])

# True smallest representable INTEGER must survive MINVAL/MAXVAL initialization.
add('integer_minimum_values',prog('integer :: aa(2)', '''aa(1)=-2147483647-1
aa(2)=-2147483647-1
print *,minval(aa),maxval(aa),minval(aa(1:1)),maxval(aa(1:1))'''),[-2147483648]*4)

# Dot products: numeric, logical, mixed arithmetic types, sections and identities.
for kind,tag,scale in [('integer','integer',1),('real','real32',0.5),('real(8)','real64',0.5)]:
    a=[scale*x for x in (1,-2,3,4)];b=[scale*x for x in (2,3,-1,2)]
    body='\n'.join(f'aa({i-1})={x}'+('d0' if kind=='real(8)' else '')+f'\nbb({i+4})={y}'+
        ('d0' if kind=='real(8)' else '') for i,(x,y) in enumerate(zip(a,b)))
    body+='\nprint *,dot_product(aa,bb),dot_product(aa(2:-1:-2),bb(4:7:2))\nprint *,dot_product(cc,cc)'
    add(f'dot_product_{tag}',prog(f'{kind} :: aa(-1:2),bb(4:7),cc(0)',body),
        [sum(x*y for x,y in zip(a,b)),sum(x*y for x,y in zip(a[::-2],b[::2])),0])
add('dot_product_logical',prog('logical :: aa(3),bb(3),cc(0)',
    'aa=.false.\nbb=.true.\naa(2)=.true.\nprint *,dot_product(aa,bb)\nbb(2)=.false.\n'
    'print *,dot_product(aa,bb),dot_product(cc,cc)'),['T','F','F'])
add('dot_product_mixed_types',prog('integer :: aa(3)\nreal(8)::bb(3)',
    'aa=2\nbb=0.25d0\nprint *,dot_product(aa,bb),dot_product(bb,aa)'),[1.5,1.5])

def matmul_values(a,b,m,k,n):
    return [sum(a[i,q]*b[q,j] for q in range(k)) for j in range(n) for i in range(m)]

for index,(m,k,n) in enumerate([(2,3,4),(3,2,1),(1,4,3),(0,3,2),(3,0,2),(2,3,0)]):
    a={(i,q):i-q+2 for q in range(k) for i in range(m)}
    b={(q,j):q+j-1 for j in range(n) for q in range(k)}
    body='\n'.join(f'aa({i+1},{q+1})={v}' for (i,q),v in a.items())+'\n'
    body+='\n'.join(f'bb({q+1},{j+1})={v}' for (q,j),v in b.items())+'\n'
    body+='cc=matmul(aa,bb)\nprint *,cc,size(cc,1),size(cc,2)\n'
    body+='print *,sum(matmul(aa,bb)),sum(matmul(aa,bb),1)'
    vals=matmul_values(a,b,m,k,n)
    add(f'matmul_integer_matrix_{index}',prog(f'integer :: aa({m},{k}),bb({k},{n}),cc({m},{n})',body),
        vals+[m,n,sum(vals)]+[sum(vals[j*m:(j+1)*m]) for j in range(n)])
add('matmul_vector_forms',prog('integer :: aa(2,3),xx(3),yy(2)', '''aa(:,1)=1
aa(:,2)=2
aa(:,3)=3
xx(1)=2
xx(2)=3
xx(3)=4
yy(1)=5
yy(2)=6
print *,matmul(aa,xx),matmul(yy,aa)
print *,matmul(aa(2:1:-1,3:1:-1),xx(3:1:-1))'''),[20,20,11,22,33,20,20])
add('matmul_logical',prog('logical :: aa(2,3),bb(3,2)', '''aa=.false.
bb=.false.
aa(1,1)=.true.
aa(2,3)=.true.
bb(1,2)=.true.
bb(3,1)=.true.
print *,matmul(aa,bb),matmul(aa,bb(:,1)),matmul(aa(1,:),bb)'''),['F','T','T','F','F','T','F','T'])
add('matmul_real64_mixed',prog('real(8) :: aa(2,2)\nreal :: bb(2,2)',
    'aa=0.1d0\nbb=0.5\nprint *,matmul(aa,bb),matmul(bb,aa)'),[0.1]*8,rel_tol=1e-13,abs_tol=1e-15)

for index in range(24):
    m,k,n=[rng.randint(1,4) for _ in range(3)]
    a={(i,q):rng.randint(-5,5) for q in range(k) for i in range(m)}
    b={(q,j):rng.randint(-5,5) for j in range(n) for q in range(k)}
    body='\n'.join(f'aa({i-2},{q+4})={v}' for (i,q),v in a.items())+'\n'
    body+='\n'.join(f'bb({q+7},{j-1})={v}' for (q,j),v in b.items())+'\n'
    body+='print *,matmul(aa,bb)\n'
    body+=f'print *,matmul(aa({m-3}:-2:-1,{k+3}:4:-1),bb({k+6}:7:-1,{n-2}:-1:-1))\n'
    body+='print *,dot_product(aa(-2,:),bb(:,-1))\n'
    vals=matmul_values(a,b,m,k,n)
    reverse_vals=[vals[i+j*m] for j in range(n-1,-1,-1) for i in range(m-1,-1,-1)]
    add(f'random_matmul_sections_{index:02}',
        prog(f'integer :: aa(-2:{m-3},4:{k+3}),bb(7:{k+6},-1:{n-2})',body),
        vals+reverse_vals+[sum(a[0,q]*b[q,0] for q in range(k))])

add('logical_zero_inner_matmul',prog('logical :: aa(2,0),bb(0,3),cc(0)',
    'print *,matmul(aa,bb),matmul(aa,cc),matmul(cc,bb)'),['F']*11)
add('intrinsic_inquiries_skip_uninitialized_data',prog('integer :: aa(2,3),bb(3,4)',
    'print *,size(sum(aa,1)),size(sum(aa,2)),lbound(sum(aa,1),1),ubound(sum(aa,2),1)\n'
    'print *,size(matmul(aa,bb)),size(matmul(aa,bb),1),size(matmul(aa,bb),2)'),
    [3,2,1,2,8,2,4],baseline='compile')
add('nested_intrinsic_conformance',prog('integer :: aa(2,3),bb(3,2),cc(2,2)',
    'aa=2\nbb=3\ncc=matmul(aa,bb)\nprint *,sum(cc),sum(matmul(aa,bb),2)\n'
    'print *,matmul(aa,bb)+cc,product(sum(matmul(aa,bb),1))'),[72,36,36]+[36]*4+[1296])
add('reduction_scalar_broadcast_nested',prog('integer :: aa(2,3),bb(2,3)',
    'aa(:,1)=1\naa(:,2)=2\naa(:,3)=3\nbb=aa+sum(aa)+maxval(aa)\nprint *,bb\n'
    'print *,sum(aa+sum(aa),1),product(aa+minval(aa),2)'),[16,16,17,17,18,18,26,28,30,24,24])
add('runtime_dim_loop_refresh',prog('integer :: aa(2,3),dd',
    'aa(:,1)=1\naa(:,2)=2\naa(:,3)=3\ndo dd=1,2\nprint *,sum(aa,dd),size(sum(aa,dd))\nend do'),
    [2,4,6,3,6,6,2])

# Runtime checks, with a successful earlier record and an atomic failing PRINT.
RUNTIME=[
('reduction_uninitialized','integer :: aa(2)','print *,sum(aa)','uninitialized'),
('reduction_mask_uninitialized','integer :: aa(2)\nlogical :: mm(2)','aa=1\nprint *,sum(aa,mm)','uninitialized'),
('reduction_selected_uninitialized','integer :: aa(2)\nlogical :: mm(2)',
 'aa(1)=3\nmm=.true.\nprint *,sum(aa,mm)','uninitialized'),
('sum_integer_overflow','integer :: aa(2)','aa=2147483647\nprint *,sum(aa)','overflow'),
('product_integer_overflow','integer :: aa(2)','aa=50000\nprint *,product(aa)','overflow'),
('sum_real_overflow','real :: aa(2)','aa=3.0e38\nprint *,sum(aa)','finite'),
('product_real_overflow','real :: aa(2)','aa=1.0e30\nprint *,product(aa)','finite'),
('dot_product_uninitialized','integer :: aa(2),bb(2)','aa=2\nprint *,dot_product(aa,bb)','uninitialized'),
('dot_product_overflow','integer :: aa(2),bb(2)','aa=50000\nbb=50000\nprint *,dot_product(aa,bb)','overflow'),
('matmul_uninitialized','integer :: aa(2,2),bb(2,2)','aa=1\nprint *,matmul(aa,bb)','uninitialized'),
('matmul_overflow','integer :: aa(2,2),bb(2,2)','aa=50000\nbb=50000\nprint *,matmul(aa,bb)','overflow'),
('reduction_bad_section_stride','integer :: aa(3),ss','aa=1\nss=0\nprint *,sum(aa(::ss))','stride'),
('reduction_bad_mask_stride','integer :: aa(3),ss\nlogical :: mm(3)',
 'aa=1\nmm=.true.\nss=0\nprint *,sum(aa,mm(::ss))','stride'),
('reduction_section_bounds','integer :: aa(3),nn','aa=1\nnn=4\nprint *,sum(aa(1:nn))','bounds'),
('reduction_mask_shape_dynamic','integer :: aa(2,3),nn\nlogical :: mm(2,3)',
 'aa=1\nmm=.true.\nnn=2\nprint *,sum(aa,mm(:,1:nn))','shape'),
('dot_product_shape_dynamic','integer :: aa(4),bb(4),nn','aa=1\nbb=2\nnn=3\nprint *,dot_product(aa,bb(1:nn))','conform'),
('matmul_shape_dynamic','integer :: aa(2,3),bb(3,2),nn','aa=1\nbb=2\nnn=2\nprint *,matmul(aa,bb(1:nn,:))','conform'),
]
for name,decl,body,diagnostic in RUNTIME:
    add(name,prog(decl,'print *,111\n'+body),[111],category='runtime',diagnostic=diagnostic)

for dim in (-1,0,3):
    add(f'reduction_dim_runtime_{str(dim).replace("-","negative_")}',
        prog('integer :: aa(2,3),dd',f'aa=1\ndd={dim}\nprint *,111\nprint *,222,sum(aa,dd)'),
        [111],category='runtime',diagnostic='DIM')
add('reduction_atomic_print',prog('integer :: aa(2)',
    'aa(1)=3\nprint *,111\nprint *,222,sum(aa)'),[111],category='runtime',diagnostic='uninitialized')
add('reduction_dim_uninitialized',prog('integer :: aa(2,3),dd',
    'aa=1\nprint *,111\nprint *,sum(aa,dd)'),[111],category='runtime',diagnostic='uninitialized')
add('reduction_bounds_even_false_mask',prog('integer :: aa(3),nn',
    'nn=4\nprint *,111\nprint *,sum(aa(1:nn),.false.)'),[111],category='runtime',diagnostic='bounds')
add('reduction_empty_mask_shape_mismatch',prog('integer :: aa(0,3),nn\nlogical :: mm(0,4)',
    'nn=4\nprint *,111\nprint *,sum(aa,mm(:,1:nn))'),[111],category='runtime',diagnostic='shape')
add('matmul_empty_inner_shape_mismatch',prog('integer :: aa(2,0),bb(1,3),nn',
    'nn=1\nprint *,111\nprint *,matmul(aa,bb(1:nn,:))'),[111],category='runtime',diagnostic='conform')
add('reduction_execution_budget',prog('integer :: aa(1000)',
    'aa=1\nprint *,111\nprint *,sum(aa)'),[111],category='runtime',
    baseline='compile',diagnostic='limit',args=['--max-steps','2000'])
add('reduction_result_size_limit',prog('integer :: aa(65537,0)',
    'print *,111\nprint *,sum(aa,2)'),[111],category='runtime',baseline='compile',diagnostic='limit')
add('matmul_result_size_limit',prog('integer :: aa(65537,0),bb(0,1)',
    'print *,111\nprint *,matmul(aa,bb)'),[111],category='runtime',baseline='compile',diagnostic='limit')

# Masked-out source cells are not read, even if their data expression is invalid.
for op in OPS:
    add(f'{op}_unselected_uninitialized',prog('integer :: aa(3)\nlogical :: mm(3)',
        f'aa(2)=7\nmm=.false.\nmm(2)=.true.\nprint *,{op}(aa,mm)'),[7],baseline='compile')
    add(f'{op}_false_mask_skips_uninitialized',prog('integer :: aa(3)',
        f'print *,{op}(aa,.false.)'),[evaluate(op,[])],baseline='compile')
    add(f'{op}_false_mask_skips_bad_data_expression',prog('integer :: aa(3),zz',
        f'aa=1\nzz=0\nprint *,{op}(aa/zz,.false.)'),[evaluate(op,[])],baseline='compile')

INVALID=[
('reduction_scalar','integer :: aa','aa=1\nprint *,sum(aa)'),
('sum_logical','logical :: aa(2)','aa=.true.\nprint *,sum(aa)'),
('minval_logical','logical :: aa(2)','aa=.true.\nprint *,minval(aa)'),
('reduction_mask_nonlogical','integer :: aa(2),mm(2)','aa=1\nmm=1\nprint *,sum(aa,mm)'),
('reduction_dim_real','integer :: aa(2)','aa=1\nprint *,sum(aa,1.0)'),
('reduction_dim_array','integer :: aa(2),dd(1)','aa=1\ndd=1\nprint *,sum(aa,dd)'),
('reduction_dim_zero','integer :: aa(2)','aa=1\nprint *,sum(aa,0)'),
('reduction_dim_high','integer :: aa(2,3)','aa=1\nprint *,sum(aa,3)'),
('reduction_duplicate_dim','integer :: aa(2)','aa=1\nprint *,sum(aa,1,dim=1)'),
('reduction_unknown_keyword','integer :: aa(2)','aa=1\nprint *,sum(aa,axis=1)'),
('reduction_missing_array','integer :: aa(2)','aa=1\nprint *,sum(dim=1)'),
('reduction_mask_shape_static','integer :: aa(2,3)\nlogical :: mm(3,2)',
 'aa=1\nmm=.true.\nprint *,sum(aa,mm)'),
('dot_product_scalar','integer :: aa(2),bb','aa=1\nbb=2\nprint *,dot_product(aa,bb)'),
('dot_product_ranktwo','integer :: aa(2,2)','aa=1\nprint *,dot_product(aa,aa)'),
('dot_product_mixed_logical','integer :: aa(2)\nlogical :: bb(2)','aa=1\nbb=.true.\nprint *,dot_product(aa,bb)'),
('matmul_vector_vector','integer :: aa(2)','aa=1\nprint *,matmul(aa,aa)'),
('matmul_scalar','integer :: aa(2,2),bb','aa=1\nbb=2\nprint *,matmul(aa,bb)'),
('matmul_mixed_logical','integer :: aa(2,2)\nlogical :: bb(2,2)','aa=1\nbb=.true.\nprint *,matmul(aa,bb)'),
]
for name,decl,body in INVALID:
    add(name,prog(decl,'print *,111\n'+body),[111] if name in ('reduction_dim_zero','reduction_dim_high') else '',
        category='runtime' if name in ('reduction_dim_zero','reduction_dim_high') else 'invalid',baseline='reject')

(ROOT / 'manifest.json').write_text(json.dumps(dict(cases=CASES),indent=2)+'\n')
print(f'Generated {len(CASES)} independent array-intrinsic cases')
