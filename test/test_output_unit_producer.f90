! SPDX-License-Identifier: MIT
program test_output_unit_producer
    use fortfront_compiler
    use ast_nodes_misc,only:use_statement_node
    use ast_nodes_io,only:write_statement_node
    implicit none
    type(compiler_frontend_options_t)::opts
    type(compiler_frontend_result_t)::front
    character(*),parameter::nl=new_line('a')
    character(:),allocatable::source,uses,local
    integer::form,i,count_use,count_write,checks
    checks=0
    opts%input_mode=INPUT_MODE_STANDARD;opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.;opts%run_semantics=.true.
    do form=1,4
        select case(form)
        case(1);uses='use iso_fortran_env,only:output_unit';local='output_unit'
        case(2);uses='use,intrinsic::iso_fortran_env,only:output_unit';local='output_unit'
        case(3);uses='use :: iso_fortran_env,only:u=>output_unit';local='u'
        case(4);uses='use,intrinsic::iso_fortran_env,only:u=>output_unit';local='u'
        end select
        source='program p'//nl//uses//nl//'implicit none'//nl// &
            'write(unit='//local//",fmt='(a)') 'ok'"//nl//'end program'
        call compile_frontend_from_string(source,front,opts)
        call expect(front%success(),'strict producer accepts OUTPUT_UNIT forms')
        count_use=0;count_write=0
        do i=1,front%arena%entry_count
            if(.not.front%arena%has_node_at(i))cycle
            select type(n=>front%arena%entries(i)%node)
            type is(use_statement_node)
                count_use=count_use+1
                call expect(n%has_only.and..not.n%is_non_intrinsic,'ONLY nature remains explicit')
                call expect(n%is_intrinsic.eqv.(form==2.or.form==4),'source module nature preserved')
                call expect(n%module_name=='iso_fortran_env','module name preserved')
                if(form<=2)then
                    call expect(allocated(n%only_list),'only names allocated')
                    call expect(size(n%only_list)==1,'only name count')
                    call expect(n%only_list(1)%s=='output_unit','exact ordinary name')
                else
                    call expect(allocated(n%rename_list),'rename pairs allocated')
                    call expect(size(n%rename_list)==2,'rename pair count')
                    call expect(n%rename_list(1)%s=='u'.and.n%rename_list(2)%s=='output_unit','exact alias identity')
                end if
            type is(write_statement_node)
                count_write=count_write+1
                call expect(n%unit_spec==local,'WRITE unit name preserved')
                call expect(n%is_formatted,'formatted WRITE remains formatted')
                call expect(n%specifiers(1)%name=='unit'.and.n%specifiers(1)%value==local,'named UNIT preserved')
            end select
        end do
        call expect(count_use==1.and.count_write==1,'producer targets found once')
    end do
    print *, 'PASS: OUTPUT_UNIT producer assertions:',checks
contains
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok)return
        print *,form,label
        if(allocated(front%error_msg))print *,front%error_msg
        error stop 'OUTPUT_UNIT producer failure'
    end subroutine
end program
