! SPDX-License-Identifier: MIT
program test_derived_defaults_producer
    use fortfront_compiler
    use ast_nodes_data,only:module_node,derived_type_node,multi_unit_container_node,declaration_node
    use ast_nodes_core,only:program_node
    implicit none
    type(compiler_frontend_options_t)::opts
    type(compiler_frontend_result_t)::front
    character(*),parameter::nl=new_line('a')
    character(*),parameter::prefix='module statistics_mod'//nl//'implicit none'//nl// &
        'type :: dt'//nl//'real :: y=1000.0'//nl//'end type dt'//nl//'end module'//nl
    character(:),allocatable::source,body
    integer::mode,form,i,nmodule,nmain,ntype,ndefault,checks
    checks=0
    opts%operating_mode=OPERATING_MODE_STRICT;opts%standardize=.false.;opts%run_semantics=.true.
    do mode=1,2
        opts%input_mode=INPUT_MODE_STANDARD
        if(mode==2)opts%input_mode=INPUT_MODE_LAZY
        do form=1,4
            body='use statistics_mod'//nl//'implicit none'//nl//'type(dt)::x'//nl//'print*,x%y'//nl//'end'
            if(form==2)body='program p'//nl//body//' program'
            if(form==3)body='use statistics_mod'//nl//'implicit none'//nl//'type(dt)::x'//nl// &
                'x=dt()'//nl//'print*,x%y'//nl//'end'
            if(form==4)body='use statistics_mod'//nl//'implicit none'//nl//'integer::i junk'//nl//'end'
            source=prefix//body
            call compile_frontend_from_string(source,front,opts)
            if(form==4)then
                call expect(.not.front%success(),'trailing declaration tokens stay rejected')
                call expect(allocated(front%error_msg),'source rejection diagnostic exists')
                call expect(index(front%error_msg,'unexpected token after statement')>0,'exact trailing-token guard')
                cycle
            end if
            call expect(front%success(),'module plus anonymous/explicit main succeeds')
            nmodule=0;nmain=0;ntype=0;ndefault=0
            do i=1,front%arena%entry_count
                if(.not.front%arena%has_node_at(i))cycle
                select type(n=>front%arena%entries(i)%node)
                type is(module_node)
                    nmodule=nmodule+1
                type is(program_node)
                    nmain=nmain+1
                type is(derived_type_node)
                    ntype=ntype+1
                type is(declaration_node)
                    if(n%has_initializer)then
                        ndefault=ndefault+1
                        call expect(n%line==4.and.n%initializer_index>0,'component default source root retained')
                    end if
                end select
            end do
            call expect(nmodule==1.and.nmain==1.and.ntype==1.and.ndefault==1,'unit and component identities retained')
            select type(n=>front%arena%entries(front%root_index)%node)
            type is(multi_unit_container_node)
                call expect(.true.,'standard module/main container')
            class default
                call expect(.false.,'unexpected mixed container')
            end select
        end do
    end do
    print *, 'PASS derived defaults producer assertions:',checks
contains
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok)return
        print *,mode,form,label
        if(allocated(front%error_msg))print *,front%error_msg
        error stop 'derived defaults producer failure'
    end subroutine
end program
