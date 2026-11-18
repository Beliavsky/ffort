from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parent
cases=[]
def add(name,source,expected='',category='success',gnu='run',**kw):
 source=source.lstrip('\n');p=ROOT/'cases'/(name+'.f90');p.parent.mkdir(exist_ok=True);p.write_text(source)
 row=dict(name=name,source='cases/'+p.name,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),category=category,gnu=gnu,expected_stdout=expected)
 if category!='success':row.update(diagnostic='PENDING',diagnostic_line=1,diagnostic_column=1)
 row.update(kw);cases.append(row)
def program(use,body,decl=''):
 return 'program p\n'+use+'\nimplicit none\n'+decl+body+'\nend program\n'
add('exact_user_multiline','use iso_fortran_env, only: output_unit\nimplicit none\nprint*,output_unit\nend\n','6\n',numeric_lines=[0])
add('semicolon_variant','use iso_fortran_env, only: output_unit; implicit none; print*,output_unit; end\n','6\n',numeric_lines=[0])
for name,use,local in [('explicit_nature','use,intrinsic::iso_fortran_env,only:output_unit','output_unit'),('plain_separator','use :: iso_fortran_env,only:out=>output_unit','out'),('plain_alias','use iso_fortran_env,only:out=>output_unit','out'),('explicit_alias','use,intrinsic::iso_fortran_env,only:out=>output_unit','out')]:
 add(name,program(use,"print '(2i4)',"+local+',kind('+local+')'),'   6   4\n')
# OUT is a pre-existing reserved-name boundary; preserve these exact sources.
for c in cases:
 if c['name'] in ('plain_separator','plain_alias','explicit_alias'):
  c.update(category='reject',gnu='compile',expected_stdout='',diagnostic='PENDING',diagnostic_line=1,diagnostic_column=1)
for name,use in [('plain_separator_alias','use :: iso_fortran_env,only:stdout=>output_unit'),('plain_alias_success','use iso_fortran_env,only:stdout=>output_unit'),('explicit_alias_success','use,intrinsic::iso_fortran_env,only:stdout=>output_unit')]:
 add(name,program(use,"write(stdout,'(2i4)') stdout,kind(stdout)"),'   6   4\n')
add('mixed_aliases',program('use iso_fortran_env,only:dp=>real64,output_unit,ik=>int64',"print '(4i4)',output_unit,dp,ik,kind(output_unit)"),'   6   8   8   4\n')
add('parameter_expression',program('use iso_fortran_env,only:output_unit',"print '(i0)',a",'integer,parameter::a=output_unit+1\n'),'7\n')
add('format_write',program('use iso_fortran_env,only:output_unit',"write(output_unit,'(a,i0)') 'unit=',output_unit"),'unit=6\n')
add('list_write_alias',program('use iso_fortran_env,only:u=>output_unit',"write(unit=u,fmt=*) u"),'6\n',numeric_lines=[0])
add('dynamic_nonadvancing',program('use iso_fortran_env,only:u=>output_unit',"fmt='(a,t2,a)'\nwrite(unit=u,fmt=fmt,advance='no') 'ABCD','x'\nwrite(*,'(a)') '!'",'character(12)::fmt\n'),'Ax!D\n')
add('implied_do_write',program('use iso_fortran_env,only:u=>output_unit',"write(u,'(*(i0,:,a))') (i,',',i=1,3)",'integer::i\n'),'1,2,3,\n')
add('host_contained_use',program('use iso_fortran_env,only:u=>output_unit',"call show()\ncontains\nsubroutine show()\nwrite(u,'(a,i0)') 'host=',u\nend subroutine"),'host=6\n')
add('procedure_local_use',program('',"call show()\ncontains\nsubroutine show()\nuse iso_fortran_env,only:u=>output_unit\nimplicit none\nwrite(u,'(a,i0)') 'local=',u\nend subroutine"),'local=6\n')
add('module_import_export','''module io_names
use iso_fortran_env,only:u=>output_unit
implicit none
end module
program p
use io_names,only:u
implicit none
write(u,'(a,i0)') 'module=',u
end program
''','module=6\n')
add('module_procedure_host','''module io_names
use iso_fortran_env,only:u=>output_unit
implicit none
contains
subroutine show()
write(u,'(a,i0)') 'module-host=',u
end subroutine
end module
program p
use io_names,only:show
implicit none
call show()
end program
''','module-host=6\n')
add('private_module_procedure','''module io_names
use iso_fortran_env,only:u=>output_unit
implicit none
private
public::show
contains
subroutine show()
write(u,'(a)') 'private'
end subroutine
end module
program p
use io_names,only:show
implicit none
call show()
end program
''','private\n')
shadow='''module iso_fortran_env
implicit none
integer,parameter::output_unit=77
end module
'''
for name,nature,val in [('source_shadow_plain','',77),('source_shadow_nonintrinsic',',non_intrinsic::',77),('source_shadow_intrinsic',',intrinsic::',6)]:
 add(name,shadow+program('use'+nature+' iso_fortran_env,only:output_unit',"print '(i0)',output_unit"),str(val)+'\n')
