from pathlib import Path
import json,hashlib
R=Path(__file__).resolve().parent;cases=[]
MODULE="module m\nimplicit none\ntype::box\n integer::x=3\ncontains\n procedure::text\nend type\ncontains\ncharacter(2) function text(this) result(s)\n class(box),intent(in)::this\n write(s,'(i2.2)')this%x\nend function\ncharacter(2) function plain(b) result(s)\n type(box),intent(in)::b\n write(s,'(i2.2)')b%x\nend function\ncharacter(2) function number(n) result(s)\n integer,intent(in)::n\n write(s,'(i2.2)')n\nend function\nfunction make(n) result(b)\n integer,intent(in)::n\n type(box)::b\n b=box(n)\nend function\nrecursive function chain(n) result(b)\n integer,intent(in)::n\n type(box)::b\n if(n==0)then\n  b=box(3)\n else\n  b=chain(n-1)\n endif\nend function\ncharacter(2) function forbidden(b) result(s)\n type(box),intent(in)::b\n error stop 77\n s='NO'\nend function\nend module\nprogram p\nuse m\nimplicit none\ntype(box)::b,c\ncharacter(2)::a(2)\ninteger::i\nb=box(3)\nc=box(6)\n"
def add(n,expr,stage='success',out='0303\n'):
 p=R/'cases'/(n+'.f90');p.write_text(MODULE+'a=['+expr+','+expr+']\nwrite(*,"(2a)")a\nend program\n');cases.append(dict(name=n,source='cases/'+p.name,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),stage=stage,gnu='run',expected=out,diagnostic=None,integer_records=[]))
add('ordinary_abs','number(abs(b%x))')
add('ordinary_max','number(max(b%x,1))')
add('ordinary_sum','number(sum([b%x]))')
add('kind_nested_in_character','number(kind(b%x))',stage='runtime',out='')
p=R/'cases/direct_component_kind.f90';p.write_text(MODULE+'write(*,"(i0)")kind(b%x)\nend program\n');cases.append(dict(name='direct_component_kind',source='cases/'+p.name,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),stage='runtime',gnu='run',expected='',gnu_expected='4\n',diagnostic=None,integer_records=[]))
for name,control,column in [('nested_eoshift_component','b%x',48),('nested_eoshift_ancestor','abs(b%x)',52)]:
 p=R/'cases'/(name+'.f90')
 p.write_text(MODULE+"write(*,'(i0)')len([number(sum(eoshift([1,2],"+control+")))])\nend program\n")
 cases.append(dict(name=name,source='cases/'+p.name,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),stage='runtime',gnu='run',expected='',gnu_expected='2\n',diagnostic='49:'+str(column)+': invalid KIND argument opcode',integer_records=[]))
for c in cases:
 if c['name']=='kind_nested_in_character':c['gnu_expected']='0404\n'
for name,line,column in [('move_read_eoshift_vector',18,26),('metadata_no_read_default_kind',14,20)]:
 p=R/'source'/(name+'.f90');c=dict(name='original_'+name,source='source/'+p.name,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),stage='runtime',gnu='compile',expected='',diagnostic=str(line)+':'+str(column)+': invalid KIND argument opcode',integer_records=[])
 if name=='move_read_eoshift_vector':c['inputs']=[{'unit':27,'file':'inputs/move_read_eoshift_vector_27.dat'}]
 cases.append(c)
PINS={'kind_nested_in_character': '49:18: invalid KIND argument opcode', 'direct_component_kind': '49:23: invalid KIND argument opcode'}
for c in cases:
 if c["name"] in PINS:c["diagnostic"]=PINS[c["name"]]
(R/'manifest.json').write_text(json.dumps({'cases':cases},indent=2)+'\n');print(len(cases),'cases')
