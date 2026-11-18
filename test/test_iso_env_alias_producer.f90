! SPDX-License-Identifier: MIT
program test_iso_env_alias_producer
    use fortfront_compiler
    use ast_nodes_misc,only:use_statement_node
    implicit none
    type(compiler_frontend_options_t)::opts
    type(compiler_frontend_result_t)::front
    type(declaration_query_t)::decl
    type(resolved_type_query_t)::typ
    character(*),parameter::nl=new_line('a')
    character(:),allocatable::source,uses
    integer::form,i,count_decl,count_use,checks
    checks=0
    opts%input_mode=INPUT_MODE_STANDARD;opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.;opts%run_semantics=.true.
    do form=1,5
        select case(form)
        case(1);uses='use,intrinsic::iso_fortran_env,only:dp=>real64,sp=>real32'
        case(2);uses='use,intrinsic::iso_fortran_env,only: &'//nl// &
            '! before local name'//nl//'& dp &'//nl//'! before arrow'//nl// &
            '& => &'//nl//'! before remote name'//nl//'& real64, sp=>real32'
        case(3);uses='use, &'//nl//'! before nature'//nl//'& intrinsic :: iso_fortran_env, &'//nl// &
            '! before only'//nl//'& only: dp=>real64,sp=>real32'
        case(4);uses='use,intrinsic::iso_fortran_env,only:real128,dp=>real64,sp=>real32'
        case(5);uses='use,intrinsic::iso_fortran_env,only:dp=>real64,sp=>real32 ! trailing comment'//nl// &
            '! Not a continued USE statement'
        end select
        source='program p'//nl//uses//nl//'implicit none'//nl// &
            'real(dp)::x'//nl//'real(sp)::y'//nl//'x=1.0_dp'//nl//'y=2.0_sp'//nl//'end program'
        call compile_frontend_from_string(source,front,opts)
        call expect(front%success(),'strict producer accepts aliases and comments')
        count_decl=0;count_use=0
        do i=1,front%arena%entry_count
            if(.not.front%arena%has_node_at(i))cycle
            select type(n=>front%arena%entries(i)%node)
            type is(use_statement_node)
                count_use=count_use+1
                call expect(n%is_intrinsic.and.n%has_only,'intrinsic ONLY nature')
                call expect(allocated(n%rename_list),'rename pairs allocated')
                call expect(size(n%rename_list)==4,'both alias pairs retained')
                call expect(n%rename_list(1)%s=='dp'.and.n%rename_list(2)%s=='real64'.and. &
                    n%rename_list(3)%s=='sp'.and.n%rename_list(4)%s=='real32','exact remote/local pairs')
                if(form==4)then
                    call expect(allocated(n%only_list),'ordinary only name retained')
                    call expect(size(n%only_list)==1,'only list size')
                    call expect(n%only_list(1)%s=='real128','unsupported kind import retained')
                end if
            end select
            decl=query_declaration(front%arena,i)
            if(.not.decl%found)cycle
            if(decl%name/='x'.and.decl%name/='y')cycle
            typ=query_resolved_type(front%arena,i)
            call expect(typ%found,'declared kind query')
            if(decl%name=='x')call expect(typ%kind_value==8,'alias REAL64 metadata')
            if(decl%name=='y')call expect(typ%kind_value==4,'alias REAL32 metadata')
            count_decl=count_decl+1
        end do
        call expect(count_use==1.and.count_decl==2,'all producer targets found')
    end do
    source='program p'//nl//'use,intrinsic::iso_fortran_env,only:dp=>real64,'//nl// &
        '! No continuation marker before the logical newline'//nl//'sp=>real32'//nl// &
        'implicit none'//nl//'end program'
    call compile_frontend_from_string(source,front,opts)
    call expect(.not.front%success(),'logical newline is not a continuation')
    print *, 'PASS: ISO_FORTRAN_ENV independent producer assertions:',checks
contains
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok)return
        print *,form,label
        if(allocated(front%error_msg))print *,front%error_msg
        error stop 'ISO_FORTRAN_ENV producer failure'
    end subroutine
end program
