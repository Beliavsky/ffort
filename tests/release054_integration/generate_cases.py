#!/usr/bin/env python3
"""Independent INQUIRE NAME compositions; synthetic sources, not utility rewrites."""
import hashlib,json,textwrap
from pathlib import Path
ROOT=Path(__file__).resolve().parent
INPUTS={'alpha input.dat':'11\n22\n','beta.dat':'7\n8\n'}
CASES=[
('cursor_backspace','run','execute','11 22 22 alpha input.dat\n', '''
program p
implicit none
integer :: iu,a,b,c
character(18) :: name
iu=17
! GNU_REGISTER_INPUT
read(iu,*) a
inquire(unit=iu,name=name)
read(iu,*) b
backspace(iu)
inquire(name=name,unit=iu)
read(iu,*) c
write(*,'(i0,1x,i0,1x,i0,1x,a)') a,b,c,trim(name)
end program
'''),
('endfile_backspace','run','execute','22|alpha input.dat\n', '''
program p
implicit none
integer :: iu,n,ios
character(15) :: name
iu=17
! GNU_REGISTER_INPUT
read(iu,*) n
read(iu,*) n
read(iu,*,iostat=ios) n
if(ios>=0) error stop 'expected endfile'
inquire(unit=iu,name=name)
backspace(iu)
inquire(unit=iu,name=name)
backspace(iu)
read(iu,*) n
write(*,'(i0,a,a)') n,'|',name
end program
'''),
('while_unit_refresh','run','execute','alpha input.dat|beta.dat|alpha input.dat|3\n', '''
program p
implicit none
integer :: iu,i
character(15) :: name
character(15) :: saved(3)
iu=17
! GNU_REGISTER_INPUT
i=1
do while(i<=3)
  if(i==2) then
    iu=18
  else
    iu=17
  end if
  inquire(unit=iu,name=name)
  saved(i)=name
  i=i+1
end do
write(*,'(a,a,a,a,a,a,i0)') trim(saved(1)),'|',trim(saved(2)),'|',trim(saved(3)),'|',i-1
end program
'''),
('internal_element_record','run','execute','UNCHANGED!          |alpha input.dat:15  |UNCHANGED!          \n', '''
program p
implicit none
integer :: iu
character(18) :: name
character(20) :: records(3)
iu=17
! GNU_REGISTER_INPUT
records='UNCHANGED!'
inquire(name=name,unit=iu)
write(records(2),'(a,a,i0)') trim(name),':',len_trim(name)
write(*,'(a,a,a,a,a)') records(1),'|',records(2),'|',records(3)
end program
'''),
('allocated_name_move','run','execute','alpha inp|9|[beta.dat ]\n', '''
program p
implicit none
integer :: iu
character(:),allocatable :: name,moved
character(9) :: second
iu=17
! GNU_REGISTER_INPUT
allocate(character(9)::name)
inquire(unit=iu,name=name)
call move_alloc(name,moved)
iu=18
inquire(unit=iu,name=second)
write(*,'(a,a,i0,a,a,a)') moved,'|',len(moved),'|[',second,']'
end program
'''),
('dummy_name_padding','run','execute','[alpha input.dat  ]|[beta.]\n', '''
module m
implicit none
contains
subroutine lookup(iu,name)
integer(8),intent(in) :: iu
character(*),intent(out) :: name
inquire(unit=iu,name=name)
end subroutine
end module
program p
use m
implicit none
integer(8) :: iu
character(17) :: long_name
character(5) :: short_name
iu=17_8
! GNU_REGISTER_INPUT
call lookup(iu,long_name)
iu=18_8
call lookup(name=short_name,iu=iu)
write(*,'(a,a,a,a,a)') '[',long_name,']|[',short_name,']'
end program
'''),
('pending_record_survives','run','execute','NAME:alpha input.dat   \n11\n', '''
program p
implicit none
integer :: iu,n
character(18) :: name
iu=17
! GNU_REGISTER_INPUT
write(*,'(a)',advance='no') 'NAME:'
inquire(unit=iu,name=name)
write(*,'(a)') name
read(iu,*) n
write(*,'(i0)') n
end program
'''),
('undefined_unit_staging','runtime','compile-only','KEEP', '''
program p
implicit none
integer :: iu
character(8) :: name
! GNU_REGISTER_INPUT
name='original'
write(*,'(a)',advance='no') 'KEEP'
inquire(unit=iu,name=name)
write(*,'(a)') name
end program
'''),
('unregistered_stdout_unit','runtime','compile-only','KEEP', '''
program p
use iso_fortran_env, only: output_unit
implicit none
integer :: iu
character(8) :: name
! GNU_REGISTER_INPUT
iu=output_unit
name='original'
write(*,'(a)',advance='no') 'KEEP'
inquire(unit=iu,name=name)
write(*,'(a)') name
end program
'''),
('module_owned_target','reject','compile-only','', '''
module m
implicit none
character(18) :: shared_name
contains
subroutine lookup(iu)
integer,intent(in) :: iu
inquire(unit=iu,name=shared_name)
end subroutine
end module
program p
use m
implicit none
integer :: iu
iu=17
! GNU_REGISTER_INPUT
call lookup(iu)
write(*,'(a)') shared_name
end program
'''),
('ordinary_function_effect','runtime','compile-only','KEEP', '''
module m
implicit none
contains
subroutine lookup(iu,name)
integer,intent(in) :: iu
character(*),intent(out) :: name
inquire(unit=iu,name=name)
end subroutine
integer function measure(iu) result(n)
integer,intent(in) :: iu
character(18) :: name
call lookup(iu,name)
n=len_trim(name)
end function
end module
program p
use m
implicit none
integer :: iu,n
iu=17
! GNU_REGISTER_INPUT
write(*,'(a)',advance='no') 'KEEP'
n=measure(iu)
write(*,'(i0)') n
end program
'''),
('pure_local_boundary','reject','reject','', '''
module m
implicit none
contains
pure subroutine lookup(iu,name)
integer,intent(in) :: iu
character(*),intent(out) :: name
inquire(unit=iu,name=name)
end subroutine
end module
program p
end program
'''),
]
# Additive three-feature compositions; original12 CASES and bytes unchanged.
CASES += [('fzero_element_substring_records', 'run', 'execute', '[-9.25       ]|[2.5         ]\n', "\nprogram p\nimplicit none\ncharacter(12) :: a(2)\na='............'\nwrite(a(1),'(f0.2)') -1.25_8\na(1)(2:2)='9'\nwrite(a(2),'(f0.1)') 2.5\nwrite(*,'(a,a,a,a,a)') '[',a(1),']|[',a(2),']'\nend program\n"), ('inquire_fzero_while_substrings', 'run', 'execute', '[@lpha input.dat 1.0 ]\n[@eta.dat 2.0        ]\n', "\nprogram p\nimplicit none\ninteger :: iu,i\ncharacter(15) :: name\ncharacter(20) :: a(2)\n! GNU_REGISTER_INPUT\ni=1\ndo while(i<=2)\n  iu=16+i\n  inquire(unit=iu,name=name)\n  write(a(i),'(a,1x,f0.1)') trim(name),real(i)\n  a(i)(1:1)='@'\n  i=i+1\nend do\nwrite(*,'(a,a,a)') '[',a(1),']'\nwrite(*,'(a,a,a)') '[',a(2),']'\nend program\n"), ('substring_bare_distinct_base', 'run', 'execute', '[BC! ]|[ABCD]\n', "module m\nimplicit none\ncontains\nsubroutine capture(src,dst)\ncharacter(*),intent(in) :: src\ncharacter(*),intent(out) :: dst\ndst=src//'!'\nend subroutine\nend module\nprogram p\nuse m\nimplicit none\ncharacter(4) :: a(2),b(1)\na(1)='ABCD'\na(2)='WXYZ'\ncall capture(a(1)(2:3),b(1))\nwrite(*,'(a,a,a,a,a)') '[',b(1),']|[',a(1),']'\nend program\n"), ('substring_parenthesized_snapshot', 'run', 'execute', '[ABCD]|[BC! ]\n', "module m\nimplicit none\ncontains\nsubroutine capture(src,dst)\ncharacter(*),intent(in) :: src\ncharacter(*),intent(out) :: dst\ndst=src//'!'\nend subroutine\nend module\nprogram p\nuse m\nimplicit none\ncharacter(4) :: a(2)\na(1)='ABCD'\na(2)='WXYZ'\ncall capture((a(1)(2:3)),a(2))\nwrite(*,'(a,a,a,a,a)') '[',a(1),']|[',a(2),']'\nend program\n"), ('substring_bare_samebase_boundary', 'runtime', 'compile-only', 'KEEP', "module m\nimplicit none\ncontains\nsubroutine capture(src,dst)\ncharacter(*),intent(in) :: src\ncharacter(*),intent(out) :: dst\ndst=src//'!'\nend subroutine\nend module\nprogram p\nuse m\nimplicit none\ncharacter(4) :: a(2)\na(1)='ABCD'\na(2)='WXYZ'\nwrite(*,'(a)',advance='no') 'KEEP'\ncall capture(a(1)(2:3),a(2))\nwrite(*,'(a)') 'unexpected entry'\nend program\n"), ('short_fzero_after_substring_atomic_output', 'runtime', 'compile-only', '[AzzD]\nKEEP', "\nprogram p\nimplicit none\ncharacter(4) :: a(2)\na(1)='ABCD'\na(2)='WXYZ'\na(1)(2:3)='zz'\nwrite(*,'(a,a,a)') '[',a(1),']'\nwrite(*,'(a)',advance='no') 'KEEP'\nwrite(a(2),'(f0.2)') 123.45\nwrite(*,'(a)') 'unexpected commit'\nend program\n")]
# Observations are pinned only after preserving first candidate results.
DIAGNOSTICS={'undefined_unit_staging': {'line': 8, 'column': 14, 'message': 'read of uninitialized variable iu'}, 'unregistered_stdout_unit': {'line': 10, 'column': 1, 'message': 'external input unit is not explicitly bound'}, 'module_owned_target': {'line': 7, 'column': 34, 'message': 'INQUIRE NAME requires an INTEGER unit variable and a whole local writable scalar CHARACTER target outside ordinary functions, PURE or SIMPLE procedures'}, 'ordinary_function_effect': {'line': 7, 'column': 1, 'message': 'external side effect inside an ordinary function or PURE procedure'}, 'pure_local_boundary': {'line': 7, 'column': 27, 'message': 'INQUIRE NAME requires an INTEGER unit variable and a whole local writable scalar CHARACTER target outside ordinary functions, PURE or SIMPLE procedures'}}
DIAGNOSTICS.update({'substring_bare_samebase_boundary': {'line': 17, 'column': 1, 'message': 'array-element substring base overlaps a writable actual'}, 'short_fzero_after_substring_atomic_output': {'line': 9, 'column': 1, 'message': 'internal WRITE record exceeds CHARACTER length'}})
def generate(root=ROOT):
 root=Path(root);(root/'cases').mkdir(parents=True,exist_ok=True);(root/'inputs').mkdir(exist_ok=True)
 for name,body in INPUTS.items():(root/'inputs'/name).write_bytes(body.encode())
 rows=[]
 for name,mode,gnu_mode,out,body in CASES:
  raw=textwrap.dedent(body).lstrip('\n').encode();(root/'cases'/(name+'.f90')).write_bytes(raw)
  c=dict(name=name,mode=mode,gnu_mode=gnu_mode,stdout=out,source_sha256=hashlib.sha256(raw).hexdigest(),diagnostic=DIAGNOSTICS.get(name))
  if gnu_mode=='reject':c['gnu_diagnostic']='INQUIRE statement not allowed in PURE procedure'
  rows.append(c)
 (root/'manifest.json').write_text(json.dumps(rows,indent=2)+'\n')
 (root/'input-manifest.json').write_text(json.dumps({n:{'unit':17+i,'sha256':hashlib.sha256(v.encode()).hexdigest(),'bytes':len(v.encode())}for i,(n,v)in enumerate(INPUTS.items())},indent=2)+'\n')
if __name__=='__main__':generate()
