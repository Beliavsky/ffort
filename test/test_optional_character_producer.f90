! SPDX-License-Identifier: MIT
program test_optional_character_producer
    use fortfront_compiler
    use fortfront_ast,only:declaration_node
    implicit none
    character(*),parameter::nl=new_line('a')
    type(compiler_frontend_options_t)::opts
    type(compiler_frontend_result_t)::front
    type(declaration_query_t)::decl
    character(:),allocatable::length,attrs,names,source
    integer::l,order,grouped,i,found,checks
    opts%input_mode=INPUT_MODE_STANDARD
    opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.
    opts%run_semantics=.true.
    checks=0
    do l=1,2
        if(l==1)then
            length='4'
        else
            length='*'
        end if
        do order=1,2
            if(order==1)then
                attrs='optional,intent(in)'
            else
                attrs='intent(in),optional'
            end if
            do grouped=1,2
                names='x'
                if(grouped==2) names='x,y'
                source='subroutine p('//names//')'//nl//'implicit none'//nl// &
                    'character('//length//'),'//attrs//'::'//names//nl//'end subroutine'
                call compile_frontend_from_string(source,front,opts)
                if(.not.front%success())error stop 'producer rejected OPTIONAL CHARACTER'
                found=0
                do i=1,front%arena%entry_count
                    if(.not.front%arena%has_node_at(i))cycle
                    select type(node=>front%arena%entries(i)%node)
                    type is(declaration_node)
                        decl=query_declaration(front%arena,i)
                        if(.not.decl%found)cycle
                        if(.not.allocated(decl%name))cycle
                        if(decl%name/='x'.and.decl%name/='y')cycle
                        if(.not.decl%is_optional)error stop 'producer lost OPTIONAL'
                        if(.not.decl%has_character_length)error stop 'producer lost length flag'
                        if(.not.allocated(decl%character_length_expr))error stop 'producer lost length'
                        if(decl%character_length_expr/=length)error stop 'producer changed length'
                        if(allocated(decl%names))then
                            found=found+size(decl%names)
                        else
                            found=found+1
                        end if
                    end select
                end do
                if(found/=grouped)then
                    print *,length,attrs,names,found
                    error stop 'producer declaration count'
                end if
                checks=checks+found
            end do
        end do
    end do
    print *, 'PASS: OPTIONAL CHARACTER producer declarations:',checks
end program