add('ordinary_nonintrinsic_module','''module values
implicit none
integer,parameter::a=9
end module
program p
use,non_intrinsic::values,only:a
implicit none
print '(i0)',a
end program
''','9\n')
add('continuation_comments',program('use, & ! nature follows\n intrinsic :: iso_fortran_env, only: &\n u => & ! remote follows\n output_unit',"write(u,'(a)') 'continued'"),'continued\n')
add('read_value_in_pure',program('use iso_fortran_env,only:u=>output_unit',"print '(i0)',get()\ncontains\npure integer function get() result(v)\nv=u\nend function"),'6\n')
add('uninitialized_output_atomicity',program('use iso_fortran_env,only:u=>output_unit',"write(u,'(a)',advance='no') 'SAFE'\nwrite(u,'(i0)') a",'integer::a\n'),'SAFE',category='runtime',gnu='compile')
add('dynamic_format_failure_atomicity',program('use iso_fortran_env,only:u=>output_unit',"fmt='(q)'\nwrite(u,'(a)',advance='no') 'SAFE'\nwrite(u,fmt) 7",'character(3)::fmt\n'),'SAFE',category='runtime',gnu='compile')
# Runtime scalar unit names are promoted below; remaining forms stay compile-only GNU boundaries.
for name,use,body,decl in [
 ('whole_intrinsic_module','use iso_fortran_env',"print '(i0)',output_unit",''),
 ('derived_parameter_unit','use iso_fortran_env,only:u=>output_unit',"write(v,'(a)') 'no'",'integer,parameter::v=u\n'),
 ('runtime_integer_unit','use iso_fortran_env,only:u=>output_unit',"v=u\nwrite(v,'(a)') 'no'",'integer::v\n'),
 ('integer_literal_unit','use iso_fortran_env,only:u=>output_unit',"write(6,'(a)') 'no'",''),
 ('unsupported_error_unit','use iso_fortran_env,only:error_unit',"print '(i0)',error_unit",''),
 ('empty_only','use iso_fortran_env,only:',"print '(a)','ok'",''),
]:
 if name in ('derived_parameter_unit','runtime_integer_unit'):
  add(name,program(use,body,decl),'no\n',category='success',gnu='run')
 else:
  add(name,program(use,body,decl),category='reject',gnu='compile')
add('source_shadow_cannot_route',shadow+program('use iso_fortran_env,only:output_unit',"write(output_unit,'(a)') 'no'"),category='runtime',gnu='compile')
# Standard-invalid inputs with explicit GNU diagnostic evidence, not runtime comparisons.
add('immutable_output_unit',program('use iso_fortran_env,only:output_unit','output_unit=7'),category='reject',gnu='known-reject',gnu_compile_diagnostic='named constant')
add('pure_external_write',program('',"call show()\ncontains\npure subroutine show()\nuse iso_fortran_env,only:u=>output_unit\nwrite(u,'(a)') 'no'\nend subroutine"),category='reject',gnu='known-reject',gnu_compile_diagnostic='internal file')
add('forced_missing_nonintrinsic',program('use,non_intrinsic::iso_fortran_env,only:output_unit',"print '(i0)',output_unit"),category='reject',gnu='known-reject',gnu_compile_diagnostic='cannot open module file')
# Location/message metadata is kept independent of immutable source generation.
meta=ROOT/'diagnostics.json'
if meta.exists():
 for c in cases:c.update(json.loads(meta.read_text()).get(c['name'],{}))
(ROOT/'manifest.json').write_text(json.dumps(dict(cases=cases),indent=2)+'\n')
(ROOT/'SOURCE-IDENTITY.json').write_text(json.dumps(dict(sources=[dict(name=c['name'],file=c['source'],sha256=c['sha256']) for c in cases]),indent=2)+'\n')
