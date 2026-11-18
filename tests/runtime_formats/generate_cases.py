from pathlib import Path
import json,hashlib
R=Path(__file__).resolve().parent;R.mkdir(exist_ok=True)
rows=[]
def add(name,body,decl='',kind='pass',diag='',gnu='pass',prefix='',expected=None,whole=False):
 src=body if whole else 'program p\nimplicit none\n'+decl+'\n'+body+'\nend program\n'
 (R/(name+'.f90')).write_text(src)
 c=dict(name=name,kind=kind,gnu_compile=gnu,sha256=hashlib.sha256(src.encode()).hexdigest())
 if diag:c['diagnostic_contains']=diag
 if prefix:c['prefix']=prefix
 if expected is not None:c['stdout']=expected
 rows.append(c)
for label,stmt in [('print','print fmt,12'),('write','write(*,fmt)12'),('fmt','write(*,fmt=fmt)12'),('unit','write(unit=*,fmt)12'),('both','write(unit=*,fmt=fmt)12')]:add('dynamic_'+label,'fmt="(i0)"\n'+stmt,'character(12)::fmt',expected='12\n')
for label,stmt in [('plain','write(s,fmt)12'),('fmt','write(s,fmt=fmt)12'),('unit','write(unit=s,fmt)12'),('both','write(unit=s,fmt=fmt)12')]:add('internal_'+label,'fmt="(i0)"\n'+stmt+'\nprint "(a)","["//s//"]"','character(12)::fmt\ncharacter(5)::s',expected='[12   ]\n')
add('mutate_format','fmt="(i3.3)"\nprint fmt,7\nfmt="(i0)"\nwrite(*,fmt)8','character(8)::fmt',expected='007\n8\n')
add('alias_destination','fmt="(i0)"\nwrite(fmt,fmt)42\nprint "(a)","["//fmt//"]"','character(5)::fmt',expected='[42   ]\n')
add('allocatable_format',"fmt='(i0)'\nprint fmt,99\ndeallocate(fmt)\nfmt='(i3.3)'\nwrite(*,fmt)8",'character(:),allocatable::fmt',expected='99\n008\n')
add('format_named_unit',"unit='(i0)'\nwrite(*,unit)3",'character(8)::unit',expected='3\n')
add('module_format',"module m\ncharacter(8)::fmt='(i0)'\nend module\nprogram p\nuse m\nimplicit none\nprint fmt,8\nend program\n",whole=True,expected='8\n')
add('host_format',"module m\ncharacter(8)::fmt='(i0)'\ncontains\nsubroutine show()\nprint fmt,8\nend subroutine\nend module\nprogram p\nuse m\ncall show()\nend program\n",whole=True,expected='8\n')
add('dummy_format',"call show('(i0)')\ncontains\nsubroutine show(fmt)\ncharacter(*),intent(in)::fmt\nprint fmt,8\nend subroutine",expected='8\n')
add('optional_format',"call show('(i0)')\ncontains\nsubroutine show(fmt)\ncharacter(*),intent(in),optional::fmt\nprint fmt,8\nend subroutine",expected='8\n')
add('snapshot_item',"module m\ncharacter(8)::fmt='(i0)'\ncontains\ninteger function change()\nfmt='(i3.3)'\nchange=7\nend function\nend module\nprogram p\nuse m\nprint fmt,change()\nprint fmt,8\nend program\n",whole=True,expected='7\n008\n')
for spelling in ["'NO'","'no'","'No'"]:
 add('no_'+str(len(rows)),"write(*,'(a)',advance="+spelling+")'A'\nwrite(*,'(a)')'B'",expected='AB\n')
for spelling in ["'YES'","'yes'","'YeS'"]:
 add('yes_'+str(len(rows)),"write(*,'(a)',advance="+spelling+")'A'\nwrite(*,'(a)')'B'",expected='A\nB\n')
