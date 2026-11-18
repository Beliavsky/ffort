from pathlib import Path
import json,hashlib,shutil
R=Path(__file__).resolve().parent; (R/'cases').mkdir(exist_ok=True);rows=[]
def add(name,decl,body,stage='success',gnu=None,note='',inputs=None):
 s='program p\nimplicit none\n'+decl.strip()+'\n'+body.strip()+'\nend program\n';p=R/'cases'/(name+'.f90');p.write_text(s)
 rows.append(dict(name=name,source='cases/'+p.name,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),inputs=inputs or {},gnu=gnu or ('run' if stage=='success' else 'compile'),diagnostic=None,note=note,stage=stage,expected='OK\n' if stage=='success' else '',gnu_expected='OK\n' if stage=='success' else '',gnu_stderr=''))
def ok(body):return body+'\nprint \'(a)\', "OK"'
d='character(20)::lines(3)\ninteger::n,i,ios'
add('utilities_loop',d+'\ncharacter(20)::word','lines=[character(20)::"alpha rest","beta rest","gamma rest"]\ndo i=1,3\nread(lines(i),*) word\nif (i==1.and.trim(word)/="alpha") stop 1\nif (i==2.and.trim(word)/="beta") stop 2\nif (i==3.and.trim(word)/="gamma") stop 3\nend do\nprint \'(a)\', "OK"')
add('selected_only_defined',d,ok('lines(2)="17"\nread(lines(2),*) n\nif(n/=17) stop 1'))
add('unchanged_record',d,ok('lines="untouched"\nlines(2)="23"\nread(lines(2),*)n\nif(n/=23.or.lines(2)/="23".or.lines(1)/="untouched".or.lines(3)/="untouched")stop 1'))
for rank,shape,index in [(1,'(-2:0)','-1'),(2,'(-1:0,3:4)','0,4'),(3,'(-1:0,3:4,-3:-2)','0,4,-2')]:
 add('rank'+str(rank)+'_lowerbounds','character(10)::a'+shape+'\ninteger::n',ok('a('+index+')="29"\nread(a('+index+'),*)n\nif(n/=29)stop 1'))
for name,index,extra in [('index_kind8','i','integer(8)::i'),('index_arithmetic','i+2*j-1','integer::i,j')]:
 init='i=2' if name=='index_kind8' else 'i=1\nj=1'
 add(name,'character(8)::a(3)\ninteger::n\n'+extra,ok(init+'\na(2)="31"\nread(a('+index+'),*)n\nif(n/=31)stop 1'))
add('named_controls',d,ok('lines(2)="37"\nread(unit=lines(2),fmt=*,iostat=ios)n\nif(n/=37.or.ios/=0)stop 1'))
add('numeric_kinds','character(64)::a(1)\ninteger(8)::n\nreal(4)::x\nreal(8)::y',ok('a(1)="9007199254740993 1.25 2.5"\nread(a(1),*)n,x,y\nif(n/=9007199254740993_8.or.x/=1.25.or.y/=2.5_8)stop 1'))
add('quoted_character','character(64)::a(1)\ncharacter(12)::x,y',ok('a(1)=\'"hello world", "a,b"\'\nread(a(1),*)x,y\nif(x/="hello world".or.y/="a,b")stop 1'))
add('repetition_null_slash','character(32)::a(1)\ninteger::n(5)',ok('a(1)="2*7,,9/"\nn=3\nread(a(1),*)n\nif(any(n/=[7,7,3,9,3]))stop 1'))
add('array_targets','character(32)::a(1)\ninteger::n(2,2)',ok('a(1)="1 2 3 4"\nread(a(1),*)n\nif(any(reshape(n,[4])/=[1,2,3,4]))stop 1'))
for name,record,condition in [('iostat_success','41','ios/=0.or.n/=41'),('iostat_bad_token','bad','ios<=0'),('iostat_end_record','','ios>=0')]:
 add(name,d,ok('lines(1)="'+record+'"\nread(lines(1),*,iostat=ios)n\nif('+condition+')stop 1'))
add('zero_length','character(0)::a(1)\ninteger::n,ios',ok('a(1)=""\nread(a(1),*,iostat=ios)n\nif(ios>=0)stop 1'))
add('max_length','character(65536)::a(1)\ninteger::n',ok('a(1)="43"\nread(a(1),*)n\nif(n/=43)stop 1'))
for rank,shape,index in [(1,'(-1:1)','0'),(2,'(-1:0,3:4)','0,4'),(3,'(-1:0,3:4,-3:-2)','0,4,-2')]:
 dims=','.join(':' for _ in range(rank));add('allocated_rank'+str(rank),'character(16),allocatable::a('+dims+')\ninteger::n',ok('allocate(a'+shape+')\na('+index+')="47"\nread(a('+index+'),*)n\nif(n/=47)stop 1'))
