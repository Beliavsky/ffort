#!/usr/bin/env python3
"""Complete logical declaration initializers, including PARAMETER arrays."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parent
cases=[]
def add(name,decl,body,want,category='success',baseline='run'):
 source='program p\nimplicit none\n'+decl+'\n'+body+'\nend program p\n'
 path='cases/'+name+'.f90';(ROOT/path).write_text(source)
 cases.append(dict(name=name,source=path,category=category,baseline=baseline,expected_stdout=want))
add('array_not_or','logical,parameter::a(2)=[.true.,.false.]\nlogical,parameter::b(2)=.not.a.or.a','print *,b','T T')
add('array_grouped_not_or','logical,parameter::a(2)=[.true.,.false.]\nlogical,parameter::b(2)=(.not.a).or.a','print *,b','T T')
add('array_or_not','logical,parameter::a(2)=[.true.,.false.]\nlogical,parameter::b(2)=a.or..not.a','print *,b','T T')
add('array_and','logical,parameter::a(2)=[.true.,.false.]\nlogical,parameter::b(2)=a.and..true.','print *,b','T F')
add('scalar_and','logical,parameter::a=.true..and..false.','print *,a','F')
add('scalar_or','logical,parameter::a=.false..or..true.','print *,a','T')
add('scalar_eqv','logical,parameter::a=.false..eqv..false.','print *,a','T')
add('scalar_neqv','logical,parameter::a=.true..neqv..false.','print *,a','T')
add('mixed_multi_declarators','logical,parameter::a=.false..or..true.,b=a.and..false.,c=b.eqv..false.','print *,a,b,c','T F T')
add('mutable_logical_initializer','logical::a=.false..or..true.,b=.true..and..false.','print *,a,b','T F')
add('logical_precedence','logical,parameter::a=.true..or..true..and..false.\nlogical,parameter::b=.not..true..or..true.','print *,a,b','T T')
add('invalid_missing_rhs','logical,parameter::a=.true..and.','print *,a','',category='invalid',baseline='reject')
add('invalid_tail_type','logical,parameter::a=.true..or.1','print *,a','',category='invalid',baseline='reject')
add('invalid_tail_binding','logical,parameter::a=.true..or.missing','print *,a','',category='invalid',baseline='reject')
(ROOT/'manifest.json').write_text(json.dumps(dict(cases=cases),indent=2)+'\n')
