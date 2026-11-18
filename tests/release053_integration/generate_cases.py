#!/usr/bin/env python3
"""Reproduce pinned sources and contracts without reinterpreting literals."""
from pathlib import Path
import json
SOURCES = {'bad_index_pending_output.f90': 'program p\n'
                                 'implicit none\n'
                                 'integer::a(3)\n'
                                 'a=[1,2,3]\n'
                                 "write(*,'(a)',advance='no')'kept:'\n"
                                 "write(*,'(2i3)')a([1,4])\n"
                                 'end program\n',
 'bare_alias_before_entry.f90': 'module m\n'
                                'implicit none\n'
                                'contains\n'
                                'subroutine replace(a,b)\n'
                                'integer,intent(in)::a(:)\n'
                                'integer,allocatable,intent(out)::b(:)\n'
                                "write(*,'(a)')'entered'\n"
                                'allocate(b(size(a)))\n'
                                'b=a\n'
                                'end subroutine\n'
                                'end module\n'
                                'program p\n'
                                'use m\n'
                                'implicit none\n'
                                'integer,allocatable::x(:)\n'
                                'x=[2,4,6]\n'
                                "write(*,'(a)')'before'\n"
                                'call replace(x([3,1]),x)\n'
                                'end program\n',
 'do_while_integer4_cache.f90': 'program p\n'
                                'implicit none\n'
                                'integer :: a(3),b(2),i\n'
                                'a=[1,2,3]\n'
                                'i=1\n'
                                'do while(i<=3)\n'
                                ' b=a([3,1])\n'
                                " write(*,'(2i4)')b\n"
                                ' a=a+10\n'
                                ' i=i+1\n'
                                'end do\n'
                                'end program\n',
 'duplicate_all_elemental.f90': 'module m\n'
                                'implicit none\n'
                                'contains\n'
                                'pure elemental integer function twice(i) result(answer)\n'
                                'integer,intent(in)::i\n'
                                'answer=2*i\n'
                                'end function\n'
                                'end module\n'
                                'program p\n'
                                'use m\n'
                                'implicit none\n'
                                'integer::x(3),y(3)\n'
                                'x=[1,2,3]\n'
                                'y=twice(x([3,1,3]))\n'
                                "if(.not.all(y==[6,2,6]))error stop 'values'\n"
                                "write(*,'(3i3)')y\n"
                                'end program\n',
 'empty_values_and_kind.f90': 'program p\n'
                              'implicit none\n'
                              'integer(8)::x(3),ix(2),y(0)\n'
                              'y=x([integer::])\n'
                              "write(*,'(3i3)')size(y),kind(x(ix)),count(y==0_8)\n"
                              'end program\n',
 'explicit_shape_bare_boundary.f90': 'module m\n'
                                     'implicit none\n'
                                     'contains\n'
                                     'subroutine consume(a)\n'
                                     'integer,intent(in)::a(2)\n'
                                     "write(*,'(2i3)')a\n"
                                     'end subroutine\n'
                                     'end module\n'
                                     'program p\n'
                                     'use m\n'
                                     'implicit none\n'
                                     'integer::x(3)\n'
                                     'x=[1,2,3]\n'
                                     'call consume(x([3,1]))\n'
                                     'end program\n',
 'integer8_mask_indices.f90': 'program p\n'
                              'implicit none\n'
                              'integer(8) :: a(-1:2),b(3),ix(3)\n'
                              'a=[10_8,20_8,30_8,40_8]\n'
                              'ix=[int(iand(maskr(2,kind=8),1_8),8),-1_8,shiftr(maskr(2,kind=8),1)]\n'
                              'b=a(ix)\n'
                              "write(*,'(3i4)')b\n"
                              'end program\n',
 'module_host_alias_boundary.f90': 'module m\n'
                                   'implicit none\n'
                                   'integer::x(3)\n'
                                   'contains\n'
                                   'subroutine consume(a)\n'
                                   'integer,intent(in)::a(:)\n'
                                   "write(*,'(i3)')sum(a)+x(1)\n"
                                   'end subroutine\n'
                                   'end module\n'
                                   'program p\n'
                                   'use m\n'
                                   'implicit none\n'
                                   'x=[1,2,3]\n'
                                   'call consume(x([3,1]))\n'
                                   'end program\n',
 'numeric_character_staging.f90': 'program p\n'
                                  'implicit none\n'
                                  'integer::x(3),v(3),i\n'
                                  'character(4)::labels(3),chosen(2)\n'
                                  'x=[10,20,30]\n'
                                  'v=x([3,1,2])\n'
                                  'do i=1,3\n'
                                  " write(labels(i),'(i4)')v(i)\n"
                                  'end do\n'
                                  'chosen=labels([3,1])\n'
                                  "write(*,'(a,a,a,a,a)')'[',chosen(1),'][',chosen(2),']'\n"
                                  'end program\n',
 'ordinary_function_effect_boundary.f90': 'module m\n'
                                          'implicit none\n'
                                          'contains\n'
                                          'function indices() result(answer)\n'
                                          'integer::answer(2)\n'
                                          "write(*,'(a)')'effect'\n"
                                          'answer=[3,1]\n'
                                          'end function\n'
                                          'end module\n'
                                          'program p\n'
                                          'use m\n'
                                          'implicit none\n'
                                          'integer::a(3),b(2)\n'
                                          'a=[1,2,3]\n'
                                          'b=a(indices())\n'
                                          "write(*,'(2i3)')b\n"
                                          'end program\n',
 'output_implied_do_refresh.f90': 'program p\n'
                                  'implicit none\n'
                                  'integer::a(3),i\n'
                                  'a=[1,2,3]\n'
                                  "write(*,'(3i3)')(sum(a([i,1])),i=1,3)\n"
                                  'end program\n',
 'parenthesized_alias_reallocation.f90': 'module m\n'
                                         'implicit none\n'
                                         'contains\n'
                                         'subroutine replace(a,b)\n'
                                         'integer,intent(in)::a(:)\n'
                                         'integer,allocatable,intent(out)::b(:)\n'
                                         'allocate(b(size(a)))\n'
                                         'b=a\n'
                                         'end subroutine\n'
                                         'end module\n'
                                         'program p\n'
                                         'use m\n'
                                         'implicit none\n'
                                         'integer,allocatable::x(:)\n'
                                         'x=[2,4,6]\n'
                                         'call replace((x([3,1,3])),x)\n'
                                         "write(*,'(3i3)')x\n"
                                         'end program\n',
 'parenthesized_elemental_values.f90': 'module m\n'
                                       'implicit none\n'
                                       'contains\n'
                                       'pure elemental integer function twice(i) result(answer)\n'
                                       'integer,intent(in)::i\n'
                                       'answer=2*i\n'
                                       'end function\n'
                                       'end module\n'
                                       'program p\n'
                                       'use m\n'
                                       'implicit none\n'
                                       'integer::x(3),y(3)\n'
                                       'x=[1,2,3]\n'
                                       'y=twice((x([3,1,3])))\n'
                                       "if(.not.all(y==[6,2,6]))error stop 'values'\n"
                                       "write(*,'(3i3)')y\n"
                                       'end program\n',
 'portable_trailz_empty_kind.f90': 'program p\n'
                                   'use iso_fortran_env,only:int32,int64\n'
                                   'implicit none\n'
                                   'integer(int64)::x(3),bits(0)\n'
                                   'integer(int64),allocatable::y(:)\n'
                                   'y=x(trailz(bits)+1)\n'
                                   'if(size(y)/=0)error stop "empty"\n'
                                   'if(kind(trailz(0_int64))/=kind(0))error stop "default result kind"\n'
                                   'if(kind(y)/=int64)error stop "gather kind"\n'
                                   "write(*,'(3i3)')size(y),trailz(0_int32),trailz(0_int64)\n"
                                   'end program\n',
 'portable_trailz_function_actual.f90': 'module m\n'
                                        'use iso_fortran_env,only:int64\n'
                                        'implicit none\n'
                                        'contains\n'
                                        'function head(a) result(answer)\n'
                                        'integer(int64),intent(in)::a(:)\n'
                                        'integer(int64)::answer\n'
                                        'answer=a(1)\n'
                                        'end function\n'
                                        'end module\n'
                                        'program p\n'
                                        'use m\n'
                                        'implicit none\n'
                                        'integer(int64)::x(4),bits(3)\n'
                                        'x=[10_int64,20_int64,30_int64,40_int64]\n'
                                        'bits=[8_int64,1_int64,2_int64]\n'
                                        "write(*,'(2i4)')head(x(trailz(bits)+1)),head(a=(x(trailz([2_int64,1_int64])+1)))\n"
                                        'end program\n',
 'portable_trailz_numeric_indices.f90': 'program p\n'
                                        'use iso_fortran_env,only:int32,int64\n'
                                        'implicit none\n'
                                        'integer(int32)::a(3),bits4(3),i4(3)\n'
                                        'integer(int64)::b(3),bits8(3)\n'
                                        'a=[10_int32,20_int32,30_int32]\n'
                                        'b=[100_int64,200_int64,300_int64]\n'
                                        'bits4=[4_int32,1_int32,2_int32]\n'
                                        'bits8=[4_int64,1_int64,2_int64]\n'
                                        'i4=trailz(bits4)+1\n'
                                        "write(*,'(3i4)')a(i4)\n"
                                        "write(*,'(3i4)')b(trailz(bits8)+1)\n"
                                        'end program\n',
 'portable_trailz_while_element_write.f90': 'program p\n'
                                            'use iso_fortran_env,only:int32\n'
                                            'implicit none\n'
                                            'integer(int32)::x(3),bits\n'
                                            'integer::i\n'
                                            'character(9)::lines(3)\n'
                                            'x=[10_int32,20_int32,30_int32]\n'
                                            'bits=1_int32\n'
                                            'i=1\n'
                                            "lines='untouched'\n"
                                            'do while(trailz(bits)<3)\n'
                                            'write(lines(i),\'(i2.2,":",2i3)\')i,x(trailz([bits,1_int32])+1)\n'
                                            'x=x+10_int32\n'
                                            'bits=bits*2_int32\n'
                                            'i=i+1\n'
                                            'end do\n'
                                            "write(*,'(a)')lines\n"
                                            'end program\n',
 'real4_element_write.f90': 'program p\n'
                            'implicit none\n'
                            'real :: a(3)\n'
                            'character(18) :: line(2)\n'
                            'a=[1.5,-2.0,3.5]\n'
                            "line='unchanged'\n"
                            "write(line(2),'(3f6.1)')a([3,1,3])\n"
                            "write(*,'(a)')line(1),line(2)\n"
                            'end program\n',
 'real8_function_marker.f90': 'module m\n'
                              'implicit none\n'
                              'contains\n'
                              'function head(a) result(answer)\n'
                              'real(8),intent(in)::a(:)\n'
                              'real(8)::answer\n'
                              'answer=a(1)\n'
                              'end function\n'
                              'end module\n'
                              'program p\n'
                              'use m\n'
                              'implicit none\n'
                              'real(8)::x(3)\n'
                              'x=[1.25_8,2.5_8,3.75_8]\n'
                              "write(*,'(2f7.2)')head(x([3,1])),head(a=(x([2,1])))\n"
                              'end program\n',
 'real8_signed_zero_records.f90': 'program p\n'
                                  'use iso_fortran_env,only:output_unit\n'
                                  'implicit none\n'
                                  'real(8)::a(3)\n'
                                  'a=[-0.0_8,0.0_8,-2.5_8]\n'
                                  "write(output_unit,'(4f6.1)')a([2,1,2,3])\n"
                                  'end program\n',
 'scatter_boundary.f90': 'program p\n'
                         'implicit none\n'
                         'integer::a(3)\n'
                         'a=[1,2,3]\n'
                         'a([1,3])=7\n'
                         "write(*,'(3i3)')a\n"
                         'end program\n'}
