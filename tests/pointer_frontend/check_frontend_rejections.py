#!/usr/bin/env python3
"""Bounded POINTER source recognizer rejection matrix. Pass interpreter path."""
import pathlib, subprocess, sys, tempfile
exe=str(pathlib.Path(sys.argv[1]).resolve())
def main(decl,body=''):
    return f'program main\n{decl}\n{body}\nend\n'
def proc(decl,body):
    return f'module m\ncontains\nsubroutine f(p)\n{decl}\n{body}\nend subroutine\nend module\nprogram main\nend\n'
cases={
 'scalar':main('integer,pointer::p'),
 'rank_two':main('integer,pointer::p(:,:)'),
 'explicit_shape':main('integer,pointer::p(2)'),
 'logical':main('logical,pointer::p(:)'),
 'character':main('character,pointer::p(:)'),
 'target_and_pointer':main('integer,target,pointer::p(:)'),
 'allocatable_and_pointer':main('integer,allocatable,pointer::p(:)'),
 'initializer':main('integer,pointer::p(:)=>null()'),
 'module_pointer':'module m\ninteger,pointer::p(:)\nend module\nprogram main\nend\n',
 'allocate_pointer':main('integer,pointer::p(:)','allocate(p(2))'),
 'deallocate_pointer':main('integer,pointer::p(:)','deallocate(p)'),
 'ordinary_target':main('integer::a(2)\ninteger,pointer::p(:)','p=>a'),
 'rank_three_target':main('integer,target::a(2,2,2)\ninteger,pointer::p(:)','p=>a(:,1,1)'),
 'allocatable_target':main('integer,target,allocatable::a(:)\ninteger,pointer::p(:)','p=>a'),
 'scalar_target':main('integer,target::a\ninteger,pointer::p(:)','p=>a'),
 'remap':main('integer,target::a(2)\ninteger,pointer::p(:)','p(0:)=>a'),
 'null_mold':main('integer,pointer::p(:)','p=>null(p)'),
 'null_value':main('integer,pointer::p(:)','p=null()'),
 'nullify_many':main('integer,pointer::p(:),q(:)','nullify(p,q)'),
 'associated_many':main('integer,pointer::p(:),q(:)','if(associated(p,q)) stop'),
 'associated_section':main('integer,pointer::p(:)','if(associated(p(:))) stop'),
 'intent_in_reassociate':proc('integer,pointer,intent(in)::p(:)','p=>null()'),
 'intent_in_nullify':proc('integer,pointer,intent(in)::p(:)','nullify(p)'),
 'procedure_read':proc('integer,pointer,intent(in)::p(:)','print *,p'),
 'procedure_element_read':proc('integer,pointer,intent(in)::p(:)','print *,p(1)'),
 'procedure_computed_read':proc('integer,pointer,intent(in)::p(:)','print *,sum(p)'),
 'procedure_size':proc('integer,pointer,intent(in)::p(:)','print *,size(p)'),
 'procedure_lbound':proc('integer,pointer,intent(in)::p(:)','print *,lbound(p,1)'),
 'procedure_kind':proc('integer,pointer,intent(in)::p(:)','print *,kind(p)'),
 'procedure_shape':proc('integer,pointer,intent(in)::p(:)','print *,shape(p)'),
 'procedure_section':proc('integer,pointer,intent(in)::p(:)','print *,p(:)'),
 'procedure_condition':proc('integer,pointer,intent(in)::p(:)','if(sum(p)>0) stop'),
 'procedure_section_bound':proc('integer,pointer,intent(in)::p(:)\ninteger,target::a(4)\ninteger,pointer::q(:)','q=>a(:size(p))'),
 'procedure_section_element_bound':proc('integer,pointer,intent(in)::p(:)\ninteger,target::a(4)\ninteger,pointer::q(:)','q=>a(:p(1))'),
 'procedure_section_stride':proc('integer,pointer,intent(in)::p(:)\ninteger,target::a(4)\ninteger,pointer::q(:)','q=>a(::sum(p))'),
 'procedure_write':proc('integer,pointer,intent(inout)::p(:)','p=1'),
 'pointer_formal_nonpointer_actual':'module m\ncontains\nsubroutine f(p)\ninteger,pointer,intent(in)::p(:)\nend subroutine\nend module\nprogram main\nuse m\ninteger,target::a(2)\ncall f(a)\nend\n',
 'ordinary_formal_pointer_actual':'module m\ncontains\nsubroutine f(p)\ninteger,intent(in)::p(:)\nend subroutine\nend module\nprogram main\nuse m\ninteger,pointer::a(:)\ncall f(a)\nend\n',
 'automatic_target':'module m\ncontains\nsubroutine f(n,p)\ninteger,intent(in)::n\ninteger,pointer,intent(out)::p(:)\ninteger,target::a(n)\np=>a\nend subroutine\nend module\nprogram main\nend\n',
 'function_pointer':'module m\ncontains\nfunction f(p) result(r)\ninteger,pointer,intent(in)::p(:)\ninteger::r\nr=0\nend function\nend module\nprogram main\nend\n',
}
with tempfile.TemporaryDirectory() as d:
 for name,src in cases.items():
    path=pathlib.Path(d)/f'{name}.f90';path.write_text(src)
    p=subprocess.run([exe,str(path)],text=True,capture_output=True)
    expected=2 if name=='associated_many' else 1
    if name=='associated_many':
        checked=subprocess.run([exe,'--check',str(path)],text=True,capture_output=True)
        if checked.returncode!=0 or 'undefined' not in p.stderr:
            raise SystemExit('Promoted ASSOCIATED two-pointer case failed stage/undefined-status check')
    if p.returncode != expected:
        raise SystemExit(f'{name}: expected status{expected}, got{p.returncode}\n{p.stdout}{p.stderr}')
print(f'PASS: {len(cases)-1} POINTER source rejections and 1 promoted ASSOCIATED runtime safety case')