add('dynamic_no',"fmt='(a,2x)'\nwrite(unit=*,fmt=fmt,advance='no')'A'\nprint '(a)','B'",'character(12)::fmt',expected='A  B\n')
add('unterminated_end',"write(*,'(a,3x)',advance='no')'A'",expected='A   ')
add('empty_no',"write(*,'(a)',advance='no')''\nwrite(*,'(3x)',advance='no')\nwrite(*,'(a)')'B'",expected='   B\n')
add('calls_record',"write(*,'(a)',advance='no')'A'\ncall show\nprint '(a)','C'\ncontains\nsubroutine show()\nwrite(*,'(a,1x)',advance='no')'B'\nend subroutine",expected='AB C\n')
add('callee_record',"call show\nprint '(a)','B'\ncontains\nsubroutine show()\nwrite(*,'(a)',advance='no')'A'\nend subroutine",expected='AB\n')
add('ordinary_reversion',"fmt='(i1,2x)'\nwrite(*,fmt,advance='no')[1,2]\nprint '(a)','X'",'character(12)::fmt',expected='1  \n2  X\n')
add('unlimited_reversion',"fmt='(*(i1,:,2x))'\nwrite(*,fmt,advance='no')[1,2,3]\nprint '(a)','X'",'character(20)::fmt',expected='1  2  3X\n')
add('colon_exhaustion',"fmt='(i1,:,4x)'\nwrite(*,fmt,advance='no')1\nprint '(a)','X'",'character(20)::fmt',expected='1X\n')
add('advancing_trailing_x',"fmt='(i1,4x)'\nprint fmt,1\nwrite(*,fmt)2",'character(20)::fmt',expected='1\n2\n')
add('literal_padding',"fmt='(a,\"   \")'\nwrite(*,fmt,advance='no')'A'\nprint '(a)','B'",'character(20)::fmt',expected='A   B\n')
add('newline_data',"write(*,'(a)',advance='no')'A'//new_line('a')//'B'\nprint '(a)','C'",expected='A\nBC\n')
add('list_completion',"write(*,'(a)',advance='no')'A'\nprint *,'B'",expected=None)
add('internal_no_reversion',"fmt='(i0)'\nwrite(s,fmt)123\nprint '(a)',s",'character(12)::fmt\ncharacter(4)::s',expected='123 \n')
add('empty_values',"fmt='(\"empty\",*(i0))'\nprint fmt,a",'character(32)::fmt\ninteger::a(0)',expected='empty\n')
add('full_record',"write(*,'(a)',advance='no')repeat('x',65535)\nprint '(a)','z'",expected='x'*65535+'z\n')
add('record_reset',"write(*,'(a)',advance='no')repeat('x',65536)\nprint '(a)',''\nprint '(a)','z'",expected='x'*65536+'\nz\n')
# Runtime boundaries are GNU compile-only, not undefined/singular execution oracles.
for name,fmt,diag in [('malformed','(i0','format'),('empty','','format'),('type','(a)','descriptor and item type differ')]:
 add('runtime_'+name,'fmt="'+fmt+'"\nprint fmt,7','character(8)::fmt',kind='runtime',diag=diag)
