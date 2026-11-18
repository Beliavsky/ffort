! SPDX-License-Identifier: MIT
program test_external_read_runtime
    use, intrinsic :: iso_fortran_env, only: error_unit,int64
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: execute_program,input_unit_t,validate_input_units
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::decl='integer::unit,stat'//nl//'character(8)::line'//nl
    character(*),parameter::read_one='unit=7'//nl//'read(unit,"(a)",iostat=stat) line'//nl
    type(program_t)::p,q
    type(diagnostic_t)::d
    type(input_unit_t),allocatable::inputs(:)
    character(:),allocatable::source,label
    integer::checks,j,pc,e,u,b,which
    integer,parameter::controls(4)=[0,1,13,127]
    checks=0;which=0;label=''

    call prepare('LF, CRLF, blank and unterminated records',decl, &
        read_one//'if(stat/=0.or.line/="alpha") stop 1'//nl// &
        'read(unit,"( A )",iostat=stat) line'//nl// &
        'if(stat/=0.or.line/="beta") stop 2'//nl// &
        'read(unit,"(a)",iostat=stat) line'//nl// &
        'if(stat/=0.or.line/="") stop 3'//nl// &
        'read(unit,"(a)",iostat=stat) line'//nl// &
        'if(stat/=0.or.line/="longer t") stop 4'//nl// &
        'read(unit,"(a)",iostat=stat) line'//nl//'if(stat/=-1) stop 5'//nl// &
        'read(unit,"(a)",iostat=stat) line'//nl//'if(stat/=1) stop 6')
    call one_input('alpha'//nl//'beta'//achar(13)//nl//nl//'longer than eight')
    call run_ok()
    call expect(inputs(1)%position==len(inputs(1)%data)+1,'complete final record cursor')

    call prepare('repeated execution shares caller cursor',decl,read_one)
    call one_input('first'//nl//'second'//nl)
    call run_ok();call expect(inputs(1)%position==7,'first execution cursor')
    call run_ok();call expect(inputs(1)%position==14,'second execution cursor')
    call run_ok();call expect(inputs(1)%position==14,'EOF cursor is stable')
    call expect(inputs(1)%endfile,'first EOF marks the endfile record')
    inputs(1)%position=1;inputs(1)%endfile=.false.
    call run_ok();call expect(inputs(1)%position==7,'explicit cursor reset replays first record')
    call expect(.not.inputs(1)%endfile,'explicit reset clears the endfile state')
    inputs(1)%position=3
    call run_error('record boundary')
    call expect(inputs(1)%position==3,'invalid interior cursor remains unchanged')

    label='nested procedure calls share input state'
    source='module m'//nl//'contains'//nl// &
        'subroutine leaf(unit,line)'//nl//'integer,intent(in)::unit'//nl// &
        'character(8),intent(out)::line'//nl//'integer::stat'//nl// &
        'read(unit,"(a)",iostat=stat) line'//nl//'if(stat/=0) stop 1'//nl// &
        'end subroutine'//nl//'subroutine outer(unit,line)'//nl// &
        'integer,intent(in)::unit'//nl//'character(8),intent(out)::line'//nl// &
        'call leaf(unit,line)'//nl//'end subroutine'//nl//'end module'//nl// &
        'program p'//nl//'use m'//nl//'implicit none'//nl//decl//'unit=7'//nl// &
        'call outer(unit,line)'//nl//'if(line/="first") stop 2'//nl// &
        'call outer(unit,line)'//nl//'if(line/="second") stop 3'//nl//'end program'
    call load_source()
    call one_input('first'//nl//'second'//nl)
    call run_ok();call expect(inputs(1)%position==14,'nested calls preserve shared cursor')

    call prepare('separate virtual units retain separate cursors',decl, &
        read_one//'if(line/="one") stop 1'//nl//'unit=8'//nl// &
        'read(unit,"(a)",iostat=stat) line'//nl//'if(line/="other") stop 2'//nl// &
        'unit=7'//nl//'read(unit,"(a)",iostat=stat) line'//nl//'if(line/="two") stop 3')
    call input_count(2)
    inputs(1)=input_unit_t(unit=7,data='one'//nl//'two')
    inputs(2)=input_unit_t(unit=8,data='other'//nl)
    call run_ok()
    call expect(inputs(1)%position==8.and.inputs(2)%position==7,'independent cursors')

    call prepare('zero length target still consumes complete record', &
        'integer::unit,stat'//nl//'character(0)::line', &
        read_one//'if(stat/=0.or.len(line)/=0) stop 1')
    call one_input('discard the whole record'//nl)
    call run_ok();call expect(inputs(1)%position==len(inputs(1)%data)+1,'zero length cursor')
    call prepare('tabs are text data',decl,read_one// &
        'if(stat/=0.or.line(1:1)/="a".or.line(2:2)/=achar(9).or.line(3:3)/="b") stop 1')
    call one_input('a'//achar(9)//'b'//nl);call run_ok()

    call prepare('fixed and deferred allocated scalar targets', &
        'integer::unit,stat'//nl//'character(4),allocatable::fixed'//nl// &
        'character(:),allocatable::deferred', &
        'allocate(fixed)'//nl//'allocate(character(5)::deferred)'//nl//'unit=7'//nl// &
        'read(unit,"(a)",iostat=stat) fixed'//nl// &
        'if(stat/=0.or.fixed/="abcd".or.len(fixed)/=4) stop 1'//nl// &
        'read(unit,"(a)",iostat=stat) deferred'//nl// &
        'if(stat/=0.or.deferred/="xy".or.len(deferred)/=5) stop 2')
    call one_input('abcdef'//nl//'xy'//nl);call run_ok()

    call prepare('external record feeds mixed CHARACTER internal input', &
        'integer::unit,stat,n'//nl//'real::x'//nl//'character(100)::line'//nl// &
        'character(5)::words(2)', &
        read_one//'if(stat/=0) stop 1'//nl//'read(line,*,iostat=stat) words,x,n'//nl// &
        'if(stat/=0.or.any(words/="ab").or.x/=3.5.or.n/=4) stop 2')
    call one_input("2*'ab' 3.5 4"//nl);call run_ok()

    call prepare('CHARACTER allocated rank one two three order and quoting', &
        'integer::unit,stat'//nl//'character(100)::line'//nl// &
        'character(:),allocatable::a(:),b(:,:),c(:,:,:)', &
        'allocate(character(8)::a(-1:0),b(1:1,2:3),c(1:1,1:1,1:2))'//nl// &
        read_one//'read(line,*,iostat=stat) a,b,c'//nl//'if(stat/=0) stop 1'//nl// &
        'if(a(-1)/="a b".or.a(0)/="c,d") stop 2'//nl// &
        'if(b(1,2)/="e/f".or.b(1,3)/="plain") stop 3'//nl// &
        'if(c(1,1,1)/="can''t".or.c(1,1,2)/='//quoted('say"hi')//') stop 4')
    call one_input("'a b' 'c,d' 'e/f' plain 'can''t' "//'"say""hi"'//nl)
    call run_ok()

    label='runtime local CHARACTER array length is frozen at entry'
    source='module m'//nl//'contains'//nl//'subroutine read_words(n)'//nl// &
        'integer,intent(inout)::n'//nl//'character(n)::words(2)'//nl// &
        'character(20)::text'//nl//'integer::stat'//nl//'n=1'//nl// &
        'text="alphabet beta"'//nl//'read(text,*,iostat=stat) words'//nl// &
        'if(stat/=0.or.len(words)/=5.or.words(1)/="alpha".or.words(2)/="beta") stop 1'//nl// &
        'end subroutine'//nl//'end module'//nl//'program p'//nl//'use m'//nl// &
        'implicit none'//nl//'integer::n'//nl//'n=5'//nl//'call read_words(n)'//nl// &
        'if(n/=1) stop 2'//nl//'end program'
    call load_source();call one_input('');call run_ok()

    call prepare('null repetition may cross CHARACTER and INTEGER targets', &
        'integer::stat,n'//nl//'character(20)::text'//nl//'character(4)::word', &
        'word="old"'//nl//'n=7'//nl//'text="2*"'//nl// &
        'read(text,*,iostat=stat) word,n'//nl// &
        'if(stat/=0.or.word/="old".or.n/=7) stop 1')
    call one_input('');call run_ok()
    call prepare('nonnull repetition cannot cross CHARACTER and INTEGER targets', &
        'integer::stat,n'//nl//'character(20)::text'//nl//'character(4)::word', &
        'word="old"'//nl//'n=7'//nl//'text="2*5"'//nl// &
        'read(text,*,iostat=stat) word,n'//nl//'if(stat<=0) stop 1')
    call one_input('');call run_ok()
    call prepare('CHARACTER nulls preserve prior values and empty quotes assign', &
        'integer::stat'//nl//'character(40)::text'//nl//'character(4)::words(4)', &
        'words="old"'//nl//'text='//quoted(",2*,''")//nl// &
        'read(text,*,iostat=stat) words'//nl// &
        'if(stat/=0.or.any(words(1:3)/="old").or.words(4)/="") stop 1')
    call one_input('');call run_ok()
    call prepare('CHARACTER slash terminates without changing remaining values', &
        'integer::stat'//nl//'character(40)::text'//nl//'character(4)::words(2)', &
        'words="old"'//nl//'text='//quoted("new / 'ignored'")//nl// &
        'read(text,*,iostat=stat) words'//nl// &
        'if(stat/=0.or.words(1)/="new".or.words(2)/="old") stop 1')
    call one_input('');call run_ok()
    call prepare('CHARACTER null does not define an undefined target', &
        'integer::stat,n'//nl//'character(8)::text,word', &
        'text=","'//nl//'read(text,*,iostat=stat) word'//nl//'n=len_trim(word)')
    call one_input('');call run_error('uninitialized')
    call prepare('CHARACTER EOF invalidates successfully read prefix', &
        'integer::stat,n'//nl//'character(8)::text,word,other', &
        'text="first"'//nl//'word="old"'//nl//'other="old"'//nl// &
        'read(text,*,iostat=stat) word,other'//nl//'if(stat/=-1) stop 1'//nl//'n=len_trim(word)')
    call one_input('');call run_error('uninitialized')
    call prepare('malformed CHARACTER token invalidates targets', &
        'integer::stat,n'//nl//'character(8)::text,word', &
        'text='//quoted("'open")//nl//'word="old"'//nl// &
        'read(text,*,iostat=stat) word'//nl//'if(stat<=0) stop 1'//nl//'n=len_trim(word)')
    call one_input('');call run_error('uninitialized')

    call prepare('external EOF status invalidates old target',decl//'integer::n', &
        'line="old"'//nl//read_one//'if(stat/=-1) stop 1'//nl//'n=len_trim(line)')
    call one_input('');call run_error('uninitialized')
    call expect(inputs(1)%position==1,'empty input EOF does not move cursor')
    call prepare('external EOF without IOSTAT is an error',decl, &
        'unit=7'//nl//'read(unit,"(a)") line')
    call one_input('');call run_error('end of external READ')
    call expect(inputs(1)%endfile,'EOF without IOSTAT records endfile state')
    call run_error('past the endfile record')
    call prepare('unbound input cannot read host units',decl,read_one)
    call one_input('text');inputs(1)%unit=8;call run_error('not explicitly bound')
    call expect(inputs(1)%position==1,'unbound failure does not consume')
    d=diagnostic_t();call execute_program(p,d)
    call error_check('not explicitly bound')
    call input_count(0);call run_error('not explicitly bound')
    call prepare('nonpositive source unit cannot select stdin',decl, &
        'unit=0'//nl//'read(unit,"(a)",iostat=stat) line')
    call one_input('text');call run_error('positive bound unit')
    call prepare('uninitialized unit fails before input',decl, &
        'read(unit,"(a)",iostat=stat) line')
    call one_input('text');call run_error('uninitialized')

    call prepare('unallocated fixed scalar external target', &
        'integer::unit,stat'//nl//'character(8),allocatable::line',read_one)
    call one_input('text');call run_error('unallocated')
    call expect(inputs(1)%position==1,'unallocated target leaves cursor unchanged')
    call prepare('unallocated deferred scalar external target', &
        'integer::unit,stat'//nl//'character(:),allocatable::line',read_one)
    call one_input('text');call run_error('unallocated')
    call prepare('unallocated fixed scalar internal null target', &
        'integer::stat'//nl//'character(8)::text'//nl//'character(8),allocatable::word', &
        'text=","'//nl//'read(text,*,iostat=stat) word')
    call one_input('');call run_error('unallocated')
    call prepare('unallocated scalar internal CHARACTER file', &
        'integer::stat'//nl//'character(:),allocatable::text'//nl//'character(8)::word', &
        'read(text,*,iostat=stat) word')
    call one_input('');call run_error('unallocated')
    call prepare('unallocated internal CHARACTER array', &
        'integer::stat'//nl//'character(8)::text'//nl//'character(8),allocatable::words(:)', &
        'text="a"'//nl//'read(text,*,iostat=stat) words')
    call one_input('');call run_error('unallocated')

    ! Only 257 value descriptors are allocated. The repetition must be
    ! rejected before creating any 65536-byte CHARACTER element payloads.
    call prepare('fixed CHARACTER READ byte cap preflight', &
        'integer::stat'//nl//'character(20)::text'//nl//'character(65536)::a(257)', &
        'text="257*x"'//nl//'read(text,*,iostat=stat) a')
    call one_input('');call run_error('READ CHARACTER byte limit')
    call prepare('aggregate fixed CHARACTER READ byte cap preflight', &
        'integer::stat'//nl//'character(20)::text'//nl// &
        'character(65536)::a(129),b(128)', &
        'text="257*x"'//nl//'read(text,*,iostat=stat) a,b')
    call one_input('');call run_error('READ CHARACTER byte limit')

    call prepare('record length boundary and validation',decl,read_one)
    call one_input(repeat('x',65536)//nl);call run_ok()
    call expect(inputs(1)%position==65538,'maximum record accepted in full')
    call one_input(repeat('x',65537)//nl);call run_error('record exceeds 65536')
    call expect(inputs(1)%position==1,'oversize record does not consume')
    do j=1,size(controls)
        call one_input('more than eight'//achar(controls(j))//'b'//nl)
        call run_error('text records')
        call expect(inputs(1)%position==1,'invalid record byte does not consume')
    end do
    call one_input(repeat('x',1000)//nl)
    d=diagnostic_t();call execute_program(p,d,max_steps=40_int64,input_units=inputs)
    call error_check('step limit')
    call expect(inputs(1)%position==1,'exhausted read budget does not consume')

    label='binding validation before execution'
    call one_input('x');inputs(1)%unit=0;call run_error('invalid external input unit binding')
    call one_input('x');inputs(1)%unit=-1;call run_error('invalid external input unit binding')
    call one_input('x');deallocate(inputs(1)%data);call run_error('invalid external input unit binding')
    call one_input('x');inputs(1)%position=0;call run_error('invalid external input size or cursor')
    call one_input('x');inputs(1)%position=3;call run_error('invalid external input size or cursor')
    call one_input('x');inputs(1)%position=2;call run_ok()
    call one_input('x');inputs(1)%endfile=.true.;call run_error('invalid external input endfile state')
    call expect(inputs(1)%position==1.and.inputs(1)%endfile,'invalid endfile flag leaves binding unchanged')
    call one_input(repeat('x',1048577));call run_error('invalid external input size or cursor')
    call input_count(2);inputs%unit=7;call run_error('duplicate external input unit binding')
    call input_count(33);call run_error('unit limit exceeded')
    call input_count(32)
    d=diagnostic_t();call validate_input_units(inputs,d)
    call expect(d%code==0,'exactly 32 unit bindings accepted')
    call input_count(4)
    do j=1,4
        inputs(j)%data=repeat('x',1048576)
    end do
    d=diagnostic_t();call validate_input_units(inputs,d)
    call expect(d%code==0,'exact one-MiB individual and four-MiB total caps accepted')
    call input_count(5)
    do j=1,5
        inputs(j)%data=repeat('x',1048576)
    end do
    call run_error('total byte limit exceeded')

    call prepare('corrupt external READ IR rejected by direct execution',decl,read_one)
    pc=0
    do j=1,p%nc
        if(p%code(j)%op==op_read_external) pc=j
    end do
    call expect(pc>0,'external instruction found')
    e=p%code(pc)%items(1);u=p%code(pc)%a;b=p%code(pc)%b
    do which=1,27
        q=p
        select case(which)
        case(1);q%code(pc)%a=0
        case(2);q%code(pc)%a=q%ne+1
        case(3);q%code(pc)%b=-1
        case(4);q%code(pc)%b=q%ne+1
        case(5);q%code(pc)%b=u
        case(6);deallocate(q%code(pc)%items)
        case(7);q%code(pc)%items=[integer::]
        case(8);q%code(pc)%items=[e,e]
        case(9);q%code(pc)%items=[0]
        case(10);q%code(pc)%items=[q%ne+1]
        case(11);q%code(pc)%items=[u]
        case(12);q%code(pc)%format='*'
        case(13);q%code(pc)%format='(a4)'
        case(14);q%code(pc)%format_expr=u
        case(15);q%code(pc)%advance_mode=1
        case(16);q%code(pc)%symbol=1
        case(17);q%code(pc)%op=op_read_internal
        case(18);q%expressions(e)%parenthesized=.true.
        case(19);q%expressions(e)%character_len=9
        case(20);q%expressions(e)%rank=1
        case(21);q%expressions(e)%extent=1_int64
        case(22);q%expressions(e)%dims(1)=1_int64
        case(23);q%expressions(e)%value%s='forged'
        case(24);q%expressions(e)%left=1
        case(25);q%expressions(u)%parenthesized=.true.
        case(26);q%expressions(b)%rank=1
        case(27);q%symbols(q%expressions(e)%symbol)%dummy_intent=1
        end select
        call one_input('unchanged'//nl)
        d=diagnostic_t();call execute_program(q,d,input_units=inputs)
        call expect(d%code==2,'corrupt READ produces a runtime diagnostic')
        call expect(allocated(d%message),'corrupt READ diagnostic has text')
        call expect(inputs(1)%position==1,'corrupt READ leaves bound input untouched')
    end do
    ! Public IR with no format is supported list input, not malformed (A).
    q=p;deallocate(q%code(pc)%format)
    call one_input('unchanged'//nl)
    d=diagnostic_t();call execute_program(q,d,input_units=inputs)
    call expect(d%code==0,'absent format executes list-directed input')
    call expect(inputs(1)%position==11,'list-directed input advances full record')
    write(error_unit,'(a,i0,a)') 'external READ runtime: ',checks,' checks passed'
contains
    function quoted(text) result(out)
        character(*),intent(in)::text
        character(:),allocatable::out
        integer::k
        out="'"
        do k=1,len(text)
            out=out//text(k:k)
            if(text(k:k)=="'") out=out//"'"
        end do
        out=out//"'"
    end function
    subroutine prepare(name,declarations,body)
        character(*),intent(in)::name,declarations,body
        label=name
        source='program p'//nl//'implicit none'//nl//declarations//nl//body//nl//'end program'
        call load_source()
    end subroutine
    subroutine load_source()
        d=diagnostic_t();call parse_subset(source,p,d)
        call expect(d%code==0,'parser accepts runtime fixture')
        call verify_frontend(source,p,d)
        call expect(d%code==0,'independent producer accepts runtime fixture')
    end subroutine
    subroutine input_count(count)
        integer,intent(in)::count
        integer::k
        if(allocated(inputs)) deallocate(inputs)
        allocate(inputs(count))
        do k=1,count
            inputs(k)=input_unit_t(unit=k,data='')
        end do
    end subroutine
    subroutine one_input(data)
        character(*),intent(in)::data
        call input_count(1)
        inputs(1)=input_unit_t(unit=7,data=data)
    end subroutine
    subroutine run_ok()
        d=diagnostic_t();call execute_program(p,d,input_units=inputs)
        call expect(d%code==0,'runtime succeeds')
    end subroutine
    subroutine run_error(fragment)
        character(*),intent(in)::fragment
        d=diagnostic_t();call execute_program(p,d,input_units=inputs)
        call error_check(fragment)
    end subroutine
    subroutine error_check(fragment)
        character(*),intent(in)::fragment
        call expect(d%code==2,'runtime rejects invalid operation')
        call expect(allocated(d%message),'runtime diagnostic is present')
        call expect(index(d%message,fragment)>0,'runtime diagnostic identifies failure')
    end subroutine
    subroutine expect(ok,detail)
        logical,intent(in)::ok
        character(*),intent(in)::detail
        checks=checks+1
        if(ok) return
        write(error_unit,*) 'FAIL ',checks,which,': ',label,': ',detail
        if(allocated(d%message)) write(error_unit,*) d%message
        error stop 1
    end subroutine
end program
