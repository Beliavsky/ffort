! SPDX-License-Identifier: MIT
! Deliberately bounded syntax contract. Every token must be consumed.
module fi_parser
    use, intrinsic :: iso_fortran_env, only: int64, real32, real64
    use, intrinsic :: ieee_arithmetic, only: ieee_is_finite
    use fi_ir
    use fi_limits, only: max_source_bytes, max_tokens, max_access_names, max_only_names
    use fi_runtime, only: execute_program, evaluate_constant, evaluate_constant_array, evaluate_constant_shape, validate_print_format
    implicit none
    private
    public :: parse_subset
    integer, parameter :: tk_eof=0, tk_name=1, tk_integer=2, tk_real=3, tk_string=4, tk_op=5, tk_eol=6
    integer, parameter :: max_depth=64
    type :: token_t
        character(:), allocatable :: text
        integer :: kind=0, line=1, column=1
    end type
    type :: parser_t
        type(token_t), allocatable :: tokens(:)
        integer :: n=0, p=1, depth=0, block_depth=0
        integer :: active_do(max_depth)=0, active_do_entry(max_depth)=0
        character(63) :: active_do_name(max_depth)=""
        integer :: constructor_depth=0, constructor_owners(max_constructor_do_depth)=0
        integer :: constructor_symbols(max_constructor_do_depth)=0
        character(63) :: constructor_names(max_constructor_do_depth)=""
        integer :: scope=0, named_do_count=0
        integer :: named_do_scope(max_instructions)=0
        character(63) :: named_do_names(max_instructions)=""
        character(63), allocatable :: public_names(:,:), private_names(:,:)
        integer :: n_public(max_modules)=0, n_private(max_modules)=0
        logical :: default_access_set(max_modules)=.false.
        integer :: body_start(max_procedures)=0, body_end(max_procedures)=0
        type(program_t) :: prog
        type(diagnostic_t) :: diag
    end type
