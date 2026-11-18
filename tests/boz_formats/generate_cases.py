#!/usr/bin/env python3
from pathlib import Path
import json,hashlib
ROOT=Path(__file__).resolve().parent
(ROOT/'cases').mkdir(exist_ok=True)
CASES=[]
def program(decl,body):return 'program p\nimplicit none\n'+decl+'\n'+body+'\nend program\n'
def add(name,source,out,features,category='success',gnu='run',diagnostic=None):
 p=ROOT/'cases'/(name+'.f90');p.write_text(source)
 c=dict(name=name,source='cases/'+p.name,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),category=category,gnu=gnu,expected_stdout=out,features=features)
 if diagnostic:
  line,message=diagnostic;c.update(diagnostic=message,diagnostic_line=source.splitlines().index(line)+1,diagnostic_column=1)
 CASES.append(c)
def bitfield(value,kind,base,width=0,digits=None):
 # Independent mathematical oracle: unsigned residue modulo declared bit width.
 u=value%(1<<(8*kind));raw=format(u,{'b':'b','o':'o','z':'X'}[base])
 if value==0 and digits==0:raw=''
 n=max(len(raw),digits if digits is not None else 1)
 w=width or max(n,1)
 return '*'*w if n>w else ' '*(w-n)+'0'*(n-len(raw))+raw
