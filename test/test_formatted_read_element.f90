! SPDX-License-Identifier: MIT
! Source-only native draft. Counts and outcomes must be observed centrally.
program test_formatted_read_element
    use, intrinsic :: iso_fortran_env, only: error_unit,int64
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: execute_program,input_unit_t
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::declarations='integer::u,ios,i'//nl//'character(4)::a(-1:1),other(-1:1)'//nl
    character(*),parameter::initialization='u=27'//nl//'ios=17'//nl//'i=0'//nl// &
        'a(-1)="KEEP"'//nl//'a(0)="old!"'//nl//'a(1)="LAST"'//nl
    character(*),parameter::operation='read(u,"(a)",iostat=ios)a(i+0)'//nl
    character(*),parameter::check_success='if(ios/=0.or.i/=0)stop 1'//nl// &
        'if(a(-1)/="KEEP".or.a(0)/="xy  ".or.a(1)/="LAST")stop 2'//nl
    type(program_t)::p,q,saved
    type(diagnostic_t)::d
    type(input_unit_t)::inputs(1)
    character(:),allocatable::source,label,base_source,changed
    integer::checks,pc,target,index_root,leaf,s,ss,alternate,which,j
    integer,parameter::controls(4)=[0,1,13,127]
    checks=0;which=0;label=''
    call prepare('baseline',declarations,initialization//operation//check_success)
    base_source=source;saved=p
    pc=0;alternate=0
    do j=1,p%nc
        if(p%code(j)%op==op_read_external)pc=j
    end do
    do j=1,p%ns
        if(p%symbols(j)%name=='other')alternate=j
    end do
    call expect(pc>0.and.alternate>0,'retained instruction and alternate symbol')
    target=p%code(pc)%items(1);s=p%expressions(target)%symbol
    index_root=p%expressions(target)%left;leaf=p%expressions(index_root)%left
    ss=p%expressions(p%code(pc)%b)%symbol
    call expect(p%expressions(index_root)%kind==ex_binary,'independent arithmetic index root')
    call expect(p%expressions(leaf)%kind==ex_variable,'independent variable index leaf')
    call expect(valid_external_read(p,p%code(pc)),'whole external gate')
    call expect(valid_external_read_element(p,target,s,0,ss),'element public gate')
    call bind('xy'//nl);call run_ok()
    call expect(inputs(1)%position==4.and..not.inputs(1)%endfile,'success consumes one record')
    do which=1,73
        q=saved
        select case(which)
        case(1);q%expressions(target)%kind=ex_variable
        case(2);q%expressions(target)%symbol=0
        case(3);q%expressions(target)%symbol=q%ns+1
        case(4);q%expressions(target)%rank=1
        case(5);q%expressions(target)%typ=ty_integer
        case(6);q%expressions(target)%real_kind=8
        case(7);q%expressions(target)%character_len=3
        case(8);q%expressions(target)%extent=1_int64
        case(9);q%expressions(target)%dims(1)=1_int64
        case(10);q%expressions(target)%parenthesized=.true.
        case(11);q%expressions(target)%left=0
        case(12);q%expressions(target)%left=q%ne+1
        case(13);q%expressions(target)%right=index_root
        case(14);q%expressions(target)%third=index_root
        case(15);q%expressions(target)%stride=index_root
        case(16);q%expressions(target)%left2=index_root
        case(17);q%expressions(target)%right2=index_root
        case(18);q%expressions(target)%stride2=index_root
        case(19);q%expressions(target)%left3=index_root
        case(20);q%expressions(target)%right3=index_root
        case(21);q%expressions(target)%stride3=index_root
        case(22);q%expressions(target)%length_expr=index_root
        case(23);q%expressions(target)%constructor_owner=1
        case(24);q%expressions(target)%constructor_kind_expr=index_root
        case(25);q%expressions(target)%generic_id=1
        case(26);q%expressions(target)%bound_type=1
        case(27);q%expressions(target)%bound_binding=1
        case(28);q%expressions(target)%intrinsic_mask=1
        case(29);q%expressions(target)%op='forged'
        case(30);q%expressions(target)%args=[index_root]
        case(31);q%expressions(target)%triplet(1)=.false.
        case(32);q%expressions(target)%value%tag=ty_character
        case(33);q%expressions(target)%value%s='forged'
        case(34);q%symbols(s)%is_pointer=.true.
        case(35);q%symbols(s)%is_parameter=.true.
        case(36);q%symbols(s)%dummy_intent=1
        case(37);q%symbols(s)%is_class=.true.
        case(38);q%symbols(s)%is_intrinsic=.true.
        case(39);q%symbols(s)%scope=1
        case(40);q%symbols(s)%rank=0
        case(41);q%expressions(index_root)%rank=1
        case(42);q%expressions(index_root)%typ=ty_real
        case(43);q%expressions(index_root)%real_kind=2
        case(44);q%expressions(index_root)%extent=1_int64
        case(45);q%expressions(index_root)%dims(1)=1_int64
        case(46);q%expressions(leaf)%scope=1
        case(47);q%expressions(leaf)%constructor_owner=1
        case(48);q%expressions(leaf)%kind=ex_user_call
        case(49);q%expressions(leaf)%kind=ex_component
        case(50);q%expressions(leaf)%kind=ex_output_do
        case(51);q%expressions(index_root)%left=index_root
        case(52);q%expressions(leaf)%symbol=ss
        case(53);q%code(pc)%format='(a4)'
        case(54);q%code(pc)%items=[target,target]
        case(55);q%code(pc)%scope=-1
        case(56);q%expressions(leaf)%dims(1)=1_int64
        case(57);q%expressions(leaf)%real_kind=8
        case(58);q%expressions(leaf)%rank=1;q%expressions(leaf)%extent=1_int64
        case(59);q%expressions(leaf)%typ=ty_real
        case(60);q%expressions(leaf)%extent=1_int64
        case(61);q%expressions(q%expressions(index_root)%right)%value%real_kind=8
        case(62);q%expressions(q%expressions(index_root)%right)%value%s='hidden'
        case(63);allocate(q%expressions(q%expressions(index_root)%right)%value%record)
        case(64);q%expressions(leaf)%value%s='hidden'
        case(65);allocate(q%expressions(leaf)%value%record)
        case(66);q%expressions(index_root)%length_expr=leaf
        case(67);q%expressions(index_root)%constructor_kind_expr=leaf
        case(68);q%expressions(q%expressions(index_root)%right)%value%l=.true.
        case(69);q%expressions(q%expressions(index_root)%right)%value%i=2147483648_int64
        case(70);q%expressions(leaf)%character_len=0
        case(71);q%expressions(index_root)%value%tag=ty_integer
        case(72);q%expressions(q%expressions(index_root)%right)%rank=1
        case(73);q%expressions(q%expressions(index_root)%right)%value%r=1.0
        end select
        call expect(.not.valid_external_read(q,q%code(pc)),'mutation public guard rejects')
        d=diagnostic_t();call verify_frontend(base_source,q,d)
        call expect(d%code==1,'mutation independent source adapter rejects')
        call bind('xy'//nl);d=diagnostic_t();call execute_program(q,d,input_units=inputs)
        call expect(d%code==2,'mutation source-free runtime rejects')
        call expect(inputs(1)%position==1.and..not.inputs(1)%endfile,'mutation leaves input state unchanged')
    end do
    which=0
    q=saved;q%expressions(target)%symbol=alternate
    call expect(valid_external_read(q,q%code(pc)),'same-schema other destination structurally valid')
    d=diagnostic_t();call verify_frontend(base_source,q,d)
    call expect(d%code==1,'destination binding independently source checked')
    q=saved;q%expressions(leaf)%symbol=ss
    call expect(.not.valid_external_read_element(q,target,s,0,ss),'IOSTAT dependency rejected')
    q=saved
    call expect(.not.valid_external_read_element(q,target,s,0,-1),'negative status symbol rejected')
    call expect(.not.valid_external_read_element(q,target,s,0,q%ns+1),'out of table status symbol rejected')
    q%code(pc)%op=op_inquire_name;q%code(pc)%b=target
    deallocate(q%code(pc)%items,q%code(pc)%format)
    call expect(.not.valid_inquire_name(q,q%code(pc)),'READ element never expands INQUIRE NAME')

    call prepare('READY scalar PARAMETER caches',declarations//'integer,parameter::n=0', &
        initialization//'read(u,"(a)",iostat=ios)a(n)'//nl//check_success)
    call bind('xy'//nl);call run_ok()
    do j=1,p%nc
        if(p%code(j)%op==op_read_external)pc=j
    end do
    target=p%code(pc)%items(1);index_root=p%expressions(target)%left
    s=p%expressions(index_root)%symbol
    call expect(p%expressions(index_root)%kind==ex_variable,'parameter index remains variable metadata')
    call expect(p%symbols(s)%is_parameter.and.p%symbols(s)%parameter_ready,'parameter cache is ready')
    do which=1,8
        q=p
        select case(which)
        case(1);q%symbols(s)%constant_value%real_kind=8
        case(2);q%symbols(s)%constant_value%tag=ty_real
        case(3);q%symbols(s)%constant_value%s='hidden'
        case(4);allocate(q%symbols(s)%constant_value%record)
        case(5);q%symbols(s)%constant_value%real_kind=2
        case(6);q%symbols(s)%constant_value%l=.true.
        case(7);q%symbols(s)%constant_value%i=2147483648_int64
        case(8);allocate(q%symbols(s)%constant_values(1))
        end select
        call reject_metadata('READY parameter cache')
    end do
    call prepare('converted integer parameter keeps inactive REAL cache',declarations//'integer,parameter::n=0.75', &
        initialization//'read(u,"(a)",iostat=ios)a(n)'//nl//check_success)
    call bind('xy'//nl);call run_ok()
    call prepare('converted real parameter keeps inactive INTEGER cache',declarations//'real,parameter::r=2', &
        initialization//'read(u,"(a)",iostat=ios)a(int(r)-2)'//nl//check_success)
    call bind('xy'//nl);call run_ok()
    call prepare('intrinsic array metadata arguments',declarations,initialization// &
        'read(u,"(a)",iostat=ios)a(len([character(1)::"x"])-1)'//nl//check_success)
    call bind('xy'//nl);call run_ok()
    do j=1,p%nc
        if(p%code(j)%op==op_read_external)pc=j
    end do
    index_root=0
    do j=1,p%ne
        if(p%expressions(j)%kind==ex_constructor)index_root=j
    end do
    call expect(index_root>0,'constructor metadata root is retained')
    do which=1,2
        q=p;q%ne=q%ne+1
        q%expressions(q%ne)=expr_t(kind=ex_user_call,typ=ty_integer,scope=0,symbol=1)
        if(which==1)q%expressions(index_root)%length_expr=q%ne
        if(which==2)q%expressions(index_root)%constructor_kind_expr=q%ne
        call reject_metadata('auxiliary constructor user-call edge')
    end do
    which=0
    call prepare('undefined index',declarations,'u=27'//nl//operation)
    call bind('xy'//nl);call run_error('uninitialized');call unchanged_cursor()
    call prepare('below lower bound',declarations,initialization//'i=-2'//nl//operation)
    call bind('xy'//nl);call run_error('bound');call unchanged_cursor()
    call prepare('above upper bound',declarations,initialization//'i=2'//nl//operation)
    call bind('xy'//nl);call run_error('bound');call unchanged_cursor()
    call prepare('unallocated fixed target','integer::u,ios'//nl//'character(4),allocatable::a(:)', &
        'u=27'//nl//'read(u,"(a)",iostat=ios)a(1)')
    call bind('xy'//nl);call run_error('unallocated');call unchanged_cursor()
    call prepare('empty target','integer::u,ios'//nl//'character(4)::a(0)', &
        'u=27'//nl//'read(u,"(a)",iostat=ios)a(1)')
    call bind('xy'//nl);call run_error('bound');call unchanged_cursor()
    call prepare('EOF only invalidates addressed element',declarations,initialization//operation// &
        'if(ios/=-1.or.i/=0)stop 3'//nl//'if(a(-1)/="KEEP".or.a(1)/="LAST")stop 4')
    call bind('');call run_ok()
    call expect(inputs(1)%position==1.and.inputs(1)%endfile,'EOF changes only endfile state')
    call prepare('EOF addressed element cannot be read',declarations,initialization//operation// &
        'if(a(0)=="old!")stop 5')
    call bind('');call run_error('uninitialized')
    call prepare('second EOF status is positive',declarations,initialization//operation// &
        operation//'if(ios<=0)stop 6'//nl//'if(a(-1)/="KEEP".or.a(1)/="LAST")stop 7')
    call bind('');call run_ok()
    call prepare('backspace from endfile rereads last record',declarations,initialization//operation//operation// &
        'if(ios/=-1)stop 8'//nl//'backspace(u)'//nl//'backspace(u)'//nl//operation//check_success)
    call bind('xy'//nl);call run_ok()
    call prepare('record limits',declarations,initialization//operation)
    call bind(repeat('x',65536)//nl);call run_ok()
    call expect(inputs(1)%position==65538,'maximum complete record consumed')
    call bind(repeat('x',65537)//nl);call run_error('record exceeds');call unchanged_cursor()
    do j=0,3
        call bind('x'//achar(controls(j+1))//'b'//nl)
        call run_error('text records');call unchanged_cursor()
    end do
    call bind('xy'//nl);inputs(1)%unit=28
    call run_error('not explicitly bound');call unchanged_cursor()
    call bind(repeat('x',65536)//nl)
    d=diagnostic_t();call execute_program(p,d,max_steps=100_int64,input_units=inputs)
    call expect(d%code==2,'bounded record scanning consumes instruction budget')
    call unchanged_cursor()
    call prepare('zero-length elements consume record','integer::u,ios'//nl//'character(0)::a(2)', &
        'u=27'//nl//'read(u,"(a)",iostat=ios)a(2)'//nl//'if(ios/=0.or.len(a)/=0)stop 9')
    call bind('xy'//nl);call run_ok();call expect(inputs(1)%position==4,'zero length record cursor')
    call prepare('fixed array live CHARACTER cap','integer::u,ios'//nl//'character(65536)::a(257)', &
        'u=27'//nl//'read(u,"(a)",iostat=ios)a(1)')
    call bind('xy'//nl);call run_error('byte limit');call unchanged_cursor()
    write(error_unit,'(a,i0)')'formatted READ element assertions: ',checks
contains
    subroutine reject_metadata(detail)
        character(*),intent(in)::detail
        call expect(.not.valid_external_read(q,q%code(pc)),detail//' public guard')
        d=diagnostic_t();call verify_frontend(source,q,d)
        call expect(d%code==1,detail//' independent adapter')
        call bind('xy'//nl);d=diagnostic_t();call execute_program(q,d,input_units=inputs)
        call expect(d%code==2,detail//' source-free runtime')
        call unchanged_cursor()
    end subroutine
    subroutine prepare(name,decl,body)
        character(*),intent(in)::name,decl,body
        label=name;source='program p'//nl//'implicit none'//nl//decl//nl//body//nl//'end program'
        d=diagnostic_t();call parse_subset(source,p,d)
        call expect(d%code==0,'native source parser')
        call verify_frontend(source,p,d)
        call expect(d%code==0,'native independent producer')
    end subroutine
    subroutine bind(data)
        character(*),intent(in)::data
        inputs(1)=input_unit_t(unit=27,data=data)
    end subroutine
    subroutine run_ok()
        d=diagnostic_t();call execute_program(p,d,input_units=inputs)
        call expect(d%code==0,'native runtime succeeds')
    end subroutine
    subroutine run_error(fragment)
        character(*),intent(in)::fragment
        d=diagnostic_t();call execute_program(p,d,input_units=inputs)
        call expect(d%code==2,'native runtime controlled rejection')
        call expect(allocated(d%message),'native error has diagnostic')
        call expect(index(d%message,fragment)>0,'native error identifies reason')
    end subroutine
    subroutine unchanged_cursor()
        call expect(inputs(1)%position==1.and..not.inputs(1)%endfile,'preflight failure preserves cursor/endfile')
    end subroutine
    subroutine expect(ok,detail)
        logical,intent(in)::ok
        character(*),intent(in)::detail
        checks=checks+1
        if(ok)return
        write(error_unit,*)'FAIL ',checks,which,': ',label,': ',detail
        if(allocated(d%message))write(error_unit,*)d%message
        error stop 1
    end subroutine
end program
