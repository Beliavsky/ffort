! SPDX-License-Identifier: MIT
program test_character_plus_producer
    use fortfront_compiler, only: compiler_frontend_result_t,compiler_frontend_options_t, &
        compile_frontend_from_string,INPUT_MODE_STANDARD,OPERATING_MODE_STRICT, &
        query_resolved_type,resolved_type_query_t,TINT,TREAL,TCHAR
    use fortfront_ast, only: binary_op_node,call_or_subscript_node
    implicit none
    character(*),parameter::nl=new_line('a')
    type(compiler_frontend_result_t)::front
    type(compiler_frontend_options_t)::options
    type(resolved_type_query_t)::q
    character(:),allocatable::source,call,decl,prefix,body,op,signature
    integer::which,j,n,checks,want_rank
    logical::want_found,operator_case
    options%input_mode=INPUT_MODE_STANDARD;options%operating_mode=OPERATING_MODE_STRICT
    options%standardize=.false.;options%run_semantics=.true.;checks=0
    do which=1,20
        decl='integer,optional,intent(in)::a,b'//nl//'integer,intent(in)::c'
        body='r=c'//nl//'if(present(a))r=r+a'//nl//'if(present(b))r=r+b'
        prefix='';call='choose(c=3)';want_found=.true.;want_rank=0;operator_case=.false.
        signature='a,b,c'
        select case(which)
        case(2);call='choose(1,c=3)'
        case(3);call='choose(c=3,b=2,a=1)'
        case(4)
            decl='integer,optional,intent(in)::a,b,c';body='r=1';call='choose()'
        case(5);call='choose(a=1)';want_found=.false.
        case(6);call='choose(c=3,c=4)';want_found=.false.
        case(7);call='choose(c=3,d=4)';want_found=.false.
        case(8);call='choose(c=.true.)';want_found=.false.
        case(9);call='choose(c=3_8)';want_found=.false.
        case(10);call='choose(c=3,4)';want_found=.false.
        case(11);call='choose(1,2,3,4)';want_found=.false.
        case(12);call='choose(c=[1,2])';want_found=.false.
        case(13);call='choose(c=[1,2])';prefix='elemental ';want_rank=1
        case(14);call='choose([1,2],c=3)';prefix='elemental ';want_rank=1
        case(15)
            ! An omitted optional array contributes no rank to a scalar result.
            decl='integer,optional,intent(in)::a(:),b'//nl//'integer,intent(in)::c';body='r=c'
        case(16:20)
            operator_case=.true.;signature='a,b';call='"x"+3';body='r=b';op='+'
            decl='character(*),intent(in)::a'//nl//'integer,intent(in)::b'
            if(which==17)then
                decl='character(*),intent(in)::a'//nl//'integer,optional,intent(in)::b';want_found=.false.
            else if(which==18)then
                call='"x"+3_8';want_found=.false.
            else if(which==19)then
                call='3+"x"';want_found=.false.
            else if(which==20)then
                call='"x"+[1,2]';prefix='elemental ';want_rank=1
            end if
        end select
        source='module m'//nl//'implicit none'//nl
        if(operator_case)then
            source=source//'interface operator(+)'//nl
        else
            source=source//'interface choose'//nl
        end if
        source=source//'module procedure f'//nl//'end interface'//nl//'contains'//nl// &
            prefix//'integer function f('//signature//') result(r)'//nl//decl//nl//body//nl// &
            'end function'//nl//'end module'//nl//'program p'//nl//'use m'//nl//'implicit none'//nl// &
            'print *, '//call//nl//'end program'//nl
        call compile_frontend_from_string(source,front,options)
        n=0
        do j=1,front%arena%entry_count
            if(.not.front%arena%has_node_at(j))cycle
            select type(node=>front%arena%entries(j)%node)
            type is(call_or_subscript_node)
                if(operator_case.or..not.allocated(node%name))cycle
                if(node%name/='choose')cycle
            type is(binary_op_node)
                if(.not.operator_case.or..not.allocated(node%operator))cycle
                if(node%operator/='+')cycle
            class default
                cycle
            end select
            n=n+1;q=query_resolved_type(front%arena,j)
            if(q%found.neqv.want_found)then
                print *,which,q%found
                error stop 'optional generic/operator producer match differs'
            end if
            if(q%found)then
                if(q%type_kind/=TINT.or.q%kind_value/=4.or.q%rank/=want_rank) &
                    error stop 'optional generic/operator producer result differs'
            end if
        end do
        if(n/=1)then
            print *,which,n
            error stop 'expected producer occurrence absent'
        end if
        checks=checks+1
    end do
    print '(a,i0,a)','PASS: ',checks,' optional-generic and CHARACTER plus producer guards'
end program