add('undefined_format','print fmt,1','character(8)::fmt',kind='runtime',diag='undefined')
add('unallocated_format','print fmt,1','character(:),allocatable::fmt',kind='runtime',diag='unallocated')
add('absent_format','call show()\ncontains\nsubroutine show(fmt)\ncharacter(*),intent(in),optional::fmt\nprint fmt,1\nend subroutine',kind='runtime',diag='absent')
add('grammar_before_items','fmt="(i0"\nprint fmt,i','character(8)::fmt\ninteger::i',kind='runtime',diag='format')
add('oversize_format','fmt=repeat(" ",65537)\nprint fmt,1','character(:),allocatable::fmt',kind='reject',diag='REPEAT CHARACTER length limit exceeded')
add('prior_prefix_error','fmt="(i0"\nwrite(*,"(a)",advance="no")"OK"\nprint fmt,1','character(8)::fmt',kind='runtime',diag='format',prefix='OK')
add('record_overflow','write(*,"(a)",advance="no")repeat("x",65536)\nprint "(a)","z"',kind='runtime',diag='combined output record',prefix='x'*65536)
add('record_overflow_no','write(*,"(a)",advance="no")"X"\nwrite(*,"(a)",advance="no")repeat("y",65536)',kind='runtime',diag='combined output record',prefix='X')
add('internal_overflow','fmt="(i0)"\nwrite(s,fmt)123','character(8)::fmt\ncharacter(2)::s',kind='runtime',diag='internal WRITE record exceeds')
add('empty_still_validate','fmt="(i0"\nprint fmt,a','character(8)::fmt\ninteger::a(0)',kind='runtime',diag='format')
# Bounded source syntax rejections.
for name,stmt,decl,gnu in [
 ('integer','print fmt,1','integer::fmt=1','fail'),
 ('array','print fmt,1',"character(8)::fmt(1)=['(i0)   ']",'pass'),
 ('element','print fmt(1),1',"character(8)::fmt(1)=['(i0)   ']",'pass'),
 ('substring','print fmt(1:4),1',"character(8)::fmt='(i0)'",'pass'),
 ('parenthesized','print (fmt),1',"character(8)::fmt='(i0)'",'pass'),
 ('concat','print fmt//" ",1',"character(8)::fmt='(i0)'",'pass'),
 ('unknown','print fmt,1','', 'fail'),
 ('advance_variable','write(*,"(i0)",advance=mode)1',"character(3)::mode='no'",'pass'),
 ('advance_bad','write(*,"(i0)",advance="maybe")1','','fail'),
 ('advance_list','write(*,*,advance="no")1','','fail'),
 ('advance_internal','write(s,"(i0)",advance="no")1','character(8)::s','fail'),
 ('advance_twice','write(*,"(i0)",advance="no",advance="yes")1','','fail'),
 ('iostat','write(*,"(i0)",iostat=i)1','integer::i','pass'),
 ('reverse_controls','write(fmt="(i0)",unit=6)1','','pass'),
 ('numeric_unit','write(6,"(i0)")1','','pass')]:
 add('reject_'+name,stmt,decl,kind='reject',diag='',gnu=gnu)
for c in rows:
 if c['name']=='snapshot_item':
  c['kind']='reject';c['diagnostic_contains']='Mutable module writes inside ordinary functions';c.pop('stdout',None)
 if c['name'] in ['dynamic_unit','internal_unit']:
  c['kind']='reject';c['gnu_compile']='fail';c['diagnostic_contains']='WRITE controls differ';c.pop('stdout',None)
add('reject_advance_padding',"write(*,'(a)',advance='NO   ')'A'",kind='reject',gnu='fail',diag='ADVANCE requires literal')
diagnostics = {'reject_integer': 'Expected *, found fmt', 'reject_array': 'Expected *, found fmt', 'reject_element': 'Expected *, found fmt', 'reject_substring': 'Runtime format requires a whole scalar CHARACTER variable', 'reject_parenthesized': 'Expected *, found (', 'reject_concat': 'Unexpected trailing token: //', 'reject_unknown': 'Expected *, found fmt', 'reject_advance_variable': 'ADVANCE requires an explicit format and literal YES or NO', 'reject_advance_bad': 'ADVANCE requires literal YES or NO', 'reject_advance_list': 'ADVANCE requires an explicit format and literal YES or NO', 'reject_advance_internal': 'Expected ), found ,', 'reject_advance_twice': 'Expected ), found ,', 'reject_iostat': 'Expected advance, found iostat', 'reject_reverse_controls': 'Internal WRITE requires a declared CHARACTER variable', 'reject_numeric_unit': 'WRITE unit must be * or a supported declared variable'}
for c in rows:
 if c['name'] in diagnostics: c['diagnostic_contains']=diagnostics[c['name']]
(R/'manifest.json').write_text(json.dumps(dict(cases=rows),indent=2)+'\n')
print('generated',len(rows))
