#!/usr/bin/env python3
from pathlib import Path
import json,hashlib
R=Path(__file__).resolve().parent
(R/'cases').mkdir(exist_ok=True)
C=[]
def add(name,src,out,features,category='success',gnu='run',note=''):
 src=src.strip()+'\n';p=R/'cases'/(name+'.f90');p.write_bytes(src.encode())
 c=dict(name=name,source='cases/'+p.name,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),category=category,gnu=gnu,expected_stdout=out,features=features)
 if category!='success':c.update(diagnostic='PENDING immutable candidate',diagnostic_line=1,diagnostic_column=1)
 if note:c['oracle_note']=note
 C.append(c)
def program(decl,body,uses='use iso_fortran_env, only: output_unit'):
 return 'program p\n'+uses+'\nimplicit none\n'+decl+'\n'+body+'\nend program\n'
def box(decl,body,main,extra='',methods=''):
 return 'module m\nimplicit none\ntype::box\n'+decl+'\n'+methods+'end type\n'+extra+'contains\n'+body+'\nend module\n'+program(main[0],main[1],'use m\nuse iso_fortran_env, only: output_unit')
generic='interface repeat\n module procedure user_repeat\nend interface\n'
user='integer function user_repeat(n) result(answer)\ninteger,intent(in)::n\nanswer=n+100\nend function'
add('grouped_fields_bits_records',box('integer::a,b=8,c\ncharacter(3)::s="Ab",t','',('type(box)::x\ninteger::n,u','x%a=1\nx%c=3\nx%t="Q"\nn=x%b\nu=output_unit\nwrite(u,"(a,/,3(i0,1x))")repeat(x%s,2),x%a,leadz(n),x%c')),'Ab Ab \n1 28 3\n',['mixed defaults','CHAR fields','REPEAT','LEADZ','runtime unit','slash'])
add('copy_generic_fallback',box('integer::n=1\ncharacter(3)::s="aB"',user,('type(box)::x,y\ninteger::u','y=x\nx%s="Q"\nu=output_unit\nwrite(u,"(a,/,i0)")repeat(y%s,2),repeat(7)'),generic),'aB aB \n107\n',['deep copy','generic user precedence','intrinsic REPEAT fallback','slash'])
add('fresh_frame_defaults',box('integer::a,b=4\ncharacter(3)::s="cat"','''function make(n) result(answer)
integer,intent(in)::n
type(box)::answer,local
if(local%s/="cat".or.local%b/=4)error stop "fresh"
local%s="owl"
answer%a=n
answer%s=repeat("X",n)
end function''',('type(box)::x,y\ninteger::u','x=make(1)\ny=make(2)\nu=output_unit\nwrite(u,"(a,/,a,/,2i2)")x%s,y%s,x%a,y%a')),'X  \nXX \n 1 2\n',['fresh procedure defaults','returned CHAR copy lifetime','REPEAT','runtime unit'])
add('intent_out_defaults_reentry',box('integer::a,b=8\ncharacter(3)::s="cat"','''subroutine reset(x,n)
type(box),intent(out)::x
integer,intent(in)::n
if(x%b/=8.or.x%s/="cat")error stop "out defaults"
x%a=n
x%s="Q"
end subroutine''',('type(box)::x\ninteger::u,n','x%s="old"\ncall reset(x,2)\ncall reset(x,3)\nn=x%b\nu=output_unit\nwrite(u,"(a,/,2i3)")x%s,x%a,leadz(n)')),'Q  \n  3 28\n',['INTENT OUT resets','mixed undefined/default','LEADZ staged component'])
add('zero_length_fallback',box('integer::n=0\ncharacter(0)::s',user,('type(box)::x\ninteger::u','x%s="discard"\nu=output_unit\nwrite(u,"(a,/,i0)")"["//repeat(x%s,3)//"]",len(x%s)'),generic),'[]\n0\n',['zero-length field','metadata LEN','generic fallback','records'])
add('wide_leadz_default_kind',program('integer(8)::x(4)\ninteger::u','x=[0_8,1_8,2147483648_8,-1_8]\nu=output_unit\nwrite(u,"(4i3,/,i0)")leadz(x),kind(leadz(x))'),' 64 63 32  0\n4\n',['LEADZ INTEGER8 input','default INTEGER result','array','runtime unit'])
add('rank_three_leadz_records',program('integer::x(2,1,2),u','x(:,1,1)=[0,1]\nx(:,1,2)=[2,8]\nu=output_unit\nwrite(u,"(2(i2,1x),/)")leadz(x)'),'32 31\n\n30 28\n\n',['rank3 LEADZ','slash and ordinary reversion','runtime unit'])
add('empty_leadz_constructor',program('integer(8)::a(0)\ninteger::b(0),u\ncharacter(:),allocatable::s','b=leadz(a)\ns=repeat("x",size(b))\nu=output_unit\nwrite(u,"(a,/,i0)")"["//s//"]",kind(b)'),'[]\n4\n',['empty elemental LEADZ','REPEAT zero count','allocatable CHAR','slash'])
add('metadata_leadz_unallocated',program('integer(8),allocatable::a(:)\ninteger::u','u=output_unit\nwrite(u,"(i0,/,a)")kind(leadz(a)),repeat("M",2)'),'4\nMM\n',['KIND non-evaluation','unallocated LEADZ operand','REPEAT','runtime unit'])
add('runtime_format_repeat',box('integer::n=1\ncharacter(3)::s="fmt"','',('type(box)::x\ninteger::u,n\ncharacter(20)::fmt','fmt=repeat("(a,/,i0)",1)\nu=output_unit\nn=x%n\nwrite(u,fmt=fmt)x%s,leadz(n)')),'fmt\n31\n',['CHAR field','runtime format via REPEAT','named FMT','LEADZ'])
add('matching_repeat_specific',box('character(3)::s="Ab"','''character(4) function user_repeat(string,ncopies) result(answer)
character(*),intent(in)::string
integer,intent(in)::ncopies
answer="USER"
end function''',('type(box)::x\ninteger::u','u=output_unit\nwrite(u,"(a,/,i0)")repeat(ncopies=2,string=x%s),leadz(1)'),generic),'USER\n31\n',['matching user specific wins','keyword association','CHAR component','LEADZ'])
add('generic_host_fallback',box('character(2)::s="Z "',user+'''\nsubroutine show(x,u)
type(box),intent(in)::x
integer,intent(in)::u
write(u,"(a,/,i0)")repeat(ncopies=2,string=x%s),repeat(1)
end subroutine''',('type(box)::x\ninteger::u','u=output_unit\ncall show(x,u)'),generic),'Z Z \n101\n',['module generic host visibility','fallback keywords','readonly stdout dummy'])
add('pending_backward_slash',box('character(5)::s="ABCDE"','',('type(box)::x\ninteger::u','u=output_unit\nwrite(u,"(a)",advance="no")x%s\nwrite(u,"(tl2,a,/)",advance="no")"X"\nwrite(u,"(a)")"Z"')),'ABCDEX\nZ\n',['pending record','CHAR default','TL overwrite','slash record reset'])
add('slash_group_reversion',box('character(2)::s="Ab"','',('type(box)::x\ninteger::u,n','u=output_unit\nn=1\nwrite(u,"(a,/,i0)")x%s,leadz(n),repeat("Q",2),leadz(0)')),'Ab\n31\nQQ\n32\n',['ordinary reversion','slash','record component','LEADZ and REPEAT'])
add('colon_skips_internal_slash',box('character(3)::s="xy"','',('type(box)::x\ncharacter(5)::buffer\ninteger::u','write(buffer,"(a,:,/)")x%s\nu=output_unit\nwrite(u,"(a,/,i0)")"["//buffer//"]",leadz(2)')),'[xy   ]\n30\n',['internal scalar file','colon skips slash','CHAR padding','runtime stdout'])
add('slash_nonadvancing_position',box('character(3)::s="ABC"','',('type(box)::x\ninteger::u','u=output_unit\nwrite(u,"(a)",advance="no")x%s\nwrite(u,"(/,t3,a)",advance="no")repeat("D",2)\nwrite(u,"(a)")"E"')),'ABC\n  DDE\n',['nonadvancing record reset','T positioning','REPEAT output','CHAR component'])
methods='contains\nprocedure::emit\ngeneric::write(formatted)=>emit\n'
emit='''subroutine emit(dtv,unit,iotype,v_list,iostat,iomsg)
class(box),intent(in)::dtv
integer,intent(in)::unit
character(*),intent(in)::iotype
integer,intent(in)::v_list(:)
integer,intent(out)::iostat
character(*),intent(inout)::iomsg
write(unit,"(a,i0)",iostat=iostat,iomsg=iomsg)dtv%s,dtv%b
end subroutine'''
add('defined_record_slash_runtime_unit',box('integer::a,b=7\ncharacter(3)::s="DT"',emit,('type(box)::x,y\ninteger::u','x%a=1\ny%a=2\ny%s="QQ"\nu=output_unit\nwrite(u,"(dt,/,dt)")x,y'),methods=methods),'DT 7\nQQ 7\n',['defined formatted child WRITE','mixed defaults','record-owned CHAR','runtime unit','external slash'])
add('coexisting_allocatable_char_array',box('character(2)::s="Hi"','',('type(box)::x\ncharacter(:),allocatable::a(:)\ninteger::u','a=[repeat("x",4),repeat("Y",4)]\nu=output_unit\nwrite(u,"(a,/,2a)")x%s,a')),'Hi\nxxxxYYYY\n',['record plus unrelated allocatable CHAR array','REPEAT','slash','no global heap admission'])
add('leadz_constructor_i8_broadcast',program('integer(8)::a(3)\ninteger::b(3),i,u','a=[(2_8**i,i=0,2)]\nb=leadz(a)+leadz(1_8)\nu=output_unit\nwrite(u,"(3i4,/,i0)")b,kind(leadz(a))'),' 126 125 124\n4\n',['constructor owned index','LEADZ INTEGER8 default-kind result','scalar expansion','slash'])
add('unit_kind8_component_staging',box('integer::a,b=2\ncharacter(4)::s="Wide"','',('type(box)::x\ninteger(8)::u,n','u=int(output_unit,8)\nn=int(x%b,8)\nwrite(u,"(a,/,i0)")x%s,leadz(n)')),'Wide\n62\n',['INTEGER8 runtime unit','mixed field staging','LEADZ width'])
add('component_length_undefined_no_read',box('integer::a,b=3\ncharacter(4)::s','',('type(box)::x\ninteger::u','u=output_unit\nwrite(u,"(i0,/,a)")len(x%s),repeat("_",len(x%s))')),'4\n____\n',['undefined CHAR metadata LEN','REPEAT','runtime output unit','slash'])
add('invalid_unit_before_format',program('integer::u\ncharacter(12)::fmt','write(*,"(a)",advance="no")"SAFE"\nu=99\nfmt="(bad)"\nwrite(u,fmt)leadz(1)'),'SAFE',['unit gate precedes malformed runtime format','pending output preserved'],category='runtime',gnu='compile',note='GNU compile only: executing unit99 would create a native file, forbidden in this suite.')
add('undefined_component_atomic',box('integer::a,b=3\ncharacter(4)::s','',('type(box)::x\ninteger::u','u=output_unit\nwrite(u,"(a)")"SAFE"\nwrite(u,"(a,/,i0)")x%s,leadz(1)')),'SAFE\n',['undefined field read','slash staging atomicity','runtime unit'],category='runtime',gnu='compile',note='Undefined component data is never evaluated by GNU.')
add('generic_repeat_negative_atomic',box('character(3)::s="ABC"',user,('type(box)::x\ninteger::u,n','u=output_unit\nwrite(u,"(a)",advance="no")"SAFE"\nn=-1\nwrite(u,"(a,/,i0)")repeat(x%s,n),repeat(1)'),generic),'SAFE',['fallback count safety','pending record atomicity','generic resolution'],category='runtime',gnu='compile')
add('leadz_component_boundary',box('integer::a,b=2\ncharacter(3)::s="ABC"','',('type(box)::x\ninteger::u','u=output_unit\nwrite(u,"(a,/,i0)")x%s,leadz(x%b)')),'',['retained direct component intrinsic boundary','new CHAR component coexistence'],category='reject',gnu='compile')
add('internal_write_element_boundary',box('integer::a,b=2\ncharacter(3)::s="ABC"','',('type(box)::x\ncharacter(8)::buffer(2)\ninteger::u','write(buffer(1),"(a,i0)")x%s,x%b\nu=output_unit\nwrite(u,"(a)")buffer(1)')),'',['retained utilities line2376 internal file element boundary','CHAR record'],category='reject',gnu='compile')
add('internal_executed_slash_boundary',box('character(3)::s="ABC"','',('type(box)::x\ncharacter(8)::buffer\ninteger::u','u=output_unit\nwrite(u,"(a)")"SAFE"\nwrite(buffer,"(a,/)")x%s')),'SAFE\n',['internal scalar executed slash boundary','external commit preserved'],category='runtime',gnu='compile')
add('absent_runtime_unit', '''module m
implicit none
contains
subroutine show(u)
integer,optional,intent(in)::u
write(u,"(a,/,i0)")repeat("X",2),leadz(1)
end subroutine
end module
program p
use m
implicit none
call show()
end program''','',['absent unit checked before values','REPEAT LEADZ items'],category='runtime',gnu='compile')
(R/'manifest.json').write_text(json.dumps(dict(cases=C),indent=2)+'\n')
(R/'SOURCE-IDENTITY.json').write_text(json.dumps(dict(sources=[dict(name=c['name'],file=c['source'],sha256=c['sha256']) for c in C],inputs=[]),indent=2)+'\n')
print(len(C),'cases generated')
