! SPDX-License-Identifier: MIT
program test_process_queries_producer
    use fortfront_compiler
    use intrinsic_registry,only:is_intrinsic_subroutine,is_intrinsic_function
    use ast_nodes_procedure,only:subroutine_call_node
    implicit none
    character(*),parameter::nl=new_line('a')
    type(compiler_frontend_options_t)::opts
    type(compiler_frontend_result_t)::front
    integer::i,j,found,checks
    character(:),allocatable::body
    checks=0
    opts%input_mode=INPUT_MODE_STANDARD;opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.;opts%run_semantics=.true.
    call expect(is_intrinsic_subroutine('getcwd'),'GETCWD subroutine registry')
    call expect(is_intrinsic_subroutine('GETCWD'),'GETCWD case folding')
    call expect(.not.is_intrinsic_function('getcwd'),'no GETCWD function registry expansion')
    call expect(is_intrinsic_subroutine('get_command_argument'),'standard command registry preserved')
    call compile_frontend_from_string('program p'//nl//'implicit none'//nl// &
        'character(80)::name'//nl//'integer::length,status'//nl// &
        'call getcwd(count=name,status=status)'//nl// &
        'call get_command_argument(number=0,status=status,length=length,value=name)'//nl//'end program',front,opts)
    call expect(front%success(),'producer accepts query keyword lists')
    found=0
    do i=1,front%arena%entry_count
        if(.not.front%arena%has_node_at(i)) cycle
        select type(node=>front%arena%entries(i)%node)
        type is(subroutine_call_node)
            found=found+1
            call expect(allocated(node%name).and.allocated(node%arg_indices),'query source name and arguments retained')
            if(node%name=='getcwd') then
                call expect(size(node%arg_indices)==2,'GETCWD source argument count')
            else if(node%name=='get_command_argument') then
                call expect(size(node%arg_indices)==4,'command source argument count')
            else
                call expect(.false.,'unexpected call source name')
            end if
        end select
    end do
    call expect(found==2,'query source count')
    do j=1,2
        body='call getcwd(name)'
        if(j==2) body='call get_command_argument(0,name)'
        call compile_frontend_from_string('program p'//nl//'implicit none'//nl//'integer::i'//nl// &
            'character(80)::name'//nl//'do concurrent(i=1:2)'//nl//body//nl// &
            'end do'//nl//'end program',front,opts)
        call expect(.not.front%success(),'producer rejects impure process query in DO CONCURRENT')
    end do
    print *, 'process query producer checks passed:',checks
contains
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(.not.ok) then
            print *, 'FAIL ',label
            error stop 1
        end if
    end subroutine
end program