for base in ['b','o','z']:
 for kind in [4,8]:
  bits=8*kind;lo=-(1<<(bits-1));hi=-lo-1
  vals=[lo,lo+1,-2,-1,0,1,15,16,hi]
  full={'b':bits,'o':(bits+2)//3,'z':bits//4}[base]
  forms=[(0,None),(0,0),(0,4),(0,1024),(4,None),(8,4),(full,full),(1,0),(1024,0)]
  setup=[]
  for i,v in enumerate(vals,1):
   if v==lo:setup += [f'a({i})=-huge(0_{kind})',f'a({i})=a({i})-1_{kind}']
   else:setup.append(f'a({i})={v}_{kind}')
  for index,(width,digits) in enumerate(forms):
   desc=base.upper()+str(width)+('' if digits is None else '.'+str(digits))
   src=program(f'integer({kind})::a(9)\ninteger::i','\n'.join(setup)+f'\ndo i=1,9\nprint \'(a,{desc},a)\',"[",a(i),"]"\nend do')
   out=''.join('['+bitfield(v,kind,base,width,digits)+']\n' for v in vals)
   add(f'{base}_kind{kind}_form{index}',src,out,['mathematical bit oracle','negative/high-bit/machine endpoint','width/minimum digits','exact padding'])
add('mixed_reversion',program('integer::a(3)','a=[1,15,16]\nprint \'(i3,1x,z2.2,1x,b5.5)\',a(1),a(2),a(3),a(3),a(2),a(1)'), '  1 0F 10000\n 16 0F 00001\n',['mixed data descriptors','ordinary reversion'])
add('group_reversion',program('integer::a(3)','a=[1,15,16]\nprint \'(2(z4.2))\',a'),'  01  0F\n  10\n',['repeated group','last group reversion'])
add('unlimited_colon',program('integer::a(4)',"a=[0,1,15,-1]\nprint '(*(z0,:,\":\"))',a"),'0:1:F:FFFFFFFF\n',['unlimited repetition','colon exhaustion'])
add('nested_repeat_groups',program('integer::a(4)',"a=[1,2,3,4]\nprint '(2(2b4.4))',a"),'0001001000110100\n',['nested repeat groups'])
add('rank_two_storage_order',program('integer::a(2,2)',"a=reshape([1,2,3,4],[2,2])\nprint '(*(o2.2))',a"),'01020304\n',['array storage order','unlimited octal'])
add('constructor_implied_do',program('integer::i',"i=99\nprint '(*(b4.4))',[(i,i=0,3)]\nprint '(i0)',i"),'0000000100100011\n99\n',['constructor index ownership','formatted array expansion'])
add('output_implied_do',program('integer::i',"print '(*(z2.2))',(i,i=1,4)"),'01020304\n',['output implied-DO','bit formatting'])
add('named_parameter_format',program('character(*),parameter::fmt="(a,z8.8,a)"',"print fmt,'[',-1,']'"),'[FFFFFFFF]\n',['named PARAMETER format','INTEGER4 negative width'])
add('runtime_format',program('character(20)::fmt',"fmt='(a,o0.12,a)'\nwrite(*,fmt=fmt)'[',-1,']'"),'[037777777777]\n',['runtime format','named FMT','octal minimum digits'])
add('internal_character_padding',program('character(16)::s',"s='UNCHANGED'\nwrite(s,'(z8.8)')-1\nprint '(a,a,a)','[',s,']'"),'[FFFFFFFF        ]\n',['internal WRITE','fixed target blank padding'])
add('backward_overwrite',program('',"print '(a,t3,z2.2,a)','ABCDEFGH',15,'!'"),'AB0F!FGH\n',['positioning','preserved suffix'])
add('nonadvancing_overwrite',program('',"write(*,'(a,t3,z2.2)',advance='no')'ABCDEFGH',15\nwrite(*,'(a)')'!'"),'AB0F!FGH\n',['nonadvancing cursor','pending suffix','atomic record staging'])
add('tl_tr_position',program('',"print '(a,tl4,z2.2,tr1,b2.2)','abcdefgh',15,1"),'abcd0Fg01\n',['TL/TR','backward overwrite','retained skip'])
add('zero_blank_position',program('',"print '(a,z0.0,a)','[',0,']'\nprint '(a,t2,z0.0,a)','ABCD',0,'!'"),'[ ]\nA !D\n',['one blank zero-width zero','zero-bit blank transfer'])
add('empty_array',program('integer::a(0)',"print '(*(z0))',a"),'\n',['empty output list','data edit exhaustion'])
add('exact_output_cap',program('integer::a(64)',"a=1\nprint '(*(b0.1024))',a"),('0'*1023+'1')*64+'\n',['exact65536 output cap','minimum digits zero width'])
# Runtime FORMAT strings keep GNU syntax checking separate from the interpreter
# diagnostic oracle; these sources are only compiled by GNU, never executed.
invalid=[('missing_width','(b)','B/O/Z descriptors require width and optional minimum digits'),('missing_minimum','(o3.)','B/O/Z descriptors require width and optional minimum digits'),('minimum_exceeds_width','(z2.3)','B/O/Z minimum digits must not exceed a positive width'),('width_cap','(b1025)','PRINT format width must be between 1 and 1024'),('minimum_cap','(o0.1025)','invalid PRINT format descriptor syntax'),('negative_width','(z-1)','invalid PRINT format descriptor syntax'),('negative_minimum','(b8.-1)','invalid PRINT format descriptor syntax'),('real_precision_suffix','(z8.2e3)','invalid PRINT format descriptor syntax'),('repeat_zero','(0b8)','invalid PRINT format repeat count'),('repeat_cap','(65537z1)','invalid PRINT format repeat count'),('nested_unlimited','(2(*(z0)))','unlimited format item requires a final outer-level *(...) group')]
for name,fmt,message in invalid:
 line="print fmt,1";src=program('character(40)::fmt',f"fmt='{fmt}'\nprint '(a)','SAFE'\n"+line)
 add(name,src,'SAFE\n',['runtime format validation','prior output atomicity'],category='runtime',gnu='compile',diagnostic=(line,message))
line='print fmt,1.0';src=program('character(8)::fmt',"fmt='(b0)'\nprint '(a)','SAFE'\n"+line)
add('real_item_subset',src,'SAFE\n',['INTEGER-only bounded BOZ editing','standard permits REAL but subset does not'],category='runtime',gnu='compile',diagnostic=(line,'PRINT format descriptor and item type differ'))
line="print '(*(b0.1024))',a";src=program('integer::a(65)',"a=1\nwrite(*,'(a)',advance='no')'SAFE'\n"+line)
add('output_cap_atomic',src,'SAFE',['output cap','nonadvancing prefix unaffected'],category='runtime',gnu='compile',diagnostic=(line,'formatted output exceeds 65536 characters'))
# Preserve machine-minimum probes exactly. GNU14 O/Z with m=0 blanks the
# 64-bit high-bit-only representation. This processor-specific machine boundary
# is outside the standard symmetric integer arithmetic model; it is not counted
# as GNU execution agreement. Separate symmetric-range sources agree with GNU.
for base in ['o','z']:
 for index,width in [(1,0),(7,1),(8,1024)]:
  name=f'{base}_kind8_form{index}'
  c=next(x for x in CASES if x['name']==name)
  c['gnu']='compile';c['oracle_note']='GNU14 machine-minimum O/Z m=0 discrepancy; independent fixed-width bit oracle'
  source=(ROOT/c['source']).read_text().replace('a(1)=-huge(0_8)\na(1)=a(1)-1_8','a(1)=-huge(0_8)').replace('a(2)=-9223372036854775807_8','a(2)=-42_8')
  vals=[-9223372036854775807,-42,-2,-1,0,1,15,16,9223372036854775807]
  out=''.join('['+bitfield(v,8,base,width,0)+']\n' for v in vals)
  add(f'{base}_kind8_symmetric_form{index}',source,out,['standard symmetric range','m=0','separate GNU agreement'])
(ROOT/'manifest.json').write_text(json.dumps(dict(schema=1,cases=CASES),indent=2)+'\n')
(ROOT/'SOURCE-IDENTITY.json').write_text(json.dumps(dict(sources=[dict(name=c['name'],file=c['source'],sha256=c['sha256']) for c in CASES],inputs=[]),indent=2)+'\n')
print(len(CASES))