contains
    subroutine parse_subset(source, prog, diag)
        character(*), intent(in) :: source
        type(program_t), intent(out) :: prog
        type(diagnostic_t), intent(out) :: diag
        type(parser_t) :: p
        type(instruction_t), allocatable :: initializers(:)
        integer :: typ, main_start, main_end, program_end, f, k, j, ninit, ios
        call lex(source,p)
        if(p%diag%code/=0) then
            diag=p%diag; return
        end if
        allocate(p%prog%symbols(max_symbols),p%prog%expressions(max_expressions),p%prog%code(max_instructions), &
                 p%prog%procedures(max_procedures),p%prog%generics(max_generics), &
                 p%prog%only_names(max_only_names,size(p%prog%uses)), &
                 p%public_names(max_access_names,max_modules),p%private_names(max_access_names,max_modules),stat=ios)
        if(ios/=0) then
            call fail(diag,'Unable to allocate parser metadata storage');return
        end if
        p%prog%only_names='';p%public_names='';p%private_names=''
        call skip_lines(p)
        do while(peek(p)=='module'.and.p%diag%code==0)
            call module_specification(p)
        end do
        p%scope=0
        if(take(p,'program')) then
            call read_name(p,p%prog%name)
            if(any(p%prog%modules==p%prog%name)) call error(p,'PROGRAM name conflicts with a module')
            call finish_line(p)
        end if
        do while(peek(p)=='use'.and.p%diag%code==0)
            call use_statement(p)
        end do
        if(take(p,'implicit')) then
            call expect(p,'none'); call finish_line(p)
        end if
        do while(p%diag%code==0)
            typ=declaration_type(p); if(typ==0) exit
            call declaration(p,typ)
        end do
        ! Validate initialization before admitting any executable side effect.
        if(p%diag%code==0.and.p%prog%nc>0) then
            call execute_program(p%prog,p%diag)
            if(p%diag%code/=0) then
                p%diag%code=1
                p%diag%message='Invalid constant initializer: '//p%diag%message
            end if
        end if
        ninit=p%prog%nc; initializers=p%prog%code(:ninit); p%prog%nc=0
        main_start=p%p; main_end=0; program_end=0
        do k=main_start,p%n-1
            if(k>1) then
                if(p%tokens(k-1)%kind/=tk_eol) cycle
            end if
            if(p%tokens(k)%text=='contains') then
                main_end=k; p%p=k+1; call finish_line(p)
                do while(p%diag%code==0.and.procedure_start(p))
                    call procedure_specification(p,0)
                end do
                program_end=p%p; exit
            end if
            if(p%tokens(k)%text=='end') then
                if(p%tokens(k+1)%kind==tk_eol.or.p%tokens(k+1)%text=='program') then
                    main_end=k; program_end=k; exit
                end if
            end if
        end do
        if(main_end==0) call error(p,'Expected END PROGRAM')
        ! All signatures, including internal procedures, exist before bodies.
        do f=1,p%prog%np
            if(p%diag%code/=0) exit
            p%scope=f; p%p=p%body_start(f)
            p%prog%procedures(f)%first=p%prog%nc+1
            call statements(p)
            if(p%diag%code/=0) exit
            if(p%p/=p%body_end(f)) call error(p,'Unexpected procedure body terminator')
            p%prog%procedures(f)%last=p%prog%nc
        end do
        p%scope=0; p%p=main_start; p%prog%entry_pc=p%prog%nc+1
        do j=1,ninit
            k=emit(p,initializers(j))
        end do
        call statements(p)
        if(p%diag%code==0.and.p%p/=main_end) call error(p,'Unexpected main program terminator')
        p%p=program_end
        if(p%p<1) p%p=1
        p%prog%end_line=p%tokens(p%p)%line; p%prog%end_column=p%tokens(p%p)%column
        call expect(p,'end')
        if(take(p,'program')) then
            if(p%tokens(p%p)%kind==tk_name) then
                if(len_trim(p%prog%name)==0) call error(p,'Named END PROGRAM requires a PROGRAM statement')
                if(peek(p)/=trim(p%prog%name)) call error(p,'END PROGRAM name does not match PROGRAM')
                p%p=p%p+1
            end if
        end if
        call finish_line(p)
        if(p%diag%code==0) then
            if(p%tokens(p%p)%kind/=tk_eof) call error(p,'Only modules followed by one PROGRAM unit are supported')
        end if
        if(p%diag%code==0) call validate_pointer_uses(p)
        if(p%diag%code==0) call validate_calls(p)
        diag=p%diag
        if(diag%code==0) prog=p%prog
    end subroutine

    logical function procedure_start(p)
        type(parser_t),intent(in)::p
        procedure_start=peek(p)=='function'.or.peek(p)=='subroutine'.or.peek(p)=='pure'.or. &
            peek(p)=='simple'.or.peek(p)=='recursive'.or.peek(p)=='elemental'.or.peek(p)=='impure'.or.type_name(peek(p))/=0
    end function
    subroutine module_specification(p)
        type(parser_t),intent(inout)::p
        integer::m,j,typ,n,k
        character(63)::name
        logical::pub,found
        if(p%prog%nm==max_modules) then
            call error(p,'Module limit exceeded (16)'); return
        end if
        call expect(p,'module'); call read_name(p,name)
        if(p%diag%code/=0) return
        if(any(p%prog%modules==name)) then
            call error(p,'Duplicate module name'); return
        end if
        p%prog%nm=p%prog%nm+1; m=p%prog%nm; p%prog%modules(m)=name; p%scope=-m
        call finish_line(p)
        do while(peek(p)=='use'.and.p%diag%code==0)
            call use_statement(p)
        end do
        if(take(p,'implicit')) then
            call expect(p,'none'); call finish_line(p)
        end if
        do while(p%diag%code==0)
            typ=type_name(peek(p))
            if(peek(p)=='type'.and.p%tokens(p%p+1)%text/='(') then
                call derived_definition(p,m)
            else if(peek(p)=='interface') then
                if(p%tokens(p%p+1)%text=='operator') then
                    call operator_interface(p,m)
                else
                    call generic_interface(p,m)
                end if
            else if(typ/=0) then
                call declaration(p,typ)
            else if(peek(p)=='private'.or.peek(p)=='public') then
                pub=take(p,'public')
                if(.not.pub) call expect(p,'private')
                if(take(p,'::')) then
                    do while(p%diag%code==0)
                        call access_name(p,name)
                        if(pub) then
                            n=p%n_public(m)+1; p%n_public(m)=n
                            if(n>max_access_names) then
                                call error(p,'Accessibility name limit exceeded'); return
                            end if
                            p%public_names(n,m)=name
                        else
                            n=p%n_private(m)+1; p%n_private(m)=n
                            if(n>max_access_names) then
                                call error(p,'Accessibility name limit exceeded'); return
                            end if
                            p%private_names(n,m)=name
                        end if
                        if(.not.take(p,',')) exit
                    end do
                else
                    if(p%default_access_set(m)) call error(p,'Default module accessibility specified more than once')
                    p%default_access_set(m)=.true.
                    p%prog%module_private(m)=.not.pub
                end if
                call finish_line(p)
            else
                exit
            end if
        end do
        if(take(p,'contains')) then
            call finish_line(p)
            do while(p%diag%code==0.and.procedure_start(p))
                call procedure_specification(p,m)
            end do
        end if
        if(p%diag%code/=0) return
        call resolve_bindings(p,m)
        if(p%diag%code/=0) return
        call resolve_operators(p,m)
        call resolve_generics(p,m)
        do k=1,p%n_public(m)+p%n_private(m)
            if(k<=p%n_public(m)) then
                name=p%public_names(k,m)
            else
                name=p%private_names(k-p%n_public(m),m)
            end if
            if(count(p%public_names(:,m)==name)+count(p%private_names(:,m)==name)>1) &
                call error(p,'Accessibility specified more than once for '//trim(name))
            found=.false.
            do j=1,p%prog%ns
                if(p%prog%symbols(j)%scope==-m.and.p%prog%symbols(j)%name==name) found=.true.
            end do
            do j=1,p%prog%np
                if(p%prog%procedures(j)%module_id==m.and.p%prog%procedures(j)%parent_procedure==0.and. &
                   p%prog%procedures(j)%name==name) found=.true.
            end do
            do j=1,p%prog%nt
                if(p%prog%derived_types(j)%module_id==m.and.p%prog%derived_types(j)%name==name) found=.true.
            end do
            do j=1,p%prog%no
                if(p%prog%operators(j)%module_id==m.and.'operator('//trim(p%prog%operators(j)%op)//')'==name) found=.true.
            end do
            do j=1,p%prog%ng
                if(p%prog%generics(j)%module_id==m.and.p%prog%generics(j)%name==name) found=.true.
            end do
            if(.not.found) call error(p,'Accessibility name has no declaration: '//trim(name))
        end do
        do j=1,p%prog%np
            if(p%prog%procedures(j)%module_id/=m.or.p%prog%procedures(j)%parent_procedure/=0) cycle
            name=p%prog%procedures(j)%name
            p%prog%procedures(j)%is_public=.not.p%prog%module_private(m)
            if(any(p%public_names(:,m)==name)) p%prog%procedures(j)%is_public=.true.
            if(any(p%private_names(:,m)==name)) p%prog%procedures(j)%is_public=.false.
        end do
        do j=1,p%prog%ns
            if(p%prog%symbols(j)%scope/=-m) cycle
            p%prog%symbols(j)%is_public=.not.p%prog%module_private(m)
            if(any(p%public_names(:,m)==p%prog%symbols(j)%name)) p%prog%symbols(j)%is_public=.true.
            if(any(p%private_names(:,m)==p%prog%symbols(j)%name)) p%prog%symbols(j)%is_public=.false.
        end do
        do j=1,p%prog%nt
            if(p%prog%derived_types(j)%module_id/=m) cycle
            name=p%prog%derived_types(j)%name
            if(any(p%public_names(:,m)==name)) p%prog%derived_types(j)%is_public=.true.
            if(any(p%private_names(:,m)==name)) p%prog%derived_types(j)%is_public=.false.
        end do
        do j=1,p%prog%no
            if(p%prog%operators(j)%module_id/=m) cycle
            name='operator('//trim(p%prog%operators(j)%op)//')'
            p%prog%operators(j)%is_public=.not.p%prog%module_private(m)
            if(any(p%public_names(:,m)==name)) p%prog%operators(j)%is_public=.true.
            if(any(p%private_names(:,m)==name)) p%prog%operators(j)%is_public=.false.
        end do
        do j=1,p%prog%ng
            if(p%prog%generics(j)%module_id/=m) cycle
            name=p%prog%generics(j)%name
            p%prog%generics(j)%is_public=.not.p%prog%module_private(m)
            if(any(p%public_names(:,m)==name)) p%prog%generics(j)%is_public=.true.
            if(any(p%private_names(:,m)==name)) p%prog%generics(j)%is_public=.false.
        end do
        call expect(p,'end'); call expect(p,'module')
        if(p%tokens(p%p)%kind==tk_name) then
            if(peek(p)/=trim(p%prog%modules(m))) call error(p,'END MODULE name does not match')
            p%p=p%p+1
        end if
        call finish_line(p); p%scope=0
    end subroutine

    recursive subroutine procedure_specification(p,m,parent)
        type(parser_t),intent(inout)::p
        integer,intent(in)::m
        integer,intent(in),optional::parent
        integer::f,j,k,typ,ns,a,nargs,header_type,header_kind,header_kind_expr,line,col,host
        character(63)::name,result_name,arg_names(16)
        character(:),allocatable::unit
        logical::pure_prefix,simple_prefix,elemental_prefix,impure_prefix,recursive_prefix,sub
        if(p%prog%np==max_procedures) then
            call error(p,'Procedure limit exceeded'); return
        end if
        host=0
        if(present(parent)) host=parent
        p%scope=-m
        if(host>0) p%scope=host
        line=p%tokens(p%p)%line; col=p%tokens(p%p)%column
        pure_prefix=.false.; simple_prefix=.false.; elemental_prefix=.false.; impure_prefix=.false.; recursive_prefix=.false.
        header_type=0; header_kind=4;header_kind_expr=0
        ! R1529 permits the type and procedure attributes in either order.
        do while(p%diag%code==0)
            select case(peek(p))
            case('recursive')
                if(recursive_prefix) call error(p,'Duplicate RECURSIVE procedure prefix')
                recursive_prefix=.true.; p%p=p%p+1
            case('pure')
                if(pure_prefix) call error(p,'Duplicate PURE procedure prefix')
                pure_prefix=.true.; p%p=p%p+1
            case('impure')
                if(impure_prefix) call error(p,'Duplicate IMPURE procedure prefix')
                impure_prefix=.true.; p%p=p%p+1
            case('elemental')
                if(elemental_prefix) call error(p,'Duplicate ELEMENTAL procedure prefix')
                elemental_prefix=.true.; p%p=p%p+1
            case('simple')
                if(simple_prefix) call error(p,'Duplicate SIMPLE procedure prefix')
                simple_prefix=.true.; p%p=p%p+1
            case default
                if(peek(p)=='class') then
                    call error(p,'CLASS function results are unsupported');return
                end if
                typ=type_name(peek(p))
                if(typ==0) exit
                if(header_type/=0) then
                    call error(p,'Duplicate procedure result type'); return
                end if
                header_type=typ
                call type_specification(p,header_type,header_kind,header_kind_expr)
                if(p%diag%code==0.and.header_kind_expr>0) then
                    if(p%prog%expressions(header_kind_expr)%kind==ex_call) &
                        call error(p,'Typed function headers require a literal or named REAL kind')
                end if
            end select
        end do
        if(p%diag%code/=0) return
        if(impure_prefix.and.(pure_prefix.or.simple_prefix)) then
            call error(p,'IMPURE conflicts with PURE or SIMPLE'); return
        end if
        if(impure_prefix.and..not.elemental_prefix) then
            call error(p,'IMPURE non-ELEMENTAL prefixes are unsupported'); return
        end if
        if(recursive_prefix.and.elemental_prefix) then
            call error(p,'RECURSIVE ELEMENTAL procedures are unsupported'); return
        end if
        col=p%tokens(p%p)%column
        sub=take(p,'subroutine')
        if(sub) then
            unit='subroutine'
            if(header_type/=0) call error(p,'SUBROUTINE cannot have a result type')
        else
            unit='function'; call expect(p,'function')
        end if
        p%prog%np=p%prog%np+1; f=p%prog%np; p%scope=f
        p%prog%procedures(f)%line=line; p%prog%procedures(f)%column=col
        p%prog%procedures(f)%module_id=m
        p%prog%procedures(f)%parent_procedure=host
        if(host>0) p%prog%procedures(f)%is_public=.false.
        if(m>0) p%prog%procedures(f)%module_name=p%prog%modules(m)
        p%prog%procedures(f)%is_subroutine=sub
        p%prog%procedures(f)%is_pure=pure_prefix.or.simple_prefix.or.(elemental_prefix.and..not.impure_prefix)
        p%prog%procedures(f)%is_simple=simple_prefix
        p%prog%procedures(f)%has_pure_prefix=pure_prefix
        p%prog%procedures(f)%has_impure_prefix=impure_prefix
        p%prog%procedures(f)%is_recursive=recursive_prefix
        p%prog%procedures(f)%is_elemental=elemental_prefix
        call read_name(p,name); p%prog%procedures(f)%name=name
        if(host==0.and.m>0.and.imported_name(p,name)) call error(p,'Module procedure conflicts with USE-associated name')
        if(m>0) then
            if(name==p%prog%modules(m)) call error(p,'Procedure name conflicts with its module')
        end if
        do j=1,f-1
            if(p%prog%procedures(j)%module_id==m.and.p%prog%procedures(j)%parent_procedure==host.and. &
               p%prog%procedures(j)%name==name) &
                call error(p,'Duplicate procedure name')
        end do
        call expect(p,'('); nargs=0; arg_names=''
        if(peek(p)/=')') then
            do while(p%diag%code==0)
                call read_name(p,name)
                if(nargs==16) then
                    call error(p,'Procedure argument limit exceeded (16)'); return
                end if
                if(any(arg_names==name)) call error(p,'Duplicate dummy argument')
                nargs=nargs+1; arg_names(nargs)=name
                if(.not.take(p,',')) exit
            end do
        end if
        call expect(p,')'); result_name=''
        if(.not.sub) then
            result_name=p%prog%procedures(f)%name
            if(take(p,'result')) then
                call expect(p,'('); call read_name(p,result_name); call expect(p,')')
                if(result_name==p%prog%procedures(f)%name) call error(p,'Explicit RESULT must differ from function name')
            end if
            if(any(arg_names==result_name)) call error(p,'RESULT must differ from dummy names')
        end if
        call finish_line(p)
        do while(peek(p)=='use'.and.p%diag%code==0)
            call use_statement(p)
        end do
        if(take(p,'implicit')) then
            call expect(p,'none'); call finish_line(p)
        end if
        ns=p%prog%ns
        if(header_type/=0.and..not.sub.and.p%diag%code==0) then
            if(p%prog%ns==max_symbols) then
                call error(p,'Symbol limit exceeded'); return
            end if
            p%prog%ns=p%prog%ns+1; a=p%prog%ns
            p%prog%symbols(a)=symbol_t(name=result_name,typ=header_type,line=line,column=col,real_kind=header_kind)
            p%prog%symbols(a)%scope=f
            p%prog%symbols(a)%kind_expr=header_kind_expr
            if(header_type==ty_character) then
                p%prog%symbols(a)%character_len=header_kind
                p%prog%symbols(a)%length_expr=header_kind_expr
                p%prog%symbols(a)%kind_expr=0
                p%prog%symbols(a)%real_kind=4
                if(header_kind<0) call error(p,'Assumed-length CHARACTER function results are unsupported')
            end if
        end if
        do while(p%diag%code==0)
            typ=declaration_type(p); if(typ==0) exit
            call declaration(p,typ)
        end do
        if(p%diag%code/=0) return
        allocate(p%prog%procedures(f)%args(nargs))
        do j=1,nargs
            a=find_symbol(p,trim(arg_names(j)))
            if(a==0) then
                call error(p,'Every dummy argument requires an INTENT declaration'); return
            end if
            if(.not.p%prog%symbols(a)%is_dummy.or.p%prog%symbols(a)%scope/=f) then
                call error(p,'Every dummy argument requires INTENT'); return
            end if
            if(elemental_prefix.and.p%prog%symbols(a)%rank/=0) then
                call error(p,'ELEMENTAL procedure dummy arguments must be scalar'); return
            end if
            p%prog%procedures(f)%args(j)=a
        end do
        if(.not.sub) then
            a=find_symbol(p,trim(result_name)); p%prog%procedures(f)%result_symbol=a
            if(a==0) then
                call error(p,'Function RESULT requires an explicit declaration'); return
            end if
            if(p%prog%symbols(a)%is_saved) call error(p,'Function RESULT cannot have SAVE or initialization')
            if(p%prog%symbols(a)%is_dummy.or.p%prog%symbols(a)%is_parameter.or. &
               p%prog%symbols(a)%scope/=f) call error(p,'Function RESULT must be mutable and local')
            if(elemental_prefix.and.p%prog%symbols(a)%rank/=0) &
                call error(p,'ELEMENTAL function RESULT must be scalar')
            if(p%prog%symbols(a)%rank>0.and. &
               (p%prog%symbols(a)%typ<ty_integer.or.p%prog%symbols(a)%typ>ty_character)) &
                call error(p,'Array function RESULT requires intrinsic element type')
        end if
        do j=ns+1,p%prog%ns
            if(p%prog%symbols(j)%is_dummy.and..not.any(p%prog%procedures(f)%args==j)) &
                call error(p,'INTENT is only valid on a named dummy argument')
            if(p%prog%symbols(j)%name==p%prog%procedures(f)%name.and.j/=p%prog%procedures(f)%result_symbol) &
                call error(p,'A local variable cannot have the procedure name')
            if(p%prog%symbols(j)%typ==ty_character.and.p%prog%symbols(j)%is_dummy.and. &
               p%prog%symbols(j)%character_len<0.and.p%prog%symbols(j)%length_expr/=0) then
                if(.not.valid_character_length_dummy(p%prog,j)) &
                    call error(p,'Unsupported specification-length ALLOCATABLE CHARACTER dummy')
            end if
        end do
        if(p%diag%code/=0) return
        p%body_start(f)=p%p
        do k=p%p,p%n-2
            if(k>1) then
                if(p%tokens(k-1)%kind/=tk_eol) cycle
            end if
            if(p%tokens(k)%text=='contains') exit
            if(p%tokens(k)%text=='end'.and.p%tokens(k+1)%text==unit) exit
        end do
        if(k>p%n-2) then
            call error(p,'Expected END '//unit); return
        end if
        p%p=k; p%body_end(f)=k
        if(take(p,'contains')) then
            if(host/=0.or.m==0.or.elemental_prefix) then
                call error(p,'Internal procedures require a non-ELEMENTAL module procedure host');return
            end if
            call finish_line(p)
            do while(p%diag%code==0.and.procedure_start(p))
                call procedure_specification(p,m,f)
            end do
            if(p%diag%code/=0) return
            k=p%p
        end if
        p%prog%procedures(f)%end_line=p%tokens(k)%line; p%prog%procedures(f)%end_column=p%tokens(k)%column
        call expect(p,'end'); call expect(p,unit)
        if(p%tokens(p%p)%kind==tk_name) then
            if(peek(p)/=trim(p%prog%procedures(f)%name)) call error(p,'END procedure name does not match')
            p%p=p%p+1
        end if
        call finish_line(p); p%scope=-m
        if(host>0) p%scope=host
    end subroutine
    subroutine access_name(p,name)
        type(parser_t),intent(inout)::p
        character(63),intent(out)::name
        character(:),allocatable::op
        if(take(p,'operator')) then
            call expect(p,'(');op=peek(p)
            if(precedence(op)<0) call error(p,'Unsupported defined operator')
            p%p=p%p+1;call expect(p,')');name='operator('//op//')'
        else
            call read_name(p,name)
        end if
    end subroutine
    integer function find_derived(p,name) result(t)
        type(parser_t),intent(inout)::p
        character(*),intent(in)::name
        integer::j,m,host
        logical::visible
        t=0;host=0
        if(p%scope>0) host=p%prog%procedures(p%scope)%module_id
        if(p%scope<0) host=-p%scope
        do j=1,p%prog%nt
            if(p%prog%derived_types(j)%name/=name) cycle
            m=p%prog%derived_types(j)%module_id
            visible=m==host.and.host>0
            if(.not.visible) visible=p%prog%derived_types(j)%is_public.and.imported(p,m,name)
            if(.not.visible) cycle
            if(t/=0) then
                call error(p,'Ambiguous derived type name: '//name);return
            end if
            t=j
        end do
    end function
    integer function find_component(p,typ,name) result(c)
        type(parser_t),intent(inout)::p
        integer,intent(in)::typ
        character(*),intent(in)::name
        integer::t,j
        c=0;t=typ-ty_derived_base
        if(.not.is_derived_type(typ).or.t>p%prog%nt) then
            call error(p,'Component selection requires a derived type');return
        end if
        do j=1,p%prog%derived_types(t)%ncomponents
            if(p%prog%derived_types(t)%component_names(j)==name) c=j
        end do
        if(c==0) call error(p,'Unknown derived type component: '//name)
    end function
    subroutine derived_definition(p,m)
        type(parser_t),intent(inout)::p
        integer,intent(in)::m
        integer::t,typ,rkind,kexpr,c,line,col,root,charlen
        type(value_t)::initial_value
        logical::pub,has_attributes,has_double_colon
        character(63)::name
        if(p%prog%nt==max_types) then
            call error(p,'Derived type limit exceeded (16)');return
        end if
        line=p%tokens(p%p)%line;col=p%tokens(p%p)%column
        call expect(p,'type');pub=.not.p%prog%module_private(m)
        has_attributes=take(p,',')
        if(has_attributes) then
            if(take(p,'public')) then
                pub=.true.
            else if(take(p,'private')) then
                pub=.false.
            else
                call error(p,'Unsupported derived type attribute');return
            end if
        end if
        has_double_colon=take(p,'::')
        if(has_attributes.and..not.has_double_colon) then
            call error(p,'Derived type attributes require ::');return
        end if
        call read_name(p,name)
        if(find_derived(p,trim(name))/=0) call error(p,'Duplicate derived type')
        if(imported_name(p,name)) call error(p,'Module type conflicts with USE-associated name')
        if(p%diag%code/=0) return
        p%prog%nt=p%prog%nt+1;t=p%prog%nt
        p%prog%derived_types(t)%name=name;p%prog%derived_types(t)%module_id=m
        p%prog%derived_types(t)%is_public=pub
        p%prog%derived_types(t)%line=line;p%prog%derived_types(t)%column=col
        call finish_line(p)
        do while(p%diag%code==0.and.peek(p)/='end'.and.peek(p)/='contains')
            typ=type_name(peek(p))
            if(typ/=ty_integer.and.typ/=ty_real.and.typ/=ty_logical.and.typ/=ty_character) then
                call error(p,'Derived components support scalar INTEGER, REAL, LOGICAL or fixed CHARACTER only');return
            end if
            call type_specification(p,typ,rkind,kexpr)
            if(p%diag%code/=0) return
            charlen=-1
            if(typ==ty_character) then
                charlen=rkind;rkind=4
                if(charlen<0) then
                    call error(p,'CHARACTER components require a constant explicit length');return
                end if
            end if
            has_double_colon=take(p,'::')
            do while(p%diag%code==0)
                line=p%tokens(p%p)%line;col=p%tokens(p%p)%column
                call read_name(p,name)
                if(any(p%prog%derived_types(t)%component_names==name)) call error(p,'Duplicate component name')
                c=p%prog%derived_types(t)%ncomponents+1
                if(c>16) then
                    call error(p,'Derived component limit exceeded (16)');return
                end if
                p%prog%derived_types(t)%ncomponents=c
                p%prog%derived_types(t)%component_names(c)=name
                p%prog%derived_types(t)%component_types(c)=typ
                p%prog%derived_types(t)%component_kinds(c)=rkind
                p%prog%derived_types(t)%component_lengths(c)=charlen
                if(typ==ty_character) p%prog%derived_types(t)%component_length_exprs(c)=kexpr
                p%prog%derived_types(t)%component_lines(c)=line;p%prog%derived_types(t)%component_columns(c)=col
                if(take(p,'=')) then
                    if(.not.has_double_colon) then
                        call error(p,'Component initialization requires ::');return
                    end if
                    root=expression(p,0)
                    if(p%diag%code/=0) return
                    if(.not.valid_component_initializer(p%prog,root,p%scope,0)) then
                        call error(p,'Component defaults require supported scalar constant expressions');return
                    end if
                    call assignment_types(p,typ,p%prog%expressions(root)%typ)
                    if(p%diag%code/=0) return
                    call evaluate_constant(p%prog,root,initial_value,p%diag,typ,rkind)
                    if(p%diag%code/=0) then
                        p%diag%code=1;p%diag%message='Invalid component default: '//p%diag%message;return
                    end if
                    p%prog%derived_types(t)%component_initializers(c)=root
                end if
                if(.not.take(p,',')) exit
            end do
            call finish_line(p)
        end do
        if(take(p,'contains')) then
            call finish_line(p)
            call type_bindings(p,t)
        end if
        p%prog%derived_types(t)%end_line=p%tokens(p%p)%line
        p%prog%derived_types(t)%end_column=p%tokens(p%p)%column
        call expect(p,'end');call expect(p,'type')
        if(p%tokens(p%p)%kind==tk_name) then
            if(peek(p)/=p%prog%derived_types(t)%name) call error(p,'END TYPE name does not match')
            p%p=p%p+1
        end if
        if(p%prog%derived_types(t)%ncomponents==0) call error(p,'Empty derived types are unsupported')
        call finish_line(p)
    end subroutine
    subroutine generic_interface(p,m)
        type(parser_t),intent(inout)::p
        integer,intent(in)::m
        integer::g,j,n,line,col
        character(63)::name,specific
        line=p%tokens(p%p)%line;col=p%tokens(p%p)%column
        call expect(p,'interface');call read_name(p,name);call finish_line(p)
        if(imported_name(p,name)) call error(p,'Module generic conflicts with USE-associated name')
        if(p%diag%code/=0) return
        do j=1,p%prog%ng
            if(p%prog%generics(j)%module_id==m.and.p%prog%generics(j)%name==name) &
                call error(p,'Duplicate named generic interface')
        end do
        if(p%prog%ng==max_generics) then
            call error(p,'Generic interface limit exceeded');return
        end if
        p%prog%ng=p%prog%ng+1;g=p%prog%ng
        p%prog%generics(g)%name=name;p%prog%generics(g)%module_id=m
        p%prog%generics(g)%line=line;p%prog%generics(g)%column=col
        do while(peek(p)=='module'.and.p%diag%code==0)
            call expect(p,'module');call expect(p,'procedure')
            if(peek(p)=='::') p%p=p%p+1
            do while(p%diag%code==0)
                call read_name(p,specific);n=p%prog%generics(g)%nprocedures+1
                if(n>16) then
                    call error(p,'Generic specific procedure limit exceeded (16)');return
                end if
                if(any(p%prog%generics(g)%procedure_names==specific)) call error(p,'Duplicate generic specific')
                p%prog%generics(g)%nprocedures=n;p%prog%generics(g)%procedure_names(n)=specific
                if(.not.take(p,',')) exit
            end do
            call finish_line(p)
        end do
        if(p%prog%generics(g)%nprocedures==0) call error(p,'Generic interface has no procedures')
        call expect(p,'end');call expect(p,'interface')
        if(p%tokens(p%p)%kind==tk_name) then
            if(peek(p)/=name) call error(p,'END INTERFACE name does not match')
            p%p=p%p+1
        end if
        call finish_line(p)
    end subroutine
    subroutine resolve_generics(p,m)
        type(parser_t),intent(inout)::p
        integer,intent(in)::m
        integer::g,j,k,f,other,a,b,n,prefix,x,y
        logical::overlap
        if(p%diag%code/=0) return
        do g=1,p%prog%ng
            if(p%prog%generics(g)%module_id/=m) cycle
            do j=1,p%prog%ns
                if(p%prog%symbols(j)%scope/=-m) cycle
                if(p%prog%symbols(j)%name==p%prog%generics(g)%name) &
                    call error(p,'Generic name conflicts with module data')
            end do
            do j=1,p%prog%nt
                if(p%prog%derived_types(j)%module_id/=m) cycle
                if(p%prog%derived_types(j)%name==p%prog%generics(g)%name) &
                    call error(p,'Generic constructor overrides are unsupported')
            end do
            do j=1,p%prog%np
                if(p%prog%procedures(j)%module_id/=m.or.p%prog%procedures(j)%parent_procedure/=0) cycle
                if(p%prog%procedures(j)%name==p%prog%generics(g)%name) &
                    call error(p,'A generic sharing its specific procedure name is unsupported')
            end do
            do j=1,p%prog%generics(g)%nprocedures
                f=0
                do k=1,p%prog%np
                    if(p%prog%procedures(k)%module_id/=m.or.p%prog%procedures(k)%parent_procedure/=0) cycle
                    if(p%prog%procedures(k)%name==p%prog%generics(g)%procedure_names(j)) f=k
                end do
                if(f==0) then
                    call error(p,'Generic specific procedure is absent');return
                end if
                p%prog%generics(g)%procedures(j)=f
                do k=1,j-1
                    other=p%prog%generics(g)%procedures(k)
                    if(p%prog%procedures(f)%is_subroutine.neqv.p%prog%procedures(other)%is_subroutine) then
                        call error(p,'Generic interface cannot mix functions and subroutines');return
                    end if
                    n=size(p%prog%procedures(f)%args)
                    if(n/=size(p%prog%procedures(other)%args)) cycle
                    ! All dummies are required. Check every positional prefix,
                    ! including fully keyword calls, for intersecting signatures.
                    do prefix=0,n
                        overlap=.true.
                        do x=1,n
                            a=p%prog%procedures(f)%args(x);y=x
                            if(x>prefix) then
                                do y=prefix+1,n
                                    b=p%prog%procedures(other)%args(y)
                                    if(p%prog%symbols(a)%name==p%prog%symbols(b)%name) exit
                                end do
                            end if
                            if(y>n) then
                                overlap=.false.;exit
                            end if
                            b=p%prog%procedures(other)%args(y)
                            if(p%prog%symbols(a)%typ/=p%prog%symbols(b)%typ.or. &
                               p%prog%symbols(a)%real_kind/=p%prog%symbols(b)%real_kind.or. &
                               p%prog%symbols(a)%rank/=p%prog%symbols(b)%rank) then
                                overlap=.false.;exit
                            end if
                        end do
                        if(overlap) then
                            call error(p,'Ambiguous generic specific procedures');return
                        end if
                    end do
                end do
            end do
        end do
    end subroutine
    integer function find_generic(p,name) result(g)
        type(parser_t),intent(inout)::p
        character(*),intent(in)::name
        integer::j,m,host
        logical::visible
        g=0;host=0
        if(p%scope>0) host=p%prog%procedures(p%scope)%module_id
        if(p%scope<0) host=-p%scope
        do j=1,p%prog%ng
            if(p%prog%generics(j)%name/=name) cycle
            m=p%prog%generics(j)%module_id
            visible=host==m.and.host>0
            if(.not.visible) visible=p%prog%generics(j)%is_public.and.imported(p,m,name)
            if(.not.visible) cycle
            if(g/=0) then
                call error(p,'Combining same-name generics from different modules is unsupported');return
            end if
            g=j
        end do
    end function
    subroutine select_generic(p,e,actuals,keywords)
        type(parser_t),intent(inout)::p
        type(expr_t),intent(inout)::e
        integer,intent(in)::actuals(:)
        character(63),intent(in)::keywords(:)
        integer::j,k,f,n,nf,a,d,slot,selected,score,best,slots(16),selected_slots(16)
        logical::match
        n=size(actuals);selected=0;best=-1;selected_slots=0
        if(e%generic_id<1.or.e%generic_id>p%prog%ng) then
            call error(p,'Invalid generic interface binding');return
        end if
        do j=1,p%prog%generics(e%generic_id)%nprocedures
            f=p%prog%generics(e%generic_id)%procedures(j)
            ! Module specification parsing precedes resolve_generics. A call
            ! here has only specific names, not safe procedure indices yet.
            if(f<1.or.f>p%prog%np) then
                call error(p,'Unresolved generic specific binding: generic specification calls are unsupported');return
            end if
            if(.not.allocated(p%prog%procedures(f)%args)) then
                call error(p,'Unresolved generic specific dummy arguments');return
            end if
            nf=size(p%prog%procedures(f)%args)
            if(n>nf) cycle
            slots=0;match=.true.;score=1
            do k=1,n
                slot=k
                if(keywords(k)/='') then
                    do slot=1,nf
                        d=p%prog%procedures(f)%args(slot)
                        if(p%prog%symbols(d)%name==keywords(k)) exit
                    end do
                end if
                if(slot>nf) then
                    match=.false.;exit
                end if
                if(slots(slot)/=0) then
                    match=.false.;exit
                end if
                slots(slot)=actuals(k);a=actuals(k);d=p%prog%procedures(f)%args(slot)
                if(p%prog%expressions(a)%typ/=p%prog%symbols(d)%typ) match=.false.
                if(p%prog%symbols(d)%typ==ty_integer.or.p%prog%symbols(d)%typ==ty_real) then
                    if(p%prog%expressions(a)%real_kind/=p%prog%symbols(d)%real_kind) match=.false.
                end if
                if(p%prog%expressions(a)%rank/=p%prog%symbols(d)%rank) then
                    if(p%prog%procedures(f)%is_elemental) then
                        score=0
                    else
                        match=.false.
                    end if
                end if
            end do
            do k=1,nf
                if(slots(k)==0.and..not.p%prog%symbols(p%prog%procedures(f)%args(k))%is_optional) match=.false.
            end do
            if(.not.match.or.score<best) cycle
            if(score==best) then
                call error(p,'Ambiguous generic procedure call');return
            end if
            selected=f;best=score;selected_slots=slots
        end do
        if(selected==0) then
            ! A function generic may extend intrinsic REPEAT. User specifics
            ! retain priority; only an unmatched function reference can fall
            ! back, and ordinary intrinsic association/type checks still run.
            if(e%kind==ex_call.and.e%op=='repeat') then
                match=.true.
                do j=1,p%prog%generics(e%generic_id)%nprocedures
                    f=p%prog%generics(e%generic_id)%procedures(j)
                    if(p%prog%procedures(f)%is_subroutine) match=.false.
                end do
                if(match) then
                    e%generic_id=0;e%symbol=0;e%args=actuals
                    return
                end if
            end if
            call error(p,'No matching specific procedure for generic '//trim(p%prog%generics(e%generic_id)%name));return
        end if
        e%symbol=selected;e%args=selected_slots(:size(p%prog%procedures(selected)%args))
    end subroutine
    subroutine type_bindings(p,t)
        type(parser_t),intent(inout)::p
        integer,intent(in)::t
        integer::b,lin,col
        logical::pub
        character(63)::name,target
        do while(p%diag%code==0.and.peek(p)/='end')
            lin=p%tokens(p%p)%line;col=p%tokens(p%p)%column
            if(take(p,'procedure')) then
                pub=.true.
                if(take(p,',')) then
                    if(take(p,'private')) then
                        pub=.false.
                    else if(.not.take(p,'public')) then
                        call error(p,'Type bindings support default PASS and PUBLIC/PRIVATE only');return
                    end if
                end if
                call expect(p,'::');call read_name(p,name);target=name
                if(take(p,'=>')) call read_name(p,target)
                if(any(p%prog%derived_types(t)%binding_names==name).or. &
                   any(p%prog%derived_types(t)%component_names==name)) call error(p,'Duplicate type member name')
                b=p%prog%derived_types(t)%nbindings+1
                if(b>16) then
                    call error(p,'Type binding limit exceeded (16)');return
                end if
                p%prog%derived_types(t)%nbindings=b
                p%prog%derived_types(t)%binding_names(b)=name;p%prog%derived_types(t)%binding_targets(b)=target
                p%prog%derived_types(t)%binding_public(b)=pub
                p%prog%derived_types(t)%binding_lines(b)=lin;p%prog%derived_types(t)%binding_columns(b)=col
            else if(take(p,'generic')) then
                call expect(p,'::');call expect(p,'write');call expect(p,'(')
                call expect(p,'formatted');call expect(p,')');call expect(p,'=>');call read_name(p,name)
                if(len_trim(p%prog%derived_types(t)%write_binding)>0) call error(p,'Duplicate formatted WRITE binding')
                p%prog%derived_types(t)%write_binding=name
                p%prog%derived_types(t)%write_line=lin;p%prog%derived_types(t)%write_column=col
            else
                call error(p,'Unsupported type-bound declaration');return
            end if
            call finish_line(p)
        end do
    end subroutine
    subroutine resolve_bindings(p,m)
        type(parser_t),intent(inout)::p
        integer,intent(in)::m
        integer::t,b,f,j,a
        integer::expected(6),intents(6)
        do t=1,p%prog%nt
            if(p%prog%derived_types(t)%module_id/=m) cycle
            do b=1,p%prog%derived_types(t)%nbindings
                f=0
                do j=1,p%prog%np
                    if(p%prog%procedures(j)%module_id/=m.or.p%prog%procedures(j)%parent_procedure/=0) cycle
                    if(p%prog%procedures(j)%name==p%prog%derived_types(t)%binding_targets(b)) f=j
                end do
                if(f==0) then
                    call error(p,'Type binding implementation must be a same-module procedure');return
                end if
                if(size(p%prog%procedures(f)%args)<1.or.p%prog%procedures(f)%is_elemental) then
                    call error(p,'Type binding requires a scalar passed-object dummy and is not ELEMENTAL');return
                end if
                a=p%prog%procedures(f)%args(1)
                if(p%prog%symbols(a)%typ/=ty_derived_base+t.or..not.p%prog%symbols(a)%is_class.or. &
                   p%prog%symbols(a)%rank/=0) then
                    call error(p,'First binding dummy must be CLASS of its declared type');return
                end if
                p%prog%derived_types(t)%binding_procedures(b)=f
                if(p%prog%derived_types(t)%write_binding==p%prog%derived_types(t)%binding_names(b)) then
                    p%prog%derived_types(t)%write_procedure=f
                    if(.not.p%prog%procedures(f)%is_subroutine.or.size(p%prog%procedures(f)%args)/=6) then
                        call error(p,'Defined formatted WRITE requires six subroutine dummies');return
                    end if
                    expected=[ty_derived_base+t,ty_integer,ty_character,ty_integer,ty_integer,ty_character]
                    intents=[1,1,1,1,2,3]
                    do j=1,6
                        a=p%prog%procedures(f)%args(j)
                        if(p%prog%symbols(a)%typ/=expected(j).or.p%prog%symbols(a)%dummy_intent/=intents(j)) &
                            call error(p,'Defined formatted WRITE dummy types or intents differ')
                        if(j==4) then
                            if(p%prog%symbols(a)%rank/=1.or..not.p%prog%symbols(a)%assumed_shape) &
                                call error(p,'Defined formatted WRITE V_LIST must be an assumed-shape vector')
                        else if(p%prog%symbols(a)%rank/=0) then
                            call error(p,'Defined formatted WRITE dummies must be scalar except V_LIST')
                        end if
                        if(expected(j)==ty_integer.and.p%prog%symbols(a)%real_kind/=4) &
                            call error(p,'Defined formatted WRITE requires default INTEGER dummies')
                        if(expected(j)==ty_character.and.p%prog%symbols(a)%character_len/=-1) &
                            call error(p,'Defined formatted WRITE requires assumed-length CHARACTER dummies')
                    end do
                end if
            end do
            if(len_trim(p%prog%derived_types(t)%write_binding)>0.and.p%prog%derived_types(t)%write_procedure==0) &
                call error(p,'Defined WRITE generic refers to an unknown binding')
        end do
    end subroutine
    integer function find_binding(p,typ,name) result(b)
        type(parser_t),intent(inout)::p
        integer,intent(in)::typ
        character(*),intent(in)::name
        integer::t,j,host
        b=0;t=typ-ty_derived_base
        if(.not.is_derived_type(typ).or.t>p%prog%nt) then
            call error(p,'Type-bound call requires a derived object');return
        end if
        host=0
        if(p%scope>0) host=p%prog%procedures(p%scope)%module_id
        do j=1,p%prog%derived_types(t)%nbindings
            if(p%prog%derived_types(t)%binding_names(j)/=name) cycle
            if(.not.p%prog%derived_types(t)%binding_public(j).and.host/=p%prog%derived_types(t)%module_id) then
                call error(p,'Inaccessible private type binding');return
            end if
            b=j
        end do
        if(b==0) call error(p,'Unknown type binding: '//name)
    end function
    subroutine operator_interface(p,m)
        type(parser_t),intent(inout)::p
        integer,intent(in)::m
        integer::o,j,n,line,col
        character(:),allocatable::op
        character(63)::name
        line=p%tokens(p%p)%line;col=p%tokens(p%p)%column
        call expect(p,'interface');call expect(p,'operator');call expect(p,'(')
        op=peek(p)
        if(.not.custom_operator(op).and.precedence(op)/=5.and. &
           op/='+'.and.op/='-'.and.op/='*'.and.op/='/'.and.op/='**') &
            call error(p,'Unsupported defined operator')
        p%p=p%p+1;call expect(p,')');call finish_line(p)
        do j=1,p%prog%no
            if(p%prog%operators(j)%module_id==m.and.p%prog%operators(j)%op==op) &
                call error(p,'Duplicate operator interface')
        end do
        if(p%prog%no==max_operators) then
            call error(p,'Operator interface limit exceeded');return
        end if
        p%prog%no=p%prog%no+1;o=p%prog%no
        p%prog%operators(o)%op=op;p%prog%operators(o)%module_id=m
        p%prog%operators(o)%line=line;p%prog%operators(o)%column=col
        do while(peek(p)=='module'.and.p%diag%code==0)
            call expect(p,'module');call expect(p,'procedure')
            if(take(p,'::')) continue
            do while(p%diag%code==0)
                call read_name(p,name);n=p%prog%operators(o)%nprocedures+1
                if(n>16) then
                    call error(p,'Operator specific procedure limit exceeded (16)');return
                end if
                if(any(p%prog%operators(o)%procedure_names==name)) call error(p,'Duplicate operator specific')
                p%prog%operators(o)%nprocedures=n;p%prog%operators(o)%procedure_names(n)=name
                if(.not.take(p,',')) exit
            end do
            call finish_line(p)
        end do
        if(p%prog%operators(o)%nprocedures==0) call error(p,'Operator interface has no procedures')
        call expect(p,'end');call expect(p,'interface')
        if(take(p,'operator')) then
            call expect(p,'(')
            if(peek(p)/=op) call error(p,'END INTERFACE operator does not match')
            p%p=p%p+1;call expect(p,')')
        end if
        call finish_line(p)
    end subroutine
    subroutine resolve_operators(p,m)
        type(parser_t),intent(inout)::p
        integer,intent(in)::m
        integer::o,j,f,a,b,k,g,n,x
        logical::derived,same,character_operand
        if(p%diag%code/=0) return
        do o=1,p%prog%no
            if(p%prog%operators(o)%module_id/=m) cycle
            do j=1,p%prog%operators(o)%nprocedures
                f=0
                do k=1,p%prog%np
                    if(p%prog%procedures(k)%module_id/=m.or.p%prog%procedures(k)%parent_procedure/=0) cycle
                    if(p%prog%procedures(k)%name==p%prog%operators(o)%procedure_names(j)) f=k
                end do
                if(f==0) then
                    call error(p,'Operator specific procedure is absent');return
                end if
                n=size(p%prog%procedures(f)%args)
                if(p%prog%procedures(f)%is_subroutine.or.n<1.or.n>2) then
                    call error(p,'Defined operators require one- or two-argument functions');return
                end if
                if(.not.custom_operator(trim(p%prog%operators(o)%op)).and.n/=2) then
                    call error(p,'Intrinsic-symbol overloads require two operands');return
                end if
                derived=.false.;character_operand=.false.
                do k=1,n
                    a=p%prog%procedures(f)%args(k)
                    if(p%prog%symbols(a)%is_optional) then
                        call error(p,'Defined operator arguments cannot be OPTIONAL');return
                    end if
                    if(p%prog%symbols(a)%dummy_intent/=1) then
                        call error(p,'Defined operator arguments must have INTENT(IN)');return
                    end if
                    derived=derived.or.is_derived_type(p%prog%symbols(a)%typ)
                    character_operand=character_operand.or.p%prog%symbols(a)%typ==ty_character
                end do
                if(.not.custom_operator(trim(p%prog%operators(o)%op)).and..not.derived) then
                    if(p%prog%operators(o)%op/='+'.or..not.character_operand) then
                        call error(p,'Intrinsic-symbol overload requires a derived type operand or CHARACTER operand for +');return
                    end if
                end if
                do k=1,j-1
                    g=p%prog%operators(o)%procedures(k)
                    if(size(p%prog%procedures(g)%args)/=n) cycle
                    same=.true.
                    do x=1,n
                        a=p%prog%procedures(f)%args(x);b=p%prog%procedures(g)%args(x)
                        if(p%prog%symbols(a)%typ/=p%prog%symbols(b)%typ.or. &
                           p%prog%symbols(a)%real_kind/=p%prog%symbols(b)%real_kind.or. &
                           p%prog%symbols(a)%rank/=p%prog%symbols(b)%rank) same=.false.
                    end do
                    if(same) then
                        call error(p,'Ambiguous operator specifics');return
                    end if
                end do
                p%prog%operators(o)%procedures(j)=f
            end do
        end do
    end subroutine
    integer function find_operator(p,op,actuals) result(f)
        type(parser_t),intent(inout)::p
        character(*),intent(in)::op
        integer,intent(in)::actuals(:)
        integer::o,j,g,k,a,x,host,m,score,best
        logical::visible,match,ambiguous
        f=0;host=0;best=-1;ambiguous=.false.
        if(p%scope>0) host=p%prog%procedures(p%scope)%module_id
        if(p%scope<0) host=-p%scope
        do o=1,p%prog%no
            if(p%prog%operators(o)%op/=op) cycle
            m=p%prog%operators(o)%module_id
            visible=host==m.and.host>0
            if(.not.visible) visible=p%prog%operators(o)%is_public.and.imported(p,m,'operator('//op//')')
            if(.not.visible) cycle
            do j=1,p%prog%operators(o)%nprocedures
                g=p%prog%operators(o)%procedures(j)
                if(size(p%prog%procedures(g)%args)/=size(actuals)) cycle
                match=.true.;score=1
                do k=1,size(actuals)
                    a=p%prog%procedures(g)%args(k);x=actuals(k)
                    if(p%prog%symbols(a)%typ/=p%prog%expressions(x)%typ) match=.false.
                    if(p%prog%symbols(a)%real_kind/=p%prog%expressions(x)%real_kind) match=.false.
                    if(p%prog%symbols(a)%rank/=p%prog%expressions(x)%rank) then
                        if(p%prog%procedures(g)%is_elemental.and.p%prog%symbols(a)%rank==0) then
                            score=0
                        else
                            match=.false.
                        end if
                    end if
                end do
                if(.not.match.or.score<best) cycle
                if(score==best) then
                    ambiguous=.true.
                else
                    f=g;best=score;ambiguous=.false.
                end if
            end do
        end do
        if(ambiguous) call error(p,'Ambiguous defined operator')
    end function
    logical function read_is_assignment(p) result(found)
        type(parser_t),intent(in)::p
        integer::j,level
        found=.true.
        select case(p%tokens(p%p+1)%text)
        case('=','=>','%');return
        end select
        found=.false.
        if(p%tokens(p%p+1)%text/='(') return
        level=0
        do j=p%p+1,p%n-1
            if(p%tokens(j)%kind==tk_eol.or.p%tokens(j)%kind==tk_eof) return
            if(p%tokens(j)%text=='(') level=level+1
            if(p%tokens(j)%text==')') then
                level=level-1
                if(level==0) then
                    found=p%tokens(j+1)%text=='=';return
                end if
            end if
        end do
    end function
    subroutine read_statement(p)
        type(parser_t),intent(inout)::p
        type(instruction_t)::ins
        integer::e,j
        ins%op=op_read_internal;ins%line=p%tokens(p%p)%line;ins%column=p%tokens(p%p)%column
        p%p=p%p+1;call expect(p,'(')
        if(peek(p)=='unit'.and.p%tokens(p%p+1)%text=='=') then
            p%p=p%p+1;call expect(p,'=')
        end if
        ins%a=expression(p,0)
        call expect(p,',')
        if(take(p,'fmt')) call expect(p,'=')
        if(p%tokens(p%p)%kind==tk_string) then
            ins%op=op_read_external;ins%format=peek(p);p%p=p%p+1
        else
            call expect(p,'*')
            if(ins%a>0.and.ins%a<=p%prog%ne) then
                if(p%prog%expressions(ins%a)%typ==ty_integer) ins%op=op_read_external
            end if
        end if
        if(take(p,',')) then
            call expect(p,'iostat');call expect(p,'=');ins%b=expression(p,0)
        end if
        call expect(p,')');allocate(ins%items(0))
        if(p%tokens(p%p)%kind/=tk_eol) then
            do while(p%diag%code==0)
                e=expression(p,0);if(p%diag%code/=0) return
                ins%items=[ins%items,e]
                if(size(ins%items)>64) then
                    call error(p,'READ item limit exceeded (64)');return
                end if
                if(.not.take(p,',')) exit
            end do
        end if
        ins%scope=p%scope
        if(p%diag%code/=0) return
        if(ins%op==op_read_external) then
            if(.not.valid_external_read(p%prog,ins)) then
                call error(p,'External READ requires an INTEGER unit variable, list-directed whole local numeric or CHARACTER targets or literal (A) scalar CHARACTER or local CHARACTER element without user-call or IOSTAT-dependent indices, and optional INTEGER IOSTAT outside PURE/SIMPLE procedures');return
            end if
        else
            if(.not.valid_internal_read(p%prog,ins)) then
                if(ins%a>0.and.ins%a<=p%prog%ne)then
                    if(p%prog%expressions(ins%a)%kind==ex_element.and.p%prog%expressions(ins%a)%typ==ty_character)then
                        call error(p,'Internal READ requires a scalar CHARACTER variable or complete local fixed-length CHARACTER element with independent local INTEGER arithmetic indices, distinct whole local numeric or CHARACTER targets or rank-one sections with independent INTEGER arithmetic bounds, and optional INTEGER IOSTAT');return
                    end if
                end if
                call error(p,'Internal READ requires a scalar CHARACTER variable, distinct whole local numeric or CHARACTER targets or rank-one sections with independent INTEGER arithmetic bounds, and optional INTEGER IOSTAT');return
            end if
        end if
        call finish_line(p);j=emit(p,ins)
    end subroutine
    subroutine inquire_name_statement(p)
        type(parser_t),intent(inout)::p
        type(instruction_t)::ins
        integer::j,e,seen
        character(63)::key
        ins%op=op_inquire_name;ins%line=p%tokens(p%p)%line;ins%column=p%tokens(p%p)%column
        ins%scope=p%scope;p%p=p%p+1;seen=0
        call expect(p,'(')
        do while(p%diag%code==0)
            call read_name(p,key);call expect(p,'=')
            if(p%diag%code/=0)return
            if(key/='unit'.and.key/='name')then
                call error(p,'INQUIRE supports only explicit UNIT and NAME controls');return
            end if
            if((key=='unit'.and.btest(seen,0)).or.(key=='name'.and.btest(seen,1)))then
                call error(p,'Duplicate INQUIRE control');return
            end if
            e=expression(p,0)
            if(p%diag%code/=0)return
            if(key=='unit')then
                ins%a=e;seen=ibset(seen,0)
            else
                ins%b=e;seen=ibset(seen,1)
            end if
            if(.not.take(p,','))exit
        end do
        call expect(p,')')
        if(p%diag%code/=0)return
        if(seen/=3.or..not.valid_inquire_name(p%prog,ins))then
            call error(p,'INQUIRE NAME requires an INTEGER unit variable and a whole local writable scalar CHARACTER target outside ordinary functions, PURE or SIMPLE procedures');return
        end if
        call finish_line(p);j=emit(p,ins)
    end subroutine
    subroutine backspace_statement(p)
        type(parser_t),intent(inout)::p
        type(instruction_t)::ins
        integer::j
        logical::parentheses
        ins%op=op_backspace;ins%line=p%tokens(p%p)%line;ins%column=p%tokens(p%p)%column
        ins%scope=p%scope;p%p=p%p+1;parentheses=take(p,'(')
        if(parentheses.and.peek(p)=='unit'.and.p%tokens(p%p+1)%text=='=') p%p=p%p+2
        ins%a=expression(p,0)
        if(parentheses) then
            if(take(p,',')) then
                call expect(p,'iostat');call expect(p,'=');ins%b=expression(p,0)
            end if
            call expect(p,')')
        end if
        if(p%diag%code/=0) return
        if(.not.valid_backspace(p%prog,ins)) then
            call error(p,'BACKSPACE requires an INTEGER unit variable and optional distinct local INTEGER IOSTAT outside PURE/SIMPLE procedures');return
        end if
        call finish_line(p);j=emit(p,ins)
    end subroutine
    logical function output_do_ahead(p) result(found)
        type(parser_t),intent(in)::p
        integer::j,level
        found=.false.;level=0
        if(p%tokens(p%p)%kind/=tk_op.or.peek(p)/='(') return
        do j=p%p,p%n-2
            if(p%tokens(j)%kind==tk_eol.or.p%tokens(j)%kind==tk_eof) return
            if(p%tokens(j)%kind/=tk_op) cycle
            if(p%tokens(j)%text=='(') level=level+1
            if(p%tokens(j)%text==')') then
                level=level-1
                if(level==0) return
            end if
            if(level/=1.or.p%tokens(j)%text/=',') cycle
            if(p%tokens(j+1)%kind/=tk_name.or.p%tokens(j+2)%kind/=tk_op) cycle
            if(p%tokens(j+2)%text=='=') then
                found=.true.;return
            end if
        end do
    end function
    recursive integer function output_item(p,depth) result(root)
        type(parser_t),intent(inout)::p
        integer,intent(in)::depth
        type(expr_t)::e
        integer::a,s
        root=0
        if(.not.output_do_ahead(p)) then
            root=expression(p,0);return
        end if
        if(depth>max_output_do_depth) then
            call error(p,'Output implied-DO nesting limit exceeded (8)');return
        end if
        e%kind=ex_output_do;e%typ=ty_integer;e%scope=p%scope
        e%line=p%tokens(p%p)%line;e%column=p%tokens(p%p)%column
        call expect(p,'(');allocate(e%args(0))
        do while(p%diag%code==0)
            a=output_item(p,depth+1)
            if(p%diag%code/=0) return
            e%args=[e%args,a]
            if(size(e%args)>64) then
                call error(p,'Output implied-DO object limit exceeded (64)');return
            end if
            call expect(p,',')
            if(p%diag%code/=0) return
            if(p%tokens(p%p)%kind==tk_name.and.p%tokens(p%p+1)%text=='=') exit
        end do
        s=find_symbol(p,peek(p));e%symbol=s
        if(s==0.or.any(p%active_do==s)) then
            call error(p,'Output implied-DO requires a declared inactive local INTEGER counter');return
        end if
        p%p=p%p+1;call expect(p,'=')
        e%left=expression(p,0);call expect(p,',');e%right=expression(p,0)
        if(take(p,',')) e%stride=expression(p,0)
        call expect(p,')')
        if(p%diag%code/=0) return
        root=add_expr(p,e)
        if(p%diag%code/=0) return
        if(.not.valid_output_do(p%prog,root)) &
            call error(p,'Unsupported output implied-DO counter, controls, objects or nested counter reuse')
    end function
    subroutine internal_write_statement(p)
        type(parser_t),intent(inout)::p
        type(instruction_t)::ins
        integer::s,a,j,t,f,ctl
        logical::has_format
        ins%op=op_write_internal;ins%line=p%tokens(p%p)%line;ins%column=p%tokens(p%p)%column
        p%p=p%p+1;call expect(p,'(')
        if(peek(p)=='unit'.and.p%tokens(p%p+1)%text=='=') then
            p%p=p%p+1;call expect(p,'=')
        end if
        if(p%tokens(p%p)%kind==tk_op.and.peek(p)=='*') then
            p%p=p%p+1
            call stdout_write_statement(p,ins)
            return
        end if
        if(p%tokens(p%p)%kind/=tk_name) then
            call error(p,'WRITE unit must be * or a supported declared variable');return
        end if
        s=find_symbol(p,peek(p))
        if(s==0) then
            call error(p,'Internal WRITE requires a declared CHARACTER variable');return
        end if
        if(valid_stdout_unit(p%prog,s,p%scope)) then
            ins%symbol=s;p%p=p%p+1
            call stdout_write_statement(p,ins)
            return
        end if
        if(p%prog%symbols(s)%typ==ty_integer) then
            f=0
            do t=1,p%prog%nt
                if(p%prog%derived_types(t)%write_procedure==p%scope.and.p%scope>0) f=p%scope
            end do
            if(f==0) then
                ins%symbol=s
                ins%a=add_expr(p,expr_t(kind=ex_variable,typ=ty_integer, &
                    real_kind=p%prog%symbols(s)%real_kind,symbol=s, &
                    line=p%tokens(p%p)%line,column=p%tokens(p%p)%column))
                if(p%diag%code/=0)return
                if(.not.valid_runtime_output_unit(p%prog,ins%a,s,p%scope))then
                    call error(p,'Runtime WRITE unit requires a supported whole scalar INTEGER name');return
                end if
                p%p=p%p+1
                call stdout_write_statement(p,ins)
                return
            end if
            if(s/=p%prog%procedures(f)%args(2)) then
                call error(p,'Defined WRITE must use its UNIT dummy');return
            end if
            ins%op=op_write_defined
        else if(p%prog%symbols(s)%typ/=ty_character.or. &
           p%prog%symbols(s)%is_parameter.or.p%prog%symbols(s)%dummy_intent==1) then
            call error(p,'Internal WRITE requires a writable scalar CHARACTER variable');return
        end if
        ins%symbol=s
        if(ins%op==op_write_internal.and.p%prog%symbols(s)%rank>0)then
            ins%a=expression(p,0)
            if(p%diag%code/=0)return
            if(.not.valid_internal_write_element(p%prog,ins%a,s,p%scope))then
                call error(p,'Internal WRITE array unit requires one whole writable CHARACTER element');return
            end if
        else
            p%p=p%p+1
        end if
        call expect(p,',')
        if(peek(p)=='fmt'.and.p%tokens(p%p+1)%text=='=') then
            p%p=p%p+1;call expect(p,'=')
        end if
        call output_format(p,ins,has_format)
        if(.not.has_format) then
            call error(p,'Internal WRITE requires a literal format or scalar CHARACTER name');return
        end if
        if(ins%op==op_write_defined.and.ins%format_expr/=0) then
            call error(p,'Defined child WRITE requires a constant format');return
        end if
        if(ins%op==op_write_defined) then
            do while(take(p,','))
                ctl=0
                if(take(p,'iostat')) then
                    ctl=5
                else if(take(p,'iomsg')) then
                    ctl=6
                else
                    call error(p,'Defined child WRITE supports IOSTAT and IOMSG only');return
                end if
                call expect(p,'=');a=find_symbol(p,peek(p))
                if(a/=p%prog%procedures(f)%args(ctl)) then
                    call error(p,'Defined child WRITE controls must use their matching dummies');return
                end if
                p%p=p%p+1
                if(ctl==5) then
                    if(ins%a/=0) call error(p,'Repeated IOSTAT control')
                    ins%a=a
                else
                    if(ins%b/=0) call error(p,'Repeated IOMSG control')
                    ins%b=a
                end if
            end do
        end if
        call expect(p,')');allocate(ins%items(0))
        if(p%tokens(p%p)%kind/=tk_eol) then
            do while(p%diag%code==0)
                a=output_item(p,1);if(p%diag%code/=0) return
                if(is_derived_type(p%prog%expressions(a)%typ)) &
                    call error(p,'Derived values are supported only in parent PRINT data transfer')
                ins%items=[ins%items,a]
                if(size(ins%items)>64) call error(p,'Internal WRITE item limit exceeded')
                if(.not.take(p,',')) exit
            end do
        end if
        if(ins%op==op_write_internal.and.ins%a/=0)then
            if(.not.valid_internal_write_values(p%prog,ins))then
                call error(p,'Internal WRITE element does not support IMPURE function references');return
            end if
        end if
        if(allocated(ins%format)) call validate_output_format(p,ins)
        call finish_line(p);j=emit(p,ins)
    end subroutine
    subroutine stdout_write_statement(p,ins)
        type(parser_t),intent(inout)::p
        type(instruction_t),intent(inout)::ins
        integer::a,j,t
        logical::has_format
        ! The default output unit supports a bounded optional ADVANCE control.
        ! Use PRINT's opcode so staging, formats, purity and recursive-I/O
        ! guards remain one runtime contract, not a second output backend.
        ins%op=op_print
        call expect(p,',')
        if(peek(p)=='fmt'.and.p%tokens(p%p+1)%text=='=') then
            p%p=p%p+1;call expect(p,'=')
        end if
        call output_format(p,ins,has_format)
        if(.not.has_format) then
            if(.not.take(p,'*')) then
                call error(p,'Standard-output WRITE requires * or a literal format or scalar CHARACTER name');return
            end if
        end if
        if(take(p,',')) then
            call expect(p,'advance');call expect(p,'=')
            if(.not.has_format.or.p%tokens(p%p)%kind/=tk_string) then
                call error(p,'ADVANCE requires an explicit format and literal YES or NO');return
            end if
            select case(lower(peek(p)))
            case('no')
                if(len(peek(p))/=2) call error(p,'ADVANCE requires literal YES or NO without padding')
                ins%advance_mode=1
            case('yes')
                if(len(peek(p))/=3) call error(p,'ADVANCE requires literal YES or NO without padding')
                ins%advance_mode=0
            case default
                call error(p,'ADVANCE requires literal YES or NO');return
            end select
            p%p=p%p+1
        end if
        call expect(p,')')
        if(p%diag%code/=0) return
        allocate(ins%items(0))
        if(p%tokens(p%p)%kind/=tk_eol) then
            do while(p%diag%code==0)
                a=output_item(p,1)
                if(p%diag%code/=0) return
                ins%items=[ins%items,a]
                if(size(ins%items)>64) then
                    call error(p,'WRITE item limit exceeded');return
                end if
                t=p%prog%expressions(a)%typ-ty_derived_base
                if(t>=1.and.t<=p%prog%nt) then
                    if(p%prog%derived_types(t)%write_procedure==0) &
                        call error(p,'Derived output requires a defined formatted WRITE binding')
                end if
                if(.not.take(p,',')) exit
            end do
        end if
        call finish_line(p)
        if(allocated(ins%format).and.p%diag%code==0) call validate_output_format(p,ins)
        if(p%diag%code/=0) return
        j=emit(p,ins)
    end subroutine
    subroutine read_name(p,name)
        type(parser_t),intent(inout)::p
        character(63),intent(out)::name
        name=''
        if(p%diag%code/=0) return
        if(p%tokens(p%p)%kind/=tk_name.or.reserved(peek(p))) then
            call error(p,'Expected a nonreserved name'); return
        end if
        name=peek(p); p%p=p%p+1
    end subroutine
    subroutine use_statement(p)
        type(parser_t),intent(inout)::p
        integer::m,lin,j,u,a,k
        character(63)::name,item,remote
        logical::intrinsic,non_intrinsic,found
        lin=p%tokens(p%p)%line
        call expect(p,'use'); intrinsic=.false.;non_intrinsic=.false.
        if(take(p,',')) then
            if(take(p,'intrinsic')) then
                intrinsic=.true.
            else
                call expect(p,'non_intrinsic');non_intrinsic=.true.
            end if
            call expect(p,'::')
        else if(take(p,'::')) then
            ! Optional separator with omitted module nature.
        end if
        call read_name(p,name)
        if(p%diag%code/=0) return
        ! A previously defined source module wins when nature is omitted.
        ! Explicit INTRINSIC bypasses it; NON_INTRINSIC never falls back.
        if(name=='iso_fortran_env'.and..not.intrinsic.and..not.non_intrinsic) then
            intrinsic=.true.
            do m=1,p%prog%nm
                if(p%prog%modules(m)==name) intrinsic=.false.
            end do
        end if
        if(intrinsic) then
            if(name/='iso_fortran_env') then
                call error(p,'Only intrinsic ISO_FORTRAN_ENV is supported'); return
            end if
            call expect(p,','); call expect(p,'only'); call expect(p,':')
            do while(p%diag%code==0)
                call read_name(p,item)
                remote=item
                if(take(p,'=>')) call read_name(p,remote)
                if(p%diag%code/=0) return
                select case(trim(remote))
                case('real32','int32'); k=4
                case('real64','int64'); k=8
                case('real128','int8','int16'); k=-1
                case('integer_kinds'); k=0
                case('output_unit'); k=processor_output_unit
                case default
                    call error(p,'Supported ISO_FORTRAN_ENV imports are REAL32, REAL64, REAL128, INT8, INT16, INT32, INT64, INTEGER_KINDS and OUTPUT_UNIT'); return
                end select
                if(find_symbol(p,trim(item))/=0) then
                    call error(p,'Duplicate intrinsic import'); return
                end if
                if(p%prog%ns==max_symbols) then
                    call error(p,'Symbol limit exceeded'); return
                end if
                p%prog%ns=p%prog%ns+1; a=p%prog%ns
                p%prog%symbols(a)=symbol_t(name=item,typ=ty_integer,line=lin,column=1)
                p%prog%symbols(a)%scope=p%scope
                p%prog%symbols(a)%is_parameter=.true.; p%prog%symbols(a)%parameter_ready=.true.
                p%prog%symbols(a)%is_intrinsic=.true.
                p%prog%symbols(a)%intrinsic_import=remote
                if(remote=='integer_kinds')then
                    ! Only kinds implemented by this interpreter are advertised.
                    p%prog%symbols(a)%rank=1
                    p%prog%symbols(a)%upper_bound=2_int64
                    p%prog%symbols(a)%constant_values=[value_t(tag=ty_integer,i=4_int64), &
                                                      value_t(tag=ty_integer,i=8_int64)]
                else
                    p%prog%symbols(a)%constant_value=value_t(tag=ty_integer,i=int(k,int64))
                end if
                if(p%scope<0) p%prog%symbols(a)%is_public=.not.p%prog%module_private(-p%scope)
                if(.not.take(p,',')) exit
            end do
            call finish_line(p); return
        end if
        if(p%scope>0) then
            call error(p,'Nonintrinsic USE inside procedures is unsupported'); return
        end if
        do m=1,p%prog%nm
            if(p%prog%modules(m)==name) exit
        end do
        if(m>p%prog%nm.or.m==-p%scope) then
            call error(p,'USE requires a module defined earlier in this source'); return
        end if
        if(any(p%prog%uses==m.and.p%prog%use_scopes==p%scope)) then
            call error(p,'Duplicate USE statements are unsupported'); return
        end if
        if(p%prog%nu==size(p%prog%uses)) then
            call error(p,'USE association limit exceeded'); return
        end if
        p%prog%nu=p%prog%nu+1; u=p%prog%nu; p%prog%uses(u)=m; p%prog%use_lines(u)=lin
        p%prog%use_scopes(u)=p%scope
        if(take(p,',')) then
            call expect(p,'only'); call expect(p,':'); p%prog%use_only(u)=.true.
            do while(p%diag%code==0.and.p%tokens(p%p)%kind/=tk_eol)
                call access_name(p,item); found=.false.
                do j=1,p%prog%ns
                    if(p%prog%symbols(j)%scope/=-m.or.p%prog%symbols(j)%name/=item) cycle
                    if(p%prog%symbols(j)%is_public) found=.true.
                end do
                do j=1,p%prog%np
                    if(p%prog%procedures(j)%module_id/=m.or.p%prog%procedures(j)%name/=item) cycle
                    if(p%prog%procedures(j)%is_public) found=.true.
                end do
                do j=1,p%prog%nt
                    if(p%prog%derived_types(j)%module_id/=m.or.p%prog%derived_types(j)%name/=item) cycle
                    if(p%prog%derived_types(j)%is_public) found=.true.
                end do
                do j=1,p%prog%no
                    if(p%prog%operators(j)%module_id/=m) cycle
                    if('operator('//trim(p%prog%operators(j)%op)//')'/=item) cycle
                    if(p%prog%operators(j)%is_public) found=.true.
                end do
                do j=1,p%prog%ng
                    if(p%prog%generics(j)%module_id/=m.or.p%prog%generics(j)%name/=item) cycle
                    if(p%prog%generics(j)%is_public) found=.true.
                end do
                if(.not.found) then
                    call error(p,'ONLY name is absent or PRIVATE: '//trim(item)); return
                end if
                if(p%prog%n_only(u)==max_only_names) then
                    call error(p,'ONLY list limit exceeded'); return
                end if
                p%prog%n_only(u)=p%prog%n_only(u)+1
                p%prog%only_names(p%prog%n_only(u),u)=item
                if(.not.take(p,',')) exit
            end do
        end if
        call finish_line(p)
    end subroutine
    logical function imported(p,m,name)
        type(parser_t),intent(in)::p
        integer,intent(in)::m
        character(*),intent(in)::name
        integer::u,host
        imported=.false.;host=p%scope
        if(host>0) host=-p%prog%procedures(host)%module_id
        do u=1,p%prog%nu
            if(p%prog%use_scopes(u)/=host) cycle
            if(p%prog%uses(u)/=m) cycle
            imported=.not.p%prog%use_only(u).or.any(p%prog%only_names(:,u)==name)
        end do
    end function
    logical function imported_name(p,name) result(found)
        type(parser_t),intent(in)::p
        character(*),intent(in)::name
        integer::j,m
        found=.false.
        do j=1,p%prog%ns
            m=-p%prog%symbols(j)%scope
            if(m<=0.or.p%prog%symbols(j)%name/=name.or..not.p%prog%symbols(j)%is_public) cycle
            if(imported(p,m,name)) found=.true.
        end do
        do j=1,p%prog%np
            m=p%prog%procedures(j)%module_id
            if(m<=0.or.p%prog%procedures(j)%name/=name.or..not.p%prog%procedures(j)%is_public) cycle
            if(imported(p,m,name)) found=.true.
        end do
        do j=1,p%prog%nt
            m=p%prog%derived_types(j)%module_id
            if(p%prog%derived_types(j)%name/=name.or..not.p%prog%derived_types(j)%is_public) cycle
            if(imported(p,m,name)) found=.true.
        end do
        do j=1,p%prog%ng
            m=p%prog%generics(j)%module_id
            if(p%prog%generics(j)%name/=name.or..not.p%prog%generics(j)%is_public) cycle
            if(imported(p,m,name)) found=.true.
        end do
    end function
    integer function find_procedure(p,name) result(f)
        type(parser_t),intent(inout)::p
        character(*),intent(in)::name
        integer::j,m,host
        logical::visible
        f=0; host=0
        if(p%scope>0) then
            host=p%scope
            if(p%prog%procedures(p%scope)%parent_procedure>0) host=p%prog%procedures(p%scope)%parent_procedure
            do j=1,p%prog%np
                if(p%prog%procedures(j)%parent_procedure/=host.or.p%prog%procedures(j)%name/=name) cycle
                f=j;return
            end do
        end if
        host=0
        if(p%scope>0) host=p%prog%procedures(p%scope)%module_id
        if(p%scope<0) host=-p%scope
        do j=1,p%prog%np
            if(p%prog%procedures(j)%name/=name.or.p%prog%procedures(j)%parent_procedure/=0) cycle
            m=p%prog%procedures(j)%module_id
            if(host>0) then
                visible=m==host
                if(.not.visible) visible=p%prog%procedures(j)%is_public.and.imported(p,m,name)
            else
                visible=m==0
                if(m>0) visible=p%prog%procedures(j)%is_public.and.imported(p,m,name)
            end if
            if(.not.visible) cycle
            if(f/=0) then
                call error(p,'Ambiguous USE-associated procedure: '//name); return
            end if
            f=j
        end do
    end function
    ! Parse actuals in source order, then associate names with declared slots.
    ! The runtime representation is dummy-ordered, with zero for omitted OPTIONAL
    ! actuals. The adapter repeats association independently from FortFront's AST.
    recursive subroutine actual_arguments(p,e,name,passed_object)
        type(parser_t),intent(inout)::p
        type(expr_t),intent(inout)::e
        character(*),intent(in)::name
        integer,intent(in),optional::passed_object
        character(63)::keywords(16),formals(16),keyword
        integer::actuals(16),slots(16),n,nformal,j,k,a,required
        logical::saw_keyword,reduction
        keywords='';formals='';actuals=0;slots=0;n=0;saw_keyword=.false.
        if(present(passed_object)) then
            n=1;actuals(1)=passed_object
        end if
        allocate(e%args(0))
        if(p%tokens(p%p)%kind/=tk_op.or.peek(p)/=')') then
            do while(p%diag%code==0)
                if(n==16) then
                    call error(p,'Procedure argument limit exceeded (16)'); return
                end if
                keyword=''
                if(p%tokens(p%p)%kind==tk_name.and.p%tokens(p%p+1)%text=='=') then
                    if(name=='associated'.and.e%symbol==0.and.peek(p)=='pointer') then
                        keyword='pointer';p%p=p%p+1
                    else
                        call read_name(p,keyword)
                    end if
                    call expect(p,'='); saw_keyword=.true.
                else if(saw_keyword) then
                    call error(p,'Positional argument cannot follow a keyword argument'); return
                end if
                a=expression(p,0)
                if(p%diag%code/=0) return
                n=n+1;actuals(n)=a;keywords(n)=keyword
                if(.not.take(p,',')) exit
            end do
        end if
        call expect(p,')')
        if(p%diag%code/=0) return
        e%args=actuals(:n)
        if(e%generic_id>0) then
            call select_generic(p,e,actuals(:n),keywords(:n))
            if(p%diag%code/=0.or.e%symbol>0) return
            ! An unmatched REPEAT extension continues into intrinsic keyword
            ! association; never reinterpret its source arguments as dummies.
        end if
        if(.not.saw_keyword.and.e%symbol==0.and.name/='getcwd'.and.name/='get_command_argument'.and.name/='system_clock'.and.name/='reshape'.and.name/='cshift'.and.name/='eoshift'.and..not.is_bounds_inquiry(name).and..not.is_character_search_intrinsic(name).and..not.is_location_reduction(name)) then
            if((name=='selected_real_kind'.or.is_logical_reduction(name)).and.e%symbol==0) then
                if(n>3) then
                    if(is_logical_reduction(name)) then
                        call error(p,'Logical reduction accepts at most MASK, DIM and KIND');return
                    end if
                    call error(p,'SELECTED_REAL_KIND accepts at most P, R and RADIX');return
                end if
                e%intrinsic_mask=2**n-1
            end if
            return
        end if
        reduction=.false.;nformal=0;required=0
        if(e%symbol>0) then
            nformal=size(p%prog%procedures(e%symbol)%args);required=0
            do j=1,nformal
                formals(j)=p%prog%symbols(p%prog%procedures(e%symbol)%args(j))%name
            end do
        else
            select case(name)
            case('associated')
                nformal=2;required=1;formals(:2)=[character(63)::'pointer','target']
            case('system_clock')
                nformal=3;required=0;formals(:3)=[character(63)::'count','count_rate','count_max']
            case('cpu_time')
                nformal=1;required=1;formals(1)='time'
            case('move_alloc')
                nformal=2;required=2;formals(:2)=[character(63)::'from','to']
            case('allocated')
                nformal=1;required=1;formals(1)='array'
            case('present')
                nformal=1;required=1;formals(1)='a'
            case('min','max')
                nformal=16;required=2
                do j=1,nformal
                    write(formals(j),'("a",i0)')j
                end do
            case('iand','ior','ieor')
                nformal=2;required=2;formals(:2)=[character(63)::'i','j']
            case('not','bit_size','leadz','trailz')
                nformal=1;required=1;formals(1)='i'
            case('maskl','maskr')
                nformal=2;required=1;formals(:2)=[character(63)::'i','kind']
            case('shiftr')
                nformal=2;required=2;formals(:2)=[character(63)::'i','shift']
            case('btest')
                nformal=2;required=2;formals(:2)=[character(63)::'i','pos']
            case('lge','lgt','lle','llt')
                nformal=2;required=2;formals(:2)=[character(63)::'string_a','string_b']
            case('index')
                nformal=4;required=2;formals(:4)=[character(63)::'string','substring','back','kind']
            case('scan','verify')
                nformal=4;required=2;formals(:4)=[character(63)::'string','set','back','kind']
            case('len_trim')
                nformal=2;required=1;formals(:2)=[character(63)::'string','kind']
            case('repeat')
                nformal=2;required=2;formals(:2)=[character(63)::'string','ncopies']
            case('trim','len','adjustl','adjustr')
                nformal=1;required=1;formals(1)='string'
            case('new_line')
                nformal=1;required=1;formals(1)='a'
            case('iachar')
                nformal=2;required=1;formals(:2)=[character(63)::'c','kind']
            case('set_exponent')
                nformal=2;required=2;formals(:2)=[character(63)::'x','i']
            case('fraction','exponent')
                nformal=1;required=1;formals(1)='x'
            case('char','achar')
                nformal=2;required=1;formals(:2)=[character(63)::'i','kind']
            case('aint','anint')
                nformal=2;required=1;formals(:2)=[character(63)::'a','kind']
            case('atan','atan2')
                nformal=2;required=2;formals(:2)=[character(63)::'y','x']
                if(name=='atan'.and.n==1) then
                    nformal=1;required=1;formals(1)='x'
                end if
            case('acosd','asind','sind','cosd','rrspacing','asin','acos','asinh','acosh')
                nformal=1;required=1;formals(1)='x'
            case('real','int','nint','floor','ceiling')
                nformal=2;required=1;formals(:2)=[character(63)::'a','kind']
            case('selected_real_kind')
                nformal=3;required=0;formals(:3)=[character(63)::'p','r','radix']
            case('selected_int_kind')
                nformal=1;required=1;formals(1)='r'
            case('nearest')
                nformal=2;required=2;formals(:2)=[character(63)::'x','s']
            case('dim','dprod')
                nformal=2;required=2;formals(:2)=[character(63)::'x','y']
            case('tand')
                nformal=1;required=1;formals(1)='x'
            case('bessel_jn','bessel_yn')
                nformal=2;required=2;formals(:2)=[character(63)::'n','x']
            case('sign')
                nformal=2;required=2;formals(:2)=[character(63)::'a','b']
            case('kind','digits','epsilon','radix','tiny','huge','minexponent','maxexponent','isnan','erfc_scaled','erf','bessel_j0','bessel_j1','bessel_y0','bessel_y1','sinh','cosh','tanh','sin','cos','tan','log10','log_gamma','spacing')
                nformal=1;required=1;formals(1)='x'
            case('getcwd')
                nformal=2;required=1;formals(:2)=[character(63)::'count','status']
            case('get_command_argument')
                nformal=4;required=1;formals(:4)=[character(63)::'number','value','length','status']
            case('random_number')
                nformal=1;required=1;formals(1)='harvest'
            case('all','any','count','parity')
                nformal=2;required=1;formals(:2)=[character(63)::'mask','dim']
                if(name=='count') then
                    nformal=3;formals(3)='kind'
                end if
            case('merge')
                nformal=3;required=3;formals(:3)=[character(63)::'tsource','fsource','mask']
            case('dble')
                nformal=1;required=1;formals(1)='a'
            case('findloc')
                nformal=6;required=2;formals(:6)=[character(63)::'array','value','dim','mask','kind','back']
            case('minloc','maxloc')
                nformal=5;required=1;formals(:5)=[character(63)::'array','dim','mask','kind','back']
            case('sum','product','minval','maxval')
                nformal=3;required=1;reduction=.true.
                formals(:3)=[character(63)::'array','dim','mask']
            case('transpose')
                nformal=1;required=1;formals(1)='matrix'
            case('norm2')
                nformal=2;required=1;formals(:2)=[character(63)::'x','dim']
            case('shape')
                nformal=2;required=1;formals(:2)=[character(63)::'source','kind']
            case('lbound','ubound')
                nformal=3;required=1;formals(:3)=[character(63)::'array','dim','kind']
            case('size')
                nformal=2;required=1
                formals(:2)=[character(63)::'array','dim']
            case('eoshift')
                nformal=4;required=2;formals(:4)=[character(63)::'array','shift','boundary','dim']
            case('cshift')
                nformal=3;required=2;formals(:3)=[character(63)::'array','shift','dim']
            case('pack')
                nformal=3;required=2;formals(:3)=[character(63)::'array','mask','vector']
            case('dot_product')
                nformal=2;required=2
                formals(:2)=[character(63)::'vector_a','vector_b']
            case('reshape')
                nformal=4;required=2;formals(:4)=[character(63)::'source','shape','pad','order']
            case('matmul')
                nformal=2;required=2
                formals(:2)=[character(63)::'matrix_a','matrix_b']
            case default
                call error(p,'Keyword arguments are unsupported for intrinsic: '//name);return
            end select
        end if
        do j=1,n
            k=j
            ! Associate a positional second LOGICAL argument with MASK.
            if(is_location_reduction(name).and.e%symbol==0.and.j>=required+1) then
                if(len_trim(keywords(required+1))==0) then
                    if(p%prog%expressions(actuals(required+1))%typ==ty_logical) then
                        if(j>required+1.and.len_trim(keywords(j))==0) then
                            call error(p,'Location intrinsics without DIM require keyword KIND/BACK');return
                        end if
                        k=j+1
                    end if
                end if
            end if
            if(len_trim(keywords(j))>0) then
                do k=1,nformal
                    if(formals(k)==keywords(j)) exit
                end do
            end if
            if(k>nformal) then
                call error(p,'Unknown keyword or excess actual argument: '//trim(keywords(j)));return
            end if
            if(slots(k)/=0) then
                call error(p,'Repeated actual argument for '//trim(formals(k)));return
            end if
            slots(k)=actuals(j)
        end do
        if(any(slots(:required)==0)) then
            call error(p,'Missing required actual argument');return
        end if
        if(reduction) then
            ! A named DIM cannot silently select the positional MASK overload.
            if(slots(2)/=0) then
                if(p%prog%expressions(slots(2))%typ/=ty_integer.or. &
                   p%prog%expressions(slots(2))%rank/=0) then
                    call error(p,'Reduction DIM must be a scalar INTEGER');return
                end if
            end if
            if(slots(3)/=0) then
                if(p%prog%expressions(slots(3))%typ/=ty_logical) then
                    call error(p,'Reduction MASK must be LOGICAL');return
                end if
            end if
        end if
        if(e%symbol>0) then
            do j=1,nformal
                if(slots(j)/=0) cycle
                if(.not.p%prog%symbols(p%prog%procedures(e%symbol)%args(j))%is_optional) then
                    call error(p,'Missing required actual argument: '//trim(formals(j)));return
                end if
            end do
            e%args=slots(:nformal)
        else if(name=='getcwd'.or.name=='get_command_argument'.or.name=='system_clock') then
            e%args=slots(:nformal)
        else
            e%args=pack(slots(:nformal),slots(:nformal)/=0)
        end if
        if((name=='selected_real_kind'.or.is_logical_reduction(name).or.name=='reshape'.or.name=='cshift'.or.name=='eoshift'.or.is_bounds_inquiry(name).or.is_character_search_intrinsic(name).or.is_location_reduction(name)).and.e%symbol==0) then
            e%intrinsic_mask=0
            do j=1,nformal
                if(slots(j)/=0) e%intrinsic_mask=ibset(e%intrinsic_mask,j-1)
            end do
        end if
    end subroutine
    subroutine user_call_type(p,e,subroutine_call)
        type(parser_t),intent(inout)::p
        type(expr_t),intent(inout)::e
        logical,intent(in),optional::subroutine_call
        integer::j,s,f,a,v
        logical::sub
        if(p%diag%code/=0) return
        sub=.false.; if(present(subroutine_call)) sub=subroutine_call
        f=e%symbol
        if(p%prog%procedures(f)%is_subroutine.neqv.sub) then
            call error(p,'CALL requires a SUBROUTINE; expressions require a FUNCTION'); return
        end if
        if(size(e%args)/=size(p%prog%procedures(f)%args)) then
            call error(p,'Procedure requires exactly its declared arguments'); return
        end if
        if(p%scope>0) then
            if(p%prog%procedures(p%scope)%is_simple.and..not.p%prog%procedures(f)%is_simple) &
                call error(p,'SIMPLE procedure cannot invoke a procedure not designated SIMPLE')
            if(p%prog%procedures(p%scope)%is_pure.and..not.p%prog%procedures(f)%is_pure) &
                call error(p,'PURE procedure cannot invoke an impure procedure')
        end if
        do j=1,size(e%args)
            s=p%prog%procedures(f)%args(j)
            if(e%args(j)==0) then
                if(.not.p%prog%symbols(s)%is_optional) call error(p,'Missing required actual argument')
                cycle
            end if
            if((.not.p%prog%procedures(f)%is_elemental.and. &
                p%prog%expressions(e%args(j))%rank/=p%prog%symbols(s)%rank).or. &
                p%prog%expressions(e%args(j))%typ/=p%prog%symbols(s)%typ) then
                call error(p,'Procedure argument type or rank does not match its dummy declaration'); return
            end if
            a=e%args(j);v=p%prog%expressions(a)%symbol
            if(p%prog%expressions(a)%kind==ex_gather_rows.and. &
               ((.not.p%prog%expressions(a)%parenthesized.and. &
                 .not.bare_gather_input(p%prog,a,s)).or.p%prog%symbols(s)%dummy_intent/=1)) then
                call error(p,'Parenthesize a gathered row value when passing it to a user procedure');return
            end if
            if(p%prog%symbols(s)%is_pointer) then
                if(p%prog%expressions(a)%kind/=ex_variable.or.p%prog%expressions(a)%parenthesized.or.v<1) then
                    call error(p,'POINTER dummy requires a whole POINTER actual');return
                end if
                if(.not.p%prog%symbols(v)%is_pointer) then
                    call error(p,'POINTER dummy requires POINTER actual attribute');return
                end if
            else if(v>0.and.(p%prog%expressions(a)%kind==ex_variable.or. &
                p%prog%expressions(a)%kind==ex_element.or.p%prog%expressions(a)%kind==ex_section)) then
                if(p%prog%symbols(v)%is_pointer) then
                    call error(p,'Direct POINTER actual requires POINTER dummy');return
                end if
            end if
            if(p%prog%symbols(s)%is_allocatable) then
                a=e%args(j);v=p%prog%expressions(a)%symbol
                if(p%prog%expressions(a)%kind/=ex_variable.or.p%prog%expressions(a)%parenthesized.or.v<1) then
                    call error(p,'ALLOCATABLE dummy requires a whole allocatable variable actual');return
                end if
                if(.not.p%prog%symbols(v)%is_allocatable) then
                    call error(p,'ALLOCATABLE dummy requires an ALLOCATABLE actual');return
                end if
                if(p%prog%symbols(s)%deferred_character.neqv.p%prog%symbols(v)%deferred_character) then
                    call error(p,'ALLOCATABLE CHARACTER actual and dummy must agree on deferred length');return
                end if
            end if
            if(p%prog%procedures(f)%is_elemental) call merge_shape(p,e,e%args(j))
            if(p%prog%symbols(s)%dummy_intent/=1) then
                a=e%args(j); v=p%prog%expressions(a)%symbol
                if(p%prog%expressions(a)%parenthesized.or. &
                   (p%prog%expressions(a)%kind/=ex_variable.and. &
                    p%prog%expressions(a)%kind/=ex_element.and.p%prog%expressions(a)%kind/=ex_section)) then
                    call error(p,'Writable dummy requires a variable, element or section actual'); return
                end if
                if(v<1.or.v>p%prog%ns) then
                    call error(p,'Writable actual has no variable binding'); return
                end if
                if(p%prog%symbols(v)%is_parameter.or.p%prog%symbols(v)%dummy_intent==1) then
                    call error(p,'Writable actual cannot be a PARAMETER or INTENT(IN) dummy'); return
                end if
                call check_module_write(p,v)
                if(p%diag%code/=0) return
                if(any(p%active_do==v)) then
                    call error(p,'Writable actual cannot be an active DO variable'); return
                end if
            end if
            if((p%prog%symbols(s)%typ==ty_real.or.p%prog%symbols(s)%typ==ty_integer)) then
                if(p%prog%expressions(e%args(j))%real_kind/=p%prog%symbols(s)%real_kind) then
                    call error(p,'Procedure argument REAL kind does not match its dummy declaration'); return
                end if
            end if
        end do
        if(sub.and.p%prog%procedures(f)%is_elemental.and.e%rank>0) then
            a=0
            do j=1,size(e%args)
                s=p%prog%procedures(f)%args(j)
                if(e%args(j)==0) cycle
                if(p%prog%symbols(s)%dummy_intent==1) cycle
                a=a+1
                if(p%prog%expressions(e%args(j))%rank/=e%rank) then
                    call error(p,'ELEMENTAL array CALL requires array actuals for all writable dummies'); return
                end if
            end do
            if(a==0) then
                call error(p,'ELEMENTAL array CALL requires an OUT or INOUT dummy'); return
            end if
        end if
        if(.not.sub) then
            s=p%prog%procedures(f)%result_symbol
            e%typ=p%prog%symbols(s)%typ; e%real_kind=p%prog%symbols(s)%real_kind
            if(.not.p%prog%procedures(f)%is_elemental) then
                e%rank=p%prog%symbols(s)%rank
                ! The result descriptor belongs to the invocation, not the caller.
                if(e%rank>0) e%extent=-1_int64
                if(e%rank>=2) e%dims=-1_int64
            end if
        end if
    end subroutine
    subroutine validate_pointer_uses(p)
        type(parser_t),intent(inout)::p
        integer::i,j,t,f,children(12)
        do i=1,p%prog%ne
            associate(e=>p%prog%expressions(i))
            if(e%scope<=0) cycle
            if(e%kind==ex_element.or.e%kind==ex_section) then
                if(p%prog%symbols(e%symbol)%is_pointer) then
                    call error(p,'Procedure POINTER pointee reads are unsupported');return
                end if
            end if
            children=[e%left,e%right,e%stride,e%left2,e%right2,e%stride2,e%left3,e%right3,e%stride3,e%third,0,0]
            do j=1,size(children)
                if(pointer_operand(p,children(j))) then
                    call error(p,'Procedure POINTER pointee reads are unsupported');return
                end if
            end do
            if(allocated(e%args)) then
                do j=1,size(e%args)
                    if(.not.pointer_operand(p,e%args(j))) cycle
                    if(e%kind==ex_call.and.(e%op=='associated'.or.e%op=='present')) cycle
                    call error(p,'Procedure POINTER value expression is unsupported');return
                end do
            end if
            end associate
        end do
        do i=1,p%prog%nc
            associate(ins=>p%prog%code(i))
            if(ins%scope<=0) cycle
            children=0;children(:5)=[ins%a,ins%b,ins%c,ins%d,ins%third]
            if(ins%op==op_pointer_assign) children(1)=0
            if(ins%op==op_write_defined) children(:2)=0
            do j=1,5
                if(pointer_operand(p,children(j))) then
                    call error(p,'Procedure POINTER pointee use is unsupported');return
                end if
            end do
            if(ins%op==op_assign) then
                if(p%prog%symbols(ins%symbol)%is_pointer) then
                    call error(p,'Procedure POINTER pointee writes are unsupported');return
                end if
            end if
            if(allocated(ins%items)) then
                do j=1,size(ins%items)
                    if(.not.pointer_operand(p,ins%items(j))) cycle
                    if(ins%op==op_call) then
                        f=ins%symbol;t=p%prog%procedures(f)%args(j)
                        if(p%prog%symbols(t)%is_pointer) cycle
                    end if
                    call error(p,'Procedure POINTER pointee use is unsupported');return
                end do
            end if
            end associate
        end do
    end subroutine
    logical function pointer_operand(p,a) result(is_pointer)
        type(parser_t),intent(in)::p
        integer,intent(in)::a
        integer::s
        is_pointer=.false.
        if(a<1.or.a>p%prog%ne) return
        if(p%prog%expressions(a)%kind/=ex_variable) return
        s=p%prog%expressions(a)%symbol
        if(s>0.and.s<=p%prog%ns) is_pointer=p%prog%symbols(s)%is_pointer
    end function
    subroutine validate_calls(p)
        type(parser_t),intent(inout)::p
        integer::i,j,f,s,n,edge_count,edge,top,node,ios
        integer,allocatable::head(:),targets(:),next_edge(:),pending(:)
        logical,allocatable::visited(:),external_effect(:)
        do s=1,p%prog%ns
            p%scope=p%prog%symbols(s)%scope
            f=find_generic(p,trim(p%prog%symbols(s)%name))
            if(f/=0) call error(p,'Local declaration conflicts with a visible generic interface')
            f=find_procedure(p,trim(p%prog%symbols(s)%name))
            if(f/=0) then
                if(p%scope/=f.or.p%prog%procedures(f)%result_symbol/=s) &
                    call error(p,'Local declaration conflicts with a visible module function')
            end if
            if(p%diag%code/=0) return
        end do
        p%scope=0;n=p%prog%np
        ! A sparse adjacency list avoids a cap-sized stack matrix and cubic
        ! transitive closure. Each root traverses each reachable edge once.
        allocate(head(n),targets(p%prog%nc+p%prog%ne),next_edge(p%prog%nc+p%prog%ne), &
                 pending(n),visited(n),external_effect(n),stat=ios)
        if(ios/=0) then
            call error(p,'Unable to allocate procedure graph storage');return
        end if
        head=0;edge_count=0;external_effect=.false.
        do i=1,p%prog%nc
            f=p%prog%code(i)%scope
            if(p%prog%code(i)%op==op_call.and.allocated(p%prog%code(i)%items)) then
                if(module_actual_conflict(p%prog,p%prog%code(i)%symbol,p%prog%code(i)%items)) then
                    call error(p,'Module actual also referenced through callee host/USE association is unsupported');return
                end if
            end if
            if(f<=0) cycle
            s=module_write_target(p%prog%code(i))
            if(s>0) then
                if((p%prog%symbols(s)%scope<0.or.p%prog%symbols(s)%is_saved.or. &
                   (p%prog%symbols(s)%scope>0.and.p%prog%symbols(s)%scope/=f)).and. &
                   .not.p%prog%symbols(s)%is_parameter) external_effect(f)=.true.
            end if
            if(p%prog%code(i)%op==op_call) then
                do j=1,size(p%prog%code(i)%items)
                    s=p%prog%code(i)%items(j)
                    if(s==0) cycle
                    if(p%prog%symbols(p%prog%procedures(p%prog%code(i)%symbol)%args(j))%dummy_intent<2) cycle
                    s=p%prog%expressions(s)%symbol
                    if(s>0) then
                        if(p%prog%symbols(s)%scope<0.or.p%prog%symbols(s)%is_saved.or. &
                   (p%prog%symbols(s)%scope>0.and.p%prog%symbols(s)%scope/=f)) external_effect(f)=.true.
                    end if
                end do
            end if
            select case(p%prog%code(i)%op)
            case(op_call)
                edge_count=edge_count+1;targets(edge_count)=p%prog%code(i)%symbol
                next_edge(edge_count)=head(f);head(f)=edge_count
            case(op_print,op_write_defined)
                external_effect(f)=.true.
            end select
        end do
        do i=1,p%prog%ne
            if(p%prog%expressions(i)%kind/=ex_user_call) cycle
            if(module_actual_conflict(p%prog,p%prog%expressions(i)%symbol,p%prog%expressions(i)%args)) then
                call error(p,'Module actual also referenced through callee host/USE association is unsupported');return
            end if
            f=p%prog%expressions(i)%scope
            if(f<=0) cycle
            edge_count=edge_count+1;targets(edge_count)=p%prog%expressions(i)%symbol
            next_edge(edge_count)=head(f);head(f)=edge_count
        end do
        do f=1,n
            visited=.false.;visited(f)=.true.;top=1;pending(top)=f
            do while(top>0)
                node=pending(top);top=top-1;edge=head(node)
                do while(edge/=0)
                    j=targets(edge)
                    if(j==f.and..not.p%prog%procedures(f)%is_recursive) then
                        call error(p,'Recursive module function cycles require RECURSIVE on every participating procedure');return
                    end if
                    if(.not.visited(j)) then
                        visited(j)=.true.;top=top+1;pending(top)=j
                    end if
                    edge=next_edge(edge)
                end do
            end do
            if(p%prog%procedures(f)%is_subroutine.or.p%prog%procedures(f)%has_impure_prefix) cycle
            if(any(visited.and.external_effect)) then
                call error(p,'External side effects inside ordinary functions are unsupported');return
            end if
        end do
    end subroutine

    subroutine lex(source,p)
        character(*), intent(in) :: source
        type(parser_t), intent(inout) :: p
        integer :: i,j,n,line,col,start,linecol,k,ios
        character :: c,q
        character(32) :: limit_text
        character(:),allocatable :: text
        logical :: real_token,closed
        if(len(source,kind=int64)>int(max_source_bytes,int64)) then
            write(limit_text,'(i0)') max_source_bytes
            call fail(p%diag,'Source exceeds the '//trim(limit_text)//'-byte prototype limit')
            return
        end if
        n=len(source)
        ! Grow with the actual token count instead of reserving the new ceiling
        ! on every small source. Reject oversize source before any token storage.
        allocate(p%tokens(min(256,max_tokens)),stat=ios)
        if(ios/=0) then
            call fail(p%diag,'Cannot allocate token buffer')
            return
        end if
        i=1; line=1; col=1
        do while(i<=n)
            c=source(i:i)
            if(iachar(c)>126 .or. (iachar(c)<32 .and. c/=achar(10) .and. c/=achar(13) .and. c/=achar(9))) then
                call fail(p%diag,'Only ASCII free-form source is supported',line,col)
                return
            end if
            if(col>132 .and. c/=achar(10) .and. c/=achar(13)) then
                call fail(p%diag,'Source lines longer than 132 columns are unsupported',line,col)
                return
            end if
            if(c==' ' .or. c==achar(9) .or. c==achar(13)) then
                i=i+1; col=col+1; cycle
            end if
            if(c=='&') then
                i=i+1; col=col+1
                do while(i<=n)
                    if(source(i:i)/=' '.and.source(i:i)/=achar(9).and.source(i:i)/=achar(13)) exit
                    i=i+1; col=col+1
                end do
                if(i<=n) then
                    if(source(i:i)=='!') then
                        do while(i<=n)
                            if(source(i:i)==achar(10)) exit
                            i=i+1; col=col+1
                        end do
                    end if
                end if
                if(i>n) then
                    call fail(p%diag,'Continuation requires a following source line',line,col); return
                end if
                if(source(i:i)/=achar(10)) then
                    call fail(p%diag,'Trailing continuation marker must end its source line',line,col); return
                end if
                i=i+1; line=line+1; col=1
                do while(i<=n)
                    do while(i<=n)
                        if(source(i:i)/=' '.and.source(i:i)/=achar(9).and.source(i:i)/=achar(13)) exit
                        i=i+1; col=col+1
                    end do
                    if(i>n) exit
                    if(source(i:i)=='!') then
                        do while(i<=n)
                            if(source(i:i)==achar(10)) exit
                            i=i+1; col=col+1
                        end do
                    end if
                    if(i>n) exit
                    if(source(i:i)/=achar(10)) exit
                    i=i+1; line=line+1; col=1
                end do
                if(i>n) then
                    call fail(p%diag,'Continuation requires a following statement fragment',line,col); return
                end if
                if(source(i:i)=='&') then
                    i=i+1; col=col+1
                end if
                cycle
            end if
            if(c=='!') then
                do while(i<=n)
                    if(source(i:i)==achar(10)) exit
                    i=i+1; col=col+1
                end do
                cycle
            end if
            if(c==achar(10) .or. c==';') then
                call token(p,tk_eol,';',line,col)
                i=i+1
                if(c==achar(10)) then
                    line=line+1; col=1
                else
                    col=col+1
                end if
                cycle
            end if
            start=i; linecol=col
            if(letter(c)) then
                i=i+1
                do while(i<=n)
                    c=source(i:i)
                    if(.not.letter(c) .and. .not.digit(c) .and. c/='_') exit
                    i=i+1
                end do
                if(i-start>63) then
                    call fail(p%diag,'Name exceeds 63 characters',line,linecol)
                    return
                end if
                call token(p,tk_name,lower(source(start:i-1)),line,linecol)
            else if(c=='"' .or. c=="'") then
                q=c; text=''; i=i+1; closed=.false.
                do while(i<=n)
                    c=source(i:i)
                    if(c==achar(10)) exit
                    if(c==q) then
                        if(i<n) then
                            if(source(i+1:i+1)==q) then
                                text=text//q; i=i+2; cycle
                            end if
                        end if
                        i=i+1; closed=.true.; exit
                    end if
                    text=text//c; i=i+1
                end do
                if(.not.closed) then
                    call fail(p%diag,'Unterminated character literal',line,linecol)
                    return
                end if
                call token(p,tk_string,text,line,linecol)
            else if(digit(c) .or. decimal_start(source,i)) then
                real_token=.false.
                do while(i<=n)
                    if(.not.digit(source(i:i))) exit
                    i=i+1
                end do
                if(i<=n) then
                    if(source(i:i)=='.'.and..not.dotted_start(source,i)) then
                        real_token=.true.; i=i+1
                        do while(i<=n)
                            if(.not.digit(source(i:i))) exit
                            i=i+1
                        end do
                    end if
                end if
                if(i<=n) then
                    c=lower(source(i:i))
                    if(c=='e'.or.c=='d') then
                        real_token=.true.; i=i+1
                        if(i<=n) then
                            if(source(i:i)=='+' .or. source(i:i)=='-') i=i+1
                        end if
                        j=i
                        do while(i<=n)
                            if(.not.digit(source(i:i))) exit
                            i=i+1
                        end do
                        if(i==j) then
                            call fail(p%diag,'Exponent has no digits',line,linecol)
                            return
                        end if
                    end if
                end if
                if(i<=n) then
                    if(source(i:i)=='_') then
                        i=i+1; j=i
                        do while(i<=n)
                            if(.not.letter(source(i:i)).and..not.digit(source(i:i)).and.source(i:i)/='_') exit
                            i=i+1
                        end do
                        if(i==j) then
                            call fail(p%diag,'Missing literal kind suffix',line,linecol); return
                        end if
                    end if
                end if
                k=tk_integer
                if(real_token) k=tk_real
                call token(p,k,source(start:i-1),line,linecol)
            else if(c=='.') then
                i=i+1
                do while(i<=n)
                    if(.not.letter(source(i:i))) exit
                    i=i+1
                end do
                if(i>n) then
                    call fail(p%diag,'Incomplete dotted operator',line,linecol)
                    return
                end if
                if(source(i:i)/='.') then
                    call fail(p%diag,'Unknown dotted token',line,linecol)
                    return
                end if
                i=i+1
                text=lower(source(start:i-1))
                select case(text)
                case('.true.','.false.','.and.','.or.','.not.','.eqv.','.neqv.','.eq.','.ne.','.lt.','.le.','.gt.','.ge.')
                    call token(p,tk_op,text,line,linecol)
                case default
                    if(.not.custom_operator(text)) then
                        call fail(p%diag,'Defined operator names require 1 to 14 letters',line,linecol)
                        return
                    end if
                    call token(p,tk_op,text,line,linecol)
                end select
            else
                text=c; i=i+1
                if(i<=n) then
                    select case(text//source(i:i))
                    case('::','**','<=','>=','==','/=','=>','//')
                        text=text//source(i:i); i=i+1
                    end select
                end if
                select case(text)
                case('::','**','<=','>=','==','/=','=>','//','%','+','-','*','/','<','>','=',',','(',')',':','[',']')
                    call token(p,tk_op,text,line,linecol)
                case default
                    call fail(p%diag,'Unsupported source token: '//text,line,linecol)
                    return
                end select
            end if
            col=col+i-start
            if(col>133) then
                call fail(p%diag,'Source lines longer than 132 columns are unsupported',line,133)
                return
            end if
            if(p%diag%code/=0) return
        end do
        call token(p,tk_eol,';',line,col)
        call token(p,tk_eof,'<eof>',line,col)
    end subroutine

    subroutine token(p,kind,text,line,col)
        type(parser_t),intent(inout)::p
        integer,intent(in)::kind,line,col
        character(*),intent(in)::text
        type(token_t),allocatable::grown(:)
        integer::capacity,ios,i
        character(32)::limit_text
        if(p%diag%code/=0) return
        if(p%n>=max_tokens) then
            write(limit_text,'(i0)') max_tokens
            call fail(p%diag,'Token limit exceeded ('//trim(limit_text)//' including final separator and EOF)',line,col)
            return
        end if
        if(p%n==size(p%tokens)) then
            capacity=size(p%tokens)+min(size(p%tokens),max_tokens-size(p%tokens))
            allocate(grown(capacity),stat=ios)
            if(ios/=0) then
                call fail(p%diag,'Cannot grow token buffer',line,col)
                return
            end if
            do i=1,p%n
                call move_alloc(p%tokens(i)%text,grown(i)%text)
                grown(i)%kind=p%tokens(i)%kind
                grown(i)%line=p%tokens(i)%line
                grown(i)%column=p%tokens(i)%column
            end do
            call move_alloc(grown,p%tokens)
        end if
        p%n=p%n+1
        p%tokens(p%n)=token_t(text,kind,line,col)
    end subroutine
    pure logical function letter(c)
        character,intent(in)::c
        letter=(c>='a'.and.c<='z').or.(c>='A'.and.c<='Z')
    end function
    pure logical function digit(c)
        character,intent(in)::c
        digit=c>='0'.and.c<='9'
    end function
    pure logical function decimal_start(s,i)
        character(*),intent(in)::s
        integer,intent(in)::i
        decimal_start=.false.
        if(s(i:i)/='.') return
        if(i>=len(s)) return
        decimal_start=digit(s(i+1:i+1))
    end function
    pure logical function dotted_start(s,i)
        character(*),intent(in)::s
        integer,intent(in)::i
        integer::j
        dotted_start=.false.
        if(s(i:i)/='.') return
        j=i+1
        do while(j<=len(s))
            if(.not.letter(s(j:j))) exit
            j=j+1
        end do
        if(j>len(s).or.j==i+1) return
        dotted_start=s(j:j)=='.'
    end function
    function peek(p) result(s)
        type(parser_t),intent(in)::p
        character(:),allocatable::s
        s=p%tokens(p%p)%text
    end function
    subroutine error(p,message)
        type(parser_t),intent(inout)::p
        character(*),intent(in)::message
        call fail(p%diag,message,p%tokens(p%p)%line,p%tokens(p%p)%column)
    end subroutine
    subroutine expect(p,text)
        type(parser_t),intent(inout)::p
        character(*),intent(in)::text
        if(p%diag%code/=0) return
        if(p%tokens(p%p)%kind==tk_string.or.peek(p)/=text) then
            call error(p,'Expected '//text//', found '//peek(p))
            return
        end if
        p%p=p%p+1
    end subroutine
    logical function take(p,text)
        type(parser_t),intent(inout)::p
        character(*),intent(in)::text
        take=.false.
        if(p%diag%code/=0) return
        ! Quoted spellings are data, never grammar punctuation or keywords.
        if(p%tokens(p%p)%kind==tk_string) return
        if(peek(p)/=text) return
        take=.true.; p%p=p%p+1
    end function
    subroutine skip_lines(p)
        type(parser_t),intent(inout)::p
        if(p%diag%code/=0) return
        do while(p%tokens(p%p)%kind==tk_eol)
            p%p=p%p+1
        end do
    end subroutine
    subroutine finish_line(p)
        type(parser_t),intent(inout)::p
        if(p%diag%code/=0) return
        if(p%tokens(p%p)%kind/=tk_eol) then
            call error(p,'Unexpected trailing token: '//peek(p))
            return
        end if
        call skip_lines(p)
    end subroutine
    integer function declaration_type(p) result(t)
        type(parser_t),intent(in)::p
        t=type_name(peek(p))
        ! DOUBLE and DOUBLEPRECISION remain legal identifiers. In a local
        ! specification/execution boundary, assignment syntax ends declarations.
        if(peek(p)=='double'.and.p%tokens(p%p+1)%text/='precision') t=0
        if(peek(p)=='doubleprecision') then
            select case(p%tokens(p%p+1)%text)
            case('=','=>','(');t=0
            end select
        end if
    end function
    integer function type_name(s) result(t)
        character(*),intent(in)::s
        t=0
        select case(s)
        case('integer'); t=ty_integer
        case('real','double','doubleprecision'); t=ty_real
        case('logical'); t=ty_logical
        case('character'); t=ty_character
        case('type','class'); t=ty_derived_base
        end select
    end function
    logical function reserved(s)
        character(*),intent(in)::s
        ! PROCEDURE is a name in data/dummy/keyword positions. Its actual
        ! MODULE PROCEDURE and type-binding clauses are recognized by their
        ! enclosing grammar, not by reserving the spelling in every name slot.
        ! CHAR is resolved as a declared name before intrinsic dispatch; the
        ! spelling alone must not reject ordinary data or procedure names.
        reserved=.true.
        select case(s)
        case('program','end','implicit','none','integer','real','logical','print','if','then','else','elseif', &
             'endif','enddo','do','exit','cycle','forall','endforall','where','elsewhere','endwhere', &
             'pointer','null','nullify','associated','allocatable','allocate','deallocate','allocated','optional','present','abs','mod','modulo','selected_int_kind','selected_real_kind','int','nint','floor','ceiling','parameter','module','contains','function','result','use','intent','in', &
             'subroutine','call','return','error','stop','pure','simple','recursive','elemental','impure','private','public','only','character', &
             'exp','log','log10','sqrt','erfc','sinh','cosh','tanh','sin','cos','tan','out','inout','size','lbound','ubound','random_number','select','case','trim','achar','len', &
             'type','class','interface','operator','write')
        case default
            reserved=.false.
        end select
    end function
    integer function find_symbol(p,name) result(index)
        type(parser_t),intent(inout)::p
        character(*),intent(in)::name
        integer::i,host,m
        logical::visible
        index=0; host=p%scope
        do i=1,p%prog%ns
            if(p%prog%symbols(i)%name==name.and.p%prog%symbols(i)%scope==p%scope) then
                index=i; return
            end if
        end do
        if(p%scope>0) then
            host=p%prog%procedures(p%scope)%parent_procedure
            if(host>0) then
                do i=1,p%prog%ns
                    if(p%prog%symbols(i)%scope==host.and.p%prog%symbols(i)%name==name) then
                        index=i;return
                    end if
                end do
            end if
            host=-p%prog%procedures(p%scope)%module_id
        end if
        do i=1,p%prog%ns
            if(p%prog%symbols(i)%name/=name) cycle
            if(p%prog%symbols(i)%scope>=0.and..not.p%prog%symbols(i)%is_parameter) cycle
            visible=.false.; m=-p%prog%symbols(i)%scope
            if(host<0) then
                visible=p%prog%symbols(i)%scope==host
                if(m>0.and..not.visible) visible=p%prog%symbols(i)%is_public.and.imported(p,m,name)
            else if(host==0) then
                visible=p%prog%symbols(i)%scope==0
                if(m>0) visible=p%prog%symbols(i)%is_public.and.imported(p,m,name)
            end if
            if(.not.visible) cycle
            if(index/=0) then
                if(p%prog%symbols(index)%is_parameter.and.p%prog%symbols(i)%is_parameter) then
                    call error(p,'Ambiguous USE-associated constant: '//name)
                else
                    call error(p,'Ambiguous USE-associated data: '//name)
                end if
                return
            end if
            index=i
        end do
    end function
    integer function add_expr(p,e) result(index)
        type(parser_t),intent(inout)::p
        type(expr_t),intent(in)::e
        index=0
        if(p%diag%code/=0) return
        if(p%prog%ne==max_expressions) then
            call error(p,'Expression limit exceeded'); return
        end if
        if(e%kind==ex_variable.or.e%kind==ex_element.or.e%kind==ex_section.or.e%kind==ex_substring.or.e%kind==ex_gather_rows) then
            if(e%symbol>0.and.p%scope>0) then
                if(p%prog%symbols(e%symbol)%scope>0.and.p%prog%symbols(e%symbol)%scope/=p%scope) then
                    if(.not.host_symbol_visible(p%prog,e%symbol,p%scope)) then
                        call error(p,'Unsupported internal procedure host capture');return
                    end if
                end if
                if(p%prog%symbols(e%symbol)%scope<0.and..not.p%prog%symbols(e%symbol)%is_parameter.and. &
                   p%prog%procedures(p%scope)%is_simple) then
                    call error(p,'SIMPLE procedure cannot reference mutable module data');return
                end if
            end if
        end if
        p%prog%ne=p%prog%ne+1
        index=p%prog%ne; p%prog%expressions(index)=e
        p%prog%expressions(index)%scope=p%scope
        if(e%typ==ty_character) then
            select case(e%kind)
            case(ex_literal)
                if(allocated(e%value%s)) p%prog%expressions(index)%character_len=len(e%value%s)
            case(ex_variable,ex_element,ex_section)
                p%prog%expressions(index)%character_len=p%prog%symbols(e%symbol)%character_len
            case(ex_user_call)
                p%prog%expressions(index)%character_len=p%prog%symbols( &
                    p%prog%procedures(e%symbol)%result_symbol)%character_len
            end select
        end if
    end function
    subroutine check_module_write(p,s)
        type(parser_t),intent(inout)::p
        integer,intent(in)::s
        if(s<1.or.s>p%prog%ns.or.p%scope<=0) return
        if(p%prog%symbols(s)%is_parameter) return
        if(p%prog%symbols(s)%scope>0.and.p%prog%symbols(s)%scope/=p%scope) then
            if(.not.host_symbol_visible(p%prog,s,p%scope)) then
                call error(p,'Unsupported internal procedure host capture');return
            end if
            if(p%prog%procedures(p%scope)%is_pure.or.(.not.p%prog%procedures(p%scope)%is_subroutine.and. &
               .not.p%prog%procedures(p%scope)%has_impure_prefix)) &
                call error(p,'Host writes inside ordinary functions or PURE procedures are unsupported')
            return
        end if
        if(p%prog%symbols(s)%scope>=0.and..not.p%prog%symbols(s)%is_saved) return
        if(p%prog%symbols(s)%is_saved) then
            if(p%prog%procedures(p%scope)%is_pure.or.(.not.p%prog%procedures(p%scope)%is_subroutine.and. &
               .not.p%prog%procedures(p%scope)%has_impure_prefix)) &
                call error(p,'SAVE state writes inside ordinary functions or PURE procedures are unsupported')
            return
        end if
        if(p%prog%procedures(p%scope)%is_pure) &
            call error(p,'PURE/SIMPLE procedure cannot modify module data')
        if(.not.p%prog%procedures(p%scope)%is_subroutine.and. &
           .not.p%prog%procedures(p%scope)%has_impure_prefix) &
            call error(p,'Mutable module writes inside ordinary functions are unsupported')
    end subroutine
    integer function emit(p,ins) result(index)
        type(parser_t),intent(inout)::p
        type(instruction_t),intent(in)::ins
        index=0
        if(p%diag%code/=0) return
        call check_module_write(p,module_write_target(ins))
        if(p%diag%code/=0) return
        if(p%prog%nc==max_instructions) then
            call error(p,'Instruction limit exceeded'); return
        end if
        p%prog%nc=p%prog%nc+1
        index=p%prog%nc; p%prog%code(index)=ins
        p%prog%code(index)%scope=p%scope
    end function

    subroutine type_specification(p,typ,kind,kind_expr,deferred_character)
        type(parser_t),intent(inout)::p
        integer,intent(inout)::typ
        integer,intent(out)::kind
        integer,intent(out)::kind_expr
        logical,intent(out),optional::deferred_character
        integer::a
        type(value_t)::value
        type(diagnostic_t)::constant_diag
        kind=4;kind_expr=0
        if(present(deferred_character)) deferred_character=.false.
        if(peek(p)=='double'.or.peek(p)=='doubleprecision') then
            if(take(p,'double')) then
                call expect(p,'precision')
            else
                p%p=p%p+1
            end if
            kind=8
            if(peek(p)=='('.or.peek(p)=='*') &
                call error(p,'DOUBLE PRECISION does not accept a kind selector')
            return
        end if
        p%p=p%p+1
        if(present(deferred_character)) deferred_character=.false.
        if(typ==ty_derived_base) then
            call expect(p,'('); a=find_derived(p,peek(p))
            if(a==0) then
                call error(p,'Unknown or inaccessible derived type: '//peek(p)); return
            end if
            typ=ty_derived_base+a; p%p=p%p+1; call expect(p,')'); return
        end if
        if(.not.take(p,'(')) then
            if(typ==ty_character) kind=1
            return
        end if
        if(typ==ty_character) then
            kind=-1
            if(peek(p)=='len'.and.p%tokens(p%p+1)%text=='=') p%p=p%p+2
            if(take(p,':')) then
                if(.not.present(deferred_character)) then
                    call error(p,'Deferred CHARACTER length requires an ALLOCATABLE declaration');return
                end if
                deferred_character=.true.
            else if(.not.take(p,'*')) then
                a=expression(p,0)
                if(p%diag%code/=0) return
                if(p%prog%expressions(a)%rank/=0.or.p%prog%expressions(a)%typ/=ty_integer) then
                    call error(p,'CHARACTER LEN requires scalar INTEGER');return
                end if
                kind_expr=a
                call require_constant(p,a,'CHARACTER LEN requires a constant or supported specification expression')
                if(p%diag%code/=0) then
                    constant_diag=p%diag;p%diag=diagnostic_t()
                    if(.not.valid_automatic_bound(p%prog,a,p%scope)) then
                        p%diag=constant_diag;return
                    end if
                else
                    call evaluate_constant(p%prog,a,value,p%diag)
                    if(p%diag%code/=0) return
                    if(value%i>65536_int64) then
                        call error(p,'CHARACTER length limit: outside supported range (0:65536)');return
                    end if
                    kind=int(max(0_int64,value%i))
                end if
            end if
            call expect(p,')'); return
        end if
        if(typ/=ty_real.and.typ/=ty_integer) then
            call error(p,'Kind selectors are currently supported only for REAL'); return
        end if
        if(peek(p)=='kind'.and.p%tokens(p%p+1)%text=='=') then
            p%p=p%p+2
        end if
        a=expression(p,0)
        if(p%diag%code/=0) return
        if(p%prog%expressions(a)%typ/=ty_integer.or.p%prog%expressions(a)%rank/=0) then
            call error(p,'REAL kind must be a scalar INTEGER constant expression');return
        end if
        if(p%prog%expressions(a)%kind/=ex_literal.and.p%prog%expressions(a)%kind/=ex_variable) then
            if(p%prog%expressions(a)%kind/=ex_call.or.(p%prog%expressions(a)%op/='kind'.and.p%prog%expressions(a)%op/='selected_int_kind'.and. &
                p%prog%expressions(a)%op/='selected_real_kind')) then
                call error(p,'REAL kind selector supports an integer literal, named parameter or supported kind inquiry');return
            end if
        end if
        call require_constant(p,a,'REAL kind must be a scalar INTEGER constant expression')
        if(p%diag%code/=0) return
        call evaluate_constant(p%prog,a,value,p%diag)
        if(p%diag%code/=0) return
        kind=int(value%i);kind_expr=a
        call expect(p,')')
        if(kind/=4.and.kind/=8) call error(p,'Only REAL kinds 4 and 8 are supported')
    end subroutine
    subroutine declaration(p,typ)
        type(parser_t),intent(inout)::p
        integer,intent(in)::typ
        integer::s,e,j,line,col,start_expr,rkind,m,n,dummy_intent,kind_expr,dtype,charlen,entity_charlen,dim_start,dim_end,nesting,saved_pos
        integer(int64)::initializer_dims(3)
        logical::has_attributes,has_double_colon,target_attribute,pointer_attribute,save_attribute,saved_initializer
        logical::parameter_attribute,has_initializer,dummy_attribute,public_attribute,private_attribute,is_class,optional_attribute,declarator_shape,allocatable_attribute,deferred_character
        character(:),allocatable::name
        type(instruction_t)::ins
        type(value_t)::constant
        type(value_t),allocatable::constants(:)
        dtype=typ;is_class=peek(p)=='class'
        call type_specification(p,dtype,rkind,kind_expr,deferred_character)
        charlen=-1
        if(typ==ty_character) then
            charlen=rkind;rkind=4
        end if
        dummy_intent=0; optional_attribute=.false.;allocatable_attribute=.false.;dim_start=0;dim_end=0
        parameter_attribute=.false.; dummy_attribute=.false.; public_attribute=.false.; private_attribute=.false.
        has_attributes=.false.;target_attribute=.false.;pointer_attribute=.false.;save_attribute=.false.
        do while(take(p,','))
            has_attributes=.true.
            if(take(p,'parameter')) then
                parameter_attribute=.true.
            else if(take(p,'save')) then
                if(save_attribute) call error(p,'Repeated SAVE attribute')
                save_attribute=.true.
            else if(take(p,'pointer')) then
                if(pointer_attribute) call error(p,'Repeated POINTER attribute')
                pointer_attribute=.true.
            else if(take(p,'target')) then
                if(target_attribute) call error(p,'Repeated TARGET attribute')
                target_attribute=.true.
            else if(take(p,'allocatable')) then
                if(allocatable_attribute) call error(p,'Repeated ALLOCATABLE attribute')
                allocatable_attribute=.true.
            else if(take(p,'dimension')) then
                if(dim_start/=0) then
                    call error(p,'Repeated DIMENSION attribute');return
                end if
                call expect(p,'(');dim_start=p%p;nesting=1
                do while(p%diag%code==0.and.nesting>0)
                    if(p%tokens(p%p)%kind==tk_eol.or.p%tokens(p%p)%kind==tk_eof) then
                        call error(p,'Unterminated DIMENSION attribute');return
                    end if
                    if(peek(p)=='(') nesting=nesting+1
                    if(peek(p)==')') nesting=nesting-1
                    p%p=p%p+1
                end do
                dim_end=p%p
            else if(take(p,'optional')) then
                if(optional_attribute) call error(p,'Repeated OPTIONAL attribute')
                optional_attribute=.true.
            else if(take(p,'intent')) then
                if(dummy_attribute) then
                    call error(p,'Repeated or conflicting INTENT attributes are unsupported'); return
                end if
                if(p%scope<=0) call error(p,'INTENT is only supported on procedure dummy arguments')
                call expect(p,'(')
                if(take(p,'in')) then
                    dummy_intent=1
                    ! IN OUT is the permitted two-word spelling of INOUT.
                    ! Only consume the complete second keyword, not arbitrary
                    ! fragments or separators within an intent specification.
                    if(take(p,'out')) dummy_intent=3
                else if(take(p,'out')) then
                    dummy_intent=2
                else if(take(p,'inout')) then
                    dummy_intent=3
                else
                    call error(p,'Expected IN, OUT or INOUT intent')
                end if
                call expect(p,')'); dummy_attribute=.true.
                if(p%scope>0) then
                    if(.not.p%prog%procedures(p%scope)%is_subroutine.and.dummy_intent/=1) &
                        call error(p,'Function dummy arguments must have INTENT(IN)')
                end if
            else if(take(p,'public')) then
                if(p%scope>=0) call error(p,'PUBLIC declaration requires module scope')
                public_attribute=.true.
            else if(take(p,'private')) then
                if(p%scope>=0) call error(p,'PRIVATE declaration requires module scope')
                private_attribute=.true.
            else
                call error(p,'Unsupported declaration attribute')
            end if
        end do
        if(save_attribute) then
            if(p%scope<0.or.parameter_attribute.or.dummy_attribute.or.optional_attribute.or. &
               pointer_attribute.or.allocatable_attribute.or.target_attribute.or.is_class) &
                call error(p,'SAVE supports initialized intrinsic scalar procedure locals only')
        end if
        ! Main-program objects already retain storage for this execution. SAVE
        ! is accepted there without using the separate procedure-local store.
        if(save_attribute.and.p%scope==0.and.(dtype<ty_integer.or.dtype>ty_character)) &
            call error(p,'Main-program SAVE supports initialized intrinsic objects only')
        if(pointer_attribute) then
            if(p%scope<0.or.parameter_attribute.or.allocatable_attribute.or.target_attribute.or.is_class.or. &
               (dtype/=ty_integer.and.dtype/=ty_real)) call error(p,'Unsupported POINTER declaration')
            if(p%scope>0) then
                if(.not.p%prog%procedures(p%scope)%is_subroutine.or.p%prog%procedures(p%scope)%is_elemental) &
                    call error(p,'POINTER declarations require a non-elemental subroutine or main program')
            end if
        end if
        if(target_attribute) then
            if(parameter_attribute) call error(p,'TARGET cannot be PARAMETER')
            if(dtype<ty_integer.or.dtype>ty_character.or.is_class) &
                call error(p,'TARGET supports intrinsic scalar and array objects only')
        end if
        if(deferred_character.and..not.allocatable_attribute) &
            call error(p,'Deferred CHARACTER length requires ALLOCATABLE')
        if(allocatable_attribute) then
            if(dtype/=ty_integer.and.dtype/=ty_real.and.dtype/=ty_logical.and.dtype/=ty_character) &
                call error(p,'ALLOCATABLE supports INTEGER, REAL, LOGICAL and CHARACTER arrays only')
            if(parameter_attribute) call error(p,'ALLOCATABLE cannot be PARAMETER')
        end if
        if(optional_attribute.and.(p%scope<=0.or..not.dummy_attribute)) &
            call error(p,'OPTIONAL requires a procedure dummy with explicit INTENT')
        if(public_attribute.and.private_attribute) call error(p,'Conflicting accessibility attributes')
        if(dummy_attribute.and.parameter_attribute) call error(p,'A dummy argument cannot be PARAMETER')
        if(p%scope<0.and.is_derived_type(dtype).and..not.parameter_attribute) &
            call error(p,'Mutable module data supports intrinsic types only')
        if(typ==ty_character.and.charlen<0.and.kind_expr==0.and..not.dummy_attribute.and..not.parameter_attribute.and..not.deferred_character) &
            call error(p,'Assumed-length CHARACTER requires a dummy argument or PARAMETER')
        if(typ==ty_character.and.charlen<0.and.kind_expr>0) then
            if(parameter_attribute.or.(dummy_attribute.and. &
               (.not.allocatable_attribute.or.optional_attribute))) &
                call error(p,'Runtime CHARACTER length is supported only for local variables and results or mandatory ALLOCATABLE arrays')
        end if
        if(is_class.and.(p%scope<=0.or..not.dummy_attribute)) &
            call error(p,'CLASS is supported only for scalar dummy arguments')
        if(is_class.and.p%scope>0.and.dummy_intent==2) then
            if(p%prog%procedures(p%scope)%is_pure) &
                call error(p,'PURE procedures cannot have polymorphic INTENT(OUT) dummies')
        end if
        has_double_colon=take(p,'::')
        if(has_attributes.and..not.has_double_colon) then
            call error(p,'Declaration attributes require ::');return
        end if
        do while(p%diag%code==0)
            if(p%tokens(p%p)%kind/=tk_name) then
                call error(p,'Expected declaration name'); return
            end if
            name=peek(p); line=p%tokens(p%p)%line; col=p%tokens(p%p)%column
            entity_charlen=charlen
            if(p%scope<0.and.imported_name(p,name)) then
                call error(p,'Module declaration conflicts with USE-associated name');return
            end if
            if(name==trim(p%prog%name)) then
                call error(p,'A variable cannot have the PROGRAM name'); return
            end if
            if(reserved(name)) then
                call error(p,'Keyword/intrinsic names are reserved in this prototype'); return
            end if
            s=find_symbol(p,name)
            if(s/=0) then
                if(p%prog%symbols(s)%scope==p%scope.or.p%scope<=0) then
                    call error(p,'Duplicate declaration: '//name); return
                end if
            end if
            if(p%prog%ns==max_symbols) then
                call error(p,'Symbol limit exceeded'); return
            end if
            p%prog%ns=p%prog%ns+1; s=p%prog%ns
            p%prog%symbols(s)=symbol_t(name=name,typ=dtype,line=line,column=col,real_kind=rkind)
            p%prog%symbols(s)%kind_expr=kind_expr
            p%prog%symbols(s)%is_class=is_class
            if(typ==ty_character) then
                p%prog%symbols(s)%deferred_character=deferred_character
                p%prog%symbols(s)%character_len=charlen
                p%prog%symbols(s)%length_expr=kind_expr
                p%prog%symbols(s)%kind_expr=0
            end if
            p%prog%symbols(s)%is_parameter=parameter_attribute
            p%prog%symbols(s)%scope=p%scope; p%prog%symbols(s)%is_dummy=dummy_attribute
            p%prog%symbols(s)%dummy_intent=dummy_intent
            p%prog%symbols(s)%is_optional=optional_attribute
            p%prog%symbols(s)%is_allocatable=allocatable_attribute
            p%prog%symbols(s)%is_target=target_attribute
            p%prog%symbols(s)%is_pointer=pointer_attribute
            if(p%scope<0) then
                m=-p%scope; p%prog%symbols(s)%is_public=.not.p%prog%module_private(m)
                if(public_attribute) then
                    n=p%n_public(m)+1; p%n_public(m)=n
                    if(n>max_access_names) then
                        call error(p,'Accessibility name limit exceeded'); return
                    end if
                    p%public_names(n,m)=name
                else if(private_attribute) then
                    n=p%n_private(m)+1; p%n_private(m)=n
                    if(n>max_access_names) then
                        call error(p,'Accessibility name limit exceeded'); return
                    end if
                    p%private_names(n,m)=name
                end if
            end if
            p%p=p%p+1
            saved_pos=0
            if(peek(p)=='('.and.dim_start/=0) then
                call error(p,'Combined DIMENSION attribute and declarator shape are unsupported');return
            end if
            if(peek(p)/='('.and.dim_start/=0) then
                saved_pos=p%p;p%p=dim_start
            end if
            declarator_shape=saved_pos/=0
            if(.not.declarator_shape) declarator_shape=take(p,'(')
            if(declarator_shape) then
                if(allocatable_attribute.or.pointer_attribute) then
                    call deferred_shape(p,s)
                else if(dummy_attribute) then
                    call dummy_shape(p,s)
                else
                    if(p%diag%code==0) call array_shape(p,s)
                end if
                if(saved_pos/=0) then
                    if(p%diag%code==0.and.p%p/=dim_end) call error(p,'Invalid DIMENSION attribute')
                    p%p=saved_pos
                end if
            end if
            if(p%diag%code/=0) return
            if(is_derived_type(dtype).and.(p%prog%symbols(s)%rank/=0.or.parameter_attribute)) then
                call error(p,'Derived type arrays and PARAMETER values are unsupported'); return
            end if
            if(optional_attribute.and.(dtype<ty_integer.or.dtype>ty_character)) then
                call error(p,'OPTIONAL supports INTEGER, REAL, LOGICAL and CHARACTER dummies only');return
            end if
            if(pointer_attribute.and.p%prog%symbols(s)%rank/=1) then
                call error(p,'POINTER requires deferred-shape rank-one array');return
            end if
            if(pointer_attribute.and.(peek(p)=='='.or.peek(p)=='=>')) then
                call error(p,'POINTER declaration initialization is unsupported');return
            end if
            if(allocatable_attribute.and.p%prog%symbols(s)%rank==0.and.dtype/=ty_character) then
                call error(p,'ALLOCATABLE requires deferred-shape rank-one/two/three array or scalar CHARACTER');return
            end if
            if(peek(p)=='='.and..not.has_double_colon) then
                call error(p,'Declaration initialization requires ::');return
            end if
            has_initializer=take(p,'=')
            if(has_initializer) then
                if(allocatable_attribute) then
                    call error(p,'ALLOCATABLE declaration initialization is unsupported');return
                end if
                if(dummy_attribute) then
                    call error(p,'Dummy argument initializers are unsupported'); return
                end if
                saved_initializer=p%scope>0.and..not.parameter_attribute
                if(saved_initializer) then
                    if(p%prog%procedures(p%scope)%is_pure) then
                        call error(p,'PURE/SIMPLE procedures cannot declare SAVE or initialized mutable locals');return
                    end if
                    if(p%prog%symbols(s)%rank/=0.or.dtype<ty_integer.or.dtype>ty_character.or. &
                       target_attribute.or.pointer_attribute.or.is_class.or. &
                       (dtype==ty_character.and.charlen<0)) then
                        call error(p,'SAVE supports initialized intrinsic scalar procedure locals only');return
                    end if
                end if
                start_expr=p%prog%ne+1; e=expression(p,0)
                if(p%diag%code/=0) return
                call require_constant(p,e,'Declaration initializers must be constant expressions')
                if(p%diag%code/=0) return
                call assignment_types(p,dtype,p%prog%expressions(e)%typ)
                if(p%diag%code/=0) return
                if(p%prog%expressions(e)%rank>0) then
                    if(p%prog%expressions(e)%rank/=p%prog%symbols(s)%rank) then
                        call error(p,'Array initializer ranks do not conform');return
                    end if
                    if(p%prog%expressions(e)%extent>=0.and. &
                       p%prog%expressions(e)%extent/=shape_size(symbol_dims(p%prog%symbols(s)))) then
                        call error(p,'Array initializer shapes do not conform');return
                    end if
                    if(p%prog%expressions(e)%rank>=2) then
                        initializer_dims=p%prog%expressions(e)%dims
                        if(any(initializer_dims<0)) then
                            call evaluate_constant_shape(p%prog,e,initializer_dims,p%diag)
                            if(p%diag%code/=0) then
                                p%diag%code=1
                                p%diag%message='Invalid declaration initializer shape: '//p%diag%message
                                return
                            end if
                        end if
                        if(any(initializer_dims/=symbol_dims(p%prog%symbols(s)))) then
                            call error(p,'Array initializer shapes do not conform');return
                        end if
                    end if
                end if
                p%prog%symbols(s)%initializer_expr=e
                if(typ==ty_character.and.charlen<0.and.kind_expr==0.and.parameter_attribute) then
                    ! LEN=* on a named constant is inferred separately for each
                    ! entity, including scalar expansion to zero-sized arrays.
                    if(p%prog%expressions(e)%rank==0) then
                        call evaluate_constant(p%prog,e,constant,p%diag,dtype,rkind)
                        if(p%diag%code/=0) then
                            p%diag%code=1;p%diag%message='Invalid PARAMETER initializer: '//p%diag%message;return
                        end if
                        entity_charlen=len(constant%s)
                    else
                        ! Array expression lengths are uniform and known even
                        ! when the expression contains no elements.
                        entity_charlen=p%prog%expressions(e)%character_len
                    end if
                    if(entity_charlen<0.or.entity_charlen>65536) then
                        call error(p,'Inferred CHARACTER length outside supported range (0:65536)');return
                    end if
                    p%prog%symbols(s)%character_len=entity_charlen
                end if
                if(parameter_attribute.or.p%scope<0.or.saved_initializer) then
                    if(p%prog%symbols(s)%rank>0) then
                        if(p%prog%expressions(e)%rank>0) then
                            call evaluate_constant_array(p%prog,e,constants,p%diag,dtype,rkind)
                        else
                            call evaluate_constant(p%prog,e,constant,p%diag,dtype,rkind)
                            allocate(constants(int(shape_size(symbol_dims(p%prog%symbols(s))))),source=constant)
                        end if
                        if(p%diag%code==0) then
                            if(size(constants,kind=int64)/=shape_size(symbol_dims(p%prog%symbols(s)))) then
                                call error(p,'Array PARAMETER initializer shapes do not conform');return
                            end if
                            if(typ==ty_character) then
                                do j=1,size(constants)
                                    constants(j)%s=constants(j)%s(:min(len(constants(j)%s),entity_charlen))// &
                                        repeat(' ',max(0,entity_charlen-len(constants(j)%s)))
                                end do
                            end if
                            p%prog%symbols(s)%constant_values=constants
                        end if
                        if(allocated(constants)) deallocate(constants)
                    else
                        call evaluate_constant(p%prog,e,constant,p%diag,dtype,rkind)
                        if(typ==ty_character.and.p%diag%code==0) &
                            constant%s=constant%s(:min(len(constant%s),entity_charlen))//repeat(' ',max(0,entity_charlen-len(constant%s)))
                    end if
                    if(p%diag%code/=0) then
                        p%diag%code=1; p%diag%message='Invalid PARAMETER initializer: '//p%diag%message; return
                    end if
                    p%prog%symbols(s)%constant_value=constant; p%prog%symbols(s)%parameter_ready=.true.
                    p%prog%symbols(s)%is_saved=saved_initializer
                else
                    ins=instruction_t(); ins%op=op_assign; ins%symbol=s; ins%a=e
                    ins%line=line; ins%column=col; j=emit(p,ins)
                end if
            else if(save_attribute) then
                call error(p,'SAVE requires a constant initializer in this subset');return
            else if(parameter_attribute) then
                call error(p,'PARAMETER requires a constant initializer'); return
            end if
            if(.not.take(p,',')) exit
        end do
        call finish_line(p)
    end subroutine
    subroutine dummy_shape(p,symbol)
        type(parser_t),intent(inout)::p
        integer,intent(in)::symbol
        type(value_t)::lo
        integer::first,dim,j,depth
        logical::explicit_shape
        ! An assumed-shape dimension ends in a top-level colon. Inspect tokens
        ! without consuming expressions, then use the existing explicit parser.
        explicit_shape=.true.;depth=0
        do j=p%p,p%n
            if(p%tokens(j)%text=='(') depth=depth+1
            if(p%tokens(j)%text==')') then
                if(depth==0) exit
                depth=depth-1
            end if
            if(depth/=0) cycle
            if(p%tokens(j)%text==':'.and.j<p%n) then
                if(p%tokens(j+1)%text==')'.or.p%tokens(j+1)%text==',') explicit_shape=.false.
            end if
            if(p%tokens(j)%text==',') exit
        end do
        if(explicit_shape) then
            if(p%prog%symbols(symbol)%is_optional) then
                call error(p,'OPTIONAL explicit-shape dummies are unsupported');return
            end if
            call array_shape(p,symbol)
            return
        end if
        do dim=1,3
            first=0; lo%i=1_int64
            if(peek(p)/=':') first=constant_bound(p,lo)
            call expect(p,':')
            if(peek(p)/=')'.and.peek(p)/=',') then
                call error(p,'Only rank-one/two/three assumed-shape dummy arrays are supported'); return
            end if
            if(p%diag%code/=0) return
            p%prog%symbols(symbol)%rank=dim
            if(dim==1) then
                p%prog%symbols(symbol)%lower_bound=lo%i
                p%prog%symbols(symbol)%upper_bound=lo%i-1_int64
                p%prog%symbols(symbol)%lower_expr=first
            else if(dim==2) then
                p%prog%symbols(symbol)%lower_bound2=lo%i
                p%prog%symbols(symbol)%upper_bound2=lo%i-1_int64
                p%prog%symbols(symbol)%lower_expr2=first
            else
                p%prog%symbols(symbol)%lower_bound3=lo%i
                p%prog%symbols(symbol)%upper_bound3=lo%i-1_int64
                p%prog%symbols(symbol)%lower_expr3=first
            end if
            if(.not.take(p,',')) exit
            if(dim==3) then
                call error(p,'Only rank-one, rank-two and rank-three arrays are supported'); return
            end if
        end do
        call expect(p,')')
        p%prog%symbols(symbol)%assumed_shape=.true.
    end subroutine
    subroutine deferred_shape(p,symbol)
        type(parser_t),intent(inout)::p
        integer,intent(in)::symbol
        integer::d
        do d=1,3
            call expect(p,':')
            if(p%diag%code/=0) return
            p%prog%symbols(symbol)%rank=d
            if(.not.take(p,',')) exit
            if(d==3) then
                call error(p,'Only rank-one, rank-two and rank-three ALLOCATABLE arrays are supported');return
            end if
        end do
        call expect(p,')')
        p%prog%symbols(symbol)%lower_bound=1_int64;p%prog%symbols(symbol)%upper_bound=0_int64
        if(p%prog%symbols(symbol)%rank>=2) then
            p%prog%symbols(symbol)%lower_bound2=1_int64;p%prog%symbols(symbol)%upper_bound2=0_int64
        end if
        if(p%prog%symbols(symbol)%rank==3) then
            p%prog%symbols(symbol)%lower_bound3=1_int64;p%prog%symbols(symbol)%upper_bound3=0_int64
        end if
    end subroutine
    subroutine array_shape(p,symbol)
        type(parser_t),intent(inout)::p
        integer,intent(in)::symbol
        integer::first,last,j,dim
        logical::automatic
        integer(int64)::total,n,extents(3)
        character(32)::limit_text
        type(value_t)::lo,hi
        do dim=1,3
            first=declaration_bound(p,symbol,hi,automatic)
            if(automatic) p%prog%symbols(symbol)%is_automatic=.true.
            if(p%diag%code/=0) return
            lo%tag=ty_integer; lo%i=1_int64; last=first; first=0
            if(take(p,':')) then
                first=last; lo=hi
                last=declaration_bound(p,symbol,hi,automatic)
                if(automatic) p%prog%symbols(symbol)%is_automatic=.true.
            end if
            if(p%diag%code/=0) return
            ! Check each bound before subtraction, including INTEGER(kind=8)
            ! constants that would otherwise overflow upper-lower+1 in int64.
            if(lo%i< -2147483648_int64.or.lo%i>2147483647_int64.or. &
               hi%i< -2147483648_int64.or.hi%i>2147483647_int64) then
                call error(p,'Array bound exceeds supported INTEGER range'); return
            end if
            p%prog%symbols(symbol)%rank=dim
            if(dim==1) then
                p%prog%symbols(symbol)%lower_bound=lo%i
                p%prog%symbols(symbol)%upper_bound=hi%i
                p%prog%symbols(symbol)%lower_expr=first
                p%prog%symbols(symbol)%upper_expr=last
            else if(dim==2) then
                p%prog%symbols(symbol)%lower_bound2=lo%i
                p%prog%symbols(symbol)%upper_bound2=hi%i
                p%prog%symbols(symbol)%lower_expr2=first
                p%prog%symbols(symbol)%upper_expr2=last
            else
                p%prog%symbols(symbol)%lower_bound3=lo%i
                p%prog%symbols(symbol)%upper_bound3=hi%i
                p%prog%symbols(symbol)%lower_expr3=first
                p%prog%symbols(symbol)%upper_expr3=last
            end if
            if(.not.take(p,',')) exit
            if(dim==3) then
                call error(p,'Only rank-one, rank-two and rank-three arrays are supported'); return
            end if
        end do
        call expect(p,')')
        if(p%diag%code/=0) return
        total=0_int64
        do j=1,p%prog%ns
            if(p%prog%symbols(j)%rank==0.or.p%prog%symbols(j)%assumed_shape.or.p%prog%symbols(j)%is_automatic.or.p%prog%symbols(j)%is_allocatable.or.p%prog%symbols(j)%is_pointer) cycle
            extents=symbol_dims(p%prog%symbols(j))
            ! Bound subtraction is int64; reject huge extents before product.
            if(any(extents>2147483647_int64)) then
                call error(p,'Array dimension extent exceeds supported INTEGER range'); return
            end if
            n=shape_size(extents)
            total=total+n
            if(total>max_array_elements) then
                write(limit_text,'(i0)') max_array_elements
                call error(p,'Total array element limit exceeded ('//trim(limit_text)//')'); return
            end if
        end do
    end subroutine
    pure function symbol_dims(symbol) result(dims)
        type(symbol_t),intent(in)::symbol
        integer(int64)::dims(3)
        dims=[max(0_int64,symbol%upper_bound-symbol%lower_bound+1_int64),1_int64,1_int64]
        if(symbol%rank>=2) dims(2)=max(0_int64,symbol%upper_bound2-symbol%lower_bound2+1_int64)
        if(symbol%rank==3) dims(3)=max(0_int64,symbol%upper_bound3-symbol%lower_bound3+1_int64)
    end function
    integer function declaration_bound(p,symbol,value,automatic) result(root)
        type(parser_t),intent(inout)::p
        integer,intent(in)::symbol
        type(value_t),intent(out)::value
        logical,intent(out)::automatic
        type(diagnostic_t)::constant_diag
        automatic=.false.;value=value_t(tag=ty_integer,i=0_int64)
        root=expression(p,0)
        if(p%diag%code/=0) return
        if(p%prog%expressions(root)%typ/=ty_integer.or.p%prog%expressions(root)%rank/=0) then
            call error(p,'Array bounds must be scalar INTEGER expressions');return
        end if
        call require_constant(p,root,'Array bounds must be constant expressions outside procedure locals')
        if(p%diag%code/=0) then
            constant_diag=p%diag;p%diag=diagnostic_t()
            if(p%scope<=0.or.p%prog%symbols(symbol)%is_parameter) then
                p%diag=constant_diag;return
            end if
            if(p%prog%symbols(symbol)%is_dummy) then
                if(.not.valid_dummy_bound(p%prog,root,p%scope)) then
                    call error(p,'Unsupported explicit-shape dummy bound: require scalar INTEGER input dummies or parameters')
                    return
                end if
            else if(.not.valid_automatic_bound(p%prog,root,p%scope)) then
                call error(p,'Unsupported automatic array bound: require input dummies, parameters, inquiries, COUNT masks or bounded PURE specification calls')
                return
            end if
            automatic=.true.;return
        end if
        call evaluate_constant(p%prog,root,value,p%diag)
        if(p%diag%code/=0) then
            p%diag%code=1;p%diag%message='Invalid constant array bound: '//p%diag%message
        end if
    end function
    integer function constant_bound(p,value) result(root)
        type(parser_t),intent(inout)::p
        type(value_t),intent(out)::value
        integer::first
        first=p%prog%ne+1
        root=expression(p,0)
        if(p%diag%code/=0) return
        if(p%prog%expressions(root)%typ/=ty_integer.or.p%prog%expressions(root)%rank/=0) then
            call error(p,'Array bounds must be INTEGER constant expressions'); return
        end if
        call require_constant(p,root,'Array bounds must be constant expressions; variable bounds are unsupported')
        if(p%diag%code/=0) return
        call evaluate_constant(p%prog,root,value,p%diag)
        if(p%diag%code/=0) then
            p%diag%code=1
            p%diag%message='Invalid constant array bound: '//p%diag%message
        end if
    end function
    recursive subroutine require_constant(p,root,message)
        type(parser_t),intent(inout)::p
        integer,intent(in)::root
        character(*),intent(in)::message
        integer::j,s
        if(p%diag%code/=0) return
        associate(e=>p%prog%expressions(root))
        select case(e%kind)
        case(ex_variable)
            s=e%symbol
            if(.not.p%prog%symbols(s)%is_parameter.or..not.p%prog%symbols(s)%parameter_ready) &
                call error(p,message)
        case(ex_element,ex_section,ex_substring)
            s=e%symbol
            if(.not.(e%kind==ex_substring.and.s==0)) then
                if(.not.p%prog%symbols(s)%is_parameter.or..not.p%prog%symbols(s)%parameter_ready) then
                    call error(p,message);return
                end if
            end if
            if(e%left/=0) call require_constant(p,e%left,message)
            if(e%right/=0) call require_constant(p,e%right,message)
            if(e%stride/=0) call require_constant(p,e%stride,message)
            if(e%left2/=0) call require_constant(p,e%left2,message)
            if(e%right2/=0) call require_constant(p,e%right2,message)
            if(e%stride2/=0) call require_constant(p,e%stride2,message)
            if(e%left3/=0) call require_constant(p,e%left3,message)
            if(e%right3/=0) call require_constant(p,e%right3,message)
            if(e%stride3/=0) call require_constant(p,e%stride3,message)
            if(e%third/=0) call require_constant(p,e%third,message)
        case(ex_user_call,ex_component,ex_record,ex_gather_rows)
            call error(p,message)
        case(ex_unary,ex_binary)
            call require_constant(p,e%left,message)
            if(e%kind==ex_binary) call require_constant(p,e%right,message)
        case(ex_constructor_do)
            call require_constant(p,e%left,message)
            call require_constant(p,e%right,message)
            if(e%stride/=0) call require_constant(p,e%stride,message)
            do j=1,size(e%args)
                call require_constant(p,e%args(j),message)
            end do
        case(ex_constructor_index)
            if(.not.valid_constructor_index(p%prog,root)) call error(p,message)
        case(ex_call,ex_constructor)
            ! KIND is a type inquiry, including for undefined data or unevaluated
            ! expressions. Its argument need not itself be a constant expression.
            if(e%kind==ex_call.and.(e%op=='minexponent'.or.e%op=='maxexponent')) then
                if(.not.bound_constant_expression(p%prog,root,0)) call error(p,message)
                return
            end if
            if(e%kind==ex_call.and.(e%op=='kind'.or.e%op=='new_line'.or.is_numeric_model_inquiry(e%op))) return
            if(e%kind==ex_call.and.is_bounds_inquiry(e%op))then
                if(bound_constant_expression(p%prog,root,0))return
            end if
            if(e%kind==ex_call.and.e%op=='shape') then
                if(size(e%args)>=1.and.size(e%args)<=2) then
                    associate(source=>p%prog%expressions(e%args(1)))
                    if(source%kind==ex_variable) then
                        s=source%symbol
                        if(.not.p%prog%symbols(s)%is_allocatable.and..not.p%prog%symbols(s)%assumed_shape.and. &
                           .not.p%prog%symbols(s)%is_automatic.and..not.p%prog%symbols(s)%is_dummy) then
                            if(size(e%args)==2) call require_constant(p,e%args(2),message)
                            return
                        end if
                    end if
                    end associate
                end if
            end if
            if(e%kind==ex_call.and.e%op=='len') then
                if(p%prog%expressions(e%args(1))%character_len>=0) return
            end if
            do j=1,size(e%args)
                call require_constant(p,e%args(j),message)
            end do
        end select
        end associate
    end subroutine
    ! Scalars reduce rank; triplets preserve one dimension. Section descriptors
    ! are dynamic and evaluated once before assignment or argument association.
    recursive integer function element_substring(p,base) result(root)
        type(parser_t),intent(inout)::p
        integer,intent(in)::base
        type(expr_t)::e
        root=0
        if(p%prog%expressions(base)%kind/=ex_element.or.p%prog%expressions(base)%typ/=ty_character) then
            call error(p,'Substring suffix requires a scalar CHARACTER array element');return
        end if
        e%kind=ex_substring;e%typ=ty_character;e%symbol=p%prog%expressions(base)%symbol;e%third=base
        e%line=p%tokens(p%p)%line;e%column=p%tokens(p%p)%column
        if(peek(p)/=':') e%left=section_integer(p)
        if(p%diag%code/=0) return
        call expect(p,':')
        if(p%diag%code/=0) return
        if(peek(p)/=')') e%right=section_integer(p)
        if(p%diag%code/=0) return
        call expect(p,')')
        if(p%diag%code==0) root=add_expr(p,e)
    end function
    recursive integer function array_subscript(p,symbol,second,third) result(root)
        type(parser_t),intent(inout)::p
        integer,intent(in)::symbol
        integer,intent(out),optional::second,third
        type(expr_t)::e
        integer::d,operands(3,3),first,rank,vector_dim
        logical::double_colon,is_triplet(3)
        root=0; operands=0; is_triplet=.false.;vector_dim=0
        if(present(second)) second=0
        if(present(third)) third=0
        rank=p%prog%symbols(symbol)%rank
        if(rank==0.and.p%prog%symbols(symbol)%typ==ty_character) then
            e%kind=ex_substring;e%typ=ty_character;e%symbol=symbol
            e%line=p%tokens(p%p)%line;e%column=p%tokens(p%p)%column
            if(peek(p)/=':') e%left=section_integer(p)
            if(p%diag%code/=0) return
            call expect(p,':')
            if(p%diag%code/=0) return
            if(peek(p)/=')') e%right=section_integer(p)
            if(p%diag%code/=0) return
            call expect(p,')')
            if(p%diag%code/=0) return
            root=add_expr(p,e);return
        end if
        if(rank<1.or.rank>3) then
            call error(p,'Cannot subscript a scalar variable'); return
        end if
        e%line=p%tokens(p%p)%line; e%column=p%tokens(p%p)%column
        do d=1,rank
            first=0
            if(peek(p)/=':'.and.peek(p)/='::') then
                first=expression(p,0)
                if(p%diag%code/=0) return
                if(p%prog%expressions(first)%typ/=ty_integer) then
                    call error(p,'Array subscript and triplet operands must be scalar INTEGER');return
                end if
                if(p%prog%expressions(first)%rank/=0) then
                    if(vector_dim/=0.or.(rank/=3.and.rank/=1.and.(d/=1.or.rank/=2)).or. &
                       p%prog%expressions(first)%rank/=1) then
                        if(rank==3) then
                            call error(p,'Rank-three vector subscripts support exactly one rank-one INTEGER vector')
                        else
                            call error(p,'Vector subscripts support only rank-one INTEGER row indices of a matrix')
                        end if
                        return
                    end if
                    vector_dim=d
                end if
            end if
            if(p%diag%code/=0) return
            operands(1,d)=first
            double_colon=take(p,'::')
            if(double_colon.or.peek(p)==':') then
                is_triplet(d)=.true.
                if(.not.double_colon) call expect(p,':')
                if(double_colon) then
                    operands(3,d)=section_integer(p)
                else
                    if(peek(p)/=')'.and.peek(p)/=':'.and.peek(p)/=',') operands(2,d)=section_integer(p)
                    if(take(p,':')) operands(3,d)=section_integer(p)
                end if
            end if
            if(p%diag%code/=0) return
            if(d<rank) call expect(p,',')
            if(p%diag%code/=0) return
        end do
        if(peek(p)==',') then
            call error(p,'Array subscript count must match its rank'); return
        end if
        call expect(p,')')
        if(p%diag%code/=0) return
        if(vector_dim/=0) then
            do d=1,rank
                if(d==vector_dim) then
                    if(.not.is_triplet(d).and.all(operands(2:,d)==0))cycle
                else
                    if(is_triplet(d).and.all(operands(:,d)==0))cycle
                end if
                if(rank==2) then
                    call error(p,'Row gathering requires a numeric non-POINTER matrix and full column colon')
                else
                    call error(p,'Rank-three vector gathering requires bare colons on all other axes')
                end if
                return
            end do
            if((rank==1.and.p%prog%symbols(symbol)%typ/=ty_character.and. &
                .not.numeric(p%prog%symbols(symbol)%typ)).or. &
               (rank/=1.and..not.numeric(p%prog%symbols(symbol)%typ)).or.p%prog%symbols(symbol)%is_pointer) then
                if(rank==2) then
                    call error(p,'Row gathering requires a numeric non-POINTER matrix and full column colon')
                else
                    call error(p,'Rank-three vector gathering requires a numeric non-POINTER array')
                end if
                return
            end if
            e%kind=ex_gather_rows;e%symbol=symbol
            e%left=operands(1,1);e%left2=operands(1,2);e%left3=operands(1,3)
            e%typ=p%prog%symbols(symbol)%typ;e%real_kind=p%prog%symbols(symbol)%real_kind
            e%rank=rank;e%extent=-1_int64;e%dims=-1_int64;e%triplet=is_triplet
            if(e%typ==ty_character)e%character_len=p%prog%symbols(symbol)%character_len
            root=add_expr(p,e);return
        end if
        if(any(is_triplet)) then
            e%kind=ex_section; e%typ=p%prog%symbols(symbol)%typ
            e%real_kind=p%prog%symbols(symbol)%real_kind; e%symbol=symbol
            e%left=operands(1,1); e%right=operands(2,1); e%stride=operands(3,1)
            e%left2=operands(1,2); e%right2=operands(2,2); e%stride2=operands(3,2)
            e%left3=operands(1,3); e%right3=operands(2,3); e%stride3=operands(3,3)
            e%triplet=is_triplet; e%rank=count(is_triplet); e%extent=-1_int64
            if(e%rank>=2) e%dims=-1_int64
            root=add_expr(p,e)
        else
            root=operands(1,1)
            if(present(second)) second=operands(1,2)
            if(present(third)) third=operands(1,3)
        end if
    end function
    recursive integer function section_integer(p) result(root)
        type(parser_t),intent(inout)::p
        root=expression(p,0)
        if(p%diag%code/=0) return
        if(p%prog%expressions(root)%typ/=ty_integer.or.p%prog%expressions(root)%rank/=0) &
            call error(p,'Array subscript and triplet operands must be scalar INTEGER')
    end function

    recursive subroutine statements(p)
        type(parser_t),intent(inout)::p
        character(:),allocatable::s
        do while(p%diag%code==0)
            s=peek(p)
            if(s=='end'.or.s=='else'.or.s=='elseif'.or.s=='endif'.or.s=='enddo'.or. &
               s=='case'.or.s=='contains'.or.s=='<eof>') return
            call statement(p)
        end do
    end subroutine
    recursive subroutine statement(p)
        type(parser_t),intent(inout)::p
        type(instruction_t)::ins
        integer::j
        character(63)::construct_name
        if(p%tokens(p%p)%kind==tk_name.and.p%tokens(p%p+1)%text==':') then
            call read_name(p,construct_name);call expect(p,':')
            if(peek(p)/='do') then
                call error(p,'Only named counted DO constructs are supported');return
            end if
            call do_statement(p,construct_name);return
        end if
        select case(peek(p))
        case('nullify'); call nullify_statement(p)
        case('allocate','deallocate'); call allocation_statement(p)
        case('exit','cycle'); call loop_transfer_statement(p)
        case('if'); call if_statement(p)
        case('do'); call do_statement(p)
        case('forall'); call forall_statement(p)
        case('where'); call where_statement(p)
        case('select'); call select_statement(p)
        case('print')
            if(p%scope>0) then
                if(p%prog%procedures(p%scope)%is_pure.or. &
                   (.not.p%prog%procedures(p%scope)%is_subroutine.and. &
                    .not.p%prog%procedures(p%scope)%has_impure_prefix)) then
                    call error(p,'I/O requires the main program, an impure subroutine or IMPURE ELEMENTAL function'); return
                end if
            end if
            call print_statement(p)
        case('call'); call call_statement(p)
        case('write'); call internal_write_statement(p)
        case('read')
            if(read_is_assignment(p)) then
                call assignment(p)
            else
                call read_statement(p)
            end if
        case('inquire')
            if(read_is_assignment(p)) then
                call assignment(p)
            else
                call inquire_name_statement(p)
            end if
        case('backspace')
            if(read_is_assignment(p)) then
                call assignment(p)
            else
                call backspace_statement(p)
            end if
        case('stop')
            ins%op=op_stop; ins%line=p%tokens(p%p)%line; ins%column=p%tokens(p%p)%column
            if(p%scope>0) then
                if(p%prog%procedures(p%scope)%is_pure) call error(p,'STOP is not permitted in PURE procedures')
            end if
            p%p=p%p+1
            if(p%tokens(p%p)%kind/=tk_eol) ins%a=expression(p,0)
            if(p%diag%code/=0) return
            if(ins%a/=0) then
                if(p%prog%expressions(ins%a)%rank/=0.or. &
                   (p%prog%expressions(ins%a)%typ/=ty_integer.and.p%prog%expressions(ins%a)%typ/=ty_character)) &
                    call error(p,'STOP requires scalar INTEGER or CHARACTER code')
            end if
            call finish_line(p); j=emit(p,ins)
        case('return')
            if(p%scope<=0) then
                call error(p,'RETURN requires a procedure'); return
            end if
            ins%op=op_return; ins%line=p%tokens(p%p)%line; ins%column=p%tokens(p%p)%column
            p%p=p%p+1; call finish_line(p); j=emit(p,ins)
        case('error')
            ins%op=op_error_stop; ins%line=p%tokens(p%p)%line; ins%column=p%tokens(p%p)%column
            p%p=p%p+1; call expect(p,'stop'); ins%a=expression(p,0)
            if(p%diag%code/=0) return
            if(p%prog%expressions(ins%a)%rank/=0.or. &
                (p%prog%expressions(ins%a)%typ/=ty_character.and.p%prog%expressions(ins%a)%typ/=ty_integer)) &
                call error(p,'ERROR STOP requires a scalar character or integer code')
            call finish_line(p); j=emit(p,ins)
        case default; call assignment(p)
        end select
    end subroutine
    subroutine nullify_statement(p)
        type(parser_t),intent(inout)::p
        type(instruction_t)::ins
        integer::s,j
        ins%line=p%tokens(p%p)%line;ins%column=p%tokens(p%p)%column
        call expect(p,'nullify');call expect(p,'(')
        s=find_symbol(p,peek(p))
        if(s<1) then
            call error(p,'NULLIFY requires one whole POINTER');return
        end if
        if(.not.p%prog%symbols(s)%is_pointer.or.p%prog%symbols(s)%dummy_intent==1) then
            call error(p,'NULLIFY requires a reassociable POINTER');return
        end if
        p%p=p%p+1;call expect(p,')');call finish_line(p)
        ins%op=op_nullify;ins%symbol=s;j=emit(p,ins)
    end subroutine
    subroutine pointer_assignment(p,s,line,col)
        type(parser_t),intent(inout)::p
        integer,intent(in)::s,line,col
        type(instruction_t)::ins
        type(expr_t)::null_expr
        integer::a,t,j
        if(.not.p%prog%symbols(s)%is_pointer) then
            call error(p,'Pointer association requires a whole POINTER lhs');return
        end if
        if(take(p,'null')) then
            null_expr=expr_t(kind=ex_call,op='null',line=p%tokens(p%p-1)%line, &
                column=p%tokens(p%p-1)%column)
            allocate(null_expr%args(0));call expect(p,'(');call expect(p,')')
            a=add_expr(p,null_expr)
        else
            a=expression(p,0)
            if(p%diag%code/=0) return
            associate(e=>p%prog%expressions(a))
            if(e%parenthesized.or.(e%kind/=ex_variable.and.e%kind/=ex_section).or.e%rank/=1) then
                call error(p,'Pointer target requires a whole rank-one array or rank-one section');return
            end if
            t=e%symbol
            if(t<1) then
                call error(p,'Pointer target lacks a variable binding');return
            end if
            if(e%typ/=p%prog%symbols(s)%typ.or.e%real_kind/=p%prog%symbols(s)%real_kind) then
                call error(p,'Pointer association requires matching type and kind');return
            end if
            if(p%prog%symbols(t)%is_pointer) then
                if(e%kind/=ex_variable) call error(p,'Pointer-to-pointer association requires whole variable')
            else
                if(.not.p%prog%symbols(t)%is_target.or.p%prog%symbols(t)%is_allocatable.or. &
                   p%prog%symbols(t)%scope<0.or.p%prog%symbols(t)%is_automatic.or.p%prog%symbols(t)%rank>2) &
                    call error(p,'Pointer association requires nonallocatable rank-one/two TARGET')
            end if
            end associate
        end if
        call finish_line(p)
        ins%op=op_pointer_assign;ins%symbol=s;ins%a=a;ins%line=line;ins%column=col;j=emit(p,ins)
    end subroutine
    subroutine allocation_statement(p)
        type(parser_t),intent(inout)::p
        type(instruction_t)::ins,objects(max_allocation_objects)
        integer::s,d,lo,hi,j,a,t,n,first
        logical::has_options
        character(63)::option
        has_options=.false.
        ins%line=p%tokens(p%p)%line;ins%column=p%tokens(p%p)%column
        ins%op=op_allocate
        if(take(p,'deallocate')) then
            ins%op=op_deallocate
        else
            call expect(p,'allocate')
        end if
        call expect(p,'(')
        if(ins%op==op_allocate.and.take(p,'character')) then
            call expect(p,'(')
            if(peek(p)=='len'.and.p%tokens(p%p+1)%text=='=') p%p=p%p+2
            ins%b=section_integer(p)
            call expect(p,')');call expect(p,'::')
        end if
        n=0
        do
        if(n==max_allocation_objects) then
            call error(p,'Allocation object limit exceeded (64)');return
        end if
        s=find_symbol(p,peek(p))
        if(s==0) then
            call error(p,'Allocation requires a declared ALLOCATABLE array');return
        end if
        if(.not.p%prog%symbols(s)%is_allocatable.or.p%prog%symbols(s)%dummy_intent==1) then
            call error(p,'Allocation requires a writable ALLOCATABLE array');return
        end if
        if(ins%b/=0.and..not.p%prog%symbols(s)%deferred_character) then
            call error(p,'Typed ALLOCATE requires a deferred-length CHARACTER array');return
        end if
        if(ins%op==op_allocate.and.p%prog%symbols(s)%deferred_character.and.ins%b==0) then
            call error(p,'Deferred CHARACTER ALLOCATE requires CHARACTER(LEN=...) type specification');return
        end if
        if(n>0) then
            do j=1,n
                if(objects(j)%symbol==s) then
                    call error(p,'Allocation list contains a repeated object');return
                end if
            end do
        end if
        ins%symbol=s;p%p=p%p+1
        if(allocated(ins%items)) deallocate(ins%items)
        allocate(ins%items(0))
        if(ins%op==op_allocate.and.p%prog%symbols(s)%rank>0) then
            call expect(p,'(')
            do d=1,p%prog%symbols(s)%rank
                hi=section_integer(p);lo=0
                if(take(p,':')) then
                    lo=hi;hi=section_integer(p)
                end if
                if(p%diag%code/=0) return
                ins%items=[ins%items,lo,hi]
                if(d<p%prog%symbols(s)%rank) call expect(p,',')
            end do
            call expect(p,')')
        end if
        n=n+1;objects(n)=ins
        if(.not.take(p,',')) exit
        if((peek(p)=='stat'.or.peek(p)=='errmsg').and.p%tokens(p%p+1)%text=='=') then
            has_options=.true.;exit
        end if
        if((peek(p)=='source'.or.peek(p)=='mold').and. &
           p%tokens(p%p+1)%text=='=') then
            call error(p,'Allocation SOURCE/MOLD options are unsupported');return
        end if
        end do
        if(has_options)then
            do
                option=peek(p)
                if(option/='stat'.and.option/='errmsg')then
                    call error(p,'Allocation supports STAT and ERRMSG options only');return
                end if
                if((option=='stat'.and.ins%a/=0).or.(option=='errmsg'.and.ins%third/=0))then
                    call error(p,'Repeated allocation option');return
                end if
                p%p=p%p+1;call expect(p,'=');a=expression(p,0)
                if(p%diag%code/=0)return
                t=ty_integer;if(option=='errmsg')t=ty_character
                if(.not.valid_allocation_output(p%prog,a,t,p%scope))then
                    if(option=='errmsg')then
                        call error(p,'ERRMSG requires a whole writable local scalar CHARACTER with fixed or assumed length')
                    else
                        call error(p,'STAT requires a whole writable local scalar INTEGER')
                    end if
                    return
                end if
                t=p%prog%expressions(a)%symbol
                if(any(p%active_do==t))then
                    call error(p,'Allocation status target is an active DO variable');return
                end if
                do j=1,n
                    if(objects(j)%symbol==t)then
                        call error(p,'Allocation status target must not be an allocation object');return
                    end if
                end do
                call check_module_write(p,t)
                if(p%diag%code/=0)return
                if(option=='stat')ins%a=a
                if(option=='errmsg')ins%third=a
                if(.not.take(p,','))exit
            end do
        end if
        call expect(p,')');call finish_line(p)
        if(p%diag%code/=0) return
        first=p%prog%nc+1
        do j=1,n
            objects(j)%a=ins%a;objects(j)%third=ins%third;objects(j)%scope=p%scope
            if(.not.valid_allocation_message(p%prog,objects(j)))then
                call error(p,'ERRMSG allocation bounds must be independent of status variables and user functions');return
            end if
            if(n>1) then
                objects(j)%c=n;objects(j)%d=j;objects(j)%target=first+n
            end if
            a=emit(p,objects(j))
            if(p%diag%code/=0) return
        end do
        if(n>1) then
            if(.not.valid_allocation_group(p%prog,first))then
                if(ins%third/=0)then
                    call error(p,'Multi-object allocation bounds must not reference its objects or status variables, or call user functions')
                else
                    call error(p,'Multi-object allocation bounds must not reference its objects or STAT, or call user functions')
                end if
            end if
            if(ins%a/=0) call check_module_write(p,p%prog%expressions(ins%a)%symbol)
        end if
    end subroutine
    subroutine call_statement(p)
        type(parser_t),intent(inout)::p
        type(instruction_t)::ins
        type(expr_t)::e
        character(63)::name
        integer::j,s,b,t,base
        ins%op=op_call; ins%line=p%tokens(p%p)%line; ins%column=p%tokens(p%p)%column
        p%p=p%p+1
        if(peek(p)=='random_number') then
            p%p=p%p+1;call random_number_statement(p,ins);return
        end if
        call read_name(p,name)
        if(take(p,'%')) then
            s=find_symbol(p,trim(name))
            if(s==0) then
                call error(p,'Type-bound CALL requires a declared object');return
            end if
            t=p%prog%symbols(s)%typ-ty_derived_base
            b=find_binding(p,p%prog%symbols(s)%typ,peek(p));if(p%diag%code/=0) return
            base=add_expr(p,expr_t(kind=ex_variable,typ=p%prog%symbols(s)%typ,symbol=s, &
                line=ins%line,column=ins%column+5))
            e%symbol=p%prog%derived_types(t)%binding_procedures(b)
            p%p=p%p+1;call expect(p,'(');call actual_arguments(p,e,'',base)
            call user_call_type(p,e,.true.)
            ins%symbol=e%symbol;ins%items=e%args;ins%bound_type=t;ins%bound_binding=b
            call finish_line(p);j=emit(p,ins);return
        end if
        e%generic_id=find_generic(p,trim(name))
        if(e%generic_id==0) e%symbol=find_procedure(p,trim(name))
        if(p%diag%code/=0) return
        if(name=='getcwd'.or.name=='get_command_argument') then
            s=find_symbol(p,trim(name))
            if(p%diag%code/=0) return
            if(s/=0) then
                call error(p,'Process query is shadowed by a data declaration');return
            end if
            if(e%symbol==0.and.e%generic_id==0) then
                call process_query_statement(p,ins,trim(name));return
            end if
        end if
        if(name=='system_clock'.or.name=='cpu_time')then
            s=find_symbol(p,trim(name))
            if(p%diag%code/=0)return
            if(s/=0)then
                call error(p,'Timing intrinsic is shadowed by a data declaration');return
            end if
            if(e%symbol==0.and.e%generic_id==0)then
                call timing_query_statement(p,ins,trim(name));return
            end if
        end if
        if(name=='move_alloc') then
            s=find_symbol(p,trim(name))
            if(p%diag%code/=0) return
            if(s/=0) then
                call error(p,'MOVE_ALLOC is shadowed by a data declaration');return
            end if
            if(e%symbol==0.and.e%generic_id==0) then
                call move_alloc_statement(p,ins);return
            end if
        end if
        if(name=='random_seed') then
            s=find_symbol(p,trim(name))
            if(p%diag%code/=0) return
            if(s/=0) then
                call error(p,'RANDOM_SEED is shadowed by a data declaration');return
            end if
            if(e%symbol==0.and.e%generic_id==0) then
                call random_seed_statement(p,ins);return
            end if
        end if
        if(e%symbol==0.and.e%generic_id==0) then
            call error(p,'Unknown or inaccessible subroutine: '//trim(name)); return
        end if
        if(take(p,'(')) then
            call actual_arguments(p,e,trim(name))
        else
            allocate(e%args(0))
            if(e%generic_id>0) call select_generic(p,e,[integer::],[character(63)::])
        end if
        call user_call_type(p,e,.true.)
        ins%generic_id=e%generic_id
        ins%symbol=e%symbol; ins%items=e%args; call finish_line(p); j=emit(p,ins)
    end subroutine
    subroutine timing_query_statement(p,ins,name)
        type(parser_t),intent(inout)::p
        type(instruction_t),intent(inout)::ins
        character(*),intent(in)::name
        type(expr_t)::e
        integer::j,s
        if(p%scope>0)then
            if(p%prog%procedures(p%scope)%is_pure.or.p%prog%procedures(p%scope)%is_simple)then
                call error(p,'Timing inquiries are forbidden in PURE or SIMPLE procedures');return
            end if
        end if
        ins%op=op_timing_query;ins%scope=p%scope;ins%d=1
        if(name=='cpu_time')ins%d=2
        if(take(p,'('))then
            call actual_arguments(p,e,name)
        else if(ins%d==1)then
            allocate(e%args(3),source=0)
        else
            allocate(e%args(0))
        end if
        if(p%diag%code/=0)return
        ins%items=e%args
        if(.not.valid_timing_query(p%prog,ins))then
            call error(p,'Timing inquiry requires distinct whole writable supported-kind scalar outputs; INTEGER kinds must agree');return
        end if
        do j=1,size(ins%items)
            if(ins%items(j)==0)cycle
            s=p%prog%expressions(ins%items(j))%symbol
            if(any(p%active_do==s))then
                call error(p,'Timing inquiry cannot modify an active DO counter');return
            end if
            call check_module_write(p,s)
            if(p%diag%code/=0)return
        end do
        call finish_line(p);j=emit(p,ins)
    end subroutine
    subroutine move_alloc_statement(p,ins)
        type(parser_t),intent(inout)::p
        type(instruction_t),intent(inout)::ins
        type(expr_t)::e
        integer::j,s
        call expect(p,'(');call actual_arguments(p,e,'move_alloc')
        if(p%diag%code/=0) return
        ins%op=op_move_alloc;ins%scope=p%scope;ins%items=e%args
        if(.not.valid_move_alloc(p%prog,ins)) then
            call error(p,'MOVE_ALLOC requires distinct whole writable allocatables of matching type, kind and rank');return
        end if
        do j=1,2
            s=p%prog%expressions(ins%items(j))%symbol
            call check_module_write(p,s)
            if(p%diag%code/=0) return
        end do
        call finish_line(p);j=emit(p,ins)
    end subroutine
    subroutine process_query_statement(p,ins,name)
        type(parser_t),intent(inout)::p
        type(instruction_t),intent(inout)::ins
        character(*),intent(in)::name
        type(expr_t)::e
        integer::j,s,first
        if(p%scope>0) then
            if(p%prog%procedures(p%scope)%is_pure.or.p%prog%procedures(p%scope)%is_simple) then
                call error(p,'Process query is forbidden in PURE or SIMPLE procedures');return
            end if
        end if
        call expect(p,'(');call actual_arguments(p,e,name)
        if(p%diag%code/=0) return
        ins%op=op_process_query;ins%scope=p%scope;ins%items=e%args;ins%d=1;first=1
        if(name=='get_command_argument') then
            ins%d=2;first=2
        end if
        if(.not.valid_process_query(p%prog,ins)) then
            call error(p,'Process query requires default INTEGER controls and distinct whole local writable outputs');return
        end if
        do j=first,size(ins%items)
            if(ins%items(j)==0) cycle
            s=p%prog%expressions(ins%items(j))%symbol
            if(any(p%active_do==s)) then
                call error(p,'Process query cannot modify an active DO counter');return
            end if
        end do
        call finish_line(p);j=emit(p,ins)
    end subroutine
    subroutine random_seed_statement(p,ins)
        type(parser_t),intent(inout)::p
        type(instruction_t),intent(inout)::ins
        integer::j
        if(p%scope>0) then
            if(p%prog%procedures(p%scope)%is_pure.or.p%prog%procedures(p%scope)%is_simple) then
                call error(p,'RANDOM_SEED is forbidden in PURE or SIMPLE procedures');return
            end if
        end if
        if(take(p,'(')) then
            if(.not.take(p,')')) then
                call error(p,'RANDOM_SEED supports only an empty argument list; SIZE, PUT and GET are unsupported');return
            end if
        end if
        call finish_line(p)
        ins%op=op_random_seed;j=emit(p,ins)
    end subroutine
    subroutine random_number_statement(p,ins)
        type(parser_t),intent(inout)::p
        type(instruction_t),intent(inout)::ins
        type(expr_t)::e
        integer::a,s,j
        if(p%scope>0) then
            if(p%prog%procedures(p%scope)%is_pure.or.p%prog%procedures(p%scope)%is_simple) then
                call error(p,'RANDOM_NUMBER is forbidden in PURE or SIMPLE procedures');return
            end if
        end if
        call expect(p,'(');call actual_arguments(p,e,'random_number')
        if(p%diag%code/=0) return
        if(size(e%args)/=1) then
            call error(p,'RANDOM_NUMBER requires one HARVEST argument');return
        end if
        a=e%args(1);s=p%prog%expressions(a)%symbol
        associate(target=>p%prog%expressions(a))
        if(target%parenthesized.or.(target%kind/=ex_variable.and. &
           target%kind/=ex_element.and.target%kind/=ex_section)) then
            call error(p,'RANDOM_NUMBER requires a writable variable, element or section');return
        end if
        if(target%typ/=ty_real) then
            call error(p,'RANDOM_NUMBER HARVEST must be REAL');return
        end if
        end associate
        if(p%prog%symbols(s)%is_parameter.or.p%prog%symbols(s)%dummy_intent==1) then
            call error(p,'RANDOM_NUMBER cannot modify PARAMETER or INTENT(IN)');return
        end if
        ins%op=op_random_number;ins%symbol=s;ins%a=a
        call finish_line(p);j=emit(p,ins)
    end subroutine
    subroutine assignment_types(p,left,right)
        type(parser_t),intent(inout)::p
        integer,intent(in)::left,right
        if(left==right) return
        if(numeric(left).and.numeric(right)) return
        call error(p,'Incompatible assignment types')
    end subroutine
    pure logical function numeric(t)
        integer,intent(in)::t
        numeric=t==ty_integer.or.t==ty_real
    end function
    subroutine assignment(p)
        type(parser_t),intent(inout)::p
        integer::s,e,j,line,col,subscript,section,second,third,target_rank,component,target_type,t
        integer(int64)::dims(3)
        type(instruction_t)::ins
        line=p%tokens(p%p)%line; col=p%tokens(p%p)%column
        if(p%tokens(p%p)%kind/=tk_name) then
            call error(p,'Expected supported statement'); return
        end if
        s=find_symbol(p,peek(p))
        if(s==0) then
            call error(p,'Undeclared variable or unsupported statement: '//peek(p)); return
        end if
        if(p%prog%symbols(s)%dummy_intent==1) then
            call error(p,'Cannot assign to an INTENT(IN) dummy argument'); return
        end if
        if(p%prog%symbols(s)%is_parameter) then
            call error(p,'Cannot assign to a PARAMETER constant'); return
        end if
        if(any(p%active_do==s)) then
            call error(p,'Cannot assign to an active DO variable'); return
        end if
        p%p=p%p+1
        if(take(p,'=>')) then
            call pointer_assignment(p,s,line,col);return
        end if
        if(p%scope>0.and.p%prog%symbols(s)%is_pointer) then
            call error(p,'Procedure POINTER pointee assignment is unsupported');return
        end if
        subscript=0; section=0; second=0;third=0;component=0;target_type=p%prog%symbols(s)%typ
        if(take(p,"%")) then
            component=find_component(p,target_type,peek(p))
            if(p%diag%code/=0) return
            t=target_type-ty_derived_base
            target_type=p%prog%derived_types(t)%component_types(component);p%p=p%p+1
        end if
        if(take(p,'(')) then
            subscript=array_subscript(p,s,second,third)
            if(p%diag%code/=0) return
            if(p%prog%expressions(subscript)%kind==ex_gather_rows) then
                call error(p,'Vector row gathering is read-only; scatter assignment is unsupported');return
            end if
            if(p%prog%expressions(subscript)%kind==ex_section.or. &
               p%prog%expressions(subscript)%kind==ex_substring) then
                section=subscript; subscript=0
            end if
        end if
        if(peek(p)=='(' .and. subscript/=0) then
            block
                type(expr_t)::base_element
                integer::base_root
                base_element%kind=ex_element;base_element%typ=target_type;base_element%symbol=s
                base_element%real_kind=p%prog%symbols(s)%real_kind
                base_element%line=line;base_element%column=col
                base_element%left=subscript;base_element%right=second;base_element%third=third
                base_root=add_expr(p,base_element);p%p=p%p+1
                section=element_substring(p,base_root)
                if(p%diag%code/=0) return
                subscript=0;second=0;third=0
            end block
        end if
        call expect(p,'=')
        e=expression(p,0)
        if(p%diag%code/=0) return
        call assignment_types(p,target_type,p%prog%expressions(e)%typ)
        if(p%prog%expressions(e)%rank>0) then
            target_rank=p%prog%symbols(s)%rank
            if(section/=0) target_rank=p%prog%expressions(section)%rank
            if(subscript/=0) target_rank=0
            if(target_rank/=p%prog%expressions(e)%rank) then
                call error(p,'Array assignment ranks do not conform')
            else if(section==0.and..not.p%prog%symbols(s)%assumed_shape.and..not.p%prog%symbols(s)%is_automatic.and..not.p%prog%symbols(s)%is_allocatable.and..not.p%prog%symbols(s)%is_pointer) then
                dims=symbol_dims(p%prog%symbols(s))
                if(p%prog%expressions(e)%extent>=0) then
                    if(p%prog%expressions(e)%extent/=shape_size(dims)) &
                        call error(p,'Array assignment shapes do not conform')
                end if
                if(target_rank>=2) then
                    if(any(p%prog%expressions(e)%dims>=0.and.p%prog%expressions(e)%dims/=dims)) &
                        call error(p,'Array assignment shapes do not conform')
                end if
            end if
        end if
        call finish_line(p)
        ins%op=op_assign; ins%symbol=s; ins%a=e; ins%b=subscript; ins%c=section; ins%d=second; ins%line=line; ins%column=col
        ins%component=component; ins%third=third
        j=emit(p,ins)
    end subroutine
    subroutine print_statement(p)
        type(parser_t),intent(inout)::p
        integer::e,j
        logical::has_format
        type(instruction_t)::ins
        ins%op=op_print; ins%line=p%tokens(p%p)%line; ins%column=p%tokens(p%p)%column
        allocate(ins%items(0))
        p%p=p%p+1
        call output_format(p,ins,has_format)
        if(.not.has_format) call expect(p,'*')
        ! An empty PRINT * is standard and emits an empty record.
        if(take(p,',')) then
            do while(p%diag%code==0)
                e=output_item(p,1)
                if(p%diag%code/=0) return
                ins%items=[ins%items,e]
                if(size(ins%items)>64) then
                    call error(p,'PRINT item limit exceeded'); return
                end if
                if(.not.take(p,',')) exit
            end do
        end if
        call finish_line(p)
        do j=1,size(ins%items)
            e=p%prog%expressions(ins%items(j))%typ-ty_derived_base
            if(e<1.or.e>p%prog%nt) cycle
            if(p%prog%derived_types(e)%write_procedure==0) &
                call error(p,'Derived output requires a defined formatted WRITE binding')
        end do
        if(allocated(ins%format).and.p%diag%code==0) call validate_output_format(p,ins)
        j=emit(p,ins)
    end subroutine
    subroutine output_format(p,ins,found)
        type(parser_t),intent(inout)::p
        type(instruction_t),intent(inout)::ins
        logical,intent(out)::found
        integer::s,e
        call constant_output_format(p,ins%format,found)
        if(found.or.p%diag%code/=0) return
        if(p%tokens(p%p)%kind/=tk_name) return
        s=find_symbol(p,peek(p))
        if(s==0) return
        if(p%prog%symbols(s)%typ/=ty_character.or.p%prog%symbols(s)%rank/=0.or. &
           p%prog%symbols(s)%is_parameter) return
        ! PRIMARY may parse a subobject/call, but the bounded format contract
        ! accepts only the whole scalar data object and independently binds it.
        e=primary(p)
        if(p%diag%code/=0) return
        if(p%prog%expressions(e)%kind/=ex_variable.or.p%prog%expressions(e)%symbol/=s) then
            call error(p,'Runtime format requires a whole scalar CHARACTER variable');return
        end if
        ins%format_expr=e;found=.true.
    end subroutine
    subroutine constant_output_format(p,fmt,found)
        type(parser_t),intent(inout)::p
        character(:),allocatable,intent(out)::fmt
        logical,intent(out)::found
        integer::s
        found=.false.
        if(p%tokens(p%p)%kind==tk_string) then
            fmt=peek(p)
        else if(p%tokens(p%p)%kind==tk_name) then
            s=find_symbol(p,peek(p))
            if(s==0) return
            associate(v=>p%prog%symbols(s))
            if(.not.v%is_parameter.or..not.v%parameter_ready.or.v%typ/=ty_character.or.v%rank/=0) return
            if(v%constant_value%tag/=ty_character.or..not.allocated(v%constant_value%s)) return
            ! PARAMETER initialization has already applied the declared length.
            ! Freeze only the named scalar value, never an executable format.
            fmt=v%constant_value%s
            end associate
        else
            return
        end if
        p%p=p%p+1;found=.true.
    end subroutine
    subroutine validate_output_format(p,ins)
        type(parser_t),intent(inout)::p
        type(instruction_t),intent(in)::ins
        integer::types(size(ins%items)),j,e
        integer(int64)::counts(size(ins%items))
        do j=1,size(ins%items)
            e=ins%items(j);types(j)=p%prog%expressions(e)%typ;counts(j)=1_int64
            if(p%prog%expressions(e)%rank>0) counts(j)=p%prog%expressions(e)%extent
            if(p%prog%expressions(e)%kind==ex_output_do) counts(j)=-1_int64
        end do
        call validate_print_format(ins%format,types,p%diag,ins%line,ins%column,counts,ins%op==op_print)
    end subroutine
    recursive subroutine select_statement(p)
        type(parser_t),intent(inout)::p
        type(instruction_t)::ins
        integer::entry,arm,previous,j,a,b,k,t
        integer,allocatable::jumps(:),bounds(:)
        logical::default_seen,is_range
        call enter_block(p)
        if(p%diag%code/=0) return
        ins%op=op_select;ins%line=p%tokens(p%p)%line;ins%column=p%tokens(p%p)%column
        call expect(p,'select');call expect(p,'case');call expect(p,'(')
        ins%a=expression(p,0);call expect(p,')');call finish_line(p)
        if(p%diag%code/=0) return
        t=p%prog%expressions(ins%a)%typ
        if(p%prog%expressions(ins%a)%rank/=0.or.(t/=ty_integer.and.t/=ty_character.and.t/=ty_logical)) then
            call error(p,'SELECT CASE selector must be scalar INTEGER, CHARACTER or LOGICAL');return
        end if
        entry=emit(p,ins);previous=0;default_seen=.false.
        allocate(jumps(0),bounds(0))
        do while(peek(p)=='case'.and.p%diag%code==0)
            ins=instruction_t();ins%op=op_case;ins%a=entry
            ins%line=p%tokens(p%p)%line;ins%column=p%tokens(p%p)%column
            allocate(ins%items(0));p%p=p%p+1
            if(take(p,'default')) then
                if(default_seen) call error(p,'Duplicate CASE DEFAULT')
                default_seen=.true.
            else
                call expect(p,'(')
                do while(p%diag%code==0)
                    a=0;b=0
                    if(peek(p)/=':') a=case_bound(p,t)
                    is_range=take(p,':')
                    if(is_range) then
                        if(peek(p)/=')'.and.peek(p)/=',') b=case_bound(p,t)
                        if(t==ty_logical) call error(p,'LOGICAL CASE ranges are invalid')
                        if(a==0.and.b==0) call error(p,'CASE range requires a bound')
                    else
                        b=a
                    end if
                    if(p%diag%code/=0) return
                    if(size(bounds)>=128) then
                        call error(p,"CASE value/range limit exceeded (64)");return
                    end if
                    do k=1,size(bounds),2
                        if(case_overlap(p,a,b,bounds(k),bounds(k+1))) then
                            call error(p,'Overlapping CASE selector values');return
                        end if
                        if(p%diag%code/=0) return
                    end do
                    bounds=[bounds,a,b];ins%items=[ins%items,a,b]
                    if(.not.take(p,',')) exit
                end do
                call expect(p,')')
            end if
            call finish_line(p)
            arm=emit(p,ins)
            if(p%diag%code/=0) return
            if(previous/=0) p%prog%code(previous)%target=arm
            previous=arm
            call statements(p)
            ins=instruction_t();ins%op=op_jump;ins%line=p%tokens(p%p)%line;ins%column=p%tokens(p%p)%column
            j=emit(p,ins);jumps=[jumps,j]
        end do
        call expect(p,'end');call expect(p,'select');call finish_line(p)
        if(p%diag%code/=0) return
        p%prog%code(entry)%target=p%prog%nc+1
        if(previous/=0) p%prog%code(previous)%target=p%prog%nc+1
        do k=1,size(jumps)
            p%prog%code(jumps(k))%target=p%prog%nc+1
        end do
        p%block_depth=p%block_depth-1
    end subroutine
    integer function case_bound(p,typ) result(root)
        type(parser_t),intent(inout)::p
        integer,intent(in)::typ
        type(value_t)::value
        root=expression(p,0)
        if(p%diag%code/=0) return
        if(p%prog%expressions(root)%rank/=0.or.p%prog%expressions(root)%typ/=typ) then
            call error(p,'CASE bound must be scalar and match the selector type');return
        end if
        call require_constant(p,root,'CASE bounds must be constant expressions')
        if(p%diag%code==0) call evaluate_constant(p%prog,root,value,p%diag)
        if(p%diag%code/=0) then
            p%diag%code=1;p%diag%message="Invalid CASE bound: "//p%diag%message
        end if
    end function
    logical function case_overlap(p,a,b,c,d) result(overlap)
        type(parser_t),intent(inout)::p
        integer,intent(in)::a,b,c,d
        type(value_t)::lo1,hi1,lo2,hi2
        overlap=.false.
        if(a/=0) call evaluate_constant(p%prog,a,lo1,p%diag)
        if(b/=0) call evaluate_constant(p%prog,b,hi1,p%diag)
        if(c/=0) call evaluate_constant(p%prog,c,lo2,p%diag)
        if(d/=0) call evaluate_constant(p%prog,d,hi2,p%diag)
        if(p%diag%code/=0) return
        if(a/=0.and.b/=0) then
            if(case_less(hi1,lo1)) return
        end if
        if(c/=0.and.d/=0) then
            if(case_less(hi2,lo2)) return
        end if
        if(b/=0.and.c/=0) then
            if(case_less(hi1,lo2)) return
        end if
        if(d/=0.and.a/=0) then
            if(case_less(hi2,lo1)) return
        end if
        overlap=.true.
    end function
    logical function case_less(a,b) result(less)
        type(value_t),intent(in)::a,b
        less=.false.
        select case(a%tag)
        case(ty_integer);less=a%i<b%i
        case(ty_character);less=a%s<b%s
        case(ty_logical);less=.not.a%l.and.b%l
        end select
    end function
    recursive subroutine if_statement(p)
        type(parser_t),intent(inout)::p
        type(instruction_t)::ins
        integer::cond,branch,jumps(max_instructions),nj,j
        logical::elseif_arm
        call enter_block(p)
        if(p%diag%code/=0) return
        nj=0
        do
            ins=instruction_t()
            ins%line=p%tokens(p%p)%line;ins%column=p%tokens(p%p)%column
            p%p=p%p+1;call expect(p,'(')
            cond=expression(p,0);call expect(p,')')
            if(p%diag%code/=0) return
            if(p%prog%expressions(cond)%typ/=ty_logical.or.p%prog%expressions(cond)%rank/=0) then
                call error(p,'IF condition must be scalar LOGICAL');return
            end if
            ins%op=op_branch;ins%a=cond;branch=emit(p,ins)
            if(p%diag%code/=0) return
            if(.not.take(p,'then')) then
                if(nj>0.or.peek(p)=='if'.or.peek(p)=='do'.or.peek(p)=='select'.or. &
                   p%tokens(p%p+1)%text==':') then
                    call error(p,'Single-line IF requires a supported action statement');return
                end if
                if(peek(p)=='forall') then
                    call forall_statement(p,.true.)
                else if(peek(p)=='where') then
                    call where_statement(p,.true.)
                else
                    call statement(p)
                end if
                p%prog%code(branch)%target=p%prog%nc+1
                p%block_depth=p%block_depth-1;return
            end if
            call finish_line(p);call statements(p)
            if(p%diag%code/=0) return
            if(peek(p)/='else'.and.peek(p)/='elseif') then
                p%prog%code(branch)%target=p%prog%nc+1;exit
            end if
            ins%op=op_jump;ins%a=0
            nj=nj+1;jumps(nj)=emit(p,ins)
            if(p%diag%code/=0) return
            p%prog%code(branch)%target=p%prog%nc+1
            elseif_arm=peek(p)=='elseif'
            if(.not.elseif_arm) then
                p%p=p%p+1
                elseif_arm=peek(p)=='if'
            end if
            if(elseif_arm) cycle
            call finish_line(p);call statements(p);exit
        end do
        if(.not.take(p,'endif')) then
            call expect(p,'end');call expect(p,'if')
        end if
        call finish_line(p)
        do j=1,nj
            p%prog%code(jumps(j))%target=p%prog%nc+1
        end do
        p%block_depth=p%block_depth-1
    end subroutine
    subroutine loop_transfer_statement(p)
        type(parser_t),intent(inout)::p
        type(instruction_t)::ins
        integer::depth,j
        ins%line=p%tokens(p%p)%line;ins%column=p%tokens(p%p)%column
        ins%op=op_exit
        if(peek(p)=='cycle') ins%op=op_cycle
        p%p=p%p+1
        if(p%tokens(p%p)%kind==tk_name) call read_name(p,ins%construct_name)
        call finish_line(p)
        if(p%diag%code/=0) return
        do depth=p%block_depth,1,-1
            if(p%active_do_entry(depth)==0) cycle
            if(len_trim(ins%construct_name)>0) then
                if(ins%construct_name/=p%active_do_name(depth)) cycle
            end if
            ins%a=p%active_do_entry(depth);j=emit(p,ins);return
        end do
        call error(p,'EXIT/CYCLE requires a matching enclosing DO construct')
    end subroutine
    subroutine where_statement(p,action_only)
        type(parser_t),intent(inout)::p
        logical,optional,intent(in)::action_only
        type(instruction_t)::ins
        integer::entry,arm,j,k,s,mask,rank,first_expr
        integer(int64)::dims(3)
        logical::inline,final_else
        first_expr=p%prog%ne+1
        ins%op=op_where;ins%line=p%tokens(p%p)%line;ins%column=p%tokens(p%p)%column
        call expect(p,'where');call expect(p,'(')
        mask=expression(p,0);call expect(p,')')
        if(p%diag%code/=0) return
        if(p%prog%expressions(mask)%typ/=ty_logical.or.p%prog%expressions(mask)%rank<1.or.p%prog%expressions(mask)%rank>2) then
            call error(p,'WHERE mask must be a LOGICAL array');return
        end if
        ins%a=mask;inline=p%tokens(p%p)%kind/=tk_eol;ins%c=merge(1,0,inline)
        if(present(action_only)) then
            if(action_only.and..not.inline) then
                call error(p,'Single-line IF requires a WHERE statement, not a construct');return
            end if
        end if
        if(.not.inline) call finish_line(p)
        entry=emit(p,ins);arm=entry;final_else=.false.
        do while(p%diag%code==0)
            if(.not.inline) then
                if(peek(p)=='end'.or.peek(p)=='endwhere') exit
                if(peek(p)=='elsewhere') then
                    if(final_else) then
                        call error(p,'ELSEWHERE without a mask must be last');return
                    end if
                    ins=instruction_t();ins%op=op_elsewhere;ins%d=entry
                    ins%line=p%tokens(p%p)%line;ins%column=p%tokens(p%p)%column;p%p=p%p+1
                    if(take(p,'(')) then
                        ins%a=expression(p,0);call expect(p,')')
                        if(p%diag%code/=0) return
                        if(p%prog%expressions(ins%a)%typ/=ty_logical.or. &
                           p%prog%expressions(ins%a)%rank/=p%prog%expressions(mask)%rank) then
                            call error(p,'ELSEWHERE mask must conform to the WHERE LOGICAL array');return
                        end if
                        if(p%prog%expressions(ins%a)%extent>=0.and.p%prog%expressions(mask)%extent>=0) then
                            if(p%prog%expressions(ins%a)%extent/=p%prog%expressions(mask)%extent.or. &
                               any(p%prog%expressions(ins%a)%dims/=p%prog%expressions(mask)%dims)) then
                                call error(p,'ELSEWHERE mask shape differs from WHERE');return
                            end if
                        end if
                    else
                        final_else=.true.
                    end if
                    call finish_line(p);j=emit(p,ins);p%prog%code(arm)%b=j;arm=j
                    cycle
                end if
            end if
            if(p%tokens(p%p)%kind/=tk_name.or.find_symbol(p,peek(p))==0) then
                call error(p,'WHERE body supports array assignments only; nested constructs are unsupported');return
            end if
            call assignment(p)
            if(p%diag%code/=0) return
            j=p%prog%nc;s=p%prog%code(j)%symbol;rank=p%prog%symbols(s)%rank
            if(p%prog%code(j)%c/=0) rank=p%prog%expressions(p%prog%code(j)%c)%rank
            if(rank<1.or.rank/=p%prog%expressions(mask)%rank.or. &
               p%prog%code(j)%b/=0.or.p%prog%code(j)%component/=0) then
                call error(p,'WHERE target must be a conforming whole array or section');return
            end if
            if(p%prog%code(j)%c==0.and..not.p%prog%symbols(s)%assumed_shape.and. &
               .not.p%prog%symbols(s)%is_automatic.and..not.p%prog%symbols(s)%is_allocatable.and..not.p%prog%symbols(s)%is_pointer) then
                dims=symbol_dims(p%prog%symbols(s))
                if(p%prog%expressions(mask)%extent>=0) then
                    if(product(dims)/=p%prog%expressions(mask)%extent.or. &
                       (rank==2.and.any(dims/=p%prog%expressions(mask)%dims))) then
                        call error(p,'WHERE target shape differs from mask');return
                    end if
                end if
            end if
            if(inline) exit
        end do
        if(.not.inline) then
            if(.not.take(p,'endwhere')) then
                call expect(p,'end');call expect(p,'where')
            end if
            call finish_line(p)
        end if
        if(p%diag%code/=0) return
        p%prog%code(arm)%b=p%prog%nc+1
        j=entry
        do while(j<=p%prog%nc)
            p%prog%code(j)%target=p%prog%nc+1;j=p%prog%code(j)%b
        end do
        do j=first_expr,p%prog%ne
            if(p%prog%expressions(j)%kind==ex_gather_rows) then
                call error(p,'Vector row gathering inside WHERE/FORALL is unsupported');return
            end if
            if(p%prog%expressions(j)%kind/=ex_user_call) cycle
            k=p%prog%expressions(j)%symbol
            if(.not.p%prog%procedures(k)%is_pure) then
                call error(p,'WHERE expressions may reference only PURE user functions');return
            end if
        end do
    end subroutine

    subroutine forall_statement(p,action_only)
        type(parser_t),intent(inout)::p
        logical,optional,intent(in)::action_only
        type(instruction_t)::ins
        integer::entry,s,a,b,c,j,k,n,first_expr,header_end
        integer::indices(2)
        logical::inline
        ins%op=op_forall;ins%line=p%tokens(p%p)%line;ins%column=p%tokens(p%p)%column
        first_expr=p%prog%ne+1;indices=0;n=0;allocate(ins%items(0))
        call expect(p,'forall');call expect(p,'(')
        do while(p%diag%code==0)
            if(n==2) then
                call error(p,'FORALL supports at most two index variables');return
            end if
            s=find_symbol(p,peek(p))
            if(s==0) then
                call error(p,'FORALL index requires a declared local INTEGER scalar');return
            end if
            if(p%prog%symbols(s)%typ/=ty_integer.or.p%prog%symbols(s)%rank/=0.or. &
               p%prog%symbols(s)%scope/=p%scope.or.p%prog%symbols(s)%is_dummy.or. &
               p%prog%symbols(s)%is_parameter.or.any(p%active_do==s)) then
                call error(p,'FORALL index requires a local non-dummy INTEGER variable outside active DO controls');return
            end if
            if(any(indices==s)) then
                call error(p,'Duplicate FORALL index variable');return
            end if
            n=n+1;indices(n)=s;p%p=p%p+1;call expect(p,'=')
            a=section_integer(p);call expect(p,':');b=section_integer(p);c=0
            if(take(p,':')) c=section_integer(p)
            if(p%diag%code/=0) return
            ins%items=[ins%items,s,a,b,c]
            if(.not.take(p,',')) exit
            if(p%tokens(p%p)%kind==tk_name.and.p%tokens(p%p+1)%text=='=') cycle
            header_end=p%prog%ne
            ins%a=expression(p,0)
            exit
        end do
        if(ins%a==0) header_end=p%prog%ne
        call expect(p,')')
        if(p%diag%code/=0) return
        if(ins%a/=0) then
            if(p%prog%expressions(ins%a)%typ/=ty_logical.or.p%prog%expressions(ins%a)%rank/=0) then
                call error(p,'FORALL mask must be scalar LOGICAL');return
            end if
        end if
        do j=first_expr,header_end
            if(p%prog%expressions(j)%kind/=ex_variable) cycle
            if(any(indices==p%prog%expressions(j)%symbol)) then
                call error(p,'FORALL bounds and strides cannot reference an index in the same header');return
            end if
        end do
        inline=p%tokens(p%p)%kind/=tk_eol
        if(present(action_only)) then
            if(action_only.and..not.inline) then
                call error(p,'Single-line IF requires a FORALL statement, not a construct');return
            end if
        end if
        if(.not.inline) call finish_line(p)
        entry=emit(p,ins)
        do while(p%diag%code==0)
            if(.not.inline) then
                if(peek(p)=='end'.or.peek(p)=='endforall') exit
            end if
            if(p%tokens(p%p)%kind/=tk_name.or.find_symbol(p,peek(p))==0) then
                call error(p,'FORALL body supports array assignments only; nested constructs are unsupported');return
            end if
            call assignment(p)
            if(p%diag%code/=0) return
            j=p%prog%nc;s=p%prog%code(j)%symbol
            if(p%prog%code(j)%op/=op_assign.or.p%prog%symbols(s)%rank==0.or. &
               p%prog%code(j)%component/=0.or. &
               (p%prog%code(j)%b==0.and.p%prog%code(j)%c==0)) then
                call error(p,'FORALL target must be an array element or section');return
            end if
            if(inline) exit
        end do
        if(.not.inline) then
            if(.not.take(p,'endforall')) then
                call expect(p,'end');call expect(p,'forall')
            end if
            call finish_line(p)
        end if
        if(p%diag%code/=0) return
        p%prog%code(entry)%target=p%prog%nc+1
        do j=first_expr,p%prog%ne
            if(p%prog%expressions(j)%kind==ex_gather_rows) then
                call error(p,'Vector row gathering inside WHERE/FORALL is unsupported');return
            end if
            if(p%prog%expressions(j)%kind/=ex_user_call) cycle
            k=p%prog%expressions(j)%symbol
            if(.not.p%prog%procedures(k)%is_pure) then
                call error(p,'FORALL expressions may reference only PURE user functions');return
            end if
        end do
    end subroutine

    recursive subroutine do_statement(p,construct_name)
        type(parser_t),intent(inout)::p
        character(*),optional,intent(in)::construct_name
        type(instruction_t)::ins
        integer::s,a,b,c,entry,j,k
        character(63)::end_name
        call enter_block(p)
        if(p%diag%code/=0) return
        ins%line=p%tokens(p%p)%line; ins%column=p%tokens(p%p)%column
        if(present(construct_name)) ins%construct_name=construct_name
        if(len_trim(ins%construct_name)>0) then
            do k=1,p%named_do_count
                if(p%named_do_scope(k)/=p%scope) cycle
                if(p%named_do_names(k)==ins%construct_name) then
                    call error(p,'DO construct names must be distinct within a scoping unit');return
                end if
            end do
            if(p%named_do_count==max_instructions) then
                call error(p,'Named DO construct limit exceeded');return
            end if
            p%named_do_count=p%named_do_count+1
            p%named_do_names(p%named_do_count)=ins%construct_name
            p%named_do_scope(p%named_do_count)=p%scope
        end if
        p%p=p%p+1
        s=0;a=0;b=0;c=0
        if(p%tokens(p%p)%kind==tk_eol) then
            ! No loop-control: the instruction budget bounds execution.
            ins%d=1
            call finish_line(p)
        else if(p%tokens(p%p)%kind==tk_name.and.peek(p)=='while'.and.p%tokens(p%p+1)%text/='=') then
            ins%d=2
            p%p=p%p+1
            call expect(p,'(');a=expression(p,0);call expect(p,')')
            if(p%diag%code/=0) return
            if(p%prog%expressions(a)%typ/=ty_logical.or.p%prog%expressions(a)%rank/=0) then
                call error(p,'DO WHILE condition must be scalar LOGICAL');return
            end if
            call finish_line(p)
        else
            s=find_symbol(p,peek(p))
            if(s==0) then
                call error(p,'DO requires a declared INTEGER scalar'); return
            end if
            if(p%prog%symbols(s)%typ/=ty_integer.or.p%prog%symbols(s)%rank/=0.or. &
               (p%prog%symbols(s)%real_kind/=4.and.p%prog%symbols(s)%real_kind/=8)) then
                call error(p,'DO variable must be an INTEGER scalar of kind 4 or 8'); return
            end if
            if(p%prog%symbols(s)%dummy_intent==1) then
                call error(p,'INTENT(IN) dummy cannot be a DO variable'); return
            end if
            if(p%prog%symbols(s)%is_parameter) then
                call error(p,'DO variable cannot be a PARAMETER constant'); return
            end if
            if(any(p%active_do==s)) then
                call error(p,'A nested DO cannot redefine an active DO variable'); return
            end if
            p%p=p%p+1; call expect(p,'=')
            a=expression(p,0); call expect(p,','); b=expression(p,0); c=0
            if(take(p,',')) c=expression(p,0)
            call finish_line(p)
            if(p%diag%code/=0) return
            if(p%prog%expressions(a)%typ/=ty_integer.or.p%prog%expressions(b)%typ/=ty_integer.or. &
               p%prog%expressions(a)%rank/=0.or.p%prog%expressions(b)%rank/=0) &
                call error(p,'DO bounds must be scalar INTEGER')
            if(c/=0) then
                if(p%prog%expressions(c)%typ/=ty_integer.or.p%prog%expressions(c)%rank/=0) &
                    call error(p,'DO step must be scalar INTEGER')
            end if
        end if
        ins%op=op_do; ins%symbol=s; ins%a=a; ins%b=b; ins%c=c; entry=emit(p,ins)
        if(p%diag%code/=0) return
        p%active_do(p%block_depth)=s
        p%active_do_entry(p%block_depth)=entry
        p%active_do_name(p%block_depth)=ins%construct_name
        call statements(p)
        if(.not.take(p,'enddo')) then
            call expect(p,'end');call expect(p,'do')
        end if
        end_name=''
        if(p%tokens(p%p)%kind==tk_name) call read_name(p,end_name)
        if(end_name/=ins%construct_name) call error(p,'END DO construct name does not match DO')
        call finish_line(p)
        if(p%diag%code/=0) return
        ins%op=op_next; ins%a=entry; ins%b=0; ins%c=0; ins%target=entry+1
        j=emit(p,ins)
        p%prog%code(entry)%target=p%prog%nc+1
        do k=entry+1,j-1
            if(p%prog%code(k)%a/=entry) cycle
            if(p%prog%code(k)%op==op_exit) p%prog%code(k)%target=j+1
            if(p%prog%code(k)%op==op_cycle) p%prog%code(k)%target=j
        end do
        p%active_do(p%block_depth)=0
        p%active_do_entry(p%block_depth)=0
        p%active_do_name(p%block_depth)=''
        p%block_depth=p%block_depth-1
    end subroutine
    subroutine enter_block(p)
        type(parser_t),intent(inout)::p
        if(p%block_depth==max_depth) then
            call error(p,'Block nesting limit exceeded'); return
        end if
        p%block_depth=p%block_depth+1
    end subroutine

    recursive integer function expression(p,minprec) result(root)
        type(parser_t),intent(inout)::p
        integer,intent(in)::minprec
        type(expr_t)::e
        integer::rhs,prec,nextprec,ltyp,rtyp,f
        character(:),allocatable::op
        root=0
        if(p%diag%code/=0) return
        p%depth=p%depth+1
        if(p%depth>max_depth) then
            call error(p,'Expression nesting limit exceeded'); p%depth=p%depth-1; return
        end if
        op=peek(p)
        if(p%tokens(p%p)%kind==tk_op.and.custom_operator(op)) then
            e%line=p%tokens(p%p)%line;e%column=p%tokens(p%p)%column
            p%p=p%p+1
            ! A defined unary operator binds more tightly than exponentiation.
            rhs=primary(p)
            if(p%diag%code==0) then
                f=find_operator(p,op,[rhs])
                if(f==0) call error(p,'No matching accessible defined operator: '//op)
                if(p%diag%code==0) then
                    e%kind=ex_user_call;e%op=op;e%symbol=f;e%args=[rhs]
                    call user_call_type(p,e)
                    root=add_expr(p,e)
                end if
            end if
        else if(p%tokens(p%p)%kind==tk_op.and.(op=='+'.or.op=='-'.or.op=='.not.')) then
            if((op=='+'.or.op=='-').and.minprec>7) then
                call error(p,'Unary sign after an operator requires parentheses'); p%depth=p%depth-1; return
            end if
            if(op=='.not.'.and.minprec>4) then
                call error(p,'Misplaced logical negation'); p%depth=p%depth-1; return
            end if
            e%line=p%tokens(p%p)%line; e%column=p%tokens(p%p)%column
            p%p=p%p+1; nextprec=9
            if(op=='.not.') then
                nextprec=4
                if(p%tokens(p%p)%kind==tk_op.and.peek(p)=='.not.') then
                    call error(p,'Consecutive .NOT. operators require parentheses')
                    p%depth=p%depth-1; return
                end if
            end if
            rhs=expression(p,nextprec)
            if(p%diag%code==0) then
                e%kind=ex_unary; e%op=op; e%left=rhs; e%typ=p%prog%expressions(rhs)%typ
                e%real_kind=p%prog%expressions(rhs)%real_kind
                call merge_shape(p,e,rhs)
                if(op=='.not.') then
                    if(e%typ/=ty_logical) call error(p,'.NOT. requires LOGICAL operand')
                else
                    if(.not.numeric(e%typ)) call error(p,'Unary sign requires numeric operand')
                end if
                root=add_expr(p,e)
            end if
        else
            root=primary(p)
        end if
        do while(p%diag%code==0)
            ! Quoted operator spellings are CHARACTER data, never syntax.
            if(p%tokens(p%p)%kind/=tk_op) exit
            op=peek(p)
            if(op=='/'.and.p%tokens(p%p+1)%text==')') exit
            prec=precedence(op)
            if(prec<minprec) exit
            e=expr_t(); e%line=p%tokens(p%p)%line; e%column=p%tokens(p%p)%column
            p%p=p%p+1; nextprec=prec+1
            if(op=='**') nextprec=prec
            rhs=expression(p,nextprec)
            if(p%diag%code/=0) exit
            e%kind=ex_binary; e%op=op; e%left=root; e%right=rhs
            ltyp=p%prog%expressions(root)%typ; rtyp=p%prog%expressions(rhs)%typ
            if(custom_operator(op).or.is_derived_type(ltyp).or.is_derived_type(rtyp).or. &
               (op=='+'.and.(ltyp==ty_character.or.rtyp==ty_character))) then
                f=find_operator(p,op,[root,rhs])
                if(p%diag%code/=0) exit
                if(f==0) then
                    call error(p,'No matching accessible defined operator: '//op); exit
                end if
                e%kind=ex_user_call;e%symbol=f;e%args=[root,rhs]
                call user_call_type(p,e)
                root=add_expr(p,e);cycle
            end if
            call merge_shape(p,e,root)
            call merge_shape(p,e,rhs)
            select case(prec)
            case(7,8,10)
                if(.not.numeric(ltyp).or..not.numeric(rtyp)) call error(p,'Arithmetic requires numeric operands')
                e%typ=ty_integer
                if(ltyp==ty_real.or.rtyp==ty_real) e%typ=ty_real
                if(ltyp==e%typ) e%real_kind=p%prog%expressions(root)%real_kind
                if(rtyp==e%typ) e%real_kind=max(e%real_kind,p%prog%expressions(rhs)%real_kind)
            case(6)
                if(ltyp/=ty_character.or.rtyp/=ty_character) &
                    call error(p,'Concatenation requires CHARACTER operands')
                e%typ=ty_character
                if(p%prog%expressions(root)%character_len>=0.and.p%prog%expressions(rhs)%character_len>=0) then
                    e%character_len=p%prog%expressions(root)%character_len+p%prog%expressions(rhs)%character_len
                    if(e%character_len>65536) call error(p,'CHARACTER concatenation length limit exceeded (65536)')
                end if
            case(5)
                if((.not.numeric(ltyp).or..not.numeric(rtyp)).and. &
                   .not.(ltyp==ty_character.and.rtyp==ty_character)) &
                    call error(p,'Comparison requires numeric operands or CHARACTER operands')
                e%typ=ty_logical
            case default
                if(ltyp/=ty_logical.or.rtyp/=ty_logical) call error(p,'Logical operator requires LOGICAL operands')
                e%typ=ty_logical
            end select
            root=add_expr(p,e)
        end do
        p%depth=p%depth-1
    end function
    integer function precedence(op) result(p)
        character(*),intent(in)::op
        p=-1
        if(custom_operator(op)) p=0
        select case(op)
        case('.eqv.','.neqv.'); p=1
        case('.or.'); p=2
        case('.and.'); p=3
        case('==','/=','<','<=','>','>=','.eq.','.ne.','.lt.','.le.','.gt.','.ge.'); p=5
        case('//'); p=6
        case('+','-'); p=7
        case('*','/'); p=8
        case('**'); p=10
        end select
    end function
    logical function custom_operator(op) result(custom)
        character(*),intent(in)::op
        integer::j,n
        n=len_trim(op);custom=.false.
        ! The retained producer operator stack has 16-character storage.
        if(n<3.or.n>16) return
        if(op(1:1)/='.'.or.op(n:n)/='.') return
        do j=2,n-1
            if(.not.letter(op(j:j))) return
        end do
        select case(op)
        case('.true.','.false.','.and.','.or.','.not.','.eqv.','.neqv.', &
             '.eq.','.ne.','.lt.','.le.','.gt.','.ge.')
            return
        end select
        custom=.true.
    end function
    recursive integer function primary(p) result(root)
        type(parser_t),intent(inout)::p
        type(expr_t)::e
        integer::k,ios,a,pos,rkind,t,c,base,owner_level
        character(:),allocatable::s,suffix
        real(real32)::single_value
        root=0
        if(p%diag%code/=0) return
        e%line=p%tokens(p%p)%line; e%column=p%tokens(p%p)%column
        s=peek(p); k=p%tokens(p%p)%kind
        if(take(p,'[')) then
            root=array_constructor(p,e,.false.);return
        end if
        if(take(p,'(')) then
            if(take(p,'/')) then
                root=array_constructor(p,e,.true.);return
            end if
            root=expression(p,0); call expect(p,')')
            if(p%diag%code==0) p%prog%expressions(root)%parenthesized=.true.
            return
        end if
        rkind=4
        if(k==tk_integer.or.k==tk_real) then
            pos=index(s,'_')
            if(pos>0) then
                suffix=s(pos+1:); s=s(:pos-1)
                if(index(lower(s),'d')>0) then
                    call error(p,'D exponent literals cannot have an explicit kind suffix'); return
                end if
                if(len(suffix)==0) then
                    call error(p,'Missing literal kind suffix'); return
                end if
                if(digit(suffix(1:1))) then
                    read(suffix,*,iostat=ios) rkind
                    if(ios/=0) then
                        call error(p,'Invalid literal kind suffix'); return
                    end if
                else
                    a=find_symbol(p,lower(suffix))
                    if(a==0) then
                        call error(p,'Undefined literal kind parameter: '//suffix); return
                    end if
                    if(.not.p%prog%symbols(a)%is_parameter.or.p%prog%symbols(a)%typ/=ty_integer) then
                        call error(p,'Literal kind suffix must be an INTEGER PARAMETER'); return
                    end if
                    rkind=int(p%prog%symbols(a)%constant_value%i)
                end if
            else if(index(lower(s),'d')>0) then
                rkind=8
            end if
            if(rkind/=4.and.rkind/=8) then
                call error(p,'Only REAL literal kinds 4 and 8 are supported'); return
            end if
        end if
        select case(k)
        case(tk_integer)
            e%kind=ex_literal; e%typ=ty_integer; e%value%tag=ty_integer
            read(s,*,iostat=ios) e%value%i
            if(ios/=0) then
                call error(p,'INTEGER literal out of range'); return
            end if
            e%real_kind=rkind; e%value%real_kind=rkind
            if(rkind==4.and.e%value%i>2147483647_int64) then
                call error(p,'Default INTEGER literal exceeds 32-bit range'); return
            end if
        case(tk_real)
            e%kind=ex_literal; e%typ=ty_real; e%value%tag=ty_real
            e%real_kind=rkind; e%value%real_kind=rkind
            if(rkind==4) then
                read(s,*,iostat=ios) single_value
                e%value%r=real(single_value,real64)
            else
                read(s,*,iostat=ios) e%value%r
            end if
            if(ios/=0) then
                call error(p,'REAL literal out of range'); return
            end if
            if(.not.ieee_is_finite(e%value%r)) then
                call error(p,'Non-finite REAL literal'); return
            end if
        case(tk_string)
            e%kind=ex_literal; e%typ=ty_character; e%value%tag=ty_character; e%value%s=s
            if(p%tokens(p%p+1)%text=='(') then
                p%p=p%p+2
                e%kind=ex_substring
                if(peek(p)/=':') e%left=section_integer(p)
                if(p%diag%code/=0) return
                call expect(p,':')
                if(p%diag%code/=0) return
                if(peek(p)/=')') e%right=section_integer(p)
                if(p%diag%code/=0) return
                call expect(p,')')
                root=add_expr(p,e);return
            end if
        case(tk_name)
            p%p=p%p+1
            do owner_level=p%constructor_depth,1,-1
                if(s/=p%constructor_names(owner_level)) cycle
                if(peek(p)=='('.or.peek(p)=='%') then
                    call error(p,'Constructor implied-DO index is a scalar INTEGER value');return
                end if
                e%kind=ex_constructor_index;e%typ=ty_integer
                e%symbol=p%constructor_symbols(owner_level)
                e%real_kind=p%prog%symbols(e%symbol)%real_kind
                e%constructor_owner=p%constructor_owners(owner_level)
                root=add_expr(p,e);return
            end do
            e%symbol=find_symbol(p,s)
            if(take(p,'(')) then
                if(e%symbol/=0) then
                    e%left=array_subscript(p,e%symbol,e%right,e%third)
                    if(p%diag%code/=0) return
                    if(p%prog%expressions(e%left)%kind==ex_gather_rows) then
                        root=e%left;return
                    end if
                    if(p%prog%expressions(e%left)%kind==ex_section.or. &
                       p%prog%expressions(e%left)%kind==ex_substring) then
                        root=e%left; return
                    end if
                    e%kind=ex_element; e%typ=p%prog%symbols(e%symbol)%typ
                    e%real_kind=p%prog%symbols(e%symbol)%real_kind
                    root=add_expr(p,e)
                    if(take(p,'(')) root=element_substring(p,root)
                    return
                end if
                t=find_derived(p,s)
                if(t/=0) then
                    e%kind=ex_record;e%typ=ty_derived_base+t;allocate(e%args(0))
                    if(peek(p)/=')') then
                        do while(p%diag%code==0)
                            a=expression(p,0);if(p%diag%code/=0) return
                            c=size(e%args)+1
                            if(c>p%prog%derived_types(t)%ncomponents) then
                                call error(p,'Too many structure constructor arguments');return
                            end if
                            if(p%prog%expressions(a)%rank/=0) call error(p,'Structure components must be scalar')
                            call assignment_types(p,p%prog%derived_types(t)%component_types(c),p%prog%expressions(a)%typ)
                            e%args=[e%args,a]
                            if(.not.take(p,',')) exit
                        end do
                    end if
                    call expect(p,')')
                    do c=size(e%args)+1,p%prog%derived_types(t)%ncomponents
                        if(p%prog%derived_types(t)%component_initializers(c)==0) &
                            call error(p,'Omitted structure component requires a default initializer')
                    end do
                    root=add_expr(p,e);return
                end if
                e%kind=ex_call; e%op=s
                e%generic_id=find_generic(p,s)
                if(e%generic_id==0) e%symbol=find_procedure(p,s)
                if(p%diag%code/=0) return
                call actual_arguments(p,e,s)
                if(p%diag%code/=0) return
                if(e%symbol/=0) then
                    e%kind=ex_user_call; e%op=''
                    call user_call_type(p,e)
                else
                    call call_type(p,e,s)
                end if
                root=add_expr(p,e); return
            end if
            e%symbol=find_symbol(p,s)
            if(e%symbol==0) then
                call error(p,'Undeclared variable: '//s); return
            end if
            e%rank=p%prog%symbols(e%symbol)%rank
            if(e%rank==1) e%extent=max(0_int64, &
                p%prog%symbols(e%symbol)%upper_bound-p%prog%symbols(e%symbol)%lower_bound+1_int64)
            if(e%rank>=2) then
                e%dims=symbol_dims(p%prog%symbols(e%symbol)); e%extent=shape_size(e%dims)
            end if
            if(e%rank>0.and.(p%prog%symbols(e%symbol)%assumed_shape.or.p%prog%symbols(e%symbol)%is_automatic.or.p%prog%symbols(e%symbol)%is_allocatable.or.p%prog%symbols(e%symbol)%is_pointer)) then
                e%extent=-1_int64
                if(e%rank>=2) e%dims=-1_int64
            end if
            e%kind=ex_variable; e%typ=p%prog%symbols(e%symbol)%typ
            e%real_kind=p%prog%symbols(e%symbol)%real_kind
            root=add_expr(p,e)
            if(take(p,'%')) then
                if(e%typ==ty_character.and.peek(p)=='len') then
                    if(p%tokens(p%p+1)%text=='(') then
                        call error(p,'CHARACTER %LEN inquiry takes no arguments');return
                    end if
                    base=root
                    e=expr_t(kind=ex_call,op='len',args=[base], &
                        line=p%tokens(p%p)%line,column=p%tokens(p%p)%column)
                    p%p=p%p+1
                    call call_type(p,e,'len')
                    root=add_expr(p,e);return
                end if
                if(p%tokens(p%p+1)%text=='(') then
                    t=e%typ-ty_derived_base;c=find_binding(p,e%typ,peek(p));if(p%diag%code/=0) return
                    base=root;e=expr_t(kind=ex_user_call,symbol=p%prog%derived_types(t)%binding_procedures(c), &
                        bound_type=t,bound_binding=c,line=e%line,column=e%column)
                    p%p=p%p+1;call expect(p,'(');call actual_arguments(p,e,'',base)
                    call user_call_type(p,e);root=add_expr(p,e);return
                end if
                c=find_component(p,e%typ,peek(p));if(p%diag%code/=0) return
                t=e%typ-ty_derived_base;base=root
                e=expr_t(kind=ex_component,left=base,symbol=c, &
                    typ=p%prog%derived_types(t)%component_types(c), &
                    real_kind=p%prog%derived_types(t)%component_kinds(c), &
                    character_len=p%prog%derived_types(t)%component_lengths(c), &
                    line=p%tokens(p%p)%line,column=p%tokens(p%p)%column)
                p%p=p%p+1;root=add_expr(p,e)
            end if
            return
        case(tk_op)
            if(s/='.true.'.and.s/='.false.') then
                call error(p,'Expected expression operand, found '//s); return
            end if
            e%kind=ex_literal; e%typ=ty_logical; e%value%tag=ty_logical; e%value%l=s=='.true.'
        case default
            call error(p,'Expected expression operand, found '//s); return
        end select
        p%p=p%p+1; root=add_expr(p,e)
    end function
    recursive integer function constructor_item(p,typed_character,character_len) result(root)
        type(parser_t),intent(inout)::p
        logical,intent(in)::typed_character
        integer,intent(in)::character_len
        type(expr_t)::e
        type(value_t)::step_value
        type(diagnostic_t)::step_diag
        integer::j,level,control,s,a,n,slot,known_length
        root=0;known_length=-1
        if(.not.output_do_ahead(p)) then
            root=expression(p,0);return
        end if
        if(p%constructor_depth>=max_constructor_do_depth) then
            call error(p,'Constructor implied-DO nesting limit exceeded (8)');return
        end if
        level=0;control=0
        do j=p%p,p%n-2
            if(p%tokens(j)%kind/=tk_op) cycle
            if(p%tokens(j)%text=='(') level=level+1
            if(p%tokens(j)%text==')') level=level-1
            if(level/=1.or.p%tokens(j)%text/=',') cycle
            if(p%tokens(j+1)%kind==tk_name.and.p%tokens(j+2)%text=='=') then
                control=j+1;exit
            end if
        end do
        if(control==0) then
            call error(p,'Invalid constructor implied-DO control');return
        end if
        s=find_symbol(p,p%tokens(control)%text)
        if(s==0) then
            call error(p,'Constructor implied-DO requires a declared scalar INTEGER index');return
        end if
        associate(v=>p%prog%symbols(s))
        if(v%typ/=ty_integer.or.v%rank/=0.or.v%is_parameter.or.v%is_intrinsic.or. &
           (v%real_kind/=4.and.v%real_kind/=8)) then
            call error(p,'Constructor implied-DO requires a non-PARAMETER scalar INTEGER index');return
        end if
        end associate
        if(any(p%constructor_names(:p%constructor_depth)==p%tokens(control)%text)) then
            call error(p,'Nested constructor implied-DO indices must have distinct names');return
        end if
        e%kind=ex_constructor_do;e%symbol=s;e%scope=p%scope;e%rank=1;e%extent=-1_int64
        e%line=p%tokens(p%p)%line;e%column=p%tokens(p%p)%column
        root=add_expr(p,e)
        if(p%diag%code/=0) return
        p%constructor_depth=p%constructor_depth+1;slot=p%constructor_depth
        p%constructor_owners(slot)=root;p%constructor_symbols(slot)=s
        p%constructor_names(slot)=p%tokens(control)%text
        allocate(e%args(0))
        if(typed_character) then
            e%typ=ty_character;e%character_len=character_len;e%op='character'
        end if
        call expect(p,'(')
        do while(p%diag%code==0.and.p%p<control)
            a=constructor_item(p,typed_character,character_len)
            if(p%diag%code/=0) exit
            n=size(e%args)
            if(n>=64) then
                call error(p,'Constructor implied-DO object limit exceeded (64)');exit
            end if
            associate(child=>p%prog%expressions(a))
            if(child%rank>1.or.child%typ<ty_integer.or.child%typ>ty_character) then
                call error(p,'Constructor implied-DO items must be intrinsic scalars or rank-one arrays');exit
            end if
            if(n==0.and..not.typed_character) then
                e%typ=child%typ;e%real_kind=child%real_kind;e%character_len=child%character_len
            end if
            if(child%typ/=e%typ.or.child%real_kind/=e%real_kind) then
                call error(p,'Constructor implied-DO items must have matching types and kinds');exit
            end if
            if(e%typ==ty_character.and..not.typed_character) then
                if(.not.constructor_length_item_supported(p%prog,a)) then
                    call error(p,'Untyped CHARACTER constructor requires descriptor-known item lengths');exit
                end if
                if(child%character_len>=0) then
                    if(known_length>=0.and.known_length/=child%character_len) then
                        call error(p,'Untyped CHARACTER constructor requires matching fixed item lengths');exit
                    end if
                    known_length=child%character_len
                end if
                if(child%character_len<0) e%character_len=-1
            end if
            end associate
            e%args=[e%args,a]
            call expect(p,',')
        end do
        if(p%diag%code==0) then
            p%p=control+1;call expect(p,'=')
            e%left=expression(p,0);call expect(p,',');e%right=expression(p,0)
            if(take(p,',')) e%stride=expression(p,0)
            call expect(p,')')
        end if
        p%constructor_depth=p%constructor_depth-1
        if(p%diag%code/=0) return
        p%prog%expressions(root)=e
        if(e%stride/=0) then
            if(bound_constant_expression(p%prog,e%stride,0)) then
                call evaluate_constant(p%prog,e%stride,step_value,step_diag)
                if(step_diag%code==0.and.step_value%tag==ty_integer) then
                    if(step_value%i==0_int64) then
                        call error(p,'Constructor implied-DO step is zero');return
                    end if
                end if
            end if
        end if
        if(slot==1) then
            if(.not.valid_constructor_do(p%prog,root)) &
                call error(p,'Invalid constructor implied-DO index scope, controls or body')
        end if
    end function
    recursive integer function array_constructor(p,e,slash) result(root)
        type(parser_t),intent(inout)::p
        type(expr_t),intent(inout)::e
        logical,intent(in)::slash
        integer::a,n,t,k,le,j,level,known_length
        integer(int64)::amount
        logical::typed
        root=0;known_length=-1;e%kind=ex_constructor;e%rank=1;e%extent=0_int64
        allocate(e%args(0))
        typed=peek(p)=='character'
        t=0
        select case(peek(p))
        case('integer');t=ty_integer
        case('real');t=ty_real
        case('logical');t=ty_logical
        case('character');t=ty_character
        end select
        ! INTEGER/REAL/LOGICAL are not reserved names. Recognize a type-spec
        ! only when the complete selector is followed by the explicit ::.
        if(t>0.and.t/=ty_character) then
            j=p%p+1;level=0
            if(p%tokens(j)%text=='(') then
                do while(j<size(p%tokens))
                    if(p%tokens(j)%text=='(') level=level+1
                    if(p%tokens(j)%text==')') level=level-1
                    j=j+1
                    if(level==0) exit
                end do
            end if
            typed=p%tokens(j)%text=='::'
        end if
        if(typed) then
            call type_specification(p,t,k,le)
            if(p%diag%code/=0) return
            e%typ=t
            if(t==ty_character) then
                if(k<0) then
                    call error(p,'Constructor CHARACTER length must be fixed');return
                end if
                e%character_len=k;e%length_expr=le;e%op='character'
            else
                if(le>0) then
                    if(p%prog%expressions(le)%kind/=ex_literal.and.p%prog%expressions(le)%kind/=ex_variable) then
                        call error(p,'Empty constructor KIND requires a literal or named INTEGER parameter');return
                    end if
                end if
                e%real_kind=k;e%constructor_kind_expr=le
                select case(t)
                case(ty_integer);e%op='integer'
                case(ty_real);e%op='real'
                case(ty_logical);e%op='logical'
                end select
            end if
            call expect(p,'::')
            if(t/=ty_character.and.peek(p)/=']'.and..not.(slash.and.peek(p)=='/')) then
                call error(p,'Nonempty typed numeric/logical constructors are unsupported');return
            end if
        end if
        do while(p%diag%code==0)
            if(typed.and.p%tokens(p%p)%kind==tk_op.and.(peek(p)==']'.or.(slash.and.peek(p)=='/'))) then
                if(size(e%args)>0) call error(p,'Trailing comma in array constructor')
                exit
            end if
            a=constructor_item(p,typed.and.e%typ==ty_character,e%character_len)
            if(p%diag%code/=0) return
            n=size(e%args)
            if(n>=max_expressions) then
                call error(p,'Array constructor item limit exceeded');return
            end if
            associate(child=>p%prog%expressions(a))
            if(child%rank>1) then
                call error(p,'Constructor items must be intrinsic scalars or rank-one arrays');return
            end if
            if(n==0.and..not.typed) then
                e%typ=child%typ;e%real_kind=child%real_kind;e%character_len=child%character_len
            else if(child%typ/=e%typ.or.((e%typ==ty_real.or.e%typ==ty_integer).and.child%real_kind/=e%real_kind)) then
                call error(p,'Array constructor items must have matching types and REAL kinds');return
            end if
            if(e%typ==ty_character.and..not.typed) then
                if(.not.constructor_length_item_supported(p%prog,a)) then
                    call error(p,'Untyped CHARACTER constructor requires descriptor-known item lengths');return
                end if
                if(child%character_len>=0) then
                    if(known_length>=0.and.known_length/=child%character_len) then
                        call error(p,'Untyped CHARACTER constructor requires matching fixed item lengths');return
                    end if
                    known_length=child%character_len
                end if
                if(child%character_len<0) e%character_len=-1
            end if
            amount=1_int64
            if(child%rank==1) amount=child%extent
            if(amount<0.or.e%extent<0) then
                e%extent=-1_int64
            else
                e%extent=e%extent+amount
                if(e%extent>max_array_elements) then
                    call error(p,'Array constructor element limit exceeded');return
                end if
            end if
            end associate
            e%args=[e%args,a]
            if(.not.take(p,',')) exit
        end do
        if(slash) then
            call expect(p,'/');call expect(p,')')
        else
            call expect(p,']')
        end if
        root=add_expr(p,e)
    end function
    ! Elemental operations accept scalar expansion or conformable rank-one
    ! operands. Extents, not the declared lower bounds, define conformance.
    ! Retain constraints from known-sized descendants even when another child
    ! makes the result dynamic (e.g. MAX(a3, section, a4)).
    recursive integer(int64) function known_extent(p,e,dim) result(n)
        type(parser_t),intent(in)::p
        type(expr_t),intent(in)::e
        integer,intent(in),optional::dim
        integer(int64)::other
        integer::j
        n=-1_int64
        select case(e%kind)
        case(ex_variable,ex_constructor)
            if(e%rank>0) n=e%extent
            if(present(dim).and.e%rank>=2) n=e%dims(dim)
        case(ex_unary,ex_binary)
            n=known_extent(p,p%prog%expressions(e%left),dim)
            if(e%kind==ex_binary) then
                other=known_extent(p,p%prog%expressions(e%right),dim)
                if(n== -2_int64.or.other== -2_int64) then
                    n=-2_int64
                else if(n>=0.and.other>=0.and.n/=other) then
                    n=-2_int64
                else if(n<0) then
                    n=other
                end if
            end if
        case(ex_call,ex_user_call)
            if(e%kind==ex_user_call) then
                if(.not.p%prog%procedures(e%symbol)%is_elemental) return
            end if
            if(e%op=='size'.or.e%op=='kind'.or.e%op=='new_line'.or.e%op=='len'.or.e%op=='allocated'.or.e%op=='associated'.or. &
               (e%kind==ex_call.and.is_numeric_model_inquiry(e%op))) return
            if(is_array_transform(e%op)) then
                if(e%rank>0) n=e%extent
                if(present(dim).and.e%rank>=2) n=e%dims(dim)
                return
            end if
            if(.not.allocated(e%args)) return
            do j=1,size(e%args)
                if(e%args(j)==0) cycle
                other=known_extent(p,p%prog%expressions(e%args(j)),dim)
                if(n== -2_int64.or.other== -2_int64) then
                    n=-2_int64; return
                else if(n>=0.and.other>=0.and.n/=other) then
                    n=-2_int64; return
                else if(n<0) then
                    n=other
                end if
            end do
        end select
    end function
    subroutine merge_shape(p,e,operand)
        type(parser_t),intent(inout)::p
        type(expr_t),intent(inout)::e
        integer,intent(in)::operand
        if(p%diag%code/=0) return
        if(known_extent(p,e)== -2_int64.or.known_extent(p,e,1)== -2_int64.or. &
           known_extent(p,e,2)== -2_int64.or.known_extent(p,e,3)== -2_int64) then
            call error(p,'Array expression shapes do not conform'); return
        end if
        associate(child=>p%prog%expressions(operand))
        if(child%rank==0) return
        if(e%rank>0) then
            if(e%rank/=child%rank) then
                call error(p,'Array expression ranks do not conform'); return
            end if
            if(e%rank>=2) then
                if(any(e%dims>=0.and.child%dims>=0.and.e%dims/=child%dims)) then
                    call error(p,'Array expression shapes do not conform'); return
                end if
                where(e%dims<0.or.child%dims<0) e%dims=-1_int64
            end if
            if(e%extent>=0.and.child%extent>=0.and.e%extent/=child%extent) then
                call error(p,'Array expression shapes do not conform'); return
            end if
            if(e%extent<0.or.child%extent<0) then
                e%extent=-1_int64; return
            end if
        end if
        e%rank=child%rank
        e%extent=child%extent; e%dims=child%dims
        end associate
    end subroutine
    subroutine character_intrinsic_type(p,e)
        type(parser_t),intent(inout)::p
        type(expr_t),intent(inout)::e
        type(value_t)::kv
        integer::n,j,last_data,kind_arg
        n=size(e%args);kind_arg=0;last_data=n
        if(is_character_search_intrinsic(e%op)) then
            if(n<2.or.n>4.or.e%intrinsic_mask<3.or.e%intrinsic_mask>15) then
                call error(p,'Character search requires STRING, SUBSTRING/SET and optional BACK/KIND');return
            end if
            if(iand(e%intrinsic_mask,3)/=3.or.popcnt(e%intrinsic_mask)/=n) then
                call error(p,'Invalid character search argument association');return
            end if
            if(btest(e%intrinsic_mask,3)) then
                kind_arg=e%args(n);last_data=n-1
            end if
        else if(e%op=='len_trim') then
            if(n<1.or.n>2) then
                call error(p,'LEN_TRIM requires STRING and optional KIND');return
            end if
            if(n==2) kind_arg=e%args(2)
            last_data=1
        else
            if(n/=1) then
                call error(p,'ADJUSTL/ADJUSTR require one STRING argument');return
            end if
        end if
        do j=1,last_data
            if(is_character_search_intrinsic(e%op).and.j==3) then
                if(p%prog%expressions(e%args(j))%typ/=ty_logical) then
                    call error(p,'Character search BACK must be LOGICAL');return
                end if
            else if(p%prog%expressions(e%args(j))%typ/=ty_character) then
                call error(p,'Character intrinsic STRING/SUBSTRING/SET must be CHARACTER');return
            end if
            call merge_shape(p,e,e%args(j))
            if(p%diag%code/=0) return
        end do
        e%typ=ty_integer;e%real_kind=4
        if(kind_arg/=0) then
            if(p%prog%expressions(kind_arg)%typ/=ty_integer.or.p%prog%expressions(kind_arg)%rank/=0) then
                call error(p,'Character intrinsic KIND must be a scalar INTEGER constant');return
            end if
            call require_constant(p,kind_arg,'Character intrinsic KIND must be constant')
            call evaluate_constant(p%prog,kind_arg,kv,p%diag)
            if(p%diag%code/=0) return
            if(kv%i/=4.and.kv%i/=8) then
                call error(p,'Character intrinsic supports INTEGER kinds 4 and 8');return
            end if
            e%real_kind=int(kv%i)
        end if
        if(e%op=='adjustl'.or.e%op=='adjustr') then
            e%typ=ty_character;e%character_len=p%prog%expressions(e%args(1))%character_len
        end if
    end subroutine
    subroutine reject_optional_dim(p,index)
        type(parser_t),intent(inout)::p
        integer,intent(in)::index
        integer::symbol
        if(p%diag%code/=0) return
        associate(arg=>p%prog%expressions(index))
        if(arg%kind/=ex_variable.or.arg%parenthesized) return
        symbol=arg%symbol
        if(symbol<1.or.symbol>p%prog%ns) return
        if(p%prog%symbols(symbol)%is_optional) &
            call error(p,'DIM must not be a direct OPTIONAL dummy')
        end associate
    end subroutine
    subroutine pack_call_type(p,e)
        type(parser_t),intent(inout)::p
        type(expr_t),intent(inout)::e
        type(expr_t)::a,m,v,shape
        if(size(e%args)<2.or.size(e%args)>3) then
            call error(p,'PACK requires ARRAY, MASK and optional VECTOR');return
        end if
        a=p%prog%expressions(e%args(1));m=p%prog%expressions(e%args(2))
        if(a%rank<1.or.a%rank>2.or.a%typ<ty_integer.or.a%typ>ty_character) then
            call error(p,'PACK ARRAY must be a rank-one/rank-two intrinsic array');return
        end if
        if(a%typ==ty_character.and.a%character_len<0) then
            call error(p,'PACK requires a known CHARACTER length; deferred/runtime lengths are unsupported');return
        end if
        if(m%typ/=ty_logical) then
            call error(p,'PACK MASK must be LOGICAL');return
        end if
        shape=a
        call merge_shape(p,shape,e%args(2))
        if(p%diag%code/=0) return
        if(size(e%args)==3) then
            v=p%prog%expressions(e%args(3))
            if(v%rank/=1.or.v%typ/=a%typ.or.v%real_kind/=a%real_kind) then
                call error(p,'PACK VECTOR must be rank one with ARRAY type and kind');return
            end if
            if(a%typ==ty_character.and.v%character_len/=a%character_len) then
                call error(p,'PACK VECTOR and ARRAY CHARACTER lengths must match');return
            end if
        end if
        e%typ=a%typ;e%real_kind=a%real_kind;e%character_len=a%character_len
        e%rank=1;e%extent=-1_int64;e%dims=0_int64
    end subroutine
    subroutine reshape_call_type(p,e)
        type(parser_t),intent(inout)::p
        type(expr_t),intent(inout)::e
        integer::n,a,b,j
        n=size(e%args)
        if(n<2.or.n>4.or.e%intrinsic_mask<3.or.e%intrinsic_mask>15) then
            call error(p,'RESHAPE requires SOURCE, SHAPE and optional PAD, ORDER');return
        end if
        if(iand(e%intrinsic_mask,3)/=3.or.popcnt(e%intrinsic_mask)/=n) then
            call error(p,'Invalid RESHAPE argument association');return
        end if
        a=e%args(1);b=e%args(2)
        associate(src=>p%prog%expressions(a),sh=>p%prog%expressions(b))
        if(src%rank<1.or.src%rank>2.or.src%typ<ty_integer.or.src%typ>ty_character) then
            call error(p,'RESHAPE SOURCE must be a rank-one or rank-two intrinsic array');return
        end if
        if(sh%rank/=1.or.sh%typ/=ty_integer.or.sh%extent<1.or.sh%extent>2) then
            call error(p,'RESHAPE SHAPE must be an INTEGER vector of known size 1 or 2');return
        end if
        e%typ=src%typ;e%real_kind=src%real_kind;e%character_len=src%character_len
        if(src%typ==ty_character.and.src%character_len<0) then
            call error(p,'RESHAPE CHARACTER SOURCE requires a fixed length');return
        end if
        e%rank=int(sh%extent);e%extent=-1_int64
        if(e%rank>=2) e%dims=-1_int64
        if(btest(e%intrinsic_mask,2)) then
            b=e%args(3)
            associate(pad=>p%prog%expressions(b))
            if(pad%rank<1.or.pad%rank>2.or.pad%typ/=src%typ.or.pad%real_kind/=src%real_kind) then
                call error(p,'RESHAPE PAD must be an array matching SOURCE type and kind');return
            end if
            if(src%typ==ty_character.and.pad%character_len/=src%character_len) then
                call error(p,'RESHAPE PAD and SOURCE CHARACTER lengths must match');return
            end if
            end associate
        end if
        if(btest(e%intrinsic_mask,3)) then
            b=e%args(n)
            if(p%prog%expressions(b)%rank/=1.or.p%prog%expressions(b)%typ/=ty_integer) then
                call error(p,'RESHAPE ORDER must be an INTEGER vector');return
            end if
            if(p%prog%expressions(b)%extent>=0.and.p%prog%expressions(b)%extent/=e%rank) then
                call error(p,'RESHAPE ORDER size must match result rank');return
            end if
        end if
        end associate
        do j=3,n
            b=e%args(j)
            if(p%prog%expressions(b)%kind/=ex_variable) cycle
            if(p%prog%expressions(b)%parenthesized) cycle
            a=p%prog%expressions(b)%symbol
            if(p%prog%symbols(a)%is_optional) then
                call error(p,'RESHAPE direct OPTIONAL PAD or ORDER is unsupported');return
            end if
        end do
    end subroutine
    subroutine location_call_type(p,e)
        type(parser_t),intent(inout)::p
        type(expr_t),intent(inout)::e
        type(expr_t)::a,b,shape
        type(value_t)::kv
        integer::j,k,slot,s,off
        off=merge(1,0,e%op=='findloc')
        if(size(e%args)<1+off.or.size(e%args)>5+off.or.e%intrinsic_mask<1.or.e%intrinsic_mask>2**(5+off)-1) then
            call error(p,'Location intrinsic require ARRAY and optional DIM, MASK, KIND, BACK');return
        end if
        if(iand(e%intrinsic_mask,2**(1+off)-1)/=2**(1+off)-1.or.popcnt(e%intrinsic_mask)/=size(e%args)) then
            call error(p,'Invalid Location intrinsic argument association');return
        end if
        a=p%prog%expressions(e%args(1))
        if(a%rank<1.or.a%rank>2.or.a%typ<ty_integer.or.a%typ>merge(ty_character,ty_real,off==1)) then
            call error(p,'Location intrinsic ARRAY must be a supported rank-one/rank-two array');return
        end if
        if(off==1) then
            b=p%prog%expressions(e%args(2))
            if(b%rank/=0.or.b%typ/=a%typ) then
                call error(p,'FINDLOC VALUE must be scalar with the same intrinsic type as ARRAY');return
            end if
        end if
        e%typ=ty_integer;e%real_kind=4;e%rank=1;e%extent=int(a%rank,int64)
        if(btest(e%intrinsic_mask,1+off)) then
            e%rank=a%rank-1;e%extent=0_int64
            if(e%rank>0) e%extent=-1_int64
        end if
        j=1+off
        do slot=2,5
            if(.not.btest(e%intrinsic_mask,slot-1+off)) cycle
            j=j+1;k=e%args(j);b=p%prog%expressions(k)
            if(b%kind==ex_variable.and..not.b%parenthesized) then
                s=b%symbol
                if(p%prog%symbols(s)%is_optional) then
                    call error(p,'Location intrinsic direct OPTIONAL arguments are unsupported');return
                end if
            end if
            select case(slot)
            case(2,4)
                if(b%typ/=ty_integer.or.b%rank/=0) then
                    call error(p,'Location intrinsic DIM/KIND must be scalar INTEGER');return
                end if
                if(slot==4) then
                    call require_constant(p,k,'Location intrinsic KIND must be constant')
                    call evaluate_constant(p%prog,k,kv,p%diag)
                    if(p%diag%code/=0) return
                    if(kv%i/=4.and.kv%i/=8) then
                        call error(p,'Location intrinsic support INTEGER result kinds 4 and 8');return
                    end if
                    e%real_kind=int(kv%i)
                end if
            case(3)
                if(b%typ/=ty_logical) then
                    call error(p,'Location intrinsic MASK must be LOGICAL');return
                end if
                shape=a;call merge_shape(p,shape,k)
            case(5)
                if(b%typ/=ty_logical.or.b%rank/=0) then
                    call error(p,'Location intrinsic BACK must be scalar LOGICAL');return
                end if
            end select
            if(p%diag%code/=0) return
        end do
    end subroutine
    subroutine shape_call_type(p,e)
        type(parser_t),intent(inout)::p
        type(expr_t),intent(inout)::e
        type(value_t)::kv
        integer::n,a,b
        n=size(e%args)
        if(n<1.or.n>2) then
            call error(p,'SHAPE requires SOURCE and optional KIND');return
        end if
        a=e%args(1)
        if(p%prog%expressions(a)%rank<0.or.p%prog%expressions(a)%rank>3.or. &
           p%prog%expressions(a)%typ<ty_integer.or.p%prog%expressions(a)%typ>ty_character) then
            call error(p,'SHAPE supports intrinsic scalar and rank-one/two/three SOURCE');return
        end if
        e%typ=ty_integer;e%real_kind=4;e%rank=1
        e%extent=int(p%prog%expressions(a)%rank,int64);e%dims=0_int64
        if(n==2) then
            b=e%args(2)
            if(p%prog%expressions(b)%rank/=0.or.p%prog%expressions(b)%typ/=ty_integer) then
                call error(p,'SHAPE KIND must be scalar INTEGER constant');return
            end if
            call require_constant(p,b,'SHAPE KIND must be constant')
            call evaluate_constant(p%prog,b,kv,p%diag)
            if(p%diag%code/=0) return
            if(kv%i/=4.and.kv%i/=8) then
                call error(p,'SHAPE supports INTEGER kinds 4 and 8');return
            end if
            e%real_kind=int(kv%i)
        end if
    end subroutine
    subroutine eoshift_call_type(p,e)
        type(parser_t),intent(inout)::p
        type(expr_t),intent(inout)::e
        type(value_t)::v
        integer::a,b,d,n,j
        n=size(e%args)
        if(n<2.or.n>4.or.e%intrinsic_mask<3.or.e%intrinsic_mask>15) then
            call error(p,'EOSHIFT requires ARRAY, SHIFT and optional BOUNDARY/DIM');return
        end if
        if(iand(e%intrinsic_mask,3)/=3.or.popcnt(e%intrinsic_mask)/=n) then
            call error(p,'EOSHIFT argument slots differ');return
        end if
        a=e%args(1);b=e%args(2)
        associate(x=>p%prog%expressions(a),shift=>p%prog%expressions(b))
        if(x%rank<1.or.x%rank>2.or.x%typ<ty_integer.or.x%typ>ty_character.or. &
           (x%real_kind/=4.and.x%real_kind/=8).or. &
           ((x%typ==ty_character.or.x%typ==ty_logical).and.x%real_kind/=4)) then
            call error(p,'EOSHIFT supports intrinsic rank-one/rank-two ARRAY');return
        end if
        if(x%typ==ty_character.and.(x%character_len<0.or.x%character_len>65536)) then
            call error(p,'EOSHIFT CHARACTER ARRAY requires fixed length up to 65536');return
        end if
        if(shift%typ/=ty_integer.or.(shift%real_kind/=4.and.shift%real_kind/=8).or. &
           shift%rank<0.or.shift%rank>x%rank-1) then
            call error(p,'EOSHIFT SHIFT must be scalar INTEGER or rank-one INTEGER for a matrix');return
        end if
        if(btest(e%intrinsic_mask,2)) then
            associate(boundary=>p%prog%expressions(e%args(3)))
            if(boundary%typ/=x%typ.or.boundary%real_kind/=x%real_kind.or. &
               boundary%rank<0.or.boundary%rank>x%rank-1.or.boundary%character_len/=x%character_len) then
                call error(p,'EOSHIFT BOUNDARY type, kind, length or rank differs from ARRAY');return
            end if
            end associate
        end if
        d=1
        if(btest(e%intrinsic_mask,3)) then
            b=e%args(n)
            if(p%prog%expressions(b)%typ/=ty_integer.or.p%prog%expressions(b)%rank/=0.or. &
               (p%prog%expressions(b)%real_kind/=4.and.p%prog%expressions(b)%real_kind/=8)) then
                call error(p,'EOSHIFT DIM must be scalar INTEGER kind 4 or 8');return
            end if
            call reject_optional_dim(p,b)
            if(p%diag%code/=0)return
            d=0
            if(bound_constant_expression(p%prog,b,0)) then
                call evaluate_constant(p%prog,b,v,p%diag)
                if(p%diag%code/=0)return
                if(v%i<1.or.v%i>x%rank) then
                    call error(p,'EOSHIFT DIM is outside ARRAY rank');return
                end if
                d=int(v%i)
            end if
        end if
        if(d>0) then
            do j=2,2+merge(1,0,btest(e%intrinsic_mask,2))
                b=e%args(j)
                if(p%prog%expressions(b)%rank/=1)cycle
                if(x%dims(3-d)>=0.and.p%prog%expressions(b)%extent>=0.and. &
                   x%dims(3-d)/=p%prog%expressions(b)%extent) then
                    call error(p,'EOSHIFT SHIFT/BOUNDARY shape must match ARRAY with DIM removed');return
                end if
            end do
        end if
        e%typ=x%typ;e%real_kind=x%real_kind;e%character_len=x%character_len
        e%rank=x%rank;e%extent=x%extent;e%dims=x%dims
        end associate
    end subroutine
    subroutine cshift_call_type(p,e)
        type(parser_t),intent(inout)::p
        type(expr_t),intent(inout)::e
        type(value_t)::v
        integer::a,b,d,n
        n=size(e%args)
        if(n<2.or.n>3) then
            call error(p,'CSHIFT requires ARRAY, SHIFT and optional DIM');return
        end if
        if(e%intrinsic_mask/=2**n-1) then
            call error(p,'CSHIFT requires ARRAY, SHIFT and optional DIM');return
        end if
        a=e%args(1);b=e%args(2)
        associate(x=>p%prog%expressions(a),shift=>p%prog%expressions(b))
        if(x%rank<1.or.x%rank>2.or.x%typ<ty_integer.or.x%typ>ty_character) then
            call error(p,'CSHIFT supports intrinsic rank-one/rank-two ARRAY');return
        end if
        if(x%typ==ty_character.and.x%character_len<0) then
            call error(p,'CSHIFT CHARACTER ARRAY requires fixed length');return
        end if
        if(shift%typ/=ty_integer.or.(shift%real_kind/=4.and.shift%real_kind/=8).or. &
           shift%rank<0.or.shift%rank>x%rank-1) then
            call error(p,'CSHIFT SHIFT must be scalar INTEGER or rank-one INTEGER for a matrix');return
        end if
        d=1
        if(n==3) then
            associate(dim=>p%prog%expressions(e%args(3)))
            if(dim%typ/=ty_integer.or.dim%rank/=0.or.(dim%real_kind/=4.and.dim%real_kind/=8)) then
                call error(p,'CSHIFT DIM must be scalar INTEGER kind 4 or 8');return
            end if
            end associate
            call reject_optional_dim(p,e%args(3))
            if(p%diag%code/=0) return
            d=0
            if(bound_constant_expression(p%prog,e%args(3),0)) then
                call evaluate_constant(p%prog,e%args(3),v,p%diag)
                if(p%diag%code/=0) return
                if(v%i<1.or.v%i>x%rank) then
                    call error(p,'CSHIFT DIM is outside ARRAY rank');return
                end if
                d=int(v%i)
            end if
        end if
        if(d>0.and.shift%rank==1) then
            if(x%dims(3-d)>=0.and.shift%extent>=0.and.x%dims(3-d)/=shift%extent) then
                call error(p,'CSHIFT SHIFT shape must match ARRAY with DIM removed');return
            end if
        end if
        e%typ=x%typ;e%real_kind=x%real_kind;e%character_len=x%character_len
        e%rank=x%rank;e%extent=x%extent;e%dims=x%dims
        end associate
    end subroutine
    subroutine bounds_call_type(p,e)
        type(parser_t),intent(inout)::p
        type(expr_t),intent(inout)::e
        type(value_t)::v
        integer::a,b,n,r
        n=size(e%args)
        if(n<1.or.n>3.or.e%intrinsic_mask<1.or.e%intrinsic_mask>7)then
            call error(p,'LBOUND/UBOUND requires ARRAY and optional DIM/KIND');return
        end if
        if(.not.btest(e%intrinsic_mask,0).or.popcnt(e%intrinsic_mask)/=n)then
            call error(p,'Invalid LBOUND/UBOUND argument slots');return
        end if
        a=e%args(1);r=p%prog%expressions(a)%rank
        if(r<1.or.r>3.or.p%prog%expressions(a)%typ<ty_integer.or.p%prog%expressions(a)%typ>ty_character)then
            call error(p,'LBOUND/UBOUND requires intrinsic ARRAY of rank one through three');return
        end if
        e%typ=ty_integer;e%real_kind=4;e%rank=1;e%extent=int(r,int64);e%dims=0_int64
        if(btest(e%intrinsic_mask,1))then
            b=e%args(2)
            if(p%prog%expressions(b)%typ/=ty_integer.or.p%prog%expressions(b)%rank/=0.or. &
               (p%prog%expressions(b)%real_kind/=4.and.p%prog%expressions(b)%real_kind/=8))then
                call error(p,'LBOUND/UBOUND DIM must be scalar INTEGER kind 4 or 8');return
            end if
            call reject_optional_dim(p,b)
            if(p%diag%code/=0)return
            if(bound_constant_expression(p%prog,b,0))then
                call evaluate_constant(p%prog,b,v,p%diag)
                if(p%diag%code/=0)return
                if(v%i<1.or.v%i>r)then
                    call error(p,'LBOUND/UBOUND DIM outside ARRAY rank');return
                end if
            end if
            e%rank=0;e%extent=0_int64
        end if
        if(btest(e%intrinsic_mask,2))then
            b=e%args(n)
            if(p%prog%expressions(b)%typ/=ty_integer.or.p%prog%expressions(b)%rank/=0.or. &
               (p%prog%expressions(b)%real_kind/=4.and.p%prog%expressions(b)%real_kind/=8))then
                call error(p,'LBOUND/UBOUND KIND must be scalar INTEGER constant');return
            end if
            call require_constant(p,b,'LBOUND/UBOUND KIND must be constant')
            call evaluate_constant(p%prog,b,v,p%diag)
            if(p%diag%code/=0)return
            if(v%i/=4.and.v%i/=8)then
                call error(p,'LBOUND/UBOUND supports INTEGER kinds 4 and 8');return
            end if
            e%real_kind=int(v%i)
        end if
    end subroutine
    subroutine matrix_call_type(p,e)
        type(parser_t),intent(inout)::p
        type(expr_t),intent(inout)::e
        type(value_t)::v
        integer::a,b,n,r
        n=size(e%args)
        if(n<1.or.n>2.or.(e%op=='transpose'.and.n/=1))then
            call error(p,'TRANSPOSE requires MATRIX; NORM2 requires X and optional DIM');return
        end if
        a=e%args(1);r=p%prog%expressions(a)%rank
        if((p%prog%expressions(a)%real_kind/=4.and.p%prog%expressions(a)%real_kind/=8).or. &
           (p%prog%expressions(a)%typ/=ty_real.and.p%prog%expressions(a)%typ/=ty_integer))then
            call error(p,'TRANSPOSE/NORM2 requires supported numeric array kind 4 or 8');return
        end if
        if(e%op=='transpose')then
            if(r/=2)then
                call error(p,'TRANSPOSE requires rank-two INTEGER or REAL MATRIX');return
            end if
            e%rank=2
        else
            if(r<1.or.r>3.or.p%prog%expressions(a)%typ/=ty_real)then
                call error(p,'NORM2 requires REAL array X of rank one through three');return
            end if
            e%rank=0
            if(n==2)then
                b=e%args(2)
                if(p%prog%expressions(b)%typ/=ty_integer.or.p%prog%expressions(b)%rank/=0.or. &
                   (p%prog%expressions(b)%real_kind/=4.and.p%prog%expressions(b)%real_kind/=8))then
                    call error(p,'NORM2 DIM must be scalar INTEGER kind 4 or 8');return
                end if
                call reject_optional_dim(p,b)
                if(p%diag%code/=0)return
                if(bound_constant_expression(p%prog,b,0))then
                    call evaluate_constant(p%prog,b,v,p%diag)
                    if(p%diag%code/=0)return
                    if(v%i<1.or.v%i>r)then
                        call error(p,'NORM2 DIM is outside ARRAY rank');return
                    end if
                end if
                e%rank=r-1
            end if
        end if
        e%typ=p%prog%expressions(a)%typ;e%real_kind=p%prog%expressions(a)%real_kind
        e%extent=0_int64;e%dims=0_int64
        if(e%rank>0)e%extent=-1_int64
        if(e%rank>=2)e%dims=-1_int64
    end subroutine
    subroutine array_call_type(p,e,name)
        type(parser_t),intent(inout)::p
        type(expr_t),intent(inout)::e
        character(*),intent(in)::name
        type(expr_t)::a,b,m,shape
        type(value_t)::kv
        integer::n,mask,dim
        if(is_bounds_inquiry(name))then
            call bounds_call_type(p,e)
            return
        end if
        if(name=='transpose'.or.name=='norm2')then
            call matrix_call_type(p,e)
            return
        end if
        if(name=='eoshift') then
            call eoshift_call_type(p,e)
            return
        end if
        if(name=='cshift') then
            call cshift_call_type(p,e)
            return
        end if
        if(name=='shape') then
            call shape_call_type(p,e)
            return
        end if
        if(is_location_reduction(name)) then
            call location_call_type(p,e)
            return
        end if
        if(name=='pack') then
            call pack_call_type(p,e)
            return
        end if
        n=size(e%args)
        if(n<1.or.n>3) then
            call error(p,'Invalid array intrinsic argument count'); return
        end if
        a=p%prog%expressions(e%args(1))
        if(a%rank<1.or.a%rank>2) then
            call error(p,'Array intrinsic requires a rank-one or rank-two array'); return
        end if
        e%typ=a%typ; e%real_kind=a%real_kind
        if(is_logical_reduction(name)) then
            if(a%typ/=ty_logical.or.a%real_kind/=4.or.e%intrinsic_mask<1.or.e%intrinsic_mask>7) then
                call error(p,'Logical reduction requires LOGICAL array MASK');return
            end if
            if(.not.btest(e%intrinsic_mask,0).or.popcnt(e%intrinsic_mask)/=n.or. &
               (name/='count'.and.btest(e%intrinsic_mask,2))) then
                call error(p,'Invalid logical reduction argument association');return
            end if
            e%real_kind=4
            if(name=='count') e%typ=ty_integer
            if(btest(e%intrinsic_mask,1)) then
                b=p%prog%expressions(e%args(2))
                if(b%typ/=ty_integer.or.b%rank/=0) then
                    call error(p,'Logical reduction DIM must be scalar INTEGER');return
                end if
                call reject_optional_dim(p,e%args(2))
                if(p%diag%code/=0) return
                e%rank=a%rank-1
            end if
            if(btest(e%intrinsic_mask,2)) then
                b=p%prog%expressions(e%args(n))
                if(b%typ/=ty_integer.or.b%rank/=0) then
                    call error(p,'COUNT KIND must be scalar INTEGER constant');return
                end if
                call require_constant(p,e%args(n),'COUNT KIND must be constant')
                call evaluate_constant(p%prog,e%args(n),kv,p%diag)
                if(p%diag%code/=0) return
                if(kv%i/=4.and.kv%i/=8) then
                    call error(p,'COUNT supports INTEGER kinds 4 and 8');return
                end if
                e%real_kind=int(kv%i)
            end if
        else if(is_array_reduction(name)) then
            if(.not.numeric(a%typ)) then
                call error(p,'Reduction ARRAY must be INTEGER or REAL'); return
            end if
            mask=0;dim=0
            if(n>=2) then
                b=p%prog%expressions(e%args(2))
                if(b%typ==ty_integer) then
                    dim=2
                    if(b%rank/=0) then
                        call error(p,'Reduction DIM must be a scalar INTEGER'); return
                    end if
                    call reject_optional_dim(p,e%args(2))
                    if(p%diag%code/=0) return
                else if(b%typ==ty_logical.and.n==2) then
                    mask=2
                else
                    call error(p,'Reduction requires scalar INTEGER DIM or LOGICAL MASK'); return
                end if
            end if
            if(n==3) mask=3
            if(mask/=0) then
                m=p%prog%expressions(e%args(mask))
                if(m%typ/=ty_logical) then
                    call error(p,'Reduction MASK must be LOGICAL'); return
                end if
                shape=a
                call merge_shape(p,shape,e%args(mask))
                if(p%diag%code/=0) return
            end if
            if(dim/=0) e%rank=a%rank-1
        else
            if(n/=2) then
                call error(p,'DOT_PRODUCT/MATMUL require two arrays'); return
            end if
            b=p%prog%expressions(e%args(2))
            if(b%rank<1.or.b%rank>2) then
                call error(p,'DOT_PRODUCT/MATMUL require array arguments'); return
            end if
            if(a%typ==ty_logical.and.b%typ==ty_logical) then
                e%typ=ty_logical
            else if(numeric(a%typ).and.numeric(b%typ)) then
                e%typ=ty_integer; e%real_kind=4
                if(a%typ==ty_integer.and.b%typ==ty_integer) &
                    e%real_kind=max(a%real_kind,b%real_kind)
                if(a%typ==ty_real) then
                    e%typ=ty_real; e%real_kind=a%real_kind
                end if
                if(b%typ==ty_real) then
                    e%typ=ty_real; e%real_kind=max(e%real_kind,b%real_kind)
                end if
            else
                call error(p,'DOT_PRODUCT/MATMUL require numeric arrays or two LOGICAL arrays'); return
            end if
            if(name=='dot_product') then
                if(a%rank/=1.or.b%rank/=1) then
                    call error(p,'DOT_PRODUCT requires rank-one arrays'); return
                end if
                if(a%extent>=0.and.b%extent>=0.and.a%extent/=b%extent) then
                    call error(p,'DOT_PRODUCT vector sizes do not conform'); return
                end if
            else
                if(a%rank==1.and.b%rank==1) then
                    call error(p,'MATMUL requires at least one rank-two array'); return
                end if
                e%rank=a%rank+b%rank-2
            end if
        end if
        ! Runtime DIM and sections may change extents. Keep conservative shape
        ! caches; the adapter derives the same contract independently.
        if(e%rank>0) e%extent=-1_int64
        if(e%rank>=2) e%dims=-1_int64
    end subroutine
    subroutine repeat_call_type(p,e)
        type(parser_t),intent(inout)::p
        type(expr_t),intent(inout)::e
        type(value_t)::count
        type(diagnostic_t)::fold_diag
        integer::a,b,n
        if(size(e%args)/=2) then
            call error(p,'REPEAT requires STRING and NCOPIES');return
        end if
        a=e%args(1);b=e%args(2)
        if(p%prog%expressions(a)%typ/=ty_character.or.p%prog%expressions(a)%rank/=0.or. &
           p%prog%expressions(b)%typ/=ty_integer.or.p%prog%expressions(b)%rank/=0) then
            call error(p,'REPEAT requires scalar CHARACTER STRING and scalar INTEGER NCOPIES');return
        end if
        e%typ=ty_character;e%real_kind=4;e%rank=0;e%extent=0_int64;e%dims=0_int64;e%character_len=-1
        if(.not.bound_constant_expression(p%prog,b,0)) return
        call evaluate_constant(p%prog,b,count,fold_diag)
        if(fold_diag%code/=0) return
        if(count%i<0) then
            call error(p,'REPEAT NCOPIES must be nonnegative');return
        end if
        n=p%prog%expressions(a)%character_len
        if(count%i==0) then
            e%character_len=0
        else if(n>=0) then
            if(n>0) then
                if(count%i>65536_int64/int(n,int64)) then
                    call error(p,'REPEAT CHARACTER length limit exceeded (65536)');return
                end if
            end if
            e%character_len=int(int(n,int64)*count%i)
        end if
    end subroutine
    ! Keep numeric-model inquiries within KIND's existing intrinsic-expression
    ! boundary, but reject component operands during checking, before output.
    logical function model_argument_has_component(p,index) result(found)
        type(parser_t),intent(in)::p
        integer,intent(in)::index
        integer,allocatable::marks(:)
        allocate(marks(p%prog%ne),source=0)
        found=model_argument_component_tree(p,index,marks,0)
    end function
    recursive logical function model_argument_component_tree(p,index,marks,depth) result(found)
        type(parser_t),intent(in)::p
        integer,intent(in)::index,depth
        integer,intent(inout)::marks(:)
        integer::j,children(10)
        found=.true.
        if(index<1.or.index>p%prog%ne.or.depth>512) return
        if(marks(index)==1) return
        if(marks(index)==2) then
            found=.false.;return
        end if
        marks(index)=1
        associate(x=>p%prog%expressions(index))
        if(x%kind==ex_component) return
        children=[x%left,x%right,x%stride,x%left2,x%right2,x%stride2,x%left3,x%right3,x%stride3,x%third]
        do j=1,size(children)
            if(children(j)==0) cycle
            if(model_argument_component_tree(p,children(j),marks,depth+1)) return
        end do
        if(allocated(x%args)) then
            do j=1,size(x%args)
                if(x%args(j)==0) cycle
                if(model_argument_component_tree(p,x%args(j),marks,depth+1)) return
            end do
        end if
        end associate
        marks(index)=2;found=.false.
    end function
    subroutine model_decomposition_type(p,e)
        type(parser_t),intent(inout)::p
        type(expr_t),intent(inout)::e
        type(value_t)::kv
        integer::n,a,b
        n=size(e%args)
        if((e%op=='set_exponent'.and.n/=2).or.(e%op=='iachar'.and.(n<1.or.n>2)).or. &
           ((e%op=='fraction'.or.e%op=='exponent').and.n/=1)) then
            call error(p,'Invalid argument count for '//trim(e%op));return
        end if
        a=e%args(1)
        e%typ=ty_real;e%real_kind=p%prog%expressions(a)%real_kind
        if(e%op=='iachar') then
            if(p%prog%expressions(a)%typ/=ty_character.or.p%prog%expressions(a)%real_kind/=4) then
                call error(p,'IACHAR requires default CHARACTER C');return
            end if
            if(p%prog%expressions(a)%character_len>=0.and.p%prog%expressions(a)%character_len/=1) then
                call error(p,'IACHAR C must have length one');return
            end if
            e%typ=ty_integer;e%real_kind=4
            if(n==2) then
                b=e%args(2)
                if(p%prog%expressions(b)%typ/=ty_integer.or.p%prog%expressions(b)%rank/=0) then
                    call error(p,'IACHAR KIND must be scalar INTEGER constant');return
                end if
                call require_constant(p,b,'IACHAR KIND must be constant')
                call evaluate_constant(p%prog,b,kv,p%diag)
                if(p%diag%code/=0)return
                if(kv%i/=4.and.kv%i/=8) then
                    call error(p,'IACHAR supports INTEGER kinds 4 and 8');return
                end if
                e%real_kind=int(kv%i)
            end if
        else
            if(p%prog%expressions(a)%typ/=ty_real.or.(e%real_kind/=4.and.e%real_kind/=8)) then
                call error(p,'Model decomposition requires REAL kind 4 or 8 X');return
            end if
            if(e%op=='exponent') then
                e%typ=ty_integer;e%real_kind=4
            end if
            if(e%op=='set_exponent') then
                b=e%args(2)
                if(p%prog%expressions(b)%typ/=ty_integer.or. &
                   (p%prog%expressions(b)%real_kind/=4.and.p%prog%expressions(b)%real_kind/=8)) then
                    call error(p,'SET_EXPONENT I must be INTEGER kind 4 or 8');return
                end if
            end if
        end if
        call merge_shape(p,e,a)
        if(e%op=='set_exponent')call merge_shape(p,e,e%args(2))
    end subroutine
    subroutine call_type(p,e,name)
        type(parser_t),intent(inout)::p
        type(expr_t),intent(inout)::e
        character(*),intent(in)::name
        type(value_t)::kv
        type(diagnostic_t)::fold_diag
        character(:),allocatable::display_name
        integer::n,i,t,j
        if(p%diag%code/=0) return
        n=size(e%args)
        display_name=name
        if(name=='int') display_name='INT'
        if(name=='real') display_name='REAL'
        if(name=='associated') then
            if(n<1.or.n>2) then
                call error(p,'ASSOCIATED requires POINTER and optional TARGET');return
            end if
            i=e%args(1);t=p%prog%expressions(i)%symbol
            if(p%prog%expressions(i)%kind/=ex_variable.or.p%prog%expressions(i)%parenthesized.or.t<1) then
                call error(p,'ASSOCIATED requires a whole POINTER');return
            end if
            if(.not.p%prog%symbols(t)%is_pointer) then
                call error(p,'ASSOCIATED requires POINTER attribute');return
            end if
            if(n==2) then
                i=e%args(2)
                associate(target=>p%prog%expressions(i))
                if(target%parenthesized.or.(target%kind/=ex_variable.and.target%kind/=ex_section).or. &
                   target%rank/=1.or.target%symbol<1) then
                    call error(p,'ASSOCIATED TARGET requires a rank-one target designator');return
                end if
                if(target%typ/=p%prog%symbols(t)%typ.or.target%real_kind/=p%prog%symbols(t)%real_kind) then
                    call error(p,'ASSOCIATED POINTER and TARGET require matching type and kind');return
                end if
                associate(sym=>p%prog%symbols(target%symbol))
                if(sym%is_pointer) then
                    if(target%kind/=ex_variable) then
                        call error(p,'ASSOCIATED pointer TARGET requires a whole variable');return
                    end if
                else if(.not.sym%is_target.or.sym%is_allocatable.or.sym%is_automatic.or. &
                        sym%scope<0.or.sym%rank>2) then
                    call error(p,'ASSOCIATED requires nonallocatable rank-one/two TARGET storage');return
                end if
                end associate
                end associate
            end if
            e%typ=ty_logical;e%rank=0;e%real_kind=4;e%extent=0_int64;return
        end if
        if(name=='allocated') then
            if(n/=1) then
                call error(p,'ALLOCATED requires one allocatable array');return
            end if
            i=e%args(1);t=p%prog%expressions(i)%symbol
            if(p%prog%expressions(i)%kind/=ex_variable.or.p%prog%expressions(i)%parenthesized.or.t==0) then
                call error(p,'ALLOCATED requires a whole allocatable array name');return
            end if
            if(.not.p%prog%symbols(t)%is_allocatable) then
                call error(p,'ALLOCATED requires an ALLOCATABLE array');return
            end if
            e%typ=ty_logical;e%rank=0;e%real_kind=4;e%extent=0_int64;return
        end if
        if(name=='present') then
            if(n/=1) then
                call error(p,'PRESENT requires one optional dummy argument');return
            end if
            i=e%args(1)
            if(p%prog%expressions(i)%kind/=ex_variable.or.p%prog%expressions(i)%parenthesized) then
                call error(p,'PRESENT argument must be an optional dummy name');return
            end if
            t=p%prog%expressions(i)%symbol
            if(.not.p%prog%symbols(t)%is_dummy.or..not.p%prog%symbols(t)%is_optional.or. &
               p%prog%symbols(t)%scope/=p%scope) then
                call error(p,'PRESENT argument must be an optional dummy name');return
            end if
            e%typ=ty_logical;e%real_kind=4;e%rank=0;e%extent=0_int64
            return
        end if
        if(name=='selected_real_kind') then
            if(n>3.or.e%intrinsic_mask<0.or.e%intrinsic_mask>7) then
                call error(p,'Invalid SELECTED_REAL_KIND arguments');return
            end if
            if(popcnt(e%intrinsic_mask)/=n) then
                call error(p,'Invalid SELECTED_REAL_KIND argument association');return
            end if
            do i=1,n
                if(p%prog%expressions(e%args(i))%typ/=ty_integer.or.p%prog%expressions(e%args(i))%rank/=0) then
                    call error(p,'SELECTED_REAL_KIND arguments must be scalar INTEGER');return
                end if
            end do
            e%typ=ty_integer;e%real_kind=4;e%rank=0;e%extent=0_int64
            return
        end if
        if(name=='merge') then
            if(n/=3) then
                call error(p,'MERGE requires TSOURCE, FSOURCE and MASK');return
            end if
            t=p%prog%expressions(e%args(1))%typ
            e%typ=t;e%real_kind=p%prog%expressions(e%args(1))%real_kind
            if(t<ty_integer.or.t>ty_character.or.p%prog%expressions(e%args(2))%typ/=t.or. &
               p%prog%expressions(e%args(2))%real_kind/=e%real_kind.or. &
               p%prog%expressions(e%args(3))%typ/=ty_logical) then
                call error(p,'MERGE requires matching intrinsic source types/kinds and LOGICAL MASK');return
            end if
            if(t==ty_character) then
                e%character_len=p%prog%expressions(e%args(1))%character_len
                if(e%character_len>=0.and.p%prog%expressions(e%args(2))%character_len>=0.and. &
                   e%character_len/=p%prog%expressions(e%args(2))%character_len) then
                    call error(p,'MERGE CHARACTER source lengths must match');return
                end if
            end if
            do i=1,n
                call merge_shape(p,e,e%args(i))
            end do
            return
        end if
        if(is_bit_intrinsic(name)) then
            i=2
            if(name=='not'.or.name=='bit_size'.or.(name=='leadz'.or.name=='trailz'))i=1
            if(name=='maskl'.or.name=='maskr')then
                if(n<1.or.n>2)then
                    call error(p,'MASKL/MASKR accept I and optional KIND');return
                end if
            else if(n/=i)then
                call error(p,'Bit intrinsic argument count differs');return
            end if
            e%typ=ty_integer;e%real_kind=p%prog%expressions(e%args(1))%real_kind
            if((name=='leadz'.or.name=='trailz'))e%real_kind=4
            if(name=='maskl'.or.name=='maskr')then
                e%real_kind=4
                if(n==2)then
                    i=e%args(2)
                    if(p%prog%expressions(i)%typ/=ty_integer.or.p%prog%expressions(i)%rank/=0)then
                        call error(p,'MASKL/MASKR KIND must be scalar INTEGER constant');return
                    end if
                    call require_constant(p,i,'MASKL/MASKR KIND must be constant')
                    call evaluate_constant(p%prog,i,kv,p%diag)
                    if(p%diag%code/=0)return
                    if(kv%tag/=ty_integer.or.(kv%i/=4.and.kv%i/=8))then
                        call error(p,'MASKL/MASKR support result kinds 4 and 8');return
                    end if
                    e%real_kind=int(kv%i)
                end if
            end if
            if(name=='btest')then
                e%typ=ty_logical;e%real_kind=4
            end if
            do j=1,n
                i=e%args(j)
                if(p%prog%expressions(i)%typ/=ty_integer.or. &
                   (p%prog%expressions(i)%real_kind/=4.and.p%prog%expressions(i)%real_kind/=8))then
                    call error(p,'Bit intrinsics require INTEGER kind 4 or 8');return
                end if
                if(name/='btest'.and.(name/='leadz'.and.name/='trailz').and.name/='maskl'.and.name/='maskr'.and.name/='shiftr'.and.p%prog%expressions(i)%real_kind/=e%real_kind)then
                    call error(p,'Bit intrinsic operands require the same INTEGER kind');return
                end if
                if(model_argument_has_component(p,i))then
                    call error(p,'Bit intrinsic component operands are unsupported');return
                end if
                if(name/='bit_size'.and.(j==1.or.(name/='maskl'.and.name/='maskr')))call merge_shape(p,e,i)
            end do
            return
        end if
        if(is_lexical_intrinsic(name)) then
            if(n/=2) then
                call error(p,'Lexical comparison requires STRING_A and STRING_B');return
            end if
            e%typ=ty_logical;e%real_kind=4
            do j=1,2
                i=e%args(j)
                if(p%prog%expressions(i)%typ/=ty_character.or.p%prog%expressions(i)%real_kind/=4) then
                    call error(p,'Lexical comparison requires default CHARACTER operands');return
                end if
                call merge_shape(p,e,i)
            end do
            return
        end if
        if(is_character_intrinsic(name)) then
            call character_intrinsic_type(p,e)
            return
        end if
        if(name=='fraction'.or.name=='exponent'.or.name=='set_exponent'.or.name=='iachar') then
            call model_decomposition_type(p,e)
            return
        end if
        if(name=='char'.or.name=='achar') then
            if(n<1.or.n>2) then
                call error(p,'CHAR/ACHAR require I and optional KIND');return
            end if
            i=e%args(1)
            if(p%prog%expressions(i)%typ/=ty_integer) then
                call error(p,'CHAR/ACHAR I must be INTEGER');return
            end if
            if(n==2) then
                i=e%args(2)
                if(p%prog%expressions(i)%typ/=ty_integer.or.p%prog%expressions(i)%rank/=0) then
                    call error(p,'CHAR/ACHAR KIND must be a scalar INTEGER constant');return
                end if
                call require_constant(p,i,'CHAR/ACHAR KIND must be constant')
                call evaluate_constant(p%prog,i,kv,p%diag)
                if(p%diag%code/=0) return
                if(kv%i/=1) then
                    call error(p,'CHAR/ACHAR support default CHARACTER kind 1 only');return
                end if
            end if
            e%typ=ty_character;e%real_kind=4;e%character_len=1
            call merge_shape(p,e,e%args(1))
            return
        end if
        if(name=='len') then
            if(n/=1) then
                call error(p,'LEN requires one STRING argument; KIND is unsupported');return
            end if
            if(p%prog%expressions(e%args(1))%typ/=ty_character) then
                call error(p,'LEN requires CHARACTER');return
            end if
            e%typ=ty_integer;e%rank=0;e%extent=0_int64;e%real_kind=4
            return
        end if
        if(name=='repeat') then
            call repeat_call_type(p,e)
            return
        end if
        if(name=='trim') then
            if(n/=1) then
                call error(p,'TRIM requires one STRING argument');return
            end if
            if(p%prog%expressions(e%args(1))%typ/=ty_character.or.p%prog%expressions(e%args(1))%rank/=0) then
                call error(p,'TRIM requires scalar CHARACTER');return
            end if
            e%typ=ty_character
            ! Constant TRIM has a known length. Preserve it so constructors,
            ! concatenation and empty array expressions can infer element LEN
            ! without requiring a nonexistent first element. A nonconstant
            ! operand keeps the existing runtime-dependent length marker.
            call evaluate_constant(p%prog,e%args(1),kv,fold_diag)
            if(fold_diag%code==0.and.allocated(kv%s)) e%character_len=len_trim(kv%s)
            return
        end if
        if(name=='aint'.or.name=='anint'.or.name=='asinh'.or.name=='acosh') then
            if(n<1.or.n>2.or.((name=='asinh'.or.name=='acosh').and.n/=1)) then
                call error(p,'AINT/ANINT require A and optional KIND; ASINH/ACOSH require X');return
            end if
            i=e%args(1)
            if(p%prog%expressions(i)%typ/=ty_real.or. &
               (p%prog%expressions(i)%real_kind/=4.and.p%prog%expressions(i)%real_kind/=8)) then
                call error(p,'Real rounding/inverse hyperbolic requires REAL kind 4 or 8');return
            end if
            e%typ=ty_real;e%real_kind=p%prog%expressions(i)%real_kind
            call merge_shape(p,e,i)
            if(n==2) then
                i=e%args(2)
                if(p%prog%expressions(i)%typ/=ty_integer.or.p%prog%expressions(i)%rank/=0) then
                    call error(p,'AINT/ANINT KIND must be scalar INTEGER constant');return
                end if
                call require_constant(p,i,'AINT/ANINT KIND must be constant')
                call evaluate_constant(p%prog,i,kv,p%diag)
                if(p%diag%code/=0)return
                if(kv%i/=4.and.kv%i/=8) then
                    call error(p,'AINT/ANINT support result kinds 4 and 8');return
                end if
                e%real_kind=int(kv%i)
            end if
            return
        end if
        if(is_erf_bessel(name)) then
            j=1
            if(name=='bessel_jn'.or.name=='bessel_yn') j=2
            if(n/=j) then
                call error(p,'ERF/Bessel requires X, or N and X for elemental JN/YN');return
            end if
            i=e%args(j)
            if(p%prog%expressions(i)%typ/=ty_real.or. &
               (p%prog%expressions(i)%real_kind/=4.and.p%prog%expressions(i)%real_kind/=8)) then
                call error(p,'ERF/Bessel X requires REAL kind 4 or 8');return
            end if
            e%typ=ty_real;e%real_kind=p%prog%expressions(i)%real_kind
            if(j==2) then
                i=e%args(1)
                if(p%prog%expressions(i)%typ/=ty_integer.or. &
                   (p%prog%expressions(i)%real_kind/=4.and.p%prog%expressions(i)%real_kind/=8)) then
                    call error(p,'Bessel N requires INTEGER kind 4 or 8');return
                end if
            end if
            do i=1,n
                call merge_shape(p,e,e%args(i))
            end do
            return
        end if
        if(name=='dprod'.or.name=='tand') then
            j=1
            if(name=='dprod') j=2
            if(n/=j) then
                call error(p,'DPROD requires X,Y; TAND requires X');return
            end if
            e%typ=ty_real;e%real_kind=p%prog%expressions(e%args(1))%real_kind
            if(name=='dprod') e%real_kind=8
            do j=1,n
                i=e%args(j)
                if(p%prog%expressions(i)%typ/=ty_real.or. &
                   (p%prog%expressions(i)%real_kind/=4.and.p%prog%expressions(i)%real_kind/=8)) then
                    call error(p,'DPROD/TAND require REAL arguments');return
                end if
                if(name=='dprod'.and.p%prog%expressions(i)%real_kind/=4) then
                    call error(p,'DPROD requires default REAL kind 4 operands');return
                end if
                call merge_shape(p,e,i)
            end do
            return
        end if
        if(name=='asin'.or.name=='atan'.or.name=='atan2') then
            if(n<1.or.n>2.or.(name=='asin'.and.n/=1).or.(name=='atan2'.and.n/=2)) then
                call error(p,'ASIN requires X; ATAN requires X or Y,X; ATAN2 requires Y,X');return
            end if
            e%typ=ty_real;e%real_kind=p%prog%expressions(e%args(1))%real_kind
            do j=1,n
                i=e%args(j)
                if(p%prog%expressions(i)%typ/=ty_real.or. &
                   (p%prog%expressions(i)%real_kind/=4.and.p%prog%expressions(i)%real_kind/=8).or. &
                   p%prog%expressions(i)%real_kind/=e%real_kind) then
                    call error(p,'ASIN/ATAN/ATAN2 require matching REAL kind 4 or 8 operands');return
                end if
                call merge_shape(p,e,i)
            end do
            return
        end if
        if(name=='new_line') then
            if(n/=1) then
                call error(p,'NEW_LINE requires one CHARACTER A argument');return
            end if
            i=e%args(1)
            if(p%prog%expressions(i)%typ/=ty_character.or.p%prog%expressions(i)%real_kind/=4) then
                call error(p,'NEW_LINE requires default CHARACTER A');return
            end if
            if(.not.exponent_inquiry_operand_supported(p%prog,i)) then
                call error(p,'NEW_LINE subobject operands are unsupported');return
            end if
            e%typ=ty_character;e%real_kind=4;e%character_len=1
            e%rank=0;e%extent=0_int64;e%dims=0_int64;return
        end if
        if(is_degree_trig(name).or.name=='acos'.or.name=='rrspacing') then
            if(n/=1) then
                call error(p,'Unary real intrinsic requires one REAL X argument');return
            end if
            i=e%args(1)
            if(p%prog%expressions(i)%typ/=ty_real.or. &
               (p%prog%expressions(i)%real_kind/=4.and.p%prog%expressions(i)%real_kind/=8)) then
                call error(p,'Unary real intrinsic requires REAL kind 4 or 8');return
            end if
            e%typ=ty_real;e%real_kind=p%prog%expressions(i)%real_kind
            call merge_shape(p,e,i)
            return
        end if
        if(name=='erfc_scaled') then
            if(n/=1) then
                call error(p,'ERFC_SCALED requires one REAL X argument');return
            end if
            i=e%args(1)
            if(p%prog%expressions(i)%typ/=ty_real.or. &
               (p%prog%expressions(i)%real_kind/=4.and.p%prog%expressions(i)%real_kind/=8)) then
                call error(p,'ERFC_SCALED requires REAL kind 4 or 8');return
            end if
            e%typ=ty_real;e%real_kind=p%prog%expressions(i)%real_kind
            call merge_shape(p,e,i)
            return
        end if
        if(name=='isnan') then
            if(n/=1) then
                call error(p,'ISNAN requires one REAL X argument (GNU extension)');return
            end if
            i=e%args(1)
            if(p%prog%expressions(i)%typ/=ty_real.or. &
               (p%prog%expressions(i)%real_kind/=4.and.p%prog%expressions(i)%real_kind/=8)) then
                call error(p,'ISNAN requires REAL kind 4 or 8 (GNU extension)');return
            end if
            e%typ=ty_logical;e%real_kind=4
            call merge_shape(p,e,i)
            return
        end if
        if(name=='spacing'.or.name=='nearest') then
            i=1
            if(name=='nearest') i=2
            if(n/=i) then
                call error(p,'SPACING/NEAREST argument count differs');return
            end if
            e%typ=ty_real;e%real_kind=p%prog%expressions(e%args(1))%real_kind
            do i=1,n
                if(p%prog%expressions(e%args(i))%typ/=ty_real.or. &
                   (p%prog%expressions(e%args(i))%real_kind/=4.and.p%prog%expressions(e%args(i))%real_kind/=8)) then
                    call error(p,'SPACING/NEAREST requires REAL kind 4 or 8 arguments');return
                end if
                call merge_shape(p,e,e%args(i))
            end do
            return
        end if
        if(is_numeric_model_inquiry(name)) then
            if(n/=1) then
                call error(p,'Numeric model inquiry requires one X argument');return
            end if
            i=e%args(1)
            if(name=='minexponent'.or.name=='maxexponent') then
                if(.not.exponent_inquiry_operand_supported(p%prog,i)) then
                    call error(p,'MINEXPONENT/MAXEXPONENT subobject operands are unsupported');return
                end if
            end if
            if(model_argument_has_component(p,i)) then
                call error(p,'Numeric model inquiry component operands are unsupported');return
            end if
            t=p%prog%expressions(i)%typ
            if((name=='minexponent'.or.name=='maxexponent').and.t/=ty_real) then
                call error(p,'MINEXPONENT/MAXEXPONENT requires REAL X');return
            end if
            if((name=='epsilon'.or.name=='tiny').and.t/=ty_real) then
                call error(p,'EPSILON/TINY requires REAL X');return
            end if
            if(t/=ty_real.and.t/=ty_integer) then
                call error(p,'HUGE/RADIX requires INTEGER or REAL X');return
            end if
            e%typ=t;e%real_kind=p%prog%expressions(i)%real_kind
            if(e%real_kind/=4.and.e%real_kind/=8) then
                call error(p,'Numeric model inquiry supports kinds 4 and 8');return
            end if
            if(name=='digits'.or.name=='radix'.or.name=='minexponent'.or.name=='maxexponent') then
                e%typ=ty_integer;e%real_kind=4
            end if
            e%rank=0;e%extent=0_int64;e%dims=0_int64
            return
        end if
        if(name=='kind') then
            if(n/=1) then
                call error(p,'KIND requires one X argument');return
            end if
            e%typ=ty_integer;e%rank=0;e%extent=0_int64;e%real_kind=4
            return
        end if
        if(name=='reshape') then
            call reshape_call_type(p,e)
            return
        end if
        if(is_array_transform(name)) then
            call array_call_type(p,e,name)
            return
        end if
        if(name=='size') then
            if(n<1.or.n>2.or.(name/='size'.and.n/=2)) then
                call error(p,'Array inquiry requires ARRAY and DIM (DIM optional for SIZE)'); return
            end if
            if(p%prog%expressions(e%args(1))%rank==0) then
                call error(p,'Array inquiry requires an array'); return
            end if
            if(n==2) then
                if(p%prog%expressions(e%args(2))%rank/=0.or.p%prog%expressions(e%args(2))%typ/=ty_integer) &
                    call error(p,'Array inquiry DIM must be a scalar INTEGER')
                if(name/='size') call reject_optional_dim(p,e%args(2))
            end if
            e%typ=ty_integer; e%rank=0; e%extent=0_int64
            return
        end if
        select case(name)
        case('abs','dble','exp','log','log10','log_gamma','sqrt','erfc','sinh','cosh','tanh','sin','cos','tan','selected_int_kind')
            if(n/=1) then
                call error(p,'Intrinsic requires one argument: '//name); return
            end if
        case('real','int','nint','floor','ceiling')
            if(n<1.or.n>2) then
                call error(p,display_name//' requires one or two arguments'); return
            end if
        case('dim','sign')
            if(n/=2) then
                call error(p,'Intrinsic requires two arguments: '//name); return
            end if
        case('mod','modulo')
            if(n/=2) then
                call error(p,'MOD requires two arguments'); return
            end if
        case('min','max')
            if(n<2) then
                call error(p,'MIN/MAX require at least two arguments'); return
            end if
        case default
            call error(p,'Unsupported procedure or array reference: '//name); return
        end select
        t=p%prog%expressions(e%args(1))%typ
        e%real_kind=p%prog%expressions(e%args(1))%real_kind
        if((name=='min'.or.name=='max').and.t==ty_character) then
            e%typ=ty_character;e%real_kind=4;e%character_len=0
            do j=1,n
                i=e%args(j)
                if(p%prog%expressions(i)%typ/=ty_character.or.p%prog%expressions(i)%real_kind/=4) then
                    call error(p,'MIN/MAX require matching default CHARACTER arguments');return
                end if
                if(p%prog%expressions(i)%character_len< -1.or.p%prog%expressions(i)%character_len>65536) then
                    call error(p,'MIN/MAX CHARACTER length limit exceeded (65536)');return
                end if
                if(e%character_len<0.or.p%prog%expressions(i)%character_len<0) then
                    e%character_len=-1
                else
                    e%character_len=max(e%character_len,p%prog%expressions(i)%character_len)
                end if
                call merge_shape(p,e,i)
            end do
            return
        end if
        if(name=='exp'.or.name=='log'.or.name=='log10'.or.name=='sqrt'.or.name=='erfc'.or. &
           name=='sinh'.or.name=='cosh'.or.name=='tanh'.or. &
           name=='sin'.or.name=='cos'.or.name=='tan'.or.name=='log_gamma') then
            if(t/=ty_real) call error(p,'Transcendental intrinsic requires REAL argument')
        end if
        if(name=='nint'.or.name=='floor'.or.name=='ceiling') then
            if(t/=ty_real) then
                call error(p,'Rounding intrinsic requires REAL argument');return
            end if
        end if
        do i=1,n
            call merge_shape(p,e,e%args(i))
            if(.not.numeric(p%prog%expressions(e%args(i))%typ)) then
                call error(p,'Intrinsic requires numeric arguments'); return
            end if
            if(name=='mod'.or.name=='modulo'.or.name=='min'.or.name=='max'.or.name=='dim'.or.name=='sign') then
                if(p%prog%expressions(e%args(i))%typ/=t.or. &
                    ((t==ty_real.or.t==ty_integer).and.p%prog%expressions(e%args(i))%real_kind/=e%real_kind)) then
                    call error(p,'Intrinsic arguments must have matching types'); return
                end if
            end if
        end do
        e%typ=t
        if(name=='selected_int_kind') then
            if(t/=ty_integer.or.e%rank/=0) call error(p,'SELECTED_INT_KIND requires scalar INTEGER')
            e%typ=ty_integer; e%real_kind=4
        end if
        if(name=='real'.or.name=='int'.or.name=='nint'.or.name=='floor'.or.name=='ceiling') then
            e%typ=ty_integer; e%real_kind=4
            if(name=='real') e%typ=ty_real
            if(n==2) then
                if(p%prog%expressions(e%args(2))%typ/=ty_integer.or.p%prog%expressions(e%args(2))%rank/=0) then
                    call error(p,display_name//' kind must be scalar INTEGER constant'); return
                end if
                call require_constant(p,e%args(2),display_name//' kind must be constant')
                call evaluate_constant(p%prog,e%args(2),kv,p%diag)
                if(p%diag%code/=0) return
                if(kv%i/=4.and.kv%i/=8) then
                    call error(p,display_name//' supports kinds 4 and 8'); return
                end if
                e%real_kind=int(kv%i)
            end if
        end if
        if(name=='dble') then
            e%typ=ty_real; e%real_kind=8
        end if
    end subroutine
end module
