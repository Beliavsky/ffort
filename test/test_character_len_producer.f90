! SPDX-License-Identifier: MIT
program test_character_len_producer
    use fortfront_compiler
    use ast_nodes_core,only:component_access_node
    implicit none
    character(*),parameter::nl=new_line('a')
    type(compiler_frontend_options_t)::opts
    type(compiler_frontend_result_t)::front
    type(resolved_type_query_t)::typ
    integer::checks
    opts%input_mode=INPUT_MODE_STANDARD
    opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.;opts%run_semantics=.true.
    checks=0
    call probe('character(7)::s','s%len',TINT,0,4)
    call probe('character(0)::s','s%LEN',TINT,0,4)
    call probe('character(7)::s(0)','s%len',TINT,0,4)
    call probe('character(7)::s(2,0)','s%len',TINT,0,4)
    call probe('character(7)::s(2,0,2)','s%len',TINT,0,4)
    call probe('character(:),allocatable::s','s%len',TINT,0,4)
    call probe('character(:),allocatable::s(:,:)','s%len',TINT,0,4)
    call probe('type::t'//nl//'real(8)::len'//nl//'end type'//nl//'type(t)::s','s%len',TREAL,0,8)
    call probe('type::t'//nl//'integer::len(2)'//nl//'end type'//nl//'type(t)::s','s%len',TINT,1,4)
    call probe('type::t'//nl//'character(8)::len'//nl//'end type'//nl//'type(t)::s','s%len',TCHAR,0,1)
    print '(a,i0,a)','CHARACTER %LEN: ',checks,' independent producer checks passed'
contains
    subroutine probe(decl,expression,type_kind,rank,kind_value)
        character(*),intent(in)::decl,expression
        integer,intent(in)::type_kind,rank,kind_value
        integer::i,found
        call compile_frontend_from_string('program p'//nl//'implicit none'//nl// &
            decl//nl//'print *,'//expression//nl//'end program',front,opts)
        if(.not.front%success())then
            print *,decl,expression
            if(allocated(front%error_msg))print *,front%error_msg
            error stop 'LEN producer compile failed'
        end if
        found=0
        do i=1,front%arena%entry_count
            if(.not.front%arena%has_node_at(i))cycle
            select type(node=>front%arena%entries(i)%node)
            type is(component_access_node)
                if(.not.allocated(node%component_name))cycle
                found=found+1;typ=query_resolved_type(front%arena,i)
                if(.not.typ%found.or.typ%type_kind/=type_kind.or.typ%rank/=rank.or.typ%kind_value/=kind_value)then
                    print *,decl,expression,typ%found,typ%type_kind,typ%rank,typ%kind_value
                    error stop 'LEN producer type/kind/rank differs'
                end if
            end select
        end do
        if(found/=1)error stop 'LEN producer component missing'
        checks=checks+1
    end subroutine
end program
