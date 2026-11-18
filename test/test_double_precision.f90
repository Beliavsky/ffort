! SPDX-License-Identifier: MIT
program test_double_precision
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    use fortfront_compiler
    use fortfront_ast,only:declaration_node,function_def_node
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    type(compiler_frontend_options_t)::opts
    type(compiler_frontend_result_t)::front
    type(declaration_query_t)::decl
    type(resolved_type_query_t)::resolved
    character(*),parameter::nl=new_line('a')
    character(:),allocatable::source,spec
    integer::variant,i,j,found,checks=0
    opts%input_mode=INPUT_MODE_STANDARD
    opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.;opts%run_semantics=.true.
    do variant=1,6
        select case(variant)
        case(1);spec='double precision'
        case(2);spec='doubleprecision'
        case(3);spec='DoUbLe PrEcIsIoN'
        case(4);spec='DoUbLePrEcIsIoN'
        case(5);spec='double'//achar(9)//'precision'
        case(6);spec='double & ! type spelling'//nl//' ! retained continuation comment'//nl//' & precision'
        end select
        source='module m'//nl//'implicit none'//nl// &
            spec//',parameter::factor=2.0d0,values(2)=[1.0d0,3.0d0]'//nl// &
            spec//',public::counter'//nl// &
            'interface twice'//nl//'module procedure twice_dp'//nl//'end interface'//nl// &
            'contains'//nl//'pure '//spec//' function twice_dp(x) result(y)'//nl// &
            spec//',intent(in)::x'//nl//'y=factor*x'//nl//'end function'//nl// &
            spec//' elemental function plus_one(x) result(y)'//nl// &
            spec//',intent(in)::x'//nl//'y=x+1.0d0'//nl//'end function'//nl// &
            'end module'//nl//'program p'//nl//'use m'//nl//'implicit none'//nl// &
            spec//' bare, a(2)'//nl//spec//',target::target_values(2)'//nl// &
            spec//',pointer::ptr(:)'//nl//spec//',allocatable::alloc(:)'//nl// &
            'bare=twice(3.0d0)'//nl//'a=plus_one(values)'//nl// &
            'target_values=a'//nl//'ptr=>target_values'//nl//'allocate(alloc(2))'//nl// &
            'alloc=ptr'//nl//'counter=bare'//nl// &
            'if(kind(bare)/=8.or.kind(factor)/=8.or.kind(twice(bare))/=8)error stop 1'//nl// &
            'if(counter/=6.0d0.or.any(alloc/=[2.0d0,4.0d0]))error stop 2'//nl// &
            'deallocate(alloc)'//nl//'end program'
        call parse_subset(source,p,d)
        call expect(d%code==0,'recognizer declarations/functions/attributes')
        call verify_frontend(source,p,d)
        call expect(d%code==0,'strict REAL8 adapter agreement')
        call execute_program(p,d)
        call expect(d%code==0,'REAL8 execution and generic selection')
        do j=1,3
            call parse_subset(source,p,d)
            do i=1,p%ns
                if(p%symbols(i)%name=='bare')then
                    select case(j)
                    case(1);p%symbols(i)%real_kind=4
                    case(2);p%symbols(i)%typ=ty_integer
                    case(3);p%symbols(i)%kind_expr=1
                    end select
                end if
            end do
            call verify_frontend(source,p,d)
            call expect(d%code==1,'adapter rejects altered REAL8 metadata')
        end do
        ! Interface bodies remain producer-only: they are not admitted by IR.
        source='module signatures'//nl//'interface'//nl// &
            'pure '//spec//' function external_value(x) result(y)'//nl// &
            spec//',intent(in)::x'//nl//'end function'//nl//'end interface'//nl// &
            'end module'//nl//'program p'//nl//'end program'
        call compile_frontend_from_string(source,front,opts)
        call expect(front%success(),'independent producer interface body')
        found=0
        do i=1,front%arena%entry_count
            if(.not.front%arena%has_node_at(i))cycle
            select type(node=>front%arena%entries(i)%node)
            type is(declaration_node)
                decl=query_declaration(front%arena,i)
                if(.not.decl%found.or..not.allocated(decl%name))cycle
                if(decl%name/='x')cycle
                resolved=query_resolved_type(front%arena,i)
                call expect(resolved%found.and.resolved%type_kind==TREAL.and.resolved%kind_value==8, &
                    'producer dummy resolved REAL8')
                call expect(decl%has_intent.and.decl%intent=='in','producer retains INTENT')
                found=found+1
            type is(function_def_node)
                resolved=query_resolved_type(front%arena,i)
                call expect(resolved%found.and.resolved%type_kind==TREAL.and.resolved%kind_value==8, &
                    'producer function result resolved REAL8')
                found=found+1
            end select
        end do
        call expect(found==2,'producer interface identities')
    end do
    do variant=1,3
        select case(variant)
        case(1)
            source='program p'//nl//'integer::double,precision,doubleprecision'//nl// &
                'double=1'//nl//'precision=2'//nl//'doubleprecision=3'//nl// &
                'call bump(double=double,precision=precision,doubleprecision=doubleprecision)'//nl// &
                'if(double/=2.or.precision/=4.or.doubleprecision/=6)error stop 1'//nl//'contains'//nl// &
                'subroutine bump(double,precision,doubleprecision)'//nl// &
                'integer,intent(inout)::double,precision,doubleprecision'//nl// &
                'double=double+1'//nl//'precision=precision+2'//nl//'doubleprecision=doubleprecision+3'//nl// &
                'end subroutine'//nl//'end program'
        case(2)
            source='program p'//nl//'integer::double(2),doubleprecision(2),precision(2)'//nl// &
                'double(1)=1'//nl//'double(2)=2'//nl//'doubleprecision(1)=3'//nl//'doubleprecision(2)=4'//nl// &
                'precision=double+doubleprecision'//nl//'if(any(precision/=[4,6]))error stop 1'//nl//'end program'
        case(3)
            source='program p'//nl//'if(double(1)/=2.or.precision(2)/=4.or.doubleprecision(3)/=6)error stop 1'//nl// &
                'contains'//nl//'integer function double(x)'//nl//'integer,intent(in)::x'//nl// &
                'double=x+1'//nl//'end function'//nl//'function precision(x) result(y)'//nl// &
                'integer,intent(in)::x'//nl//'integer::y'//nl//'y=x+2'//nl//'end function'//nl// &
                'function doubleprecision(x)'//nl//'integer,intent(in)::x'//nl//'integer::doubleprecision'//nl// &
                'doubleprecision=x+3'//nl//'end function'//nl//'end program'
        end select
        call parse_subset(source,p,d)
        call expect(d%code==0,'contextual identifiers remain unreserved')
        call verify_frontend(source,p,d)
        call expect(d%code==0,'contextual identifier producer/adapter identity')
        call execute_program(p,d)
        call expect(d%code==0,'contextual identifier runtime semantics')
    end do
    do variant=1,8
        select case(variant)
        case(1);spec='double'
        case(2);spec='double complex'
        case(3);spec='doubleprecision(8)'
        case(4);spec='double precision(kind=8)'
        case(5);spec='doubleprecision*8'
        case(6);spec='double precision*16'
        case(7);spec='double precisio'
        case(8);spec='real(16)'
        end select
        source='program p'//nl//spec//'::x'//nl//'print *,1'//nl//'end program'
        call parse_subset(source,p,d)
        call expect(d%code==1,'reject unsupported or malformed double type')
    end do
    print '(a,i0,a)','PASS: ',checks,' DOUBLE PRECISION producer/adapter/runtime checks'
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
