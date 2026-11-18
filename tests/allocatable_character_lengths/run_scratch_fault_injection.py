#!/usr/bin/env python3
"""Execute the exact frozen-length helper with a targeted malloc failure.

This is a native unit probe of the extracted production helper, not a whole
interpreter rebuild. Test doubles supply valid association metadata and record
runtime_error/tree/evaluation calls. GNU ld --wrap=malloc injects only the scratch
allocation failure after setup. No production fault-injection hook is added.
"""
from pathlib import Path
import argparse, hashlib, json, subprocess, tempfile, shutil

def main():
 p=argparse.ArgumentParser(description=__doc__)
 p.add_argument('--runtime',type=Path,required=True)
 p.add_argument('--gfortran',default='gfortran')
 p.add_argument('--cc',default='cc')
 p.add_argument('--result',type=Path,required=True)
 p.add_argument('--negative-control',action='store_true',help='Expect the unguarded original helper to abort on allocation failure')
 a=p.parse_args(); text=a.runtime.read_bytes().decode()
 start=text.index('        subroutine freeze_character_dummy_lengths()')
 end=text.index('        end subroutine',start)+len('        end subroutine')
 routine=text[start:end]
 if not a.negative_control:
  assert 'allocate(marks(prog%ne),stat=allocation_status)' in routine
  assert 'if(allocation_status/=0)' in routine
 header=r'''module probe
use, intrinsic :: iso_fortran_env, only: int64
use, intrinsic :: iso_c_binding, only: c_int,c_size_t
implicit none
integer,parameter::ty_integer=1,ty_character=4
integer::scope=1,tree_calls=0,evaluation_calls=0
logical::dummy_present(1)=.true.
type value_t
 integer::tag=ty_integer
 integer(int64)::i=3_int64
 character(:),allocatable::s
end type
type symbol_t
 integer::scope=1,typ=ty_character,character_len=-1,length_expr=1,line=7,column=9
 logical::is_dummy=.true.
end type
type program_t
 integer::ns=1,ne=10
 type(symbol_t)::symbols(1)
end type
type array_t
 integer::character_len=3
end type
type ref_t
 type(value_t)::value
 type(array_t)::array
end type
type diagnostic_t
 integer::code=0,line=0,column=0
 character(:),allocatable::message
end type
type(program_t)::prog
type(ref_t)::refs(1)
type(diagnostic_t)::diag
interface
 subroutine arm_failure(n) bind(C)
  import c_size_t
  integer(c_size_t),value::n
 end subroutine
 integer(c_int) function failures() bind(C)
  import c_int
 end function
end interface
contains
logical function valid_character_length_dummy(p,s) result(ok)
 type(program_t),intent(in)::p
 integer,intent(in)::s
 ok=p%ns==1.and.s==1
end function
subroutine validate_kind_tree(e,marks,level)
 integer,intent(in)::e,level
 integer,intent(inout)::marks(:)
 if(e/=1.or.level/=0.or.any(marks/=0)) error stop 90
 tree_calls=tree_calls+1
end subroutine
function evaluate(e,level) result(v)
 integer,intent(in)::e,level
 type(value_t)::v
 if(e/=1.or.level/=0) error stop 91
 evaluation_calls=evaluation_calls+1
end function
subroutine runtime_error(message,line,column)
 character(*),intent(in)::message
 integer,intent(in)::line,column
 diag%code=2;diag%line=line;diag%column=column;diag%message=message
end subroutine
'''
 footer=r'''
end module
program test
use probe
implicit none
integer::j
refs(1)%value%s='abc'
! Normal path, small allocation.
call arm_failure(0_c_size_t)
call freeze_character_dummy_lengths()
if(diag%code/=0.or.tree_calls/=1.or.evaluation_calls/=1.or.failures()/=0) error stop 1
! Inject malloc failure at 40 bytes, then at the maximum 40,000-byte scratch.
do j=1,2
 prog%ne=10
 if(j==2) prog%ne=10000
 diag=diagnostic_t();tree_calls=0;evaluation_calls=0
 call arm_failure(int(prog%ne,c_size_t)*int(storage_size(0)/8,c_size_t))
 call freeze_character_dummy_lengths()
 if(failures()/=1) error stop 2
 call arm_failure(0_c_size_t)
 if(diag%code/=2.or.diag%line/=7.or.diag%column/=9) error stop 3
 if(diag%message/='CHARACTER dummy length validation allocation failed') error stop 4
 if(tree_calls/=0.or.evaluation_calls/=0) error stop 5
 if(refs(1)%value%s/='abc'.or.refs(1)%array%character_len/=3) error stop 6
end do
! A new invocation recovers; no stale scratch or status survives the failed call.
diag=diagnostic_t();tree_calls=0;evaluation_calls=0
call freeze_character_dummy_lengths()
if(diag%code/=0.or.tree_calls/=1.or.evaluation_calls/=1) error stop 7
print '(a)','PASS: normal, two injected allocation failures, recovery'
end program
'''
 csrc=r'''#include <stddef.h>
#include <errno.h>
void *__real_malloc(size_t n);
static size_t armed_size;
static int count;
void arm_failure(size_t n) { armed_size=n; count=0; }
int failures(void) { return count; }
void *__wrap_malloc(size_t n) {
  if (armed_size && n == armed_size) { armed_size=0; ++count; errno=ENOMEM; return NULL; }
  return __real_malloc(n);
}
'''
 report={'scope':'Native unit fault injection of exact production helper; setup, validation/evaluation and diagnostic sink are test doubles. Not a whole interpreter acceptance run.', 'runtime_sha256':hashlib.sha256(a.runtime.read_bytes()).hexdigest(),'routine_sha256':hashlib.sha256(routine.encode()).hexdigest(),'cases':4,'steps':[]}
 with tempfile.TemporaryDirectory(prefix='character-length-scratch-') as td:
  td=Path(td);(td/'probe.f90').write_text(header+routine+footer);(td/'fail.c').write_text(csrc)
  commands=[[a.cc,'-Wall','-Wextra','-Werror','-c','fail.c','-o','fail.o'],[a.gfortran,'-std=f2018','-pedantic-errors','-fcheck=all','-g','probe.f90','fail.o','-Wl,--wrap=malloc','-o','probe'],[str(td/'probe')]]
  for command in commands:
   r=subprocess.run(command,cwd=td,capture_output=True,text=True,timeout=60)
   report['steps'].append({'command':command,'status':r.returncode,'stdout':r.stdout,'stderr':r.stderr})
   if r.returncode:break
 report['negative_control']=a.negative_control
 if a.negative_control:
  report['passed']=len(report['steps'])==3 and all(s['status']==0 for s in report['steps'][:2]) and report['steps'][-1]['status']!=0 and 'allocat' in report['steps'][-1]['stderr'].lower()
 else:
  report['passed']=len(report['steps'])==3 and all(s['status']==0 for s in report['steps'])
 a.result.write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2));return not report['passed']
if __name__=='__main__':raise SystemExit(main())