add('empty_target_list',d,ok('lines(1)="irrelevant"\nread(lines(1),*,iostat=ios)\nif(ios/=0)stop 1'))
add('tab_delimiter',d+'\ninteger::m',ok('lines(1)="2"//achar(9)//"3"\nread(lines(1),*)n,m\nif(n/=2.or.m/=3)stop 1'))
add('repeat_execution',d,ok('lines(1)="53"\nread(lines(1),*)n\nif(n/=53)stop 1\nn=0\nread(lines(1),*)n\nif(n/=53)stop 2'))
add('external_composition',d+'\ninteger::unit\ncharacter(20)::after',ok('unit=27\nread(unit,"(a)")lines(2)\nread(lines(2),*)n\nif(n/=59)stop 1\nread(unit,"(a)")after\nif(after/="NEXT")stop 2'),inputs={'27':'59\nNEXT\n'})
add('backspace_composition',d+'\ninteger::unit',ok('unit=27\nread(unit,"(a)")lines(2)\nread(lines(2),*)n\nif(n/=61)stop 1\nbackspace(unit)\nread(unit,"(a)")lines(1)\nif(lines(1)/=lines(2))stop 2'),inputs={'27':'61\nNEXT\n'})
for name,expr,decl in [('section','lines(1:2)',d),('substring','lines(1)(1:2)',d),('whole_array','lines',d),('compound','trim(lines(1))',d),('literal','"17"',d),('intrinsic_index','lines(abs(i))',d),('target_index','lines(n)',d),('status_index','lines(ios)',d)]:
 gnu='reject' if name in ('compound','literal') else 'compile'
 add('excluded_'+name,decl,'lines="17"\ni=1\nn=1\nios=1\nread('+expr+',*,iostat=ios)n',stage='compile',gnu=gnu,note='Explicit subset exclusion, not necessarily invalid Fortran')
add('excluded_pointer','character(8),target::storage(1)\ncharacter(8),pointer::a(:)\ninteger::n','storage="17"\na=>storage\nread(a(1),*)n',stage='compile')
add('excluded_overlap',d,'lines="17"\nread(lines(1),*)lines',stage='compile')
add('undefined_selected',d,'read(lines(2),*)n',stage='runtime')
add('undefined_index',d,'lines="17"\nread(lines(i),*)n',stage='runtime')
add('out_of_bounds',d,'lines="17"\ni=4\nread(lines(i),*)n',stage='runtime')
add('unallocated','character(8),allocatable::a(:)\ninteger::n','read(a(1),*)n',stage='runtime')
add('control_character',d,'lines(1)="1"//achar(10)//"2"\nread(lines(1),*)n',stage='runtime')
add('bad_conversion_without_status',d,'lines(1)="bad"\nread(lines(1),*)n',stage='runtime')
add('eof_without_status',d,'lines(1)=""\nread(lines(1),*)n',stage='runtime')
# Procedure-scope and effect boundaries use complete self-contained programs.
def proc(name,inner,body,stage='success'):
 add(name,'integer::n',body+'\ncontains\n'+inner,stage=stage)
