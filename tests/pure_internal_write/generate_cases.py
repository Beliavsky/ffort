from pathlib import Path
import json,hashlib
r=Path(__file__).parent/'cases';r.mkdir(exist_ok=True);rows=[]
def add(name,decl,stmt,kind='pass',whole=None,expected='07\n',gnu='pass'):
 src=whole or ('program p\nimplicit none\nprint "(a)",mark(7)\ncontains\npure function mark(n) result(s)\ninteger,intent(in)::n\ncharacter(2)::s\n'+decl+'\n'+stmt+'\nend function\nend program\n')
 (r/(name+'.f90')).write_text(src);rows.append(dict(name=name,sha256=hashlib.sha256(src.encode()).hexdigest(),kind=kind,gnu=gnu,expected=expected if kind=='pass' else ''))
add('local_result','','write(s,"(i2.2)")n')
add('local_other','character(2)::tmp','write(tmp,"(i2.2)")n\ns=tmp')
add('runtime_format','character(8)::fmt','fmt="(i2.2)"\nwrite(s,fmt)n')
add('named_controls','','write(unit=s,fmt="(i2.2)")n')
add('conditional','','if(n>0)then\nwrite(s,"(i2.2)")n\nelse\ns="00"\nend if')
add('loop','integer::i','do i=1,1\nwrite(s,"(i2.2)")n\nend do')
add('multiple_declaration','character(2)::a,b','write(b,"(i2.2)")n\na=b\ns=a')
add('local_shadow', '', '',whole='module m\ninteger::s\nend module\nprogram p\nuse m\nimplicit none\nprint "(a)",mark(7)\ncontains\npure function mark(n) result(s)\ninteger,intent(in)::n\ncharacter(2)::s\nwrite(s,"(i2.2)")n\nend function\nend program\n')
add('pure_subroutine', '', '',whole='program p\nimplicit none\ncharacter(2)::s\ncall fill(s,7)\nprint "(a)",s\ncontains\npure subroutine fill(s,n)\ncharacter(*),intent(out)::s\ninteger,intent(in)::n\nwrite(s,"(i2.2)")n\nend subroutine\nend program\n')
add('external_star','','write(*,"(i2.2)")n\ns="07"',kind='reject',gnu='fail')
add('external_integer','integer::u','u=6\nwrite(u,"(i2.2)")n\ns="07"',kind='reject',gnu='fail')
add('external_literal','','write(6,"(i2.2)")n\ns="07"',kind='reject',gnu='fail')
add('external_named','','write(unit=*,fmt="(i2.2)")n\ns="07"',kind='reject',gnu='fail')
add('external_nested_if','','if(n>0)then\nwrite(*,"(i2.2)")n\nend if\ns="07"',kind='reject',gnu='fail')
add('external_nested_do','integer::i','do i=1,1\nwrite(*,"(i2.2)")n\nend do\ns="07"',kind='reject',gnu='fail')
add('constant_target','character(2),parameter::t="00"','write(t,"(i2.2)")n\ns="07"',kind='reject',gnu='fail')
add('saved_target','character(2),save::t','write(t,"(i2.2)")n\ns="07"',kind='reject',gnu='fail')
add('initialized_target','character(2)::t="00"','write(t,"(i2.2)")n\ns="07"',kind='reject',gnu='fail')
add('intent_in_target', '', '',kind='reject',gnu='fail',whole='program p\nimplicit none\ncall fill("00",7)\ncontains\npure subroutine fill(s,n)\ncharacter(*),intent(in)::s\ninteger,intent(in)::n\nwrite(s,"(i2.2)")n\nend subroutine\nend program\n')
add('host_target', '', '',kind='reject',gnu='fail',whole='program p\nimplicit none\ncharacter(2)::t\nprint "(a)",mark(7)\ncontains\npure function mark(n) result(s)\ninteger,intent(in)::n\ncharacter(2)::s\nwrite(t,"(i2.2)")n\ns="07"\nend function\nend program\n')
add('wrong_scope_character', '', '',kind='reject',gnu='fail',whole='program p\nimplicit none\nprint "(a)",mark(7)\ncontains\nsubroutine unrelated()\ncharacter(2)::u\nend subroutine\npure function mark(n) result(s)\ninteger,intent(in)::n\ninteger::u\ncharacter(2)::s\nu=6\nwrite(u,"(i2.2)")n\ns="07"\nend function\nend program\n')
add('local_allocatable','character(:),allocatable::t','t="00"\nwrite(t,"(i2.2)")n\ns=t')
add('volatile_target','character(2),volatile::t','write(t,"(i2.2)")n\ns="07"',kind='reject',gnu='fail')
diagnostics = {'external_star': {'line': 13, 'column': 1, 'message': 'External side effects inside ordinary functions are unsupported'}, 'external_integer': {'line': 14, 'column': 1, 'message': 'External side effects inside ordinary functions are unsupported'}, 'external_literal': {'line': 9, 'column': 7, 'message': 'WRITE unit must be * or a supported declared variable'}, 'external_named': {'line': 13, 'column': 1, 'message': 'External side effects inside ordinary functions are unsupported'}, 'external_nested_if': {'line': 15, 'column': 1, 'message': 'External side effects inside ordinary functions are unsupported'}, 'external_nested_do': {'line': 15, 'column': 1, 'message': 'External side effects inside ordinary functions are unsupported'}, 'constant_target': {'line': 9, 'column': 7, 'message': 'Internal WRITE requires a writable scalar CHARACTER variable'}, 'saved_target': {'line': 8, 'column': 21, 'message': 'SAVE requires a constant initializer in this subset'}, 'initialized_target': {'line': 8, 'column': 17, 'message': 'PURE/SIMPLE procedures cannot declare SAVE or initialized mutable locals'}, 'intent_in_target': {'line': 8, 'column': 7, 'message': 'Internal WRITE requires a writable scalar CHARACTER variable'}, 'host_target': {'line': 9, 'column': 7, 'message': 'Internal WRITE requires a declared CHARACTER variable'}, 'wrong_scope_character': {'line': 17, 'column': 1, 'message': 'External side effects inside ordinary functions are unsupported'}, 'volatile_target': {'line': 8, 'column': 14, 'message': 'Unsupported declaration attribute'}}
for row in rows:
 if row['kind']=='reject': row['diagnostic']=diagnostics[row['name']]
(r.parent/'manifest.json').write_text(json.dumps(rows,indent=2)+'\n');print(len(rows))