MANIFEST = [{'name': 'do_while_integer4_cache',
  'mode': 'run',
  'gnu_mode': 'execute',
  'stdout': '   3   1\n  13  11\n  23  21\n',
  'source_sha256': '97fe5e161e251caa0f1e1163033861eea4cd65f052e0a16cbb3e2c3e762325df',
  'purpose': 'DO WHILE condition/backedge resets gathered numeric values, not stale first-iteration cache.'},
 {'name': 'integer8_mask_indices',
  'mode': 'run',
  'gnu_mode': 'execute',
  'stdout': '  30  10  30\n',
  'source_sha256': 'f974bc43e32677d0ca435c97053d3dda0b1a52951f3a883be98bb8772ea40183',
  'purpose': 'INTEGER8 vector and base with mask/shift-generated duplicate indices and nonunit lower bound.'},
 {'name': 'real4_element_write',
  'mode': 'run',
  'gnu_mode': 'execute',
  'stdout': 'unchanged         \n   3.5   1.5   3.5\n',
  'source_sha256': 'b83586fde6842de4500d8cab2d500290e994cff4f37718931ee7674a9044c482',
  'purpose': 'REAL4 gather items into one CHARACTER-array element, neighbor unchanged, exact padding.'},
 {'name': 'real8_function_marker',
  'mode': 'run',
  'gnu_mode': 'execute',
  'stdout': '   3.75   2.50\n',
  'source_sha256': 'd320151d6a5f5f28c2598c0678a063ee6e73edef3277a4b75019a822598e91e7',
  'purpose': 'Bare and grouped keyword numeric FUNCTION actuals exercise final backward closing-token '
             'anchor.'},
 {'name': 'parenthesized_alias_reallocation',
  'mode': 'run',
  'gnu_mode': 'execute',
  'stdout': '  6  2  6\n',
  'source_sha256': '000882e860a92a553e7ba3ef6bad0d70a9671e05d114a5c4e2be4eb6e7894619',
  'purpose': 'Parenthesized numeric snapshot precedes same-base INTENT(OUT) deallocation and resizing.'},
 {'name': 'bare_alias_before_entry',
  'mode': 'runtime',
  'gnu_mode': 'compile-only',
  'stdout': 'before\n',
  'source_sha256': '476b784bcd0c9143961744638c44469f16cd6ca71b3f2aa1889363699e7e6412',
  'purpose': 'Unsafe same-base bare IN/allocatable OUT association: compile GNU only; candidate must fail '
             'before entry, preserve preceding output.',
  'diagnostic': {'line': 18, 'column': 1, 'message': 'bare numeric gather base overlaps a writable actual'}},
 {'name': 'empty_values_and_kind',
  'mode': 'run',
  'gnu_mode': 'execute',
  'stdout': '  0  8  0\n',
  'source_sha256': 'c41d1e1bf2445f3c606a22552666a60aa0e5d9742dba7309a42679a48101b1fd',
  'purpose': 'Empty vector reads no undefined base data, while KIND does not evaluate undefined indices.'},
 {'name': 'duplicate_all_elemental',
  'mode': 'reject',
  'gnu_mode': 'compile-only',
  'stdout': '',
  'source_sha256': '0b8e3cefa00cd04d4d5fdc53a954f00e9a77f99dde72f2a5cf7bdcc4380210fd',
  'purpose': 'Numeric duplicate-order gather through elemental procedure and ALL validation. First strict '
             'GNU execution passed, but bare scalar ELEMENTAL association is outside the explicit ordinary '
             'assumed-shape IN slice; preserved as a bounded exclusion after owner confirmation.',
  'diagnostic': {'line': 14,
                 'column': 20,
                 'message': 'Parenthesize a gathered row value when passing it to a user procedure'}},
 {'name': 'numeric_character_staging',
  'mode': 'run',
  'gnu_mode': 'execute',
  'stdout': '[  20][  30]\n',
  'source_sha256': 'c0878f3ebbaddca6a6d1179caba17c455c99f14af0e0a36a74ce2358a2379c36',
  'purpose': 'Numeric gather staged into internal element WRITE, then existing CHARACTER gather.'},
 {'name': 'output_implied_do_refresh',
  'mode': 'run',
  'gnu_mode': 'execute',
  'stdout': '  2  3  4\n',
  'source_sha256': 'ebf55d45796b1606162f0f2db7c0625c2d04acc0dd793fb054c108d9907e49f9',
  'purpose': 'Output implied-DO changes selector and releases per-item numeric gather cache.'},
 {'name': 'ordinary_function_effect_boundary',
  'mode': 'reject',
  'gnu_mode': 'compile-only',
  'stdout': '',
  'source_sha256': '3769de3ee9c27218beba58c93de09de31cec81fdcf17d805acea8de9e19c3565',
  'purpose': 'GNU-valid ordinary function external WRITE remains outside existing effects contract; no '
             'relaxation.',
  'diagnostic': {'line': 18,
                 'column': 1,
                 'message': 'External side effects inside ordinary functions are unsupported'}},
 {'name': 'real8_signed_zero_records',
  'mode': 'run',
  'gnu_mode': 'execute',
  'stdout': '   0.0  -0.0   0.0  -2.5\n',
  'source_sha256': '891d1d0c6d1e804531a661c90eecc0c5f5abeb0d957780f6a11848f0b6c49889',
  'purpose': 'REAL8 signed zero and order preserved through gather and exact external-unit formatting.'},
 {'name': 'bad_index_pending_output',
  'mode': 'runtime',
  'gnu_mode': 'compile-only',
  'stdout': 'kept:',
  'source_sha256': '76348f4b1647d767e6fdc6b8aa80f52c8ad43d3603a87474f2ff6040385ef499',
  'purpose': 'Out-of-bounds gather cannot commit partial new record; retain prior nonadvancing bytes. GNU '
             'not executed.',
  'diagnostic': {'line': 6, 'column': 19, 'message': 'vector row index out of bounds'}},
 {'name': 'module_host_alias_boundary',
  'mode': 'reject',
  'gnu_mode': 'compile-only',
  'stdout': '',
  'source_sha256': 'f3a478db3b77eda165b16acc78dd2e7ba53c82a20fac282d302966dc51c27ad9',
  'purpose': 'Retained conservative same-base host/USE access exclusion for bare read-only gathered actual.',
  'diagnostic': {'line': 16,
                 'column': 1,
                 'message': 'Module actual also referenced through callee host/USE association is '
                            'unsupported'}},
 {'name': 'scatter_boundary',
  'mode': 'reject',
  'gnu_mode': 'compile-only',
  'stdout': '',
  'source_sha256': '705281134184592d6a97df635d1cec4103718f657f0ab610c2a94c016007af6d',
  'purpose': 'Vector scatter remains outside read-only gather scope; valid GNU source retained, not '
             'rewritten.',
  'diagnostic': {'line': 5,
                 'column': 9,
                 'message': 'Vector row gathering is read-only; scatter assignment is unsupported'}},
 {'name': 'explicit_shape_bare_boundary',
  'mode': 'reject',
  'gnu_mode': 'compile-only',
  'stdout': '',
  'source_sha256': '4606df71cfc7b9fa83d1411a08bbc1614d2c160fcdbdd1e44eb216a7670bd1bb',
  'purpose': 'Bare gather requires ordinary assumed-shape IN; explicit-shape actual boundary retained.',
  'diagnostic': {'line': 14,
                 'column': 23,
                 'message': 'Parenthesize a gathered row value when passing it to a user procedure'}},
 {'name': 'parenthesized_elemental_values',
  'mode': 'run',
  'gnu_mode': 'execute',
  'stdout': '  6  2  6\n',
  'source_sha256': '4f5962426fd8192ece138c77008a3ed57eb233fbdf0c38d1d37ea8acf20e27ea',
  'purpose': 'Separately named supported parenthesized gathered values through ELEMENTAL scalar procedure, '
             'retaining original bare source unchanged.'},
 {'name': 'portable_trailz_numeric_indices',
  'mode': 'run',
  'gnu_mode': 'execute',
  'stdout': '  30  10  20\n 300 100 200\n',
  'source_sha256': '3e967d943e572c1bd907feb50c707940b485071ff9e8665c4e1fd13f36ec0cca',
  'purpose': 'Portable INT32/INT64 constants and TRAILZ elemental default-INTEGER indices gather distinct '
             'numeric kinds.'},
 {'name': 'portable_trailz_function_actual',
  'mode': 'run',
  'gnu_mode': 'execute',
  'stdout': '  40  20\n',
  'source_sha256': '8d0916eb59d50234e9197ed7192bdae59b1c9d3f0a3b91387ff824394c4a10bb',
  'purpose': 'TRAILZ numeric gathered FUNCTION actuals exercise backward source anchoring for bare and '
             'parenthesized keyword slots.'},
 {'name': 'portable_trailz_while_element_write',
  'mode': 'run',
  'gnu_mode': 'execute',
  'stdout': '01: 10 10\n02: 30 20\n03: 50 30\n',
  'source_sha256': '55ecaa39d290194c03b991f6772a854f4cdff14501cac71b00153e023af038ec',
  'purpose': 'DO WHILE re-evaluates TRAILZ controls and resets gather caches before each staged '
             'array-element internal WRITE.'},
 {'name': 'portable_trailz_empty_kind',
  'mode': 'run',
  'gnu_mode': 'execute',
  'stdout': '  0 32 64\n',
  'source_sha256': '920eb95203a9d31afa2df26a75556d1e698c5e597a4b97f90d302856e2e5a16b',
  'purpose': 'Empty TRAILZ index vector gathers no undefined source values, while zero-width counts and '
             'default result kind remain precise.'}]
def generate(root):
    root=Path(root);(root/'cases').mkdir(parents=True,exist_ok=True)
    for name,text in SOURCES.items():(root/'cases'/name).write_text(text)
    (root/'manifest.json').write_text(json.dumps(MANIFEST,indent=2)+'\n')
if __name__=='__main__':
    import sys
    generate(sys.argv[1] if len(sys.argv)>1 else Path(__file__).resolve().parent)
