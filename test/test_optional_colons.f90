! SPDX-License-Identifier: MIT
program test_optional_colons
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    use fortfront_compiler
    use fortfront_ast,only:declaration_node
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    type(compiler_frontend_options_t)::opts
    type(compiler_frontend_result_t)::front
    type(declaration_query_t)::decl
    character(*),parameter::nl=new_line('a')
    character(:),allocatable::source,sep
    integer::variant,i,j,dummy,found,checks=0
    opts%input_mode=INPUT_MODE_STANDARD
    opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.;opts%run_semantics=.true.
    do variant=1,2
        sep=' '
        if(variant==2)sep=' :: '
        source='module m'//nl//'type'//sep//'box'//nl//'integer'//sep//'n'//nl// &
            'end type'//nl//'integer'//sep//'counter'//nl//'contains'//nl// &
            'subroutine bump(x)'//nl//'integer,intent(inout)::x'//nl//'integer'//sep//'step'//nl// &
            'step=2'//nl//'x=x+step'//nl//'end subroutine'//nl//'end module'//nl// &
            'program p'//nl//'use m'//nl//'integer'//sep//'a'//nl//'character(3)'//sep//'text'//nl// &
            'type(box)'//sep//'b'//nl//'a=1'//nl//'call bump(a)'//nl//'counter=a'//nl// &
            "text='abc'"//nl//'b=box(a)'//nl// &
            "if(counter/=3.or.b%n/=3.or.text/='abc')error stop 1"//nl//'end program'
        call parse_subset(source,p,d)
        call expect(d%code==0,'parse optional separators')
        call verify_frontend(source,p,d)
        call expect(d%code==0,'strict adapter agreement')
        call execute_program(p,d)
        call expect(d%code==0,'unchanged execution semantics')
        call compile_frontend_from_string(source,front,opts)
        call expect(front%success(),'independent producer parses optional separators')
        found=0
        do i=1,front%arena%entry_count
            if(.not.front%arena%has_node_at(i))cycle
            select type(node=>front%arena%entries(i)%node)
            type is(declaration_node)
                decl=query_declaration(front%arena,i)
                if(.not.decl%found.or..not.allocated(decl%name))cycle
                select case(decl%name)
                case('a','text','b','counter','step')
                    call expect(.not.decl%has_intent,'producer local attributes preserved')
                    found=found+1
                case('x')
                    call expect(decl%has_intent,'producer dummy attributes preserved')
                    call expect(decl%intent=='inout','producer dummy direction preserved')
                    found=found+1
                end select
            end select
        end do
        call expect(found==6,'producer declaration identities retained')
        do j=1,5
            call parse_subset(source,p,d)
            select case(j)
            case(1)
                do i=1,p%ns
                    if(p%symbols(i)%name=='a')p%symbols(i)%typ=ty_real
                end do
            case(2)
                do i=1,p%ns
                    if(p%symbols(i)%name=='text')p%symbols(i)%character_len=4
                end do
            case(3)
                p%derived_types(1)%component_types(1)=ty_real
            case(4)
                dummy=p%procedures(1)%args(1)
                p%symbols(dummy)%dummy_intent=1
            case(5)
                do i=1,p%ns
                    if(p%symbols(i)%name=='a')p%symbols(i)%rank=1
                end do
            end select
            call verify_frontend(source,p,d)
            call expect(d%code==1,'adapter rejects altered declaration metadata')
        end do
    end do
    print '(a,i0,a)','PASS: ',checks,' optional-separator producer and adapter checks'
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
