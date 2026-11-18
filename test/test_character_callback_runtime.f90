! SPDX-License-Identifier: MIT
program test_character_callback_runtime
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='module m'//nl//'implicit none'//nl// &
        'type::box'//nl//'integer::value'//nl//'contains'//nl// &
        'procedure::output'//nl//'generic::write(formatted)=>output'//nl//'end type'//nl// &
        'contains'//nl//'subroutine output(dtv,unit,iotype,v_list,iostat,iomsg)'//nl// &
        'class(box),intent(in)::dtv'//nl//'integer,intent(in)::unit'//nl// &
        'character(*),intent(in)::iotype'//nl//'integer,intent(in)::v_list(:)'//nl// &
        'integer,intent(out)::iostat'//nl//'character(*),intent(inout)::iomsg'//nl// &
        'character(len(iotype))::local'//nl// &
        'if(len(iomsg)/=1024) error stop 1'//nl// &
        'if(iotype=="DT".and.len(iotype)/=2) error stop 2'//nl// &
        'if(iotype=="LISTDIRECTED".and.len(iotype)/=12) error stop 3'//nl// &
        'local=iotype'//nl//'if(local/=iotype) error stop 4'//nl// &
        'iomsg="callback"'//nl//'if(len(iomsg)/=1024) error stop 5'//nl// &
        'write(unit,"(i0)",iostat=iostat,iomsg=iomsg) dtv%value'//nl// &
        'end subroutine'//nl//'end module'//nl//'program test'//nl//'use m'//nl// &
        'implicit none'//nl//'type(box)::b'//nl//'b=box(7)'//nl// &
        'print *,b'//nl//'print "(dt)",b'//nl//'end program'
    call parse_subset(source,p,d)
    call require_ok('parse')
    call verify_frontend(source,p,d)
    call require_ok('adapter')
    call execute_program(p,d)
    call require_ok('runtime')
    print '(a)','PASS: defined WRITE CHARACTER descriptors and callback local lengths'
contains
    subroutine require_ok(label)
        character(*),intent(in)::label
        if(d%code/=0) then
            print *,label,': ',d%message
            error stop 'defined WRITE CHARACTER regression'
        end if
    end subroutine
end program