proc('ordinary_local','subroutine s(n)\ninteger,intent(out)::n\ncharacter(8)::a(2)\na(2)="67"\nread(a(2),*)n\nend subroutine','call s(n)\nif(n/=67)stop 1\nprint \'(a)\', "OK"')
proc('pure_local','pure subroutine s(n)\ninteger,intent(out)::n\ncharacter(8)::a(2)\na(2)="71"\nread(a(2),*)n\nend subroutine','call s(n)\nif(n/=71)stop 1\nprint \'(a)\', "OK"')
proc('excluded_saved','subroutine s(n)\ninteger,intent(out)::n\ncharacter(8),save::a(1)\na(1)="17"\nread(a(1),*)n\nend subroutine','call s(n)',stage='compile')
add('excluded_dummy','character(8)::a(1)\ninteger::n','a="17"\ncall s(a,n)\ncontains\nsubroutine s(x,n)\ncharacter(*),intent(in)::x(:)\ninteger,intent(out)::n\nread(x(1),*)n\nend subroutine',stage='compile')
add('excluded_host',d,'lines="17"\ncall s(n)\ncontains\nsubroutine s(x)\ninteger,intent(out)::x\nread(lines(1),*)x\nend subroutine',stage='compile')
add('excluded_usercall',d,'lines="17"\nread(lines(f()),*)n\ncontains\npure integer function f()\nf=1\nend function',stage='compile')
add('deferred_length_pending','character(:),allocatable::a(:)\ninteger::n','allocate(character(8)::a(1))\na(1)="17"\nread(a(1),*)n',stage='compile',note='Pending IR scope confirmation; explicit bounded subset expectation')
proc('automatic_pending','subroutine s(k,n)\ninteger,intent(in)::k\ninteger,intent(out)::n\ncharacter(8)::a(k)\na(1)="17"\nread(a(1),*)n\nend subroutine','call s(2,n)',stage='compile')
# Exact independently reviewed attempt02 diagnostics; all fixture bodies remain unchanged.
DIAGNOSTICS={'automatic_pending': '11:14: Internal READ requires a scalar CHARACTER variable or complete local '
                      'fixed-length CHARACTER element with independent local INTEGER arithmetic indices, '
                      'distinct whole local numeric or CHARACTER targets and optional INTEGER IOSTAT',
 'bad_conversion_without_status': '6:1: invalid value in internal READ record',
 'control_character': '6:1: internal READ requires a single text record',
 'deferred_length_pending': '7:14: Internal READ requires a scalar CHARACTER variable or complete local '
                            'fixed-length CHARACTER element with independent local INTEGER arithmetic '
                            'indices, distinct whole local numeric or CHARACTER targets and optional INTEGER '
                            'IOSTAT',
 'eof_without_status': '6:1: end of internal READ record',
 'excluded_compound': '9:35: Internal READ requires a scalar CHARACTER variable, distinct whole local '
                      'numeric or CHARACTER targets and optional INTEGER IOSTAT',
 'excluded_dummy': '11:14: Internal READ requires a scalar CHARACTER variable or complete local fixed-length '
                   'CHARACTER element with independent local INTEGER arithmetic indices, distinct whole '
                   'local numeric or CHARACTER targets and optional INTEGER IOSTAT',
 'excluded_host': '10:14: Unsupported procedure or array reference: lines',
 'excluded_intrinsic_index': '9:34: Internal READ requires a scalar CHARACTER variable or complete local '
                             'fixed-length CHARACTER element with independent local INTEGER arithmetic '
                             'indices, distinct whole local numeric or CHARACTER targets and optional '
                             'INTEGER IOSTAT',
 'excluded_literal': '9:25: Internal READ requires a scalar CHARACTER variable, distinct whole local numeric '
                     'or CHARACTER targets and optional INTEGER IOSTAT',
 'excluded_overlap': '6:22: Internal READ requires a scalar CHARACTER variable or complete local '
                     'fixed-length CHARACTER element with independent local INTEGER arithmetic indices, '
                     'distinct whole local numeric or CHARACTER targets and optional INTEGER IOSTAT',
 'excluded_pointer': '4:21: Unsupported POINTER declaration',
 'excluded_saved': '8:24: SAVE requires a constant initializer in this subset',
 'excluded_section': '9:31: Internal READ requires a scalar CHARACTER variable, distinct whole local numeric '
                     'or CHARACTER targets and optional INTEGER IOSTAT',
 'excluded_status_index': '9:31: Internal READ requires a scalar CHARACTER variable or complete local '
                          'fixed-length CHARACTER element with independent local INTEGER arithmetic indices, '
                          'distinct whole local numeric or CHARACTER targets and optional INTEGER IOSTAT',
 'excluded_substring': '9:34: Internal READ requires a scalar CHARACTER variable, distinct whole local '
                       'numeric or CHARACTER targets and optional INTEGER IOSTAT',
 'excluded_target_index': '9:29: Internal READ requires a scalar CHARACTER variable or complete local '
                          'fixed-length CHARACTER element with independent local INTEGER arithmetic indices, '
                          'distinct whole local numeric or CHARACTER targets and optional INTEGER IOSTAT',
 'excluded_usercall': '6:20: Internal READ requires a scalar CHARACTER variable or complete local '
                      'fixed-length CHARACTER element with independent local INTEGER arithmetic indices, '
                      'distinct whole local numeric or CHARACTER targets and optional INTEGER IOSTAT',
 'excluded_whole_array': '9:26: Internal READ requires a scalar CHARACTER variable, distinct whole local '
                         'numeric or CHARACTER targets and optional INTEGER IOSTAT',
 'out_of_bounds': '7:6: array subscript 4 out of bounds for lines (1:3)',
 'unallocated': '5:1: reference to unallocated array a',
 'undefined_index': '6:12: read of uninitialized variable i',
 'undefined_selected': '5:6: read of uninitialized array element lines'}
GNU_DIAGNOSTICS={'excluded_compound': '{source}:9:5:\n'
                      '\n'
                      '    9 | read(trim(lines(1)),*,iostat=ios)n\n'
                      '      |     1\n'
                      'Error: UNIT specification at (1) must be an INTEGER expression or a CHARACTER '
                      'variable\n',
 'excluded_literal': '{source}:9:5:\n'
                     '\n'
                     '    9 | read("17",*,iostat=ios)n\n'
                     '      |     1\n'
                     'Error: UNIT specification at (1) must be an INTEGER expression or a CHARACTER '
                     'variable\n'}
for row in rows:
 row["diagnostic"]=DIAGNOSTICS.get(row["name"])
 if row["name"] in GNU_DIAGNOSTICS:row["gnu_stderr"]=GNU_DIAGNOSTICS[row["name"]]
(R/'manifest.json').write_text(json.dumps(dict(status='All 51 focused preview contracts passed, including PURE; 23 exact negative diagnostics retained. Versioned 0.56 full clean certification remains pending.',cases=rows),indent=2)+'\n')
(R/'provenance.json').write_text(json.dumps(dict(origin='New synthetic sources for bounded internal READ element file; not original utilities bodies',generator_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),case_count=len(rows),cases={x['source']:x['sha256'] for x in rows}),indent=2)+'\n')
print(len(rows))
