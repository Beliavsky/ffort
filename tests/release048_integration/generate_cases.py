#!/usr/bin/env python3
from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parent
(ROOT/'cases').mkdir(exist_ok=True)
CASES=[]
def program(decl,body):return 'program p\nimplicit none\n'+decl+'\n'+body+'\nend program\n'
def module(body,call):return 'module m\nimplicit none\ncontains\n'+body+'\nend module\nprogram p\nuse m\nimplicit none\n'+call+'\nend program\n'
def add(name,source,out,features,category='success',gnu='run',diagnostic=None,note=None):
 p=ROOT/'cases'/(name+'.f90');p.write_bytes(source.encode())
 c=dict(name=name,source='cases/'+p.name,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),category=category,gnu=gnu,expected_stdout=out,features=features)
 if diagnostic:
  line,message,column=diagnostic;c.update(diagnostic=message,diagnostic_line=source.splitlines().index(line)+1,diagnostic_column=column)
 if note:c['oracle_note']=note
 CASES.append(c)
def bits(value,kind,base,width=0,minimum=1):
 raw=format(value%(1<<(8*kind)),{'b':'b','o':'o','z':'X'}[base])
 if value==0 and minimum==0:raw=''
 size=max(len(raw),minimum);w=width or max(1,size)
 return '*'*w if size>w else ' '*(w-size)+'0'*(size-len(raw))+raw
