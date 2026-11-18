from pathlib import Path
from run_tests import compare,numeric_equal,candidate_errors,known_gnu_rejection
checks=0
def expect(value):
 global checks
 checks+=1
 assert value,checks
for a,b in [('0','1e-9'),('-0','0'),('9007199254740992','9007199254740993'),('1.000000000000001','1'),('nan','nan'),('Infinity','Infinity'),('0.1','0.10000000000000001'),('T','F')]:expect(not numeric_equal(a,b))
for a,b in [('1D-9','1e-9'),('-0.0','-0e0'),('9007199254740993','9007199254740993'),('text','text')]:expect(numeric_equal(a,b))
for a,b in [('a \n','a\n'),('a\n','a'),('a\r\n','a\n'),('a\n\n','a\n'),('',' '),('1 2\n','12\n')]:expect(not compare(a,b))
expect(compare('a \n','a \n'));expect(compare('1D-9 -0\n','1e-9 -0.0\n',mode='numeric_records'))
for a,b in [('1\n2\n','1 2\n'),('1\n','1'),('1\r\n','1\n'),('1e-9\n','0\n')]:expect(not compare(a,b,mode='numeric_records'))
c=dict(stage='success',expected_stdout='OK\n');q=dict(code=0,out='',err='');r=dict(code=0,out='OK\n',err='');p=Path('/tmp/input.f90')
expect(not candidate_errors(c,q,r,p))
for check,run in [(dict(q,out=' '),r),(dict(q,err='\n'),r),(q,dict(r,err=' ')),(q,dict(r,code=2)),(q,dict(r,out='OK'))]:expect(bool(candidate_errors(c,check,run,p)))
c=dict(stage='runtime',expected_stdout='',diagnostic={'line':4,'column':2,'message':'uninitialized value'})
expect(not candidate_errors(c,q,dict(code=2,out='',err='/tmp/input.f90:4:2: uninitialized value\n'),p))
expect(bool(candidate_errors(c,q,dict(code=2,out='',err='/tmp/uninitialized.f90:4:2: other error\n'),p)))
c['diagnostic']=None;expect(bool(candidate_errors(c,q,dict(code=2,out='',err='anything'),p)))
c=dict(gnu_diagnostic='must be CHARACTER');q=dict(code=1,out='',err='Error: argument must be CHARACTER\n')
expect(known_gnu_rejection(c,q))
for wrong in [dict(q,code=0),dict(q,code=-11),dict(q,code=None),dict(q,out=' '),dict(q,err='different error')]:expect(not known_gnu_rejection(c,wrong))
expect(not known_gnu_rejection({},q))
for marker in ['internal compiler error','SIGSEGV','SIGABRT','Backtrace','Fortran runtime error','AddressSanitizer','TIMEOUT','Traceback']:
 expect(not known_gnu_rejection(c,dict(q,err=q['err']+marker)))
print(checks,'adversarial checks passed')
