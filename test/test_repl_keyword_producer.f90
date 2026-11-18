program test_repl_keyword_producer
    use fortfront_compiler, only: compiler_frontend_result_t, compiler_frontend_options_t, &
        compile_frontend_from_string, INPUT_MODE_STANDARD, OPERATING_MODE_STRICT
    use fortfront_ast, only: assignment_node
    implicit none
    integer :: checks=0
    character,parameter :: nl=achar(10)
    call check('print *, (size(array=a,dim=1))',2,.true.)
    call check('print *, ((size(dim=1,array=a)))',2,.true.)
    call check('print *, (ubound(array=a,dim=1))',2,.true.)
    call check('print *, (size([1,2,3],dim=1))',1,.true.)
    call check('print *, (size(array=a,dim=1),i=1,2)',2,.true.)
    call check('print *, ((i+j,j=1,2),i=1,2)',0,.true.)
    call check('write(*,*) (i,i=1,3)',0,.true.)
    call check('print *, ("a,i=2"), ("b,ARRAY=c")',0,.true.)
    call check('print *, ([1,2,3])',0,.true.)
    call check('print *, (1.0,2.0)',0,.true.)
    call check('print *, ((1.0,2.0))',0,.true.)
    call check('print *, (i,i=1,)',0,.false.)
    call check('print *, (i,i=1,3',0,.false.)
    call check('print *, (i,i=,3)',0,.false.)
    print *, 'keyword producer regression checks:',checks
contains
    subroutine check(statement,expected_keywords,expected_success)
        character(*),intent(in)::statement
        integer,intent(in)::expected_keywords
        logical,intent(in)::expected_success
        type(compiler_frontend_result_t)::front
        type(compiler_frontend_options_t)::opts
        integer::i,keywords
        character(:),allocatable::source
        source='program p'//nl//'implicit none'//nl//'integer :: a(3),i,j'//nl//statement//nl//'end program'//nl
        opts%input_mode=INPUT_MODE_STANDARD
        opts%operating_mode=OPERATING_MODE_STRICT
        opts%standardize=.false.
        opts%run_semantics=.true.
        opts%allow_allocatable_reallocation=.true.
        call compile_frontend_from_string(source,front,opts)
        if(front%success().neqv.expected_success)then
            print *, 'unexpected parse result: ',statement
            if(allocated(front%error_msg))print *,front%error_msg
            error stop 1
        end if
        checks=checks+1
        if(.not.expected_success)return
        keywords=0
        do i=1,front%arena%entry_count
            if(.not.front%arena%has_node_at(i))cycle
            select type(node=>front%arena%entries(i)%node)
            type is(assignment_node)
                if(node%is_keyword_argument)keywords=keywords+1
            end select
        end do
        if(keywords/=expected_keywords)then
            print *, 'speculative keyword nodes retained: ',statement,keywords,expected_keywords
            error stop 1
        end if
        checks=checks+1
    end subroutine
end program