add('deferred_scalar_bit_records',program('character(:),allocatable::s,a(:)\ninteger::i',"s='Ab '\na=[s,s]\nprint '(*(a))','[',a,']'\nprint '(z8.8,b4.4)',not(0),iand(15,5)"),'[Ab Ab ]\nFFFFFFFF0101\n',['runtime CHAR length','untyped constructor','NOT/IAND','B/Z'])
add('assumed_length_variable_calls',module('''subroutine show(s,n)
character(*),intent(in)::s
integer,intent(in)::n
character(len(s))::a(2)
a=[s,s]
print '(*(a))','[',a,']'
print '(o4.4)',ior(n,8)
end subroutine''',"call show('A',1)\ncall show('Bc ',2)"),'[AA]\n0011\n[Bc Bc ]\n0012\n',['assumed length per frame','IOR octal','different calls'])
add('dynamic_array_alias_snapshot',program('character(:),allocatable::a(:)\ninteger::i',"a=['AB','cd']\na=[(a,i=1,2)]\nprint '(*(a))','[',a,']'\nprint '(4z2.2)',[(ieor(i,3),i=0,3)]"),'[ABcdABcd]\n03020100\n',['descriptor array constructor','self assignment snapshot','constructor index','IEOR'])
add('descriptor_concat_bit_index',module('''subroutine show(s)
character(*),intent(in)::s(:)
character(4)::a(2)
integer::i
a=[(s(1)//s(2),i=1,2)]
print '(*(a))',a
print '(2b4.4)',[(ior(i,8),i=1,2)]
end subroutine''',"call show(['ab','CD'])"),'abCDabCD\n10011010\n',['descriptor concatenation','separate index owners','IOR/B'])
add('bit_size_dynamic_length',program('integer::undefined\ncharacter(:),allocatable::s,a(:)',"s=repeat('x',bit_size(undefined)/8)\na=[s,s]\nprint '(2i3)',len(a),bit_size(undefined)\nprint '(*(a))','[',a,']'"),'  4 32\n[xxxxxxxx]\n',['BIT_SIZE undefined metadata','runtime length','constructor'])
add('bit_size_array_broadcast',program('integer::i\ninteger(8)::a(3),undefined(2)\ncharacter(:),allocatable::s,v(:)',"a=[1_8,2_8,3_8]+bit_size(undefined)\ns='K'\nv=[s,s,s]\nprint '(*(a,z2.2))',(v(i),a(i),i=1,3)"),'K41K42K43\n',['BIT_SIZE scalar broadcast','INTEGER8','output impliedDO','dynamic CHAR']),
add('runtime_format_array_element',program('character(:),allocatable::s,f(:)\ncharacter(12)::out',"s='(z8.8)'\nf=[s,s]\nwrite(out,f(2))not(0)\nprint '(a,a,a)','[',out,']'"),'[FFFFFFFF    ]\n',['runtime constructor format','FMT element boundary','NOT/Z'],category='reject',gnu='compile',diagnostic=("write(out,f(2))not(0)",'Runtime format requires a whole scalar CHARACTER variable',11))
CASES[-1]['expected_stdout']=''
add('runtime_format_scalar_staging',program('character(:),allocatable::s,f(:)\ncharacter(12)::out\ncharacter(16)::fmt',"s='(z8.8)'\nf=[s,s]\nfmt=f(2)\nwrite(out,fmt)not(0)\nprint '(a,a,a)','[',out,']'"),'[FFFFFFFF    ]\n',['descriptor constructor format','whole scalar format staging','internal padding','NOT/Z'])
add('nonadvancing_preserved_suffix',program('character(:),allocatable::s,a(:)',"s='ABCDEFGH'\na=[s]\nwrite(*,'(a,t3,z2.2)',advance='no')a(1),ior(8,7)\nwrite(*,'(tr1,b2.2)')iand(3,1)"),'AB0FE01H\n',['dynamic CHAR output','nonadvancing cursor','T/TR','IOR/IAND'])
add('tl_bit_overwrite_constructor',program('character(:),allocatable::s,a(:)',"s='abcdefgh'\na=[s]\nprint '(a,tl4,z2.2,tr1,b2.2)',a,ieor(7,8),1"),'abcd0Fg01\n',['descriptor constructor','TL overwrite','suffix retention','IEOR'])
add('bit_test_vector_positions',program('integer::i,a(4)\nlogical::v(4)\ncharacter(:),allocatable::s,c(:)',"a=[1,2,4,8]\nv=btest(a,[0_8,1_8,2_8,3_8])\ns='Y '\nc=[(s,i=1,4)]\nprint '(*(l1,a))',(v(i),c(i),i=1,4)"),'TY TY TY TY \n',['BTEST independent POS kinds','array shapes','dynamic CHAR impliedDO'])
add('bits_rank_three_surrounding',program('integer::a(2,1,2)\ncharacter(:),allocatable::s,c(:)',"a(:,1,1)=[1,2]\na(:,1,2)=[3,4]\na=ior(a,8)+bit_size(a)\ns='>'\nc=[s]\nprint '(a,4z2.2)',c,a"),'>292A2B2C\n',['rank3 bit scalar expansion','BIT_SIZE scalar expansion','dynamic CHAR prefix'])
add('wide_integer_exact_hex',program('integer(8)::x\ncharacter(:),allocatable::s,c(:)',"x=9007199254740993_8\ns='wide='\nc=[s]\nprint '(a,z16.16)',c,ieor(x,2_8)"),'wide=0020000000000003\n',['INTEGER beyond binary64 exact','IEOR','dynamic CHAR prefix'])
add('empty_bit_operands_no_data',program('integer::x,a(0)\nlogical::b(0)\ncharacter(:),allocatable::s,c(:)',"a=iand(a,x)\nb=btest(a,x)\ns=''\nc=[s,s]\nprint '(3i2)',size(a),size(b),len(c)\nprint '(*(a))','[',c,']'"),' 0 0 0\n[]\n',['empty elementwise does not read scalar','length0 descriptors','constructor'])
add('kind_bit_metadata_no_read',program('integer(8)::x\ncharacter(:),allocatable::s,c(:)',"s='M'\nc=[s]\nprint '(a,3i3)',c,kind(not(x)),kind(btest(x,999)),bit_size(x)"),'M  8  4 64\n',['KIND metadata ignores data/POS value','BIT_SIZE','dynamic prefix'],gnu='known-reject',note='GNU14 diagnoses a constant invalid POS even under metadata-only KIND; not execution agreement.')
CASES[-1]['gnu_compile_diagnostic']='must be less than BIT_SIZE'
add('kind_bit_dynamic_position_no_read',program('integer(8)::x\ninteger::pos\ncharacter(:),allocatable::s,c(:)',"s='M'\nc=[s]\nprint '(a,3i3)',c,kind(not(x)),kind(btest(x,pos)),bit_size(x)"),'M  8  4 64\n',['KIND metadata ignores undefined data/POS','BIT_SIZE','dynamic prefix'])
add('zero_width_blank_cursor',program('character(:),allocatable::s,c(:)',"s='ABCD'\nc=[s]\nprint '(a,t2,z0.0,a)',c,iand(1,2),'!'"),'A !D\n',['zero bit result','Z0.0 blank','backward overwrite'])
add('ordinary_group_reversion_bits',program('integer::a(3)\ncharacter(:),allocatable::s,c(:)',"s='go'\nc=[s]\nprint '(a)',c\na=ior([1,2,3],8)\nprint '(2(z4.2))',a"),'go\n  09  0A\n  0B\n',['ordinary group reversion','array IOR','descriptor prefix'])
line="print fmt,1.0"
add('real_boz_subset_atomic',program('character(:),allocatable::s,c(:)\ncharacter(8)::fmt',"s='SAFE'\nc=[s]\nwrite(*,'(a)',advance='no')c\nfmt='(z0)'\n"+line),'SAFE',['REAL BOZ standard-valid subset exclusion','pending prefix atomic'],category='runtime',gnu='compile',diagnostic=(line,'PRINT format descriptor and item type differ',1))
line="print fmt,ior(1,2)"
add('slash_retained_boundary',program('character(:),allocatable::s,c(:)\ncharacter(12)::fmt',"s='SAFE'\nc=[s]\nprint '(a)',c\nfmt='(z2,/)'\n"+line),'SAFE\n 3\n\n',['slash supported in 0.49','dynamic FMT','IOR'])
line="print '(*(b0.1024))',a"
add('record_cap_pending_atomic',program('integer::a(65)\ncharacter(:),allocatable::s,c(:)',"s='SAFE'\nc=[s]\nwrite(*,'(a)',advance='no')c\na=ior(0,1)\n"+line),'SAFE',['bit array result','65536 record cap','pending prefix unchanged'],category='runtime',gnu='compile',diagnostic=(line,'formatted output exceeds 65536 characters',1))
line="print '(a,l1)',c,btest(1,pos)"
add('btest_pos_record_atomic',program('integer::pos\ncharacter(:),allocatable::s,c(:)',"s='DROP'\nc=[s]\nprint '(a)','SAFE'\npos=32\n"+line),'SAFE\n',['BTEST invalid evaluated position','dynamic constructor item staged'],category='runtime',gnu='compile',diagnostic=(line,'BTEST POS outside bit width',17))
line='c=[s,t]'
add('constructor_mismatch_pending_atomic',program('character(:),allocatable::s,t,c(:)',"s='AA'\nt='B'\nwrite(*,'(z2.2)',advance='no')ior(8,7)\n"+line),'0F',['dynamic constructor mismatch','bit prefix atomic'],category='runtime',gnu='compile',diagnostic=(line,'CHARACTER constructor item lengths differ',3))
add('machine_minimum_z_zero_minimum',program('integer(8)::x\ncharacter(:),allocatable::s,c(:)',"x=-huge(0_8)\nx=x-1_8\ns='['\nc=[s]\nprint '(a,z0.0,a)',c,ior(x,0_8),']'"),'[8000000000000000]\n',['machine minimum representation','IOR','Z0.0'],gnu='compile',note='Processor-specific machine boundary outside the symmetric arithmetic model. GNU14 Z m=0 blanks this nonzero high-bit value; compile-only, independently exact bit oracle.')
# Timing owner confirmed these whole-scalar actual-host contracts. No sampled
# time/count is compared between processes; exact records report assertions only.
add('host_clock_bit_size_descriptor',program('integer(8)::c,r,m\ncharacter(:),allocatable::s,a(:)',"call system_clock(c,r,m)\nif(r==0)then\n if(m/=0.or.c/=-huge(c))stop 1\nelse\n if(r<0.or.m<0.or.c<0.or.c>m)stop 2\nend if\ns='CLOCK '\na=[s]\nprint '(a,z2.2)',a,bit_size(c)"),'CLOCK 40\n',['actual host SYSTEM_CLOCK contract','BIT_SIZE kind8','runtime CHAR descriptor'])
add('host_cpu_constructor_interval',program('real(8)::a,b\ninteger::i,n\ncharacter(:),allocatable::s,c(:)',"call cpu_time(a)\nn=0\ndo i=0,31\n n=ieor(n,i)\nend do\ns='CPU '\nc=[s,s]\ncall cpu_time(time=b)\nif(.not.(abs(a)<=huge(a)).or..not.(abs(b)<=huge(b)))stop 1\nif(a>=0.and.b>=0.and.b<a)stop 2\nprint '(*(a))',c\nprint '(z8.8)',n"),'CPU CPU \n00000000\n',['actual CPU samples','finite/nondecrease assertions only','IEOR interval work','dynamic CHAR'])
add('host_clock_absent_count_pending',module("""subroutine sample(c,r,m)
integer(8),intent(out),optional::c
integer(8),intent(out)::r,m
call system_clock(count=c,count_rate=r,count_max=m)
end subroutine""","integer(8)::r,mx\ncharacter(:),allocatable::s,c(:)\ns='ABCD'\nc=[s]\nwrite(*,'(a,t2,z2.2)',advance='no')c,ior(8,7)\ncall sample(r=r,m=mx)\nif(r==0)then\n if(mx/=0)stop 1\nelse\n if(r<0.or.mx<0)stop 2\nend if\nwrite(*,'(a)')'!'"),'A0F!\n',['forward absent optional COUNT','actual clock rate/max','pending cursor','bit format'],gnu='compile',note='GNU14.2 SIGSEGV at -O0/-O2 forwarding absent COUNT with present RATE/MAX. Independent absent-OPTIONAL contract; no GNU execution agreement.')
# Preserve both original OUT-named probes; source bytes are unchanged. OUT is
# still reserved by the baseline parser. Separately named buffer counterparts
# reach the intended FMT expression boundary and positive scalar-staging path.
for original,new_name in [('runtime_format_array_element','runtime_format_array_element_buffer'),('runtime_format_scalar_staging','runtime_format_scalar_staging_buffer')]:
 c=next(c for c in CASES if c['name']==original)
 source=(ROOT/c['source']).read_text().replace('::out','::buf').replace('write(out,','write(buf,').replace(",'[',out,']'",",'[',buf,']'")
 if original=='runtime_format_array_element':
  add(new_name,source,'',['FMT whole-scalar boundary after valid buffer name'],category='reject',gnu='compile',diagnostic=("write(buf,f(2))not(0)",'Internal WRITE requires a literal format or scalar CHARACTER name',11))
 else:
  add(new_name,source,'[FFFFFFFF    ]\n',['runtime constructor','whole-scalar FMT staging','internal NOT/Z padding'])
 c.update(category='reject',gnu='compile',expected_stdout='',diagnostic='Keyword/intrinsic names are reserved in this prototype',diagnostic_line=4,diagnostic_column=16)
 c['features'].append('preserved existing reserved OUT identifier boundary')
next(c for c in CASES if c['name']=='btest_pos_record_atomic')['diagnostic_column']=18
(ROOT/'manifest.json').write_text(json.dumps(dict(schema=1,cases=CASES),indent=2)+'\n')
(ROOT/'SOURCE-IDENTITY.json').write_text(json.dumps(dict(sources=[dict(name=c['name'],file=c['source'],sha256=c['sha256']) for c in CASES],inputs=[]),indent=2)+'\n')
print(len(CASES))
