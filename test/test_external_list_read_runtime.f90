! SPDX-License-Identifier: MIT
! Independent public embedding tests; never opens an interpreted or native input file.
program test_external_list_read_runtime
    use, intrinsic :: iso_fortran_env, only: error_unit,int64
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: execute_program,input_unit_t
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::decl='integer::u,s,a(2),b'//nl//'character(8)::word'//nl
    type(program_t)::p,q
    type(diagnostic_t)::d
    type(input_unit_t),allocatable::inputs(:),other(:)
    character(:),allocatable::source
    integer::checks,j,pc,which
    checks=0;which=0
    call prepare('u=7'//nl//'read(u,*,iostat=s)a'//nl// &
        'if(s/=0.or.any(a/=[1,2]))stop 1')
    call bind('1'//nl//'2'//nl//'3')
    call run_ok();call expect(inputs(1)%position==5,'list READ consumes final used record only')
    call expect(.not.inputs(1)%endfile,'successful transfer has no endfile')
    call prepare('u=7'//nl//'backspace(unit=u,iostat=s)'//nl//'if(s/=0)stop 1')
    call run_ok();call expect(inputs(1)%position==3,'BACKSPACE crosses one consumed record')
    call run_ok();call expect(inputs(1)%position==1,'BACKSPACE reaches initial point')
    call run_ok();call expect(inputs(1)%position==1,'initial point is a no-op')
    call bind('1'//nl//'2'//nl);inputs(1)%position=5;inputs(1)%endfile=.true.
    call run_ok();call expect(inputs(1)%position==5.and..not.inputs(1)%endfile,'EOF backspace only clears flag')
    call run_ok();call expect(inputs(1)%position==3,'second EOF backspace reaches data')
    call bind('');inputs(1)%endfile=.true.
    call run_ok();call expect(inputs(1)%position==1.and..not.inputs(1)%endfile,'empty EOF backspace clears flag')
    call run_ok();call expect(inputs(1)%position==1,'empty start remains stable')
    call bind('1'//achar(13)//nl//nl//'2');inputs(1)%position=6
    call run_ok();call expect(inputs(1)%position==5,'unterminated last record BACKSPACE')
    call run_ok();call expect(inputs(1)%position==4,'empty CRLF-adjacent record BACKSPACE')
    call run_ok();call expect(inputs(1)%position==1,'CRLF record BACKSPACE')
    ! Caller-owned binding arrays must remain independent across execute_program calls.
    call bind('1'//nl//'2'//nl);other=inputs;inputs(1)%position=5
    call run_ok();call expect(inputs(1)%position==3.and.other(1)%position==1,'binding tables are independent')
    do which=1,5
        call bind('1'//nl//'2'//nl)
        select case(which)
        case(1);inputs(1)%unit=0
        case(2);inputs(1)%position=0
        case(3);inputs(1)%position=2
        case(4);inputs(1)%endfile=.true.
        case(5);deallocate(inputs(1)%data)
        end select
        call run_error('external input')
    end do
    call bind('1'//nl);inputs(1)%unit=8
    call run_error('not explicitly bound');call expect(inputs(1)%position==1,'unbound BACKSPACE is inert')
    call prepare('u=7'//nl//'read(u,*,iostat=s)a')
    call bind('1'//nl//'bad'//nl//'3'//nl)
    call run_ok();call expect(inputs(1)%position==7,'recoverable numeric error consumes invalid record')
    call prepare('u=7'//nl//'a=9'//nl//'read(u,*,iostat=s)a'//nl//'b=sum(a)')
    call bind('1'//nl);call run_error('uninitialized')
    call expect(inputs(1)%endfile,'short input records EOF even with IOSTAT')
    call prepare('u=7'//nl//'read(u,*,iostat=s)word'//nl//'if(word/="abcd")stop 1')
    call bind("'ab"//achar(13)//nl//nl//"cd'"//nl//'discarded')
    call run_ok();call expect(inputs(1)%position==11,'quoted continuation byte cursor')
    call prepare('u=7'//nl//'read(u,*,iostat=s)b')
    call bind('1'//achar(0)//nl);call run_error('text records')
    call expect(inputs(1)%position==1,'invalid complete record cannot partially advance')
    call bind(repeat(' ',65537)//nl);call run_error('65536')
    call expect(inputs(1)%position==1,'oversize record cannot advance')
    call bind(repeat(' ',1000)//'1'//nl)
    d=diagnostic_t();call execute_program(p,d,max_steps=40_int64,input_units=inputs)
    call expect(d%code==2,'list READ budget exhaustion is checked')
    call expect(inputs(1)%position==1,'record budget failure cannot advance')
    ! Public metadata corruption must fail before any input is consumed.
    pc=0
    do j=1,p%nc
        if(p%code(j)%op==op_read_external)pc=j
    end do
    call expect(pc>0,'READ mutation instruction found')
    q=p;q%code(pc)%format='*';call bind('1'//nl)
    d=diagnostic_t();call execute_program(q,d,input_units=inputs)
    call expect(d%code==2.and.inputs(1)%position==1,'forged READ format rejected before transfer')
    call prepare('u=7'//nl//'backspace(u,iostat=s)')
    do j=1,p%nc
        if(p%code(j)%op==op_backspace)pc=j
    end do
    q=p;q%code(pc)%items=[integer::];call bind('1'//nl);inputs(1)%position=3
    d=diagnostic_t();call execute_program(q,d,input_units=inputs)
    call expect(d%code==2.and.inputs(1)%position==3,'forged BACKSPACE items rejected before movement')
    call optional_and_alias()
    write(error_unit,'(a,i0,a)')'external list READ runtime: ',checks,' checks passed'
contains
    subroutine load()
        d=diagnostic_t();call parse_subset(source,p,d);call expect(d%code==0,'parser')
        call verify_frontend(source,p,d);call expect(d%code==0,'independent producer')
    end subroutine
    subroutine prepare(body)
        character(*),intent(in)::body
        source='program p'//nl//'implicit none'//nl//decl//body//nl//'end program'
        call load()
    end subroutine
    subroutine bind(data)
        character(*),intent(in)::data
        if(allocated(inputs))deallocate(inputs)
        allocate(inputs(1));inputs(1)=input_unit_t(unit=7,data=data)
    end subroutine
    subroutine run_ok()
        d=diagnostic_t();call execute_program(p,d,input_units=inputs)
        call expect(d%code==0,'runtime success')
    end subroutine
    subroutine run_error(fragment)
        character(*),intent(in)::fragment
        d=diagnostic_t();call execute_program(p,d,input_units=inputs)
        call expect(d%code==2,'checked runtime failure')
        call expect(allocated(d%message),'runtime diagnostic present')
        call expect(index(d%message,fragment)>0,'runtime failure identity')
    end subroutine
    subroutine optional_and_alias()
        integer::i
        character(:),allocatable::statement,arguments,declarations
        do i=1,4
            statement='read(u,*,iostat=s)a';arguments='call f(u)'
            declarations='integer,intent(in)::u'//nl//'integer,intent(out),optional::a'//nl//'integer::s'
            if(i==2)then
                statement='backspace(u,iostat=a)'
            else if(i>=3)then
                arguments='call f(u,u)'
                declarations='integer,intent(in)::u'//nl//'integer,intent(out)::a'//nl//'integer::s'
                if(i==4)statement='backspace(u,iostat=a)'
            end if
            source='module m'//nl//'contains'//nl//'subroutine f(u,a)'//nl//declarations//nl// &
                statement//nl//'end subroutine'//nl//'end module'//nl//'program p'//nl//'use m'//nl// &
                'integer::u'//nl//'u=7'//nl//arguments//nl//'end program'
            call load();call bind('1'//nl)
            d=diagnostic_t();call execute_program(p,d,input_units=inputs)
            call expect(d%code==2,'absent optional or alias rejected')
            call expect(inputs(1)%position==1,'optional/alias rejection leaves cursor unchanged')
        end do
    end subroutine
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok)return
        write(error_unit,*)'FAIL ',checks,which,': ',label
        if(allocated(d%message))write(error_unit,*)d%message
        error stop 1
    end subroutine
end program
