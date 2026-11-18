from pathlib import Path
import json,hashlib,shutil
root=Path(__file__).resolve().parent
(root/'cases').mkdir(exist_ok=True)
cases=[]
def add(name,source,expected=None,kind='pass',gnu='pass',diagnostic=None,prefix='',flags=None):
 b=source.encode();(root/'cases'/f'{name}.f90').write_bytes(b)
 c=dict(name=name,source=f'cases/{name}.f90',sha256=hashlib.sha256(b).hexdigest(),kind=kind,gnu=gnu)
 if expected is not None:c['expected_stdout']=expected
 if diagnostic:c['diagnostic']=diagnostic
 if prefix:c['prefix']=prefix
 if flags:c['flags']=flags
 cases.append(c)
def program(body,decl=''):return 'program p\nimplicit none\n'+decl+('\n' if decl else '')+body+'\nend program\n'
formats=[('absolute','(a,t3,a)',"'abcdef','XY'",'abXYef'),('left','(a,tl2,a)',"'abc','Z'",'aZc'),('left_clamp','(a,tl65536,a)',"'abc','Z'",'Zbc'),('right','(a,tr3,a)',"'A','Z'",'A   Z'),('gap_then_left','(a,tr3,tl2,a)',"'A','B'",'A B'),('preserve_skipped','(a,t1,a,2x,a)',"'abcdef','Z','Q'",'ZbcQef'),('absolute_initial','(t5,a)',"'Z'",'    Z'),('left_initial','(tl4,a)',"'Z'",'Z'),('positions_only','(t5,tl2,tr1)',None,''),('trailing_forward','(a,t10)',"'abc'",'abc'),('trailing_backward','(a,t1)',"'abc'",'abc'),('zero_literal','(a,t5,"",tl3,a)',"'abc','X'",'aXc '),('group','(2(a,tl1,a))',"'abc','X','def','Y'",'abXdeY'),('unlimited','(*(a,tl1,a))',"'abc','X','def','Y'",'abXdeY'),('colon','(a,t2,a,:,tr5,"tail")',"'abc','X'",'aXc')]
# Empty literals count as a zero-width transfer, materializing a skipped gap.
for name,fmt,args,expected in formats:
 vals=(' '+args) if args else ''
 add(name+'_print',program("print '"+fmt+"'"+(','+args if args else '')),expected+'\n')
 add(name+'_internal',program("write(s,'"+fmt+"')"+vals+"\nprint '(a)',s" ,'character(16)::s'),expected.ljust(16)+'\n')
 add(name+'_runtime',program("fmt='"+fmt+"'\nwrite(*,fmt)"+vals,'character(80)::fmt'),expected+'\n')
 # Nonadvancing materializes the forward position; ending with a backward
 # control preserves the rightmost text rather than rewinding next WRITE.
 no={'positions_only':'   ','trailing_forward':'abc      '}.get(name,expected)
 add(name+'_nonadvance',program("write(*,'"+fmt+"',advance='no')"+vals+"\nwrite(*,'(t2,a)') '!'"),({'absolute':'abXYe!','left':'aZc!','left_clamp':'Zb!','preserve_skipped':'ZbcQe!','zero_literal':'aXc!','colon':'aXc!','trailing_backward':'a!c'}.get(name,no+' !'))+'\n')
add('ordinary_reversion',program("print '(a,t2,a)','ABCD','x','EFGH','y'"),'AxCD\nEyGH\n')
add('group_reversion',program("print '(\"P\",(a,t2,a))','ABCD','x','EFGH','y'"),'PxBCD\nEyGH\n')
add('nonadvance_reversion',program("write(*,'(a,t2,a)',advance='no')'ABCD','x','EFGH','y'\nwrite(*,'(tl99,a)')'!'"),'AxCD\nEy!H\n')
add('prior_left_limit',program("write(*,'(a)',advance='no') 'prior'\nwrite(*,'(a,t1,a)',advance='no') 'abc','X'\nwrite(*,'(tl65536,a)')'!'"),'priorX!c\n')
add('nested_nonadvance',program("write(*,'(a)',advance='no') 'P'\ncall emit_text()\nwrite(*,'(t2,a)') 'Z'\ncontains\nsubroutine emit_text()\nwrite(*,'(a,tl2,a)',advance='no')'abcd','X'\nend subroutine"),'PabXdZ\n')
add('internal_format_alias',program("s='(a,t2,a)'\nwrite(s,s)'ABCD','x'\nprint '(a)',s",'character(16)::s'),'AxCD            \n')
add('implied_do',program("print '(*(i2,tl1,a))',(i,'X',i=1,3)",'integer::i'),' X X X\n')
add('t_boundary',program("print '(t65536,a)','X'"),' '*65535+'X\n')
add('tr_boundary',program("write(*,'(tr65536)',advance='no')\nwrite(*,'(a)')''"),' '*65536+'\n')
add('t_no_data_extent',program("print '(t65536)'"),'\n')
for name,fmt,diag,gnu in [
 ('t_missing','(t)','T/TL/TR require a positive integer position','fail'),('tl_missing','(tl)','T/TL/TR require a positive integer position','fail'),('tr_missing','(tr)','T/TL/TR require a positive integer position','fail'),('t_zero','(t0)','T/TL/TR position must be between 1 and 65536','fail'),('tl_zero','(tl0)','T/TL/TR position must be between 1 and 65536','fail'),('tr_zero','(tr0)','T/TL/TR position must be between 1 and 65536','fail'),('t_negative','(t-1)','T/TL/TR require a positive integer position','fail'),('t_decimal','(t1.0)','T/TL/TR require a positive integer position','fail'),('t_repeat','(2t1)','T/TL/TR descriptors do not accept a repeat prefix','fail'),('tl_one_repeat','(1tl1)','T/TL/TR descriptors do not accept a repeat prefix','fail'),('tr_repeat','(2tr1)','T/TL/TR descriptors do not accept a repeat prefix','fail'),('t_over_cap','(t65537)','T/TL/TR position must be between 1 and 65536','pass'),('tl_over_cap','(tl65537)','T/TL/TR position must be between 1 and 65536','pass'),('tr_over_cap','(tr65537)','T/TL/TR position must be between 1 and 65536','pass'),('t_integer_overflow','(t99999999999999999999999999999999999999999999999999)','T/TL/TR position must be between 1 and 65536','fail'),('unlimited_no_data','(*(t2,tl1,tr1))','unlimited format item must contain a data descriptor','fail')]:
 add(name,program("print '"+fmt+"'"),kind='reject',gnu=gnu,diagnostic=diag)
