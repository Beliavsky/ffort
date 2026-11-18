! SPDX-License-Identifier: MIT
program test_intent_spelling
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    use fortfront_compiler
    use fortfront_ast,only:declaration_node,comment_node
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    type(compiler_frontend_options_t)::opts
    type(compiler_frontend_result_t)::front
    type(declaration_query_t)::decl
    character(*),parameter::nl=new_line('a')
    character(:),allocatable::source,spec
    integer::variant,i,found,which,dummy,comments,checks=0
    opts%input_mode=INPUT_MODE_STANDARD
    opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.;opts%run_semantics=.true.
    do variant=1,10
        select case(variant)
        case(1);spec='inout'
        case(2);spec='in out'
        case(3);spec='In OuT'
        case(4);spec=' in    out '
        case(5);spec='in'//achar(9)//'out'
        case(6);spec='in &'//nl//' & out'
        case(7);spec='in & ! first word'//nl//' ! comment'//nl//' & out'
        case(8);spec='& ! before direction'//nl//' & in out'
        case(9);spec='in out & ! before close'//nl//' & '
        case(10);spec='in &'//nl//nl//' ! comment'//nl//' & out'
        end select
        source='program p'//nl//'integer::a,b'//nl//'a=4'//nl//'b=9'//nl// &
            'call bump(a,b)'//nl//'if(a/=13.or.b/=10) error stop 1'//nl//'contains'//nl// &
            'subroutine bump(x,y)'//nl//'integer,intent('//spec//')::x,y'//nl//'! separate comment retained'//nl// &
            'x=x+y'//nl//'y=y+1'//nl//'end subroutine'//nl//'end program'
        call parse_subset(source,p,d)
        call expect(d%code==0,'recognizer spelling')
        dummy=p%procedures(1)%args(1)
        call expect(p%symbols(dummy)%dummy_intent==3,'recognizer canonical intent')
        call verify_frontend(source,p,d)
        call expect(d%code==0,'strict adapter agreement')
        call execute_program(p,d)
        call expect(d%code==0,'INOUT read/write semantics')
        call compile_frontend_from_string(source,front,opts)
        call expect(front%success(),'independent producer spelling')
        found=0;comments=0
        do i=1,front%arena%entry_count
            if(.not.front%arena%has_node_at(i))cycle
            select type(node=>front%arena%entries(i)%node)
            type is(declaration_node)
                decl=query_declaration(front%arena,i)
                if(.not.decl%found.or..not.decl%has_intent)cycle
                call expect(allocated(decl%intent),'producer intent storage')
                call expect(decl%intent=='inout','producer canonical intent')
                if(allocated(decl%names))then
                    found=found+size(decl%names)
                else
                    found=found+1
                end if
            type is(comment_node)
                if(allocated(node%text))then
                    if(index(node%text,'separate comment retained')>0)comments=comments+1
                end if
            end select
        end do
        call expect(comments==1,'producer retains following full-line comment')
        call expect(found==2,'producer grouped-dummy count')
        do which=0,2
            call parse_subset(source,p,d)
            p%symbols(dummy)%dummy_intent=which
            call verify_frontend(source,p,d)
            call expect(d%code==1,'adapter rejects changed intent')
        end do
        do which=1,2
            call parse_subset(source,p,d)
            p%symbols(dummy)%dummy_intent=which
            call execute_program(p,d)
            call expect(d%code==2,'runtime enforces altered IN/OUT semantics')
        end do
    end do
    do variant=1,11
        select case(variant)
        case(1);spec='in,out'
        case(2);spec='out in'
        case(3);spec='in out out'
        case(4);spec='in in out'
        case(5);spec='i nout'
        case(6);spec='in o ut'
        case(7);spec='inou t'
        case(8);spec=''
        case(9);spec='both'
        case(10);spec='in'//nl//' out'
        case(11);spec='in out) ,intent(inout'
        end select
        source='subroutine p(x)'//nl//'integer,intent('//spec//')::x'//nl// &
            'end subroutine'
        call compile_frontend_from_string(source,front,opts)
        call expect(.not.front%success(),'producer rejects malformed intent')
    end do
    print '(a,i0,a)','PASS: ',checks,' INTENT spelling producer/adapter/runtime checks'
contains
    subroutine expect(ok,message)
        logical,intent(in)::ok
        character(*),intent(in)::message
        checks=checks+1
        if(ok)return
        print *,message,variant,d%code
        if(allocated(d%message))print *,d%message
        if(allocated(front%error_msg))print *,front%error_msg
        error stop 1
    end subroutine
end program
