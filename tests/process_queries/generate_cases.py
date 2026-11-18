#!/usr/bin/env python3
"""Deterministically replay the frozen process-query corpus. Never runs candidates."""
import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT.parent / 'utilities_slices/source/xutilities.f90'
SOURCE_SHA256 = 'c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883'

def digest(data):
    return hashlib.sha256(data).hexdigest()

def build():
    raw = SOURCE.read_bytes()
    if digest(raw) != SOURCE_SHA256:
        raise ValueError('Original xutilities.f90 fingerprint changed')
    original = b''.join(raw.splitlines(keepends=True)[548:557])
    if not original.startswith(b'function exe_name()') or not original.endswith(b'end function exe_name\r\n'):
        raise ValueError('Original exe_name line range changed')
    files, cases = {}, []
    def add(name, body, *, decl='', category='success', baseline=None, expected='', mode='lines',
            dialect=None, reason='', diagnostic='', source=None, args=None, spelling='program.f90'):
        if source is None:
            source = 'program p\nimplicit none\n' + decl + body + '\nend program\n'
        if isinstance(source, str):
            source = source.encode('ascii')
        dialect = dialect or ('gnu' if b'getcwd' in source.lower() or b'getarg' in source.lower() else 'f2018')
        path = 'cases/' + name + '.f90'
        files[path] = source
        cases.append(dict(name=name, source=path, source_sha256=digest(source), category=category,
                          baseline=baseline or ('run' if category == 'success' else 'compile'),
                          dialect=dialect, expected_stdout=expected, compare_mode=mode,
                          diagnostic=diagnostic, reason=reason, args=args or [], source_spelling=spelling))
    add('original_exe_name', '', source=(b'program p\r\nimplicit none\r\ncharacter(1000)::v\r\n'
        b'v=exe_name()\r\nwrite(*,"(A)") "["//v//"]"\r\ncontains\r\n'+original+b'end program\r\n'),
        expected={'type':'original_exe_name','width':1000},
        reason='Exact original xutilities.f90 lines 549-557, including CRLF and the literal backslash.')
    add('getcwd_full', "call getcwd(c,s)\nif(s/=0) error stop 1\nwrite(*,'(A)') '['//c//']'",
        decl='character(256)::c\ninteger::s\n', expected={'type':'cwd','width':256})
    add('getcwd_keyword_reorder', "call getcwd(status=s,count=c)\nif(s/=0) error stop 1\nwrite(*,'(A)') trim(c)",
        decl='character(256)::c\ninteger::s\n', expected={'type':'cwd_trim'},
        reason='GNU 14 registers COUNT, despite its manual spelling the argument C; mirror the actual compiler interface.')
    add('getcwd_named_status', "call getcwd(c,status=s)\nif(s/=0) error stop 1\nwrite(*,'(A)') trim(c)",
        decl='character(256)::c\ninteger::s\n', expected={'type':'cwd_trim'})
    add('getcwd_omitted_status', "call getcwd(c)\nwrite(*,'(A)') trim(c)",
        decl='character(256)::c\n', expected={'type':'cwd_trim'})
    add('getcwd_short', "c='x'\ncall getcwd(c,s)\nif(s==0) error stop 1\nwrite(*,'(A)') '['//c//']'",
        decl='character(1)::c\ninteger::s\n', expected='[ ]\n',
        reason='GNU error code is platform-specific; test nonzero status and exact blank output.')
    add('getcwd_zero', "call getcwd(c,s)\nif(s==0) error stop 1\nwrite(*,'(A)') '['//c//']'",
        decl='character(0)::c\ninteger::s\n', expected='[]\n')
    add('command_full', "call get_command_argument(0,v,n,s)\nif(s/=0.or.n/=11) error stop 1\n"
        "write(*,'(A)') '['//v//']'", decl='character(20)::v\ninteger::n,s\n', expected='[program.f90         ]\n')
    add('command_relative_spelling', "call get_command_argument(0,v,n,s)\nif(s/=0.or.n/=13) error stop 1\n"
        "write(*,'(A)') '['//v//']'", decl='character(20)::v\ninteger::n,s\n',
        expected='[./program.f90       ]\n', spelling='./program.f90')
    add('command_keyword_reorder', "call get_command_argument(status=s,length=n,value=v,number=0)\n"
        "if(s/=0.or.n/=11.or.v/='program.f90') error stop 1", decl='character(11)::v\ninteger::n,s\n')
    add('command_omitted_value', "call get_command_argument(0,length=n,status=s)\nif(n/=11.or.s/=0) error stop 1",
        decl='integer::n,s\n')
    add('command_length_only', "call get_command_argument(number=0,length=n)\nif(n/=11) error stop 1", decl='integer::n\n')
    add('command_status_only', "call get_command_argument(0,status=s)\nif(s/=0) error stop 1", decl='integer::s\n')
    add('command_value_only', "call get_command_argument(0,v)\nif(v/='program.f90') error stop 1", decl='character(11)::v\n')
    add('command_number_only', 'call get_command_argument(0)')
    add('command_truncated', "call get_command_argument(0,v,n,s)\nif(n/=11.or.s/=-1) error stop 1\n"
        "write(*,'(A)') '['//v//']'", decl='character(3)::v\ninteger::n,s\n', expected='[pro]\n')
    add('command_zero_value', "call get_command_argument(0,v,n,s)\nif(n/=11.or.s<=0) error stop 1\n"
        "write(*,'(A)') '['//v//']'", decl='character(0)::v\ninteger::n,s\n', expected='[]\n',
        reason='GNU 14 returns a positive retrieval error for a present zero-length VALUE; do not hardcode errno.')
    for name, number in [('command_missing', '1'), ('command_huge_number', '2147483647')]:
        add(name, "v='xxxx'\nn=-7\ns=-7\ncall get_command_argument("+number+",v,n,s)\n"
            "if(n/=0.or.s<=0) error stop 1\nwrite(*,'(A)') '['//v//']'",
            decl='character(4)::v\ninteger::n,s\n', expected='[    ]\n')
    add('command_missing_no_value', 'call get_command_argument(1,length=n,status=s)\nif(n/=0.or.s<=0) error stop 1',
        decl='integer::n,s\n', args=['--max-steps','10000'], reason='Interpreter CLI options are not interpreted program arguments.')
    add('command_expression_alias', 'n=0\ncall get_command_argument(n+0,length=n,status=s)\nif(n/=11.or.s/=0) error stop 1',
        decl='integer::n,s\n', reason='Input expression is evaluated into a temporary before outputs are written.')
    add('command_repeat', "call get_command_argument(0,v,n,s)\nif(v/='program.f90'.or.n/=11.or.s/=0) error stop 1\n"
        "call get_command_argument(3,v,n,s)\nif(v/=' '.or.n/=0.or.s<=0) error stop 2\n"
        "call get_command_argument(0,v,n,s)\nif(v/='program.f90'.or.n/=11.or.s/=0) error stop 3",
        decl='character(20)::v\ninteger::n,s\n')
    add('allocated_character_outputs', "allocate(character(256)::c)\nallocate(character(20)::v)\n"
        "call getcwd(c,s)\nif(s/=0.or.len(c)/=256) error stop 1\n"
        "call get_command_argument(0,v,n,s)\nif(v/='program.f90'.or.n/=11.or.s/=0.or.len(v)/=20) error stop 2\n"
        "if(.not.allocated(c).or..not.allocated(v)) error stop 3",
        decl='character(:),allocatable::c,v\ninteger::n,s\n')
    add('main_save_outputs', "call getcwd(c,s)\nif(s/=0) error stop 1\ncall get_command_argument(0,v,n,s)\n"
        "if(v/='program.f90'.or.n/=11.or.s/=0) error stop 2",
        decl="character(256),save::c=' '\ncharacter(20),save::v=' '\ninteger,save::n=-7\ninteger,save::s=-7\n")
    add('impure_function_queries', '', source="""program p
implicit none
if(query()/=11) error stop 1
contains
integer function query() result(n)
character(256)::c
integer::s
call getcwd(c,s)
if(s/=0) error stop 2
call get_command_argument(0,length=n,status=s)
if(s/=0) error stop 3
end function
end program
""")
    add('procedure_shadows', '', source="""program p
implicit none
integer::n
call getcwd(n)
if(n/=7) error stop 1
call get_command_argument(n)
if(n/=9) error stop 2
contains
subroutine getcwd(x)
integer,intent(out)::x
x=7
end subroutine
subroutine get_command_argument(x)
integer,intent(out)::x
x=9
end subroutine
end program
""")
    add('generic_shadows', '', source="""module m
implicit none
interface getcwd
module procedure a
end interface
interface get_command_argument
module procedure b
end interface
contains
subroutine a(x)
integer,intent(out)::x
x=8
end subroutine
subroutine b(x)
integer,intent(out)::x
x=10
end subroutine
end module
program p
use m
implicit none
integer::n
call getcwd(n)
if(n/=8) error stop 1
call get_command_argument(n)
if(n/=10) error stop 2
end program
""")
    add('data_names_not_reserved', 'getcwd=4\nget_command_argument=5\nif(getcwd+get_command_argument/=9) error stop 1',
        decl='integer::getcwd,get_command_argument\n')
    add('exact_output_limit', "call getcwd(c,s)\nif(s/=0.or.len(c)/=65536) error stop 1\n"
        "call get_command_argument(0,v,n,s)\nif(n/=11.or.s/=0.or.len(v)/=65536) error stop 2\n"
        "if(trim(v)/='program.f90') error stop 3", decl='character(65536)::c,v\ninteger::n,s\n')
    add('getcwd_short_omitted_status', "call getcwd(c)\nwrite(*,'(A)') '['//c//']'",
        decl='character(1)::c\n', expected='[ ]\n')
    add('command_missing_omitted_status', "call get_command_argument(1,v)\nwrite(*,'(A)') '['//v//']'",
        decl='character(4)::v\n', expected='[    ]\n')
    add('command_space_filename', "call get_command_argument(0,v,n,s)\nif(n/=19.or.s/=0) error stop 1\n"
        "write(*,'(A)') '['//v//']'", decl='character(24)::v\ninteger::n,s\n',
        spelling='name with space.f90', expected='[name with space.f90     ]\n')
    add('input_dummy_number', '', source="""program p
implicit none
call q(0)
contains
subroutine q(number)
integer,intent(in)::number
integer::n,s
character(20)::v
call get_command_argument(number,v,n,s)
if(v/='program.f90'.or.n/=11.or.s/=0) error stop 1
end subroutine
end program
""")
    add('function_shadow', '', source="""program p
implicit none
if(getcwd(3)/=4) error stop 1
contains
integer function getcwd(n) result(v)
integer,intent(in)::n
v=n+1
end function
end program
""")
    add('generic_no_intrinsic_fallback', '', category='reject', baseline='compile', source="""module m
implicit none
interface get_command_argument
module procedure q
end interface
contains
subroutine q(flag)
logical,intent(in)::flag
end subroutine
end module
program p
use m
implicit none
integer::n
call get_command_argument(0,length=n)
end program
""", reason='A visible source generic with no matching specific must not fall back to the intrinsic.')
    # GNU compilation only: runtime behavior is undefined, unsupported, or intentionally bounded.
    invalid = [
        ('getcwd_missing_c','call getcwd()','','reject'),
        ('getcwd_too_many','call getcwd(c,s,s)','character(20)::c\ninteger::s\n','reject'),
        ('getcwd_c_keyword','call getcwd(c=c)','character(20)::c\n','reject'),
        ('getcwd_cwd_keyword','call getcwd(cwd=c)','character(20)::c\n','reject'),
        ('getcwd_unknown_keyword','call getcwd(directory=c)','character(20)::c\n','reject'),
        ('getcwd_duplicate_keyword','call getcwd(count=c,count=c)','character(20)::c\n','reject'),
        ('getcwd_positional_after_keyword','call getcwd(count=c,s)','character(20)::c\ninteger::s\n','reject'),
        ('command_missing_number','call get_command_argument(value=v)','character(20)::v\n','reject'),
        ('command_too_many','call get_command_argument(0,v,n,s,s)','character(20)::v\ninteger::n,s\n','reject'),
        ('command_unknown_keyword','call get_command_argument(0,argument=v)','character(20)::v\n','reject'),
        ('command_duplicate_keyword','call get_command_argument(0,status=s,status=s)','integer::s\n','reject'),
        ('command_positional_after_keyword','call get_command_argument(number=0,v)','character(20)::v\n','reject'),
        ('number_real','call get_command_argument(0.0)','','reject'),
        ('number_kind8','call get_command_argument(0_8)','','reject'),
        ('number_array','call get_command_argument(n)','integer::n(1)\n','compile'),
        ('value_literal',"call get_command_argument(0,'abc')",'','reject'),
        ('value_expression',"call get_command_argument(0,v//'x')",'character(3)::v\n','reject'),
        ('value_substring','call get_command_argument(0,v(1:3))','character(20)::v\n','compile'),
        ('value_array_element','call get_command_argument(0,v(1))','character(20)::v(2)\n','compile'),
        ('value_array','call get_command_argument(0,v)','character(20)::v(2)\n','compile'),
        ('value_integer','call get_command_argument(0,n)','integer::n\n','reject'),
        ('value_parameter',"call get_command_argument(0,v)","character(3),parameter::v='abc'\n",'reject'),
        ('length_kind8','call get_command_argument(0,length=n)','integer(8)::n\n','reject'),
        ('status_kind8','call get_command_argument(0,status=s)','integer(8)::s\n','reject'),
        ('status_real','call get_command_argument(0,status=s)','real::s\n','reject'),
        ('length_literal','call get_command_argument(0,length=1)','','reject'),
        ('length_array_element','call get_command_argument(0,length=n(1))','integer::n(2)\n','compile'),
        ('getcwd_integer_c','call getcwd(n)','integer::n\n','reject'),
        ('getcwd_status_real','call getcwd(c,s)','character(20)::c\nreal::s\n','reject'),
        ('getcwd_status_kind8','call getcwd(c,s)','character(20)::c\ninteger(8)::s\n','compile'),
        ('getcwd_substring','call getcwd(c(1:3))','character(20)::c\n','compile'),
        ('getcwd_literal',"call getcwd('abc')",'','compile'),
        ('duplicate_outputs','call get_command_argument(0,length=n,status=n)','integer::n\n','compile'),
        ('number_length_alias','n=0\ncall get_command_argument(n,length=n)','integer::n\n','compile'),
        ('number_status_alias','n=0\ncall get_command_argument(n,status=n)','integer::n\n','compile'),
        ('getcwd_function','s=getcwd(c)','character(256)::c\ninteger::s\n','compile'),
        ('unsupported_getarg','call getarg(0,c)','character(256)::c\n','compile'),
        ('unsupported_argument_count','n=command_argument_count()','integer::n\n','compile'),
        ('unsupported_environment','call get_environment_variable("PATH",c)','character(256)::c\n','compile'),
    ]
    for name, body, decl, baseline in invalid:
        add(name,body,decl=decl,category='reject',baseline=baseline,
            reason='Compile-only boundary. GNU is never executed for rejected or unsafe source.')
    for name, stmt, decl in [
        ('negative_number','call get_command_argument(-1,value=v)','character(20)::v\n'),
        ('negative_variable','n=-1\ncall get_command_argument(n,value=v)','character(20)::v\ninteger::n\n'),
        ('uninitialized_number','call get_command_argument(n,value=v)','character(20)::v\ninteger::n\n'),
        ('unallocated_value','call get_command_argument(0,value=v)','character(:),allocatable::v\n'),
        ('unallocated_cwd','call getcwd(v)','character(:),allocatable::v\n')]:
        add(name,stmt,decl=decl,category='runtime',baseline='compile',
            diagnostic='uninitialized' if name=='uninitialized_number' else 'unallocated' if name.startswith('unallocated') else 'NUMBER',
            reason='GNU compile-only: never execute unsafe or invalid-argument source.')
    # Locality and impurity are interpreter subset boundaries, not GNU errors.
    for query, call, decl in [('command','call get_command_argument(0,value=v)','character(20)::v'),
                             ('cwd','call getcwd(v)','character(256)::v')]:
        for storage in ['dummy','optional','saved','initialized','host','module','pointer']:
            if storage in ['dummy','optional']:
                opt=',optional' if storage=='optional' else ''
                source=f'program p\nimplicit none\n{decl}\ncall q(v)\ncontains\nsubroutine q(v)\n{decl.replace("::",",intent(out)"+opt+"::")}\n{call}\nend subroutine\nend program\n'
            elif storage in ['saved','initialized']:
                d=decl.replace('::',',save::')+"='old'" if storage=='saved' else decl+"='old'"
                source=f'program p\nimplicit none\ncall q()\ncontains\nsubroutine q()\n{d}\n{call}\nend subroutine\nend program\n'
            elif storage=='host':
                source=f'program p\nimplicit none\n{decl}\ncall q()\ncontains\nsubroutine q()\n{call}\nend subroutine\nend program\n'
            elif storage=='module':
                source=f'module m\nimplicit none\n{decl}\nend module\nprogram p\nuse m\nimplicit none\n{call}\nend program\n'
            else:
                source=f'program p\nimplicit none\n{decl.replace("::",",pointer::")}\n{call}\nend program\n'
            add(query+'_'+storage+'_output','',source=source,category='reject',baseline='compile',
                reason='GNU accepts this storage form; the bounded interpreter requires a whole nonsaved local output.')
        for purity in ['pure','simple']:
            source=f'program p\nimplicit none\ncontains\n{purity} subroutine q()\n{decl}\n{call}\nend subroutine\nend program\n'
            add(query+'_'+purity,'',source=source,category='reject',baseline='reject',
                reason='Impure process query is forbidden; GNU 14 also rejects SIMPLE (not implemented).')
    for name, body, decl in [('command_output_limit','call get_command_argument(0,v)','character(65537)::v\n'),
                             ('cwd_output_limit','call getcwd(v)','character(65537)::v\n')]:
        add(name,body,decl=decl,category='reject',baseline='compile',reason='The per-query CHARACTER output byte cap is 65536.')
    add('deferred_output_over_limit', 'allocate(character(65537)::v)\ncall get_command_argument(0,v)',
        decl='character(:),allocatable::v\n', category='runtime', baseline='compile',
        reason='Allocation exceeds the existing CHARACTER byte cap before the query is reached.')
    # Pin semantic diagnostic families: an unrelated parse failure must not satisfy a boundary.
    for case in cases:
        if case['category'] != 'reject':
            continue
        name=case['name']
        diagnostic='Process query requires'
        if name in ('getcwd_missing_c','command_missing_number'):
            diagnostic='Missing required actual argument'
        elif 'too_many' in name or 'unknown_keyword' in name or name in ('getcwd_c_keyword','getcwd_cwd_keyword'):
            diagnostic='Unknown keyword or excess actual argument'
        elif 'duplicate_keyword' in name:
            diagnostic='Repeated actual argument'
        elif 'positional_after_keyword' in name:
            diagnostic='Positional argument cannot follow a keyword argument'
        elif name=='generic_no_intrinsic_fallback':
            diagnostic='No matching specific procedure'
        elif name in ('getcwd_function','unsupported_argument_count'):
            diagnostic='Unsupported procedure or array reference'
        elif name.startswith('unsupported_'):
            diagnostic='Unknown or inaccessible subroutine'
        elif name.endswith(('_pure','_simple')):
            diagnostic='Process query is forbidden'
        elif name.endswith('_host_output'):
            diagnostic='Undeclared variable'
            case['reason']='The existing host-association boundary rejects this output before process-query validation. GNU compile-only.'
        elif name.endswith('_pointer_output'):
            diagnostic='Unsupported POINTER declaration'
            case['reason']='The existing CHARACTER POINTER declaration boundary rejects this output before process-query validation. GNU compile-only.'
        elif name.endswith('_output_limit'):
            diagnostic='CHARACTER length limit'
        case['diagnostic']=diagnostic
    provenance=dict(original_source='../utilities_slices/source/xutilities.f90', original_sha256=SOURCE_SHA256,
        original_exe_name_lines=[549,557], original_exe_name_sha256=digest(original),
        original_newline='CRLF', wrapper='An explicit internal procedure wrapper; original bytes are unchanged.',
        documentation=['https://gcc.gnu.org/onlinedocs/gfortran/GETCWD.html',
                       'https://gcc.gnu.org/onlinedocs/gfortran/GET_005fCOMMAND_005fARGUMENT.html',
                       'https://raw.githubusercontent.com/gcc-mirror/gcc/releases/gcc-14.2.0/gcc/fortran/intrinsic.cc'],
        getcwd_keyword='COUNT is the GNU 14 actual first keyword: intrinsic.cc line 3159 defines c="count" and lines 3329-3332 register it. C and CWD are rejected.',
        virtual_invocation='argv[0] equals the CLI source filename; positive arguments are absent, even when CLI options exist.',
        gnu_invocation='subprocess executable=reference with args[0]=the same source filename and no extra arguments.',
        safety='Only successful defined cases execute GNU. Rejected and runtime-safety cases compile only.')
    files['provenance.json']=(json.dumps(provenance,indent=2)+'\n').encode()
    files['manifest.json']=(json.dumps(dict(schema_version=1,cases=cases),indent=2)+'\n').encode()
    return files

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check',action='store_true')
    parser.add_argument('--output',type=Path,default=ROOT)
    args=parser.parse_args()
    files=build()
    mismatches=[]
    for name,data in files.items():
        target=args.output/name
        if args.check:
            if not target.is_file() or target.read_bytes()!=data: mismatches.append(name)
        else:
            target.parent.mkdir(parents=True,exist_ok=True)
            target.write_bytes(data)
    if args.check:
        actual={str(path.relative_to(args.output)) for path in (args.output/'cases').glob('*.f90')}
        mismatches.extend(sorted(actual-{name for name in files if name.startswith('cases/')}))
    if mismatches:
        raise SystemExit('Generator replay mismatch: '+', '.join(mismatches))
    print(('Verified' if args.check else 'Generated')+f' {len(files)-2} frozen cases')

if __name__=='__main__': main()
