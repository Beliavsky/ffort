from pathlib import Path
import json,hashlib
R=Path(__file__).resolve().parent;cases=[]
def add(n,code,out,decl='',stage='success',gnu='run'):
 src=('program p\nimplicit none\n'+decl+'\n'+code+'\nend program\n').encode();(R/'cases'/(n+'.f90')).write_bytes(src);cases.append(dict(name=n,source='cases/'+n+'.f90',sha256=hashlib.sha256(src).hexdigest(),stage=stage,gnu=gnu,expected=out,diagnostic=None,integer_records=[]))
for n,f,items,out in [
 ('single','(i0,/,i0)','1,2','1\n2\n'),('repeat','(i0,2/,i0)','1,2','1\n\n2\n'),
 ('adjacent','(i0//i0)','1,2','1\n\n2\n'),('omitted_comma','(i0/i0)','1,2','1\n2\n'),
 ('leading','(/i0)','7','\n7\n'),('trailing','(i0/)','7','7\n\n'),
 ('empty','(/)','','\n\n'),('empty_twice','(2/)','','\n\n\n'),
 ('nested','(2(i0,/))','1,2','1\n2\n\n'),('unlimited','(*(i0,/))','1,2,3','1\n2\n3\n\n'),
 ('reversion','(i0,/)','1,2','1\n\n2\n\n'),('colon','(i0,:,/)','1','1\n'),
 ('colon_more','(i0,:,/,i0)','1,2','1\n2\n'),('empty_colon','(:/)','','\n'),
 ('position_tr','(a,/,tr2,a)',"'X','Y'",'X\n  Y\n'),
 ('position_t','(a,/,t3,a)',"'X','Y'",'X\n  Y\n'),
 ('position_tl','(a,/,tl9,a)',"'X','Y'",'X\nY\n'),
 ('quoted_slash','("/",i0,"//")','7','/7//\n')]:
 add(n,"write(*,'"+f+"')"+items,out)
add('pending_tail',"write(*,'(a)',advance='no')'ABC'\nwrite(*,'(/,a)',advance='no')'D'\nwrite(*,'(a)')'E'",'ABC\nDE\n')
add('pending_trailing',"write(*,'(a,/)',advance='no')'ABC'\nwrite(*,'(a)')'D'",'ABC\nD\n')
add('pending_position',"write(*,'(a)',advance='no')'ABC'\nwrite(*,'(/,t3,a)',advance='no')'D'\nwrite(*,'(a)')'E'",'ABC\n  DE\n')
add('runtime_format',"f='(i0,/,i0)'\nwrite(*,f)1,2",'1\n2\n','character(30)::f')
add('internal_colon',"write(s,'(a,:,/)')'X'\nwrite(*,'(a)')s",'X   \n','character(4)::s')
add('internal_executed',"write(s,'(a,/)')'X'",'','character(4)::s',stage='runtime',gnu='compile')
for n,f in [('zero_repeat','(0/)'),('negative_repeat','(-1/)'),('huge_repeat','(2147483647/)')]:
 add(n,"f='"+f+"'\nwrite(*,f)",'','character(30)::f',stage='runtime',gnu='compile')
add('staging_exact',"write(*,'(65535/)')",'\n'*65536)
add('staging_over',"write(*,'(65536/)')",'',stage='runtime',gnu='compile')
add('operation_limit',"f='(262145(t1),/)'\nwrite(*,f)",'','character(40)::f',stage='runtime',gnu='compile')
add('forward_yes',"write(*,'(a,3x,/)')'x'",'x\n\n')
add('forward_no',"write(*,'(a,3x,/)',advance='no')'x'\nwrite(*,'(a)')'Y'",'x\nY\n')
add('tail_backspace',"write(*,'(a)',advance='no')'ABCDE'\nwrite(*,'(tl2,/)',advance='no')\nwrite(*,'(a)')'Y'",'ABCDE\nY\n')
add('trailing_no_eof',"write(*,'(a,/)',advance='no')'x'",'x\n')
# Independent complete demo oracle: each row's exact format is derived from source.
i=32768+1024+64;b=lambda x:format(x&0xffffffff,'032b');mark=lambda x:''.join('^' if c=='1' else '_' for c in b(x))
out='Looking at the integer: '+str(i)+'=>'+b(i)+'\n\nfrom bit 0 to bit 32==>\n'+''.join('T' if i&(1<<p) else 'F' for p in range(32))+'\n\nso for '+str(i)+' with a bit size of 32\n'+b(i)+'\n'+mark(i)+'\n\nand for '+str(-i)+' with a bit size of 32\n'+b(-i)+'\n'+mark(-i)+'\n\ngiven the array a ...\n 1  3\n 2  4\n\nthe value of btest (a, 2)\n F  F\n F  T\n\nthe value of btest (2, a)\n T  F\n F  F\n\n'
src=(R/'source/demo_btest.f90').read_bytes();cases.append(dict(name='original_demo_btest',source='source/demo_btest.f90',sha256=hashlib.sha256(src).hexdigest(),stage='success',gnu='run',expected=out,diagnostic=None,integer_records=[]))
(R/'manifest.json').write_text(json.dumps({'cases':cases},indent=2)+'\n')
print(len(cases),'cases')