add('runtime_bad_format',program("fmt='(t0,a)'\nwrite(*,fmt)'X'",'character(20)::fmt'),kind='runtime',diagnostic='T/TL/TR position must be between 1 and 65536')
add('runtime_cursor_overflow',program("print '(tr65536,a)','X'"),kind='runtime',diagnostic='formatted PRINT record exceeds 65536 characters')
add('runtime_position_overflow',program("print '(tr65536,tr1)'"),kind='runtime',diagnostic='formatted output exceeds 65536 characters')
add('prior_record_atomic',program("print '(a)','SAFE'\nprint '(a,tr65536,a)','BAD','X'"),kind='runtime',diagnostic='formatted output exceeds 65536 characters',prefix='SAFE\n')
add('prior_nonadvance_atomic',program("write(*,'(a)',advance='no')'SAFE'\nprint '(a,tr65536,a)','BAD','X'"),kind='runtime',diagnostic='formatted output exceeds 65536 characters',prefix='SAFE')
add('combined_record_cap',program("write(*,'(a)',advance='no')'P'\nprint '(t65536,a)','X'"),kind='runtime',diagnostic='combined output record exceeds character limit',prefix='P')
add('pending_tail_end',program("write(*,'(a,t2,a)',advance='no')'ABCD','x'"),'AxCD')
add('pending_tail_blank_advance',program("write(*,'(a,t2,a)',advance='no')'ABCD','x'\nprint '(a)'"),'AxCD\n')
add('pending_tail_list',program("write(*,'(a,t2,a)',advance='no')'ABCDEFG','x'\nprint *, 'Z'"),'Ax ZEFG\n')
add('pending_tail_failure',program("write(*,'(a,t2,a)',advance='no')'ABCD','x'\nprint '(tr65536,a)','X'"),kind='runtime',diagnostic='formatted PRINT record exceeds 65536 characters',prefix='AxCD')
add('pending_tail_skip',program("write(*,'(a,t2,a)',advance='no')'ABCDEFG','x'\nwrite(*,'(tr2,a)',advance='no')'Z'\nprint '(a)'"),'AxCDZFG\n')
add('parameter_format',program("write(*,fmt)'abc','X'",'character(*),parameter::fmt="(a,tl1,a)"'),'abX\n')
add('dynamic_format_change',program("fmt='(a,t2,a)'\nwrite(*,fmt)'abc','X'\nfmt='(a,tr2,a)'\nwrite(*,fmt)'abc','X'",'character(20)::fmt'),'aXc\nabc  X\n')
# Preserve complete upstream programs, including original comments and bytes.
up=root
for name in ('demo_cos','demo_cosd'):
 raw=(up/'cases'/(name+'.f90')).read_bytes();(root/'cases'/(name+'.f90')).write_bytes(raw)
 cases.append(dict(name=name,source='cases/'+name+'.f90',sha256=hashlib.sha256(raw).hexdigest(),kind='pass',gnu='pass',flags=['-std=f2023','-pedantic-errors'] if name=='demo_cosd' else ['-std=f2018','-pedantic-errors'],original=True))
# GCC 14.2 accept these formats at compile time; they are not executed.
for c in cases:
 if c['name'] in ('t_repeat','tl_one_repeat','tr_repeat','t_integer_overflow','unlimited_no_data'): c['gnu']='pass'
 # GCC 14.2 advancing output mishandles adjacent forward/backward tabs.
 # Retain explicit independent expectations and separately pin the discrepancy.
 if c['name'] in ('gap_then_left_print','gap_then_left_runtime'): c['gnu_expected_stdout']='A  B\n'
 if c['name']=='trailing_backward_nonadvance': c['gnu_expected_stdout']='abc !\n'
 if c['name']=='gap_then_left_internal': c['gnu_expected_stdout']='A  B            \n'
(root/'manifest.json').write_text(json.dumps(dict(cases=cases),indent=2)+'\n')
print(len(cases))
