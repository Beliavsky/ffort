! SPDX-License-Identifier: MIT
! The independent source guard owns the executable IR. FortFront must agree
! with its declarations, bindings, statements and expression trees first.
module fi_frontend
    use, intrinsic :: iso_fortran_env, only: int64, real32, real64
    use fi_ir
    use lexer_core, only: token_t, TK_OPERATOR, TK_NEWLINE, TK_COMMENT, TK_WHITESPACE
    use fi_limits, only: max_only_names
    use fi_runtime, only: evaluate_constant, evaluate_constant_array, evaluate_constant_shape
    use fortfront_compiler, only: compiler_frontend_result_t, compiler_frontend_options_t, &
        compile_frontend_from_string, INPUT_MODE_STANDARD, OPERATING_MODE_STRICT, &
        resolved_type_query_t, query_resolved_type, declaration_query_t, query_declaration, &
        declaration_binding_t, resolve_identifier_binding, resolve_name_in_scope, TINT, TREAL, TLOGICAL, TCHAR
    use fortfront_ast, only: program_node, assignment_node, binary_op_node, identifier_node, &
        literal_node, call_or_subscript_node, declaration_node, if_node, do_loop_node, do_while_node, &
        print_statement_node, implicit_statement_node, comment_node
    use ast_nodes_loops, only: forall_node
    use ast_nodes_array, only: where_node
    use ast_base, only: LITERAL_STRING
    use ast_nodes_core, only: array_literal_node, component_access_node, pointer_assignment_node
    use type_system_unified, only: TDERIVED
    use ast_nodes_conditional, only: select_case_node, case_block_node, case_default_node, case_range_node
    use ast_nodes_bounds, only: range_expression_node, array_slice_node
    use ast_nodes_misc, only: end_statement_node, use_statement_node, visibility_statement_node, contains_node, &
        interface_block_node, module_procedure_node, allocate_statement_node, deallocate_statement_node
    use ast_nodes_data, only: module_node, multi_unit_container_node, parameter_declaration_node, derived_type_node, &
        type_binding_node
    use frontend_compiler_queries, only: type_bound_call_query_t, query_type_bound_call
    use ast_nodes_procedure, only: function_def_node, subroutine_def_node, subroutine_call_node
    use ast_nodes_transfer, only: nullify_node, return_node, error_stop_node, stop_node, exit_node, cycle_node
    use ast_nodes_io, only: write_statement_node, read_statement_node, io_implied_do_node, backspace_statement_node, inquire_statement_node
    use frontend_compiler_resolution, only: find_enclosing_scope, BINDING_FUNCTION, BINDING_SUBROUTINE, &
        BINDING_GENERIC_INTERFACE, BINDING_INTRINSIC_ARRAY, ASSOCIATION_USE
    implicit none
    private
    public :: verify_frontend, read_element_unit_text_matches
contains
    subroutine verify_frontend(source, prog, diag)
        character(*), intent(in) :: source
        type(program_t), intent(in) :: prog
        type(diagnostic_t), intent(inout) :: diag
        type(compiler_frontend_result_t) :: front
        type(compiler_frontend_options_t) :: opts
        type(declaration_query_t) :: declaration
        logical, allocatable :: seen_code(:), seen_symbol(:), checked_ranges(:), checked_keywords(:)
        logical, allocatable :: checked_constructor_nodes(:)
        integer :: constructor_depth, constructor_character_context, constructor_control_depth
        integer :: constructor_metadata_depth, allocation_status
        integer :: constructor_control_ast(max_constructor_do_depth), constructor_control_ir(max_constructor_do_depth)
        integer :: constructor_ast_stack(max_constructor_do_depth), constructor_ir_stack(max_constructor_do_depth)
        integer, allocatable :: symbol_declaration(:), shape_state(:), expression_rank(:)
        integer(int64), allocatable :: expression_extent(:), known_extent(:), expression_dims(:,:), known_dims(:,:)
        integer :: i,j,k,s,pc,units,triplet_depth,current_scope,main_node,selector_depth
        integer,allocatable :: type_nodes(:), component_owner(:), operator_nodes(:), generic_nodes(:)
        integer,allocatable :: component_default_ir(:)
        logical,allocatable :: generic_public(:),generic_visibility_set(:)
        logical,allocatable :: type_public(:),operator_public(:),type_visibility_set(:),operator_visibility_set(:)
        integer,allocatable :: procedure_node(:),module_node_index(:),scope_map(:),use_count(:)
        if (diag%code /= 0) return
        if(prog%ns<0.or.prog%ns>max_symbols.or.prog%ne<0.or.prog%ne>max_expressions.or. &
           prog%nc<0.or.prog%nc>max_instructions) then
            call fail(diag,'FortFront adapter: invalid IR counts')
            return
        end if
        if(prog%ns>0) then
            if(.not.allocated(prog%symbols)) then
                call fail(diag,'FortFront adapter: symbol storage missing')
                return
            end if
            if(size(prog%symbols)<prog%ns) then
                call fail(diag,'FortFront adapter: symbol storage too short')
                return
            end if
        end if
        if(prog%ne>0) then
            if(.not.allocated(prog%expressions)) then
                call fail(diag,'FortFront adapter: expression storage missing')
                return
            end if
            if(size(prog%expressions)<prog%ne) then
                call fail(diag,'FortFront adapter: expression storage too short')
                return
            end if
        end if
        if(prog%nc>0) then
            if(.not.allocated(prog%code)) then
                call fail(diag,'FortFront adapter: instruction storage missing')
                return
            end if
            if(size(prog%code)<prog%nc) then
                call fail(diag,'FortFront adapter: instruction storage too short')
                return
            end if
        end if
        if(prog%np<0.or.prog%np>max_procedures.or.prog%nm<0.or.prog%nm>max_modules.or. &
           prog%nu<0.or.prog%nu>size(prog%uses)) then
            call fail(diag,'FortFront adapter: invalid module/procedure counts')
            return
        end if
        if(prog%np>0) then
            if(.not.allocated(prog%procedures)) then
                call fail(diag,'FortFront adapter: procedures missing')
                return
            end if
            if(size(prog%procedures)<prog%np) then
                call fail(diag,'FortFront adapter: procedure storage missing')
                return
            end if
        end if
        do i=1,prog%np
            if(.not.valid_internal_procedure(prog,i)) then
                call fail(diag,'FortFront adapter: invalid internal procedure host');return
            end if
        end do
        if(prog%nu>0) then
            if(.not.allocated(prog%only_names)) then
                call fail(diag,'FortFront adapter: USE ONLY storage missing');return
            end if
            if(size(prog%only_names,2)<prog%nu) then
                call fail(diag,'FortFront adapter: USE ONLY storage too short');return
            end if
        end if
        do i=1,prog%nu
            if(prog%n_only(i)<0.or.prog%n_only(i)>max_only_names.or. &
               prog%n_only(i)>size(prog%only_names,1)) then
                call fail(diag,'FortFront adapter: invalid USE ONLY count');return
            end if
            if(prog%use_scopes(i)>0.or.prog%use_scopes(i)<-prog%nm) then
                call fail(diag,'FortFront adapter: invalid USE scope');return
            end if
            if(prog%use_scopes(i)<0.and.prog%uses(i)>=-prog%use_scopes(i)) then
                call fail(diag,'FortFront adapter: USE must refer to an earlier module');return
            end if
            if(prog%uses(i)<1.or.prog%uses(i)>prog%nm) then
                call fail(diag,'FortFront adapter: invalid USE binding')
                return
            end if
        end do
        if(prog%nt<0.or.prog%nt>max_types.or.prog%no<0.or.prog%no>max_operators) then
            call fail(diag,'FortFront adapter: invalid type/operator counts');return
        end if
        do i=1,prog%nt
            if(prog%derived_types(i)%module_id<1.or.prog%derived_types(i)%module_id>prog%nm.or. &
               prog%derived_types(i)%ncomponents<1.or.prog%derived_types(i)%ncomponents>16.or. &
               prog%derived_types(i)%nbindings<0.or.prog%derived_types(i)%nbindings>16) then
                call fail(diag,'FortFront adapter: invalid derived-type metadata');return
            end if
        end do
        do i=1,prog%no
            if(prog%operators(i)%module_id<1.or.prog%operators(i)%module_id>prog%nm.or. &
               prog%operators(i)%nprocedures<1.or.prog%operators(i)%nprocedures>16) then
                call fail(diag,'FortFront adapter: invalid operator metadata');return
            end if
        end do
        if(prog%ng<0.or.prog%ng>max_generics) then
            call fail(diag,'FortFront adapter: invalid generic count');return
        end if
        if(prog%ng>0) then
            if(.not.allocated(prog%generics)) then
                call fail(diag,'FortFront adapter: generic storage missing');return
            end if
            if(size(prog%generics)<prog%ng) then
                call fail(diag,'FortFront adapter: generic storage too short');return
            end if
        end if
        do i=1,prog%ng
            if(prog%generics(i)%module_id<1.or.prog%generics(i)%module_id>prog%nm.or. &
               prog%generics(i)%nprocedures<1.or.prog%generics(i)%nprocedures>16) then
                call fail(diag,'FortFront adapter: invalid generic metadata');return
            end if
            do j=1,prog%generics(i)%nprocedures
                if(prog%generics(i)%procedures(j)<1.or.prog%generics(i)%procedures(j)>prog%np) then
                    call fail(diag,'FortFront adapter: invalid generic specific binding');return
                end if
            end do
        end do
        do i=1,prog%ne
            associate(e=>prog%expressions(i))
            if((e%bound_type==0).neqv.(e%bound_binding==0)) then
                call fail(diag,'FortFront adapter: incomplete bound expression metadata');return
            end if
            if(e%bound_type/=0) then
                if(e%kind/=ex_user_call.or.e%bound_type<1.or.e%bound_type>prog%nt) then
                    call fail(diag,'FortFront adapter: invalid bound expression type');return
                end if
                if(e%bound_binding<1.or.e%bound_binding>prog%derived_types(e%bound_type)%nbindings) then
                    call fail(diag,'FortFront adapter: invalid expression binding');return
                end if
                if(.not.allocated(e%args)) then
                    call fail(diag,'FortFront adapter: bound expression arguments missing');return
                end if
                if(size(e%args)<1) then
                    call fail(diag,'FortFront adapter: bound expression receiver missing');return
                end if
            end if
            end associate
            if(prog%expressions(i)%generic_id<0.or.prog%expressions(i)%generic_id>prog%ng.or. &
               (prog%expressions(i)%generic_id/=0.and.prog%expressions(i)%kind/=ex_user_call).or. &
               (prog%expressions(i)%generic_id/=0.and.prog%expressions(i)%bound_type/=0)) then
                call fail(diag,'FortFront adapter: invalid expression generic binding');return
            end if
        end do
        do i=1,prog%nc
            associate(ins=>prog%code(i))
            if(ins%format_expr<0.or.ins%format_expr>prog%ne.or.ins%advance_mode<0.or.ins%advance_mode>1) then
                call fail(diag,'FortFront adapter: invalid output control metadata');return
            end if
            if(ins%format_expr/=0) then
                if((ins%op/=op_print.and.ins%op/=op_write_internal).or.allocated(ins%format)) then
                    call fail(diag,'FortFront adapter: unexpected runtime format metadata');return
                end if
            end if
            if(ins%advance_mode/=0) then
                if(ins%op/=op_print.or.(.not.allocated(ins%format).and.ins%format_expr==0)) then
                    call fail(diag,'FortFront adapter: invalid nonadvancing output metadata');return
                end if
            end if
            if((ins%bound_type==0).neqv.(ins%bound_binding==0)) then
                call fail(diag,'FortFront adapter: incomplete bound instruction metadata');return
            end if
            if(ins%bound_type/=0) then
                if(ins%op/=op_call.or.ins%bound_type<1.or.ins%bound_type>prog%nt) then
                    call fail(diag,'FortFront adapter: invalid bound instruction type');return
                end if
                if(ins%bound_binding<1.or.ins%bound_binding>prog%derived_types(ins%bound_type)%nbindings) then
                    call fail(diag,'FortFront adapter: invalid instruction binding');return
                end if
                if(.not.allocated(ins%items)) then
                    call fail(diag,'FortFront adapter: bound instruction arguments missing');return
                end if
                if(size(ins%items)<1) then
                    call fail(diag,'FortFront adapter: bound instruction receiver missing');return
                end if
            end if
            end associate
            if(prog%code(i)%generic_id<0.or.prog%code(i)%generic_id>prog%ng.or. &
               (prog%code(i)%generic_id/=0.and.prog%code(i)%op/=op_call).or. &
               (prog%code(i)%generic_id/=0.and.prog%code(i)%bound_type/=0)) then
                call fail(diag,'FortFront adapter: invalid instruction generic binding');return
            end if
        end do
        allocate(shape_state(prog%ne),source=0)
        allocate(expression_rank(prog%ne),source=0)
        allocate(expression_extent(prog%ne),source=0_int64)
        allocate(known_extent(prog%ne),source=-1_int64)
        allocate(expression_dims(3,prog%ne),source=0_int64)
        allocate(known_dims(3,prog%ne),source=-1_int64)
        do i=1,prog%ns
            if(prog%symbols(i)%rank<0.or.prog%symbols(i)%rank>3) then
                call fail(diag,'FortFront adapter: unsupported symbol rank');return
            end if
        end do
        do i=1,prog%nc
            if(prog%code(i)%third/=0.and.prog%code(i)%op/=op_allocate.and.prog%code(i)%op/=op_deallocate) then
                if(prog%code(i)%op/=op_assign.or.prog%code(i)%b==0.or. &
                   prog%code(i)%c/=0.or.prog%code(i)%component/=0) then
                    call fail(diag,'FortFront adapter: unexpected third target subscript');return
                end if
            end if
            s=module_write_target(prog%code(i))
            if(s>0) call check_module_write_ir(s,prog%code(i)%scope)
            if(prog%code(i)%op==op_call.and.allocated(prog%code(i)%items)) then
                if(.not.internal_call_visible(prog,prog%code(i)%scope,prog%code(i)%symbol)) then
                    call fail(diag,'FortFront adapter: internal call outside host scope');return
                end if
                if(module_actual_conflict(prog,prog%code(i)%symbol,prog%code(i)%items)) &
                    call fail(diag,'FortFront adapter: conflicting module actual association')
            end if
            if(diag%code/=0) return
        end do
        do i=1,prog%ne
            associate(e=>prog%expressions(i))
            if(e%kind==ex_variable.or.e%kind==ex_element.or.e%kind==ex_section.or.e%kind==ex_substring.or.e%kind==ex_gather_rows) then
                s=e%symbol
                if(s>0.and.s<=prog%ns) then
                    if(prog%symbols(s)%scope>0.and.prog%symbols(s)%scope/=e%scope) then
                        if(.not.host_symbol_visible(prog,s,e%scope)) then
                            call fail(diag,'FortFront adapter: unsupported internal procedure host capture');return
                        end if
                    end if
                end if
            end if
            if(e%kind==ex_user_call) then
                if(.not.internal_call_visible(prog,e%scope,e%symbol)) then
                    call fail(diag,'FortFront adapter: internal call outside host scope');return
                end if
            end if
            end associate
            if(prog%expressions(i)%kind==ex_user_call.and.allocated(prog%expressions(i)%args)) then
                if(module_actual_conflict(prog,prog%expressions(i)%symbol,prog%expressions(i)%args)) &
                    call fail(diag,'FortFront adapter: conflicting module actual association')
            end if
            call derive_shape(i,0)
            if(diag%code/=0) return
        end do
        call check_pointer_uses()
        if(diag%code/=0) return
        call check_call_graph()
        if(diag%code/=0) return
        opts%input_mode=INPUT_MODE_STANDARD
        opts%operating_mode=OPERATING_MODE_STRICT
        opts%allow_allocatable_reallocation=.true.
        opts%standardize=.false.
        opts%run_semantics=.true.
        call compile_frontend_from_string(source,front,opts)
        if (.not. front%success()) then
            if (allocated(front%error_msg)) then
                call fail(diag,'FortFront rejected the source: '//front%error_msg)
            else
                call fail(diag,'FortFront rejected the source')
            end if
            return
        end if
        allocate(checked_ranges(front%arena%entry_count),source=.false.)
        allocate(checked_keywords(front%arena%entry_count),source=.false.)
        allocate(checked_constructor_nodes(front%arena%entry_count),source=.false.,stat=allocation_status)
        if(allocation_status/=0) then
            call fail(diag,'FortFront adapter: constructor verification scratch allocation failed');return
        end if
        allocate(seen_code(prog%nc),source=.false.)
        allocate(seen_symbol(prog%ns),source=.false.)
        allocate(symbol_declaration(prog%ns),source=0)
        units=0; triplet_depth=0; current_scope=0; main_node=0; selector_depth=0
        constructor_depth=0;constructor_character_context=-1
        constructor_ast_stack=0;constructor_ir_stack=0
        constructor_control_depth=0;constructor_metadata_depth=0
        constructor_control_ast=0;constructor_control_ir=0
        allocate(procedure_node(prog%np),source=0)
        allocate(module_node_index(prog%nm),source=0)
        allocate(scope_map(front%arena%entry_count),source=-max_modules-1)
        allocate(use_count(prog%nm),source=0)
        allocate(type_nodes(prog%nt),source=0)
        allocate(operator_nodes(prog%no),source=0)
        allocate(generic_nodes(prog%ng),source=0)
        allocate(generic_public(prog%ng),source=.true.)
        allocate(generic_visibility_set(prog%ng),source=.false.)
        allocate(component_owner(front%arena%entry_count),source=0)
        allocate(component_default_ir(front%arena%entry_count),source=0)
        allocate(type_public(prog%nt),source=.true.)
        allocate(operator_public(prog%no),source=.true.)
        allocate(type_visibility_set(prog%nt),source=.false.)
        allocate(operator_visibility_set(prog%no),source=.false.)
        call map_units()
        call check_type_definitions()
        if(diag%code/=0) return
        ! Resolve every declaration before checking executable expressions. This
        ! also permits calls to functions declared later in the same module.
        do i=1,front%arena%entry_count
            if(.not.front%arena%has_node_at(i)) cycle
            select type(node=>front%arena%entries(i)%node)
            type is(declaration_node)
                if(component_owner(i)>0) cycle
                current_scope=node_scope(i)
                declaration=query_declaration(front%arena,i)
                if(.not.declaration%found.or.current_scope < -prog%nm) then
                    call mismatch(i,'declaration outside supported scope')
                    return
                end if
                do j=1,size(declaration%names)
                    s=symbol_index(declaration%names(j))
                    if(s==0) then
                        call mismatch(i,'unexpected scoped declaration')
                        return
                    end if
                    if(symbol_declaration(s)/=0) then
                        call mismatch(i,'duplicate scoped declaration')
                        return
                    end if
                    symbol_declaration(s)=i
                end do
            end select
        end do
        ! Component defaults may name module PARAMETERs. Resolve them only after
        ! every ordinary declaration has an independently matched source identity.
        do i=1,front%arena%entry_count
            if(component_default_ir(i)==0) cycle
            current_scope=-prog%derived_types(component_owner(i))%module_id
            select type(node=>front%arena%entries(i)%node)
            type is(declaration_node)
                call expression(node%initializer_index,component_default_ir(i),0)
            end select
            if(diag%code/=0) return
        end do
        do i=1,front%arena%entry_count
            if (.not. front%arena%has_node_at(i)) cycle
            current_scope=node_scope(i)
            select type(node=>front%arena%entries(i)%node)
            type is(program_node)
                units=units+1
                if (.not. allocated(node%name)) then
                    call mismatch(i,'missing PROGRAM name')
                else if (len_trim(prog%name)==0) then
                    ! Pinned FortFront names a standard anonymous main "main".
                    ! This is metadata only, not an implicit source declaration.
                    if(lower(node%name)/='main') call mismatch(i,'implicit main PROGRAM differs')
                else if (lower(node%name)/=trim(prog%name)) then
                    call mismatch(i,'PROGRAM name differs')
                end if
            type is(module_node)
            type is(function_def_node)
            type is(subroutine_def_node)
            type is(contains_node)
            type is(derived_type_node)
            type is(type_binding_node)
                if(component_owner(i)==0) call mismatch(i,'unmatched type binding')
            type is(interface_block_node)
            type is(module_procedure_node)
                if(component_owner(i)>=0) call mismatch(i,'unmatched MODULE PROCEDURE')
            type is(component_access_node)
            type is(visibility_statement_node)
                if(current_scope>=0) call mismatch(i,'visibility outside module')
            type is(multi_unit_container_node)
                if(i/=front%root_index) call mismatch(i,'nested multi-unit container')
            type is(parameter_declaration_node)
                if(current_scope<1) call mismatch(i,'dummy outside function')
            type is(use_statement_node)
                call check_use(i,node)
            type is(declaration_node)
                if(component_owner(i)>0) cycle
                declaration=query_declaration(front%arena,i)
                if (.not. declaration%found) then
                    call mismatch(i,'declaration query unavailable')
                    return
                end if
                do j=1,size(declaration%names)
                    s=symbol_index(declaration%names(j))
                    if (s==0) then
                        call mismatch(i,'unexpected declaration')
                        return
                    end if
                    if(allocated(node%type_name)) then
                        if(prog%symbols(s)%is_class.neqv.(index_char(lower(node%type_name),'class(')==1)) &
                            call mismatch(i,'CLASS declaration differs')
                    end if
                    if(prog%symbols(s)%is_dummy.neqv.declaration%has_intent) &
                        call mismatch(i,'dummy INTENT attribute differs')
                    if((prog%symbols(s)%dummy_intent/=0).neqv.prog%symbols(s)%is_dummy) &
                        call mismatch(i,'dummy INTENT cache differs')
                    if(prog%symbols(s)%is_class.and.prog%symbols(s)%dummy_intent==2.and.current_scope>0) then
                        if(prog%procedures(current_scope)%is_pure) call mismatch(i,'PURE polymorphic INTENT(OUT) dummy')
                    end if
                    if(prog%symbols(s)%is_dummy.and.current_scope>0) then
                        if(.not.prog%procedures(current_scope)%is_subroutine.and.prog%symbols(s)%dummy_intent/=1) &
                            call mismatch(i,'function dummy must have INTENT(IN)')
                    end if
                    if(declaration%has_intent) then
                        if(.not.allocated(declaration%intent)) then
                            call mismatch(i,'dummy INTENT missing')
                        else
                            select case(lower(declaration%intent))
                            case('in')
                                if(prog%symbols(s)%dummy_intent/=1) call mismatch(i,'INTENT cache differs')
                            case('out')
                                if(prog%symbols(s)%dummy_intent/=2) call mismatch(i,'INTENT cache differs')
                            case('inout')
                                if(prog%symbols(s)%dummy_intent/=3) call mismatch(i,'INTENT cache differs')
                            case default
                                call mismatch(i,'unsupported INTENT')
                            end select
                        end if
                    end if
                    if(current_scope<0.and..not.declaration%is_parameter.and. &
                       is_derived_type(prog%symbols(s)%typ)) call mismatch(i,'unsupported mutable module data type')
                    if(current_scope>0) then
                        if(declaration%is_external.or.declaration%is_value.or. &
                           declaration%is_bind_c.or.declaration%is_volatile.or.declaration%is_asynchronous.or. &
                           declaration%is_contiguous.or.declaration%is_protected) &
                            call mismatch(i,'unsupported function declaration')
                    end if
                    if(prog%symbols(s)%is_saved.neqv.(current_scope>0.and. &
                       (declaration%is_save.or.(declaration%has_initializer.and..not.declaration%is_parameter)))) &
                        call mismatch(i,'SAVE storage duration differs')
                    if(declaration%is_save.and.current_scope<0) call mismatch(i,'Module SAVE declarations are unsupported')
                    if(declaration%is_save.and.current_scope==0) then
                        ! Main SAVE is redundant storage duration, not procedure
                        ! SAVE metadata. Keep the ordinary root-owned storage and
                        ! source-bound, once-per-execution initializer assignment.
                        if(.not.declaration%has_initializer.or.prog%symbols(s)%typ<ty_integer.or. &
                           prog%symbols(s)%typ>ty_character.or.prog%symbols(s)%rank<0.or.prog%symbols(s)%rank>3.or. &
                           prog%symbols(s)%is_parameter.or.prog%symbols(s)%is_dummy.or.prog%symbols(s)%is_optional.or. &
                           prog%symbols(s)%is_pointer.or.prog%symbols(s)%is_allocatable.or.prog%symbols(s)%is_target.or. &
                           prog%symbols(s)%is_class.or.prog%symbols(s)%is_automatic.or.prog%symbols(s)%assumed_shape.or. &
                           prog%symbols(s)%deferred_character.or.prog%symbols(s)%parameter_ready.or. &
                           allocated(prog%symbols(s)%constant_values)) &
                            call mismatch(i,'unsupported initialized main-program SAVE declaration')
                    end if
                    if(prog%symbols(s)%is_saved) then
                        if(.not.valid_saved_local(prog,s)) call mismatch(i,'invalid initialized SAVE local')
                    end if
                    if(prog%symbols(s)%is_pointer.neqv.declaration%is_pointer) &
                        call mismatch(i,'POINTER attribute differs')
                    if(prog%symbols(s)%is_pointer) then
                        if(current_scope<0.or.prog%symbols(s)%rank/=1.or.prog%symbols(s)%is_allocatable.or. &
                           prog%symbols(s)%is_target.or.prog%symbols(s)%is_parameter.or.prog%symbols(s)%is_class.or. &
                           (prog%symbols(s)%typ/=ty_integer.and.prog%symbols(s)%typ/=ty_real).or. &
                           prog%symbols(s)%assumed_shape.or.prog%symbols(s)%is_automatic.or.declaration%has_initializer) &
                            call mismatch(i,'unsupported POINTER declaration')
                        if(current_scope>0) then
                            if(.not.prog%procedures(current_scope)%is_subroutine.or.prog%procedures(current_scope)%is_elemental) &
                                call mismatch(i,'POINTER requires non-elemental subroutine or main program')
                        end if
                    end if
                    if(prog%symbols(s)%is_target.neqv.declaration%is_target) &
                        call mismatch(i,'TARGET attribute differs')
                    if(prog%symbols(s)%is_target) then
                        if(prog%symbols(s)%is_parameter.or.prog%symbols(s)%is_class.or. &
                           prog%symbols(s)%typ<ty_integer.or.prog%symbols(s)%typ>ty_character.or. &
                           prog%symbols(s)%rank<0.or.prog%symbols(s)%rank>3) &
                            call mismatch(i,'unsupported TARGET declaration')
                    end if
                    if(prog%symbols(s)%is_allocatable.neqv.declaration%is_allocatable) &
                        call mismatch(i,'ALLOCATABLE attribute differs')
                    if(prog%symbols(s)%is_allocatable) then
                        if(prog%symbols(s)%rank==0) then
                            if(.not.valid_scalar_character_allocatable(prog,s)) &
                                call mismatch(i,'invalid scalar ALLOCATABLE CHARACTER declaration')
                        end if
                        if(prog%symbols(s)%rank<0.or.prog%symbols(s)%rank>3.or. &
                           (prog%symbols(s)%rank==0.and.prog%symbols(s)%typ/=ty_character).or. &
                           (prog%symbols(s)%typ/=ty_integer.and.prog%symbols(s)%typ/=ty_real.and. &
                            prog%symbols(s)%typ/=ty_logical.and.prog%symbols(s)%typ/=ty_character).or. &
                           (prog%symbols(s)%typ==ty_logical.and.prog%symbols(s)%real_kind/=4).or. &
                           prog%symbols(s)%is_parameter.or. &
                           prog%symbols(s)%assumed_shape.or.prog%symbols(s)%is_automatic.or.declaration%has_initializer) &
                            call mismatch(i,'unsupported ALLOCATABLE declaration')
                    end if
                    if(prog%symbols(s)%is_optional.neqv.declaration%is_optional) &
                        call mismatch(i,'OPTIONAL attribute differs')
                    if(prog%symbols(s)%is_optional) then
                        if(.not.prog%symbols(s)%is_dummy.or.current_scope<=0.or. &
                           prog%symbols(s)%dummy_intent<1.or.prog%symbols(s)%dummy_intent>3) &
                            call mismatch(i,'unsupported OPTIONAL declaration')
                        if(prog%symbols(s)%typ==ty_character) then
                            if(prog%symbols(s)%rank<0.or.prog%symbols(s)%rank>3.or. &
                               (prog%symbols(s)%character_len<0.and.prog%symbols(s)%length_expr/=0).or. &
                               prog%symbols(s)%character_len< -1.or. &
                               prog%symbols(s)%character_len>65536.or. &
                               (prog%symbols(s)%rank>0.and..not.prog%symbols(s)%assumed_shape.and. &
                                .not.prog%symbols(s)%is_allocatable)) &
                                call mismatch(i,'unsupported OPTIONAL CHARACTER declaration')
                        else if(prog%symbols(s)%rank<0.or.prog%symbols(s)%rank>3.or. &
                                prog%symbols(s)%typ<ty_integer.or.prog%symbols(s)%typ>ty_logical.or. &
                                prog%symbols(s)%deferred_character.or.prog%symbols(s)%character_len/=-1.or. &
                                prog%symbols(s)%length_expr/=0.or.prog%symbols(s)%is_automatic.or. &
                                (prog%symbols(s)%typ==ty_logical.and.prog%symbols(s)%real_kind/=4).or. &
                                (prog%symbols(s)%rank>0.and. &
                                 (prog%symbols(s)%assumed_shape.eqv.(prog%symbols(s)%is_allocatable.or.prog%symbols(s)%is_pointer)))) then
                            call mismatch(i,'unsupported OPTIONAL declaration')
                        end if
                    end if
                    if(prog%symbols(s)%is_intrinsic) call mismatch(i,'source declaration marked intrinsic')
                    if(prog%symbols(s)%typ==ty_character) call check_character_length(i,s,declaration)
                    seen_symbol(s)=.true.
                    symbol_declaration(s)=i
                    if(declaration%is_parameter.neqv.prog%symbols(s)%is_parameter) &
                        call mismatch(i,'PARAMETER attribute differs')
                    call check_type(i,prog%symbols(s)%typ,prog%symbols(s)%rank,prog%symbols(s)%real_kind)
                    call check_shape(i,s,declaration)
                    if(prog%symbols(s)%kind_expr/=0) then
                        selector_depth=selector_depth+1
                        call expression(node%kind_selector_index,prog%symbols(s)%kind_expr,0)
                        selector_depth=selector_depth-1
                    else if(prog%symbols(s)%typ==ty_real.and.node%kind_selector_index/=0) then
                        call mismatch(i,'REAL kind selector is absent from IR')
                    end if
                end do
                if (declaration%has_initializer) then
                    s=symbol_index(declaration%name)
                    if(prog%symbols(s)%is_parameter.or.current_scope<0.or.prog%symbols(s)%is_saved) then
                        call expression(declaration%initializer_index,prog%symbols(s)%initializer_expr,0)
                        call check_parameter(i,s)
                    else
                        pc=find_instruction(op_assign,node%line,s)
                        if(pc==0) then
                            call mismatch(i,'initializer is absent from IR')
                        else
                            if(declaration%is_save.and.current_scope==0) then
                                if(prog%symbols(s)%initializer_expr/=prog%code(pc)%a) &
                                    call mismatch(i,'main-program SAVE initializer differs')
                            end if
                            call expression(declaration%initializer_index,prog%code(pc)%a,0)
                            call check_assignment(i,s,0,prog%code(pc)%a)
                            call check_initializer(i,prog%code(pc)%a,0)
                            call check_initializer_shape(i,s,prog%code(pc)%a)
                        end if
                    end if
                else if(declaration%is_parameter) then
                    call mismatch(i,'PARAMETER initializer missing')
                end if
            type is(assignment_node)
                ! Keyword wrappers are checked as call arguments, never executable
                ! assignments. Require each skipped wrapper to be matched below.
                if(node%is_keyword_argument) cycle
                if (.not. front%arena%has_node_at(node%target_index)) then
                    call mismatch(i,'assignment target missing')
                    return
                end if
                s=0
                select type(lhs=>front%arena%entries(node%target_index)%node)
                type is(identifier_node)
                    if (allocated(lhs%name)) s=symbol_index(lhs%name)
                type is(call_or_subscript_node)
                    if (allocated(lhs%name)) s=symbol_index(lhs%name)
                type is(component_access_node)
                    if(front%arena%has_node_at(lhs%base_expr_index)) then
                        select type(base=>front%arena%entries(lhs%base_expr_index)%node)
                        type is(identifier_node)
                            if(allocated(base%name)) s=symbol_index(base%name)
                        end select
                    end if
                type is(array_slice_node)
                    if(front%arena%has_node_at(lhs%array_index)) then
                        select type(base=>front%arena%entries(lhs%array_index)%node)
                        type is(identifier_node)
                            if(allocated(base%name)) s=symbol_index(base%name)
                        type is(call_or_subscript_node)
                            ! Only recover the owning symbol here. The subsequent
                            ! assignment_target/substring_reference checks bind
                            ! the exact array-element node and both bounds.
                            if(allocated(base%name)) s=symbol_index(base%name)
                        end select
                    end if
                end select
                if(s==0) then
                    call mismatch(i,'assignment target differs')
                    return
                end if
                pc=find_instruction(op_assign,node%line,s)
                if(pc==0) then
                    call mismatch(i,'assignment is absent from IR')
                else
                    if(prog%code(pc)%component>0) then
                        call component_target(node%target_index,s,prog%code(pc)%component,prog%code(pc)%a)
                    else
                        call assignment_target(node%target_index,s,prog%code(pc)%b,prog%code(pc)%c,prog%code(pc)%d,prog%code(pc)%third)
                    end if
                    call expression(node%value_index,prog%code(pc)%a,0)
                    call check_assignment(i,s,prog%code(pc)%b,prog%code(pc)%a,prog%code(pc)%c,prog%code(pc)%component)
                end if
            type is(pointer_assignment_node)
                pc=find_instruction(op_pointer_assign,node%line,0)
                if(pc==0) then
                    call mismatch(i,'pointer association absent from IR');return
                end if
                call check_pointer_statement(i,pc,node%pointer_index,node%target_index)
            type is(nullify_node)
                pc=find_instruction(op_nullify,node%line,0)
                if(pc==0.or..not.allocated(node%pointer_indices)) then
                    call mismatch(i,'NULLIFY absent from IR or missing operand');return
                end if
                if(size(node%pointer_indices)/=1) then
                    call mismatch(i,'NULLIFY requires exactly one pointer');return
                end if
                call check_pointer_statement(i,pc,node%pointer_indices(1),0)
            type is(allocate_statement_node)
                pc=find_instruction(op_allocate,node%line,0)
                if(pc==0) then
                    call mismatch(i,'ALLOCATE is absent from IR');return
                end if
                if(node%source_expr_index/=0.or. &
                   node%mold_expr_index/=0) then
                    call mismatch(i,'unsupported ALLOCATE options');return
                end if
                call check_allocation_group(i,pc,node%var_indices,node%stat_var_index,node%errmsg_var_index,node%type_spec)
            type is(deallocate_statement_node)
                pc=find_instruction(op_deallocate,node%line,0)
                if(pc==0) then
                    call mismatch(i,'DEALLOCATE is absent from IR');return
                end if
                call check_allocation_group(i,pc,node%var_indices,node%stat_var_index,node%errmsg_var_index)
            type is(print_statement_node)
                pc=find_instruction(op_print,node%line,0)
                if(pc==0) then
                    call mismatch(i,'PRINT is absent from IR')
                    return
                end if
                if(prog%code(pc)%advance_mode/=0) call mismatch(i,'PRINT cannot specify ADVANCE')
                if(prog%code(pc)%symbol/=0) call mismatch(i,'PRINT cannot specify an output unit')
                call check_output(i,pc,node%expression_indices,node%format_spec)
            type is(read_statement_node)
                s=0
                if(allocated(node%unit_spec)) s=symbol_index(node%unit_spec)
                ! An internal element has no bare UNIT symbol spelling. Use the
                ! producer's structural base only to locate the instruction;
                ! check_read must still bind the complete subscript expression.
                if(s==0.and.allocated(node%specifiers)) then
                    if(size(node%specifiers)>0) then
                        k=node%specifiers(1)%value_node_index
                        if(front%arena%has_node_at(k)) then
                            select type(unit=>front%arena%entries(k)%node)
                            type is(call_or_subscript_node)
                                if(allocated(unit%name)) then
                                    j=symbol_index(unit%name)
                                    if(j>0) then
                                        if(prog%symbols(j)%typ==ty_character.and. &
                                           prog%symbols(j)%rank>=1.and.prog%symbols(j)%rank<=3) s=j
                                    end if
                                end if
                            end select
                        end if
                    end if
                end if
                pc=0
                if(s>0) then
                    if(prog%symbols(s)%typ==ty_integer) then
                        pc=find_instruction(op_read_external,node%line,0)
                    else
                        pc=find_instruction(op_read_internal,node%line,0)
                    end if
                end if
                if(pc==0) then
                    call mismatch(i,'READ is absent from IR');return
                end if
                call check_read(i,pc,node)
            type is(inquire_statement_node)
                pc=find_instruction(op_inquire_name,node%line,0)
                if(pc==0)then
                    call mismatch(i,'INQUIRE is absent from IR');return
                end if
                call check_inquire_name(i,pc,node)
            type is(backspace_statement_node)
                pc=find_instruction(op_backspace,node%line,0)
                if(pc==0) then
                    call mismatch(i,'BACKSPACE is absent from IR');return
                end if
                call check_backspace(i,pc,node)
            type is(write_statement_node)
                s=0
                if(allocated(node%unit_spec)) s=symbol_index(node%unit_spec)
                if(s==0.and.allocated(node%specifiers))then
                    if(size(node%specifiers)>0)then
                        k=node%specifiers(1)%value_node_index
                        if(front%arena%has_node_at(k))then
                            select type(unit=>front%arena%entries(k)%node)
                            type is(call_or_subscript_node)
                                if(allocated(unit%name))s=symbol_index(unit%name)
                            end select
                        end if
                    end if
                end if
                if(s>0) then
                    if(valid_stdout_unit(prog,s,current_scope)) then
                        pc=find_instruction(op_print,node%line,s)
                    else if(prog%symbols(s)%typ==ty_integer) then
                        pc=find_instruction(op_print,node%line,s)
                        if(pc==0)pc=find_instruction(op_write_defined,node%line,s)
                    else
                        pc=find_instruction(op_write_internal,node%line,s)
                    end if
                else
                    pc=find_instruction(op_print,node%line,0)
                end if
                if(pc==0) then
                    call mismatch(i,'WRITE is absent from IR')
                    return
                end if
                if(.not.allocated(node%unit_spec)) then
                    call mismatch(i,'WRITE unit missing')
                else if(prog%code(pc)%op==op_write_defined) then
                    call check_defined_write(i,pc,node)
                else if(prog%code(pc)%op==op_print) then
                    if(node%unit_spec=='*') then
                        if(prog%code(pc)%symbol/=0) call mismatch(i,'WRITE star unit differs')
                    else if(s/=prog%code(pc)%symbol) then
                        call mismatch(i,'WRITE output unit binding differs')
                    else if(prog%code(pc)%a/=0)then
                        if(.not.valid_runtime_output_unit(prog,prog%code(pc)%a,s,current_scope)) &
                            call mismatch(i,'WRITE runtime unit metadata differs')
                    else if(.not.valid_stdout_unit(prog,s,current_scope))then
                        call mismatch(i,'WRITE OUTPUT_UNIT import differs')
                    end if
                else if(s>0) then
                    if(prog%code(pc)%a/=0)then
                        if(.not.valid_internal_write_element(prog,prog%code(pc)%a,s,current_scope)) &
                            call mismatch(i,'internal WRITE element target differs')
                    else if(prog%symbols(s)%typ/=ty_character.or.prog%symbols(s)%rank/=0.or. &
                       prog%symbols(s)%is_parameter.or.prog%symbols(s)%dummy_intent==1)then
                        call mismatch(i,'internal WRITE target differs')
                    end if
                else if(node%unit_spec/='*') then
                    call mismatch(i,'WRITE unit must be standard output')
                end if
                if(prog%code(pc)%op/=op_write_defined) then
                    if(node%iostat_var_index/=0.or.node%err_label_index/=0.or.node%end_label_index/=0) &
                        call mismatch(i,'unsupported WRITE control')
                end if
                if(prog%code(pc)%op/=op_write_defined) call check_standard_write(i,pc,node)
                call check_output(i,pc,node%arg_indices,node%format_spec)
            type is(subroutine_call_node)
                if(allocated(node%name)) then
                    if(lower(node%name)=='getcwd'.or.lower(node%name)=='get_command_argument') then
                        pc=find_instruction(op_process_query,node%line,0)
                        if(pc/=0) then
                            call check_process_query(i,pc,node)
                            if(diag%code/=0) return
                            cycle
                        end if
                    end if
                    if(lower(node%name)=='system_clock'.or.lower(node%name)=='cpu_time')then
                        pc=find_instruction(op_timing_query,node%line,0)
                        if(pc/=0)then
                            call check_timing_query(i,pc,node)
                            if(diag%code/=0)return
                            cycle
                        end if
                    end if
                    if(lower(node%name)=='move_alloc') then
                        pc=find_instruction(op_move_alloc,node%line,0)
                        if(pc/=0) then
                            call check_move_alloc(i,pc,node)
                            if(diag%code/=0) return
                            cycle
                        end if
                    end if
                    if(lower(node%name)=='random_seed') then
                        pc=find_instruction(op_random_seed,node%line,0)
                        if(pc/=0) then
                            call check_random_seed(i,pc,node)
                            if(diag%code/=0) return
                            cycle
                        end if
                    end if
                    if(lower(node%name)=='random_number') then
                        pc=find_instruction(op_random_number,node%line,0)
                        if(pc==0) then
                            call mismatch(i,'RANDOM_NUMBER is absent from IR');return
                        end if
                        call check_random_number(i,pc,node)
                        if(diag%code/=0) return
                        cycle
                    end if
                end if
                pc=find_instruction(op_call,node%line,0)
                if(pc==0) then
                    call mismatch(i,'CALL is absent from IR')
                    return
                end if
                call check_subroutine_call(i,pc,node)
            type is(return_node)
                pc=find_instruction(op_return,node%line,0)
                if(pc==0.or.current_scope<=0.or.node%has_selector.or.node%selector_index/=0) &
                    call mismatch(i,'RETURN differs from IR')
            type is(stop_node)
                pc=find_instruction(op_stop,node%line,0)
                if(pc==0) then
                    call mismatch(i,'STOP is absent from IR')
                    return
                end if
                if(node%stop_code_index>0) then
                    call expression(node%stop_code_index,prog%code(pc)%a,0)
                else if(allocated(node%stop_message)) then
                    if(prog%code(pc)%a<1.or.prog%code(pc)%a>prog%ne) then
                        call mismatch(i,'STOP message missing')
                    else
                        associate(e=>prog%expressions(prog%code(pc)%a))
                        if(e%kind/=ex_literal.or.e%typ/=ty_character.or.e%scope/=current_scope) then
                            call mismatch(i,'STOP message shape differs')
                        else if(.not.allocated(e%value%s)) then
                            call mismatch(i,'STOP message missing')
                        else if(dequote(node%stop_message)/=e%value%s) then
                            call mismatch(i,'STOP message differs')
                        end if
                        end associate
                    end if
                else if(prog%code(pc)%a/=0) then
                    call mismatch(i,'unexpected STOP operand')
                end if
            type is(error_stop_node)
                pc=find_instruction(op_error_stop,node%line,0)
                if(pc==0) then
                    call mismatch(i,'ERROR STOP is absent from IR')
                    return
                end if
                if(node%error_code_index>0) then
                    call expression(node%error_code_index,prog%code(pc)%a,0)
                else if(allocated(node%error_message)) then
                    if(prog%code(pc)%a<1.or.prog%code(pc)%a>prog%ne) then
                        call mismatch(i,'ERROR STOP message missing')
                    else
                        associate(e=>prog%expressions(prog%code(pc)%a))
                        if(e%kind/=ex_literal.or.e%typ/=ty_character.or.e%scope/=current_scope) then
                            call mismatch(i,'ERROR STOP message shape differs')
                        else if(.not.allocated(e%value%s)) then
                            call mismatch(i,'ERROR STOP message missing')
                        else if(dequote(node%error_message)/=e%value%s) then
                            call mismatch(i,'ERROR STOP message differs')
                        end if
                        end associate
                    end if
                else if(prog%code(pc)%a/=0) then
                    call mismatch(i,'unexpected ERROR STOP operand')
                end if
            type is(select_case_node)
                call check_select(i,node)
            type is(case_block_node)
                ! Matched in the containing SELECT, including source order.
            type is(case_default_node)
            type is(case_range_node)
            type is(if_node)
                call check_if(i,node)
            type is(exit_node)
                pc=find_instruction(op_exit,node%line,0)
                call check_loop_transfer(i,pc,node%label)
            type is(cycle_node)
                pc=find_instruction(op_cycle,node%line,0)
                call check_loop_transfer(i,pc,node%label)
            type is(where_node)
                call check_where(i,node)
            type is(forall_node)
                call check_forall(i,node)
            type is(do_while_node)
                pc=find_instruction(op_do,node%line,0)
                if(pc==0) then
                    call mismatch(i,'DO WHILE differs from IR');return
                end if
                if(prog%code(pc)%d/=2.or.prog%code(pc)%symbol/=0.or. &
                   prog%code(pc)%b/=0.or.prog%code(pc)%c/=0) then
                    call mismatch(i,'DO WHILE control differs');return
                end if
                if(allocated(node%label)) then
                    if(lower(node%label)/=trim(prog%code(pc)%construct_name)) &
                        call mismatch(i,'DO construct name differs')
                else if(len_trim(prog%code(pc)%construct_name)/=0) then
                    call mismatch(i,'DO construct name is absent')
                end if
                j=prog%code(pc)%a
                if(j<1.or.j>prog%ne) then
                    call mismatch(i,'DO WHILE condition is absent');return
                end if
                associate(e=>prog%expressions(j))
                if(e%typ/=ty_logical.or.e%rank/=0.or.e%real_kind/=4.or.e%extent/=0.or. &
                   any(e%dims/=0).or.e%character_len/=-1) then
                    call mismatch(i,'DO WHILE condition must be scalar LOGICAL');return
                end if
                end associate
                call expression(node%condition_index,j,0)
            type is(do_loop_node)
                ! Constructor DOs are expression items, not executable DO
                ! statements. Their complete lexical trees are matched below.
                if(ast_constructor_loop(i)) cycle
                s=0
                if(allocated(node%var_name)) s=symbol_index(node%var_name)
                pc=find_instruction(op_do,node%line,s)
                if(pc==0 .or. node%is_concurrent) then
                    call mismatch(i,'DO differs from IR')
                    return
                end if
                if(allocated(node%label)) then
                    if(lower(node%label)/=trim(prog%code(pc)%construct_name)) &
                        call mismatch(i,'DO construct name differs')
                else if(len_trim(prog%code(pc)%construct_name)/=0) then
                    call mismatch(i,'DO construct name is absent')
                end if
                if(prog%code(pc)%d==1) then
                    if(s/=0.or.prog%code(pc)%symbol/=0.or.prog%code(pc)%a/=0.or. &
                       prog%code(pc)%b/=0.or.prog%code(pc)%c/=0.or.node%start_expr_index/=0.or. &
                       node%end_expr_index/=0.or.node%step_expr_index/=0) &
                        call mismatch(i,'bare DO has unexpected loop control')
                    if(allocated(node%var_name)) then
                        if(len_trim(node%var_name)/=0) call mismatch(i,'bare DO variable differs')
                    end if
                    cycle
                end if
                if(prog%code(pc)%d/=0.or.s==0) then
                    call mismatch(i,'counted DO control is absent');return
                end if
                if(prog%symbols(s)%rank/=0.or.prog%symbols(s)%is_parameter.or.prog%symbols(s)%dummy_intent==1) &
                    call mismatch(i,'DO variable must be a mutable scalar')
                call require_scalar(i,prog%code(pc)%a)
                call require_scalar(i,prog%code(pc)%b)
                if(prog%code(pc)%c/=0) call require_scalar(i,prog%code(pc)%c)
                call expression(node%start_expr_index,prog%code(pc)%a,0)
                call expression(node%end_expr_index,prog%code(pc)%b,0)
                if(prog%code(pc)%c/=0) then
                    call expression(node%step_expr_index,prog%code(pc)%c,0)
                else if(node%step_expr_index/=0) then
                    call mismatch(i,'unexpected explicit DO step')
                end if
            type is(binary_op_node)
                if(.not. allocated(node%operator)) then
                    call mismatch(i,'missing expression operator')
                else if(lower(node%operator)=='.not.'.or.node%left_index==0) then
                    if(.not. front%arena%has_node_at(node%right_index)) &
                        call mismatch(i,'missing unary operand')
                else
                    if(.not. front%arena%has_node_at(node%left_index)) &
                        call mismatch(i,'missing left operand')
                    if(.not. front%arena%has_node_at(node%right_index)) &
                        call mismatch(i,'missing right operand')
                end if
            type is(identifier_node)
                ! Checked at each executable occurrence by expression().
            type is(literal_node)
            type is(array_literal_node)
            type is(call_or_subscript_node)
            type is(array_slice_node)
                ! Checked at each executable occurrence.
            type is(io_implied_do_node)
                ! Matched recursively at each output occurrence.
            type is(range_expression_node)
                ! Matched against declaration bounds or executable sections.
            type is(implicit_statement_node)
            type is(comment_node)
            type is(end_statement_node)
                if(node%line/=prog%end_line.or.node%column/=prog%end_column) &
                    call mismatch(i,'implicit main END location differs')
            class default
                call mismatch(i,'unsupported node in FortFront AST')
            end select
            if(diag%code/=0) return
        end do
        do i=1,front%arena%entry_count
            if(.not.front%arena%has_node_at(i)) cycle
            select type(node=>front%arena%entries(i)%node)
            type is(case_block_node)
                if(.not.checked_ranges(i)) call mismatch(i,'unmatched CASE block')
            type is(case_default_node)
                if(.not.checked_ranges(i)) call mismatch(i,'unmatched DEFAULT block')
            type is(case_range_node)
                if(.not.checked_ranges(i)) call mismatch(i,'unmatched CASE range')
            type is(range_expression_node)
                if(.not.checked_ranges(i)) call mismatch(i,'unmatched array range')
            type is(assignment_node)
                if(node%is_keyword_argument.and..not.checked_keywords(i)) &
                    call mismatch(i,'unmatched keyword argument')
            type is(do_loop_node)
                if(ast_constructor_loop(i).and..not.checked_constructor_nodes(i)) &
                    call mismatch(i,'unmatched constructor implied-DO')
            end select
        end do
        if(units/=1) call fail(diag,'FortFront adapter: expected exactly one PROGRAM')
        do k=1,prog%nm
            if(use_count(k)/=count(prog%uses(1:prog%nu)==k)) &
                call fail(diag,'FortFront adapter: USE list differs')
        end do
        do k=1,prog%ns
            if(.not. seen_symbol(k)) call fail(diag,'FortFront adapter: missing declaration '//trim(prog%symbols(k)%name))
        end do
        do k=1,prog%nc
            if(prog%code(k)%op==op_jump .or. prog%code(k)%op==op_next) cycle
            if(.not. seen_code(k)) call fail(diag,'FortFront adapter: missing statement',prog%code(k)%line)
        end do
    contains
        subroutine check_pointer_uses()
            integer::e,j,pc,d,f,edges(10)
            do e=1,prog%ne
                associate(x=>prog%expressions(e))
                if(x%scope<=0) cycle
                if(x%kind==ex_element.or.x%kind==ex_section) then
                    if(prog%symbols(x%symbol)%is_pointer) then
                        call fail(diag,'FortFront adapter: procedure POINTER data access unsupported');return
                    end if
                end if
                edges=[x%left,x%right,x%stride,x%left2,x%right2,x%stride2,x%left3,x%right3,x%stride3,x%third]
                do j=1,size(edges)
                    if(pointer_value(edges(j))) then
                        call fail(diag,'FortFront adapter: procedure POINTER expression unsupported');return
                    end if
                end do
                if(allocated(x%args)) then
                    do j=1,size(x%args)
                        if(.not.pointer_value(x%args(j))) cycle
                        if(x%kind==ex_call.and.(x%op=='associated'.or.x%op=='present')) cycle
                        call fail(diag,'FortFront adapter: procedure POINTER value argument unsupported');return
                    end do
                end if
                end associate
            end do
            do pc=1,prog%nc
                associate(ins=>prog%code(pc))
                if(ins%scope<=0) cycle
                edges=0;edges(:5)=[ins%a,ins%b,ins%c,ins%d,ins%third]
                if(ins%op==op_pointer_assign) edges(1)=0
                if(ins%op==op_write_defined) edges(:2)=0
                do j=1,5
                    if(pointer_value(edges(j))) then
                        call fail(diag,'FortFront adapter: procedure POINTER data operand unsupported');return
                    end if
                end do
                if(ins%op==op_assign.and.ins%symbol>0.and.ins%symbol<=prog%ns) then
                    if(prog%symbols(ins%symbol)%is_pointer) then
                        call fail(diag,'FortFront adapter: procedure POINTER data write unsupported');return
                    end if
                end if
                if(allocated(ins%items)) then
                    do j=1,size(ins%items)
                        if(.not.pointer_value(ins%items(j))) cycle
                        if(ins%op==op_call) then
                            f=ins%symbol
                            if(f>=1.and.f<=prog%np) then
                                if(allocated(prog%procedures(f)%args)) then
                                    if(j<=size(prog%procedures(f)%args)) then
                                        d=prog%procedures(f)%args(j)
                                        if(d>=1.and.d<=prog%ns) then
                                            if(prog%symbols(d)%is_pointer) cycle
                                        end if
                                    end if
                                end if
                            end if
                        end if
                        call fail(diag,'FortFront adapter: procedure POINTER data item unsupported');return
                    end do
                end if
                end associate
            end do
        end subroutine
        logical function pointer_value(e) result(found)
            integer,intent(in)::e
            integer::s
            found=.false.
            if(e<1.or.e>prog%ne) return
            if(prog%expressions(e)%kind/=ex_variable) return
            s=prog%expressions(e)%symbol
            if(s>=1.and.s<=prog%ns) found=prog%symbols(s)%is_pointer
        end function
        subroutine check_pointer_statement(index,pc,lhs,rhs)
            integer,intent(in)::index,pc,lhs,rhs
            integer::s,a,t
            associate(ins=>prog%code(pc))
            s=ins%symbol
            if(s<1.or.s>prog%ns.or..not.front%arena%has_node_at(lhs)) then
                call mismatch(index,'pointer lhs missing');return
            end if
            if(.not.prog%symbols(s)%is_pointer.or.prog%symbols(s)%dummy_intent==1.or. &
               ins%b/=0.or.ins%c/=0.or.ins%d/=0.or.ins%third/=0.or.ins%component/=0.or. &
               ins%target/=0.or.allocated(ins%items).or.allocated(ins%format).or.len_trim(ins%construct_name)/=0) then
                call mismatch(index,'invalid pointer instruction metadata');return
            end if
            call assignment_target(lhs,s,0,0,0,0)
            if(rhs==0) then
                if(ins%a/=0) call mismatch(index,'NULLIFY operand differs')
                return
            end if
            a=ins%a
            if(a<1.or.a>prog%ne) then
                call mismatch(index,'pointer rhs missing');return
            end if
            call expression(rhs,a,0)
            associate(e=>prog%expressions(a))
            if(e%kind==ex_call.and.e%op=='null') return
            if(e%parenthesized.or.(e%kind/=ex_variable.and.e%kind/=ex_section).or.e%rank/=1.or. &
               e%typ/=prog%symbols(s)%typ.or.e%real_kind/=prog%symbols(s)%real_kind) then
                call mismatch(index,'invalid pointer target expression');return
            end if
            t=e%symbol
            if(t<1.or.t>prog%ns) then
                call mismatch(index,'pointer target binding absent');return
            end if
            if(prog%symbols(t)%is_pointer) then
                if(e%kind/=ex_variable) call mismatch(index,'pointer-to-pointer requires whole variable')
            else
                if(.not.prog%symbols(t)%is_target.or.prog%symbols(t)%is_allocatable.or. &
                   prog%symbols(t)%scope<0.or.prog%symbols(t)%is_automatic.or.prog%symbols(t)%rank>2) &
                    call mismatch(index,'pointer target must be fixed nonmodule rank-one/two TARGET')
            end if
            end associate
            end associate
        end subroutine
        subroutine check_pointer_actual(index,e,dummy)
            integer,intent(in)::index,e,dummy
            integer::s
            s=prog%expressions(e)%symbol
            if(prog%symbols(dummy)%is_pointer) then
                if(prog%expressions(e)%kind/=ex_variable.or.prog%expressions(e)%parenthesized.or.s<1.or.s>prog%ns) then
                    call mismatch(index,'POINTER dummy requires whole POINTER actual');return
                end if
                if(.not.prog%symbols(s)%is_pointer) call mismatch(index,'POINTER actual attribute differs')
            else if(s>0.and.s<=prog%ns.and.(prog%expressions(e)%kind==ex_variable.or. &
                prog%expressions(e)%kind==ex_element.or.prog%expressions(e)%kind==ex_section)) then
                if(prog%symbols(s)%is_pointer) call mismatch(index,'Direct POINTER actual requires POINTER dummy')
            end if
        end subroutine
        subroutine check_where(index,node)
            integer,intent(in)::index
            type(where_node),intent(in)::node
            integer::entry,arm,j,n,mask
            logical::final_else
            entry=find_instruction(op_where,node%line,0)
            if(entry==0) then
                call mismatch(index,'WHERE is absent from IR');return
            end if
            if(prog%code(entry)%c/=merge(1,0,node%is_single_line).or.prog%code(entry)%d/=0) then
                call mismatch(index,'WHERE statement form differs');return
            end if
            mask=prog%code(entry)%a
            call expression(node%mask_expr_index,mask,0)
            if(diag%code/=0) return
            if(prog%expressions(mask)%typ/=ty_logical.or.prog%expressions(mask)%rank<1.or.prog%expressions(mask)%rank>2) then
                call mismatch(index,'WHERE requires a LOGICAL array mask');return
            end if
            call check_where_body(index,entry,mask,node%where_body_indices)
            if(diag%code/=0) return
            n=0
            if(allocated(node%elsewhere_clauses)) n=size(node%elsewhere_clauses)
            arm=entry;final_else=.false.
            do j=1,n
                arm=prog%code(arm)%b
                if(arm<entry+1.or.arm>prog%nc) then
                    call mismatch(index,'ELSEWHERE is absent from IR');return
                end if
                if(prog%code(arm)%op/=op_elsewhere.or.prog%code(arm)%d/=entry.or. &
                   prog%code(arm)%scope/=current_scope.or.prog%code(arm)%target/=prog%code(entry)%target.or. &
                   prog%code(arm)%c/=0.or.final_else) then
                    call mismatch(index,'ELSEWHERE chain differs');return
                end if
                seen_code(arm)=.true.
                if(node%elsewhere_clauses(j)%mask_index==0) then
                    if(prog%code(arm)%a/=0) call mismatch(index,'ELSEWHERE mask presence differs')
                    final_else=.true.
                else
                    call expression(node%elsewhere_clauses(j)%mask_index,prog%code(arm)%a,0)
                    if(diag%code/=0) return
                    if(prog%expressions(prog%code(arm)%a)%typ/=ty_logical.or. &
                       prog%expressions(prog%code(arm)%a)%rank/=prog%expressions(mask)%rank) &
                        call mismatch(index,'ELSEWHERE mask rank or type differs')
                end if
                call check_where_body(index,arm,mask,node%elsewhere_clauses(j)%body_indices)
                if(diag%code/=0) return
            end do
            if(prog%code(arm)%b/=prog%code(entry)%target) &
                call mismatch(index,'WHERE final target differs')
            if(node%is_single_line) then
                if(n/=0.or.prog%code(entry)%b/=entry+2) call mismatch(index,'single-line WHERE body differs')
            end if
        end subroutine
        subroutine check_where_body(index,arm,mask,body)
            integer,intent(in)::index,arm,mask
            integer,allocatable,intent(in)::body(:)
            integer::n,j,stmt,pc,s,r
            n=0
            if(allocated(body)) n=size(body)
            if(prog%code(arm)%b/=arm+1+n.or.prog%code(arm)%b>prog%nc+1) then
                call mismatch(index,'WHERE body interval differs');return
            end if
            do j=1,n
                stmt=body(j);pc=arm+j
                if(.not.front%arena%has_node_at(stmt)) then
                    call mismatch(index,'WHERE body node missing');return
                end if
                select type(assignment=>front%arena%entries(stmt)%node)
                type is(assignment_node)
                    if(assignment%is_keyword_argument.or.prog%code(pc)%op/=op_assign.or. &
                       prog%code(pc)%scope/=current_scope.or.prog%code(pc)%b/=0.or.prog%code(pc)%d/=0.or. &
                       prog%code(pc)%component/=0.or.prog%code(pc)%line/=assignment%line.or. &
                       prog%code(pc)%column/=assignment%column) then
                        call mismatch(index,'WHERE assignment order or target differs');return
                    end if
                    s=prog%code(pc)%symbol
                    if(s<1.or.s>prog%ns) then
                        call mismatch(index,'WHERE target symbol missing');return
                    end if
                    r=prog%symbols(s)%rank
                    if(prog%code(pc)%c/=0) then
                        if(prog%code(pc)%c<1.or.prog%code(pc)%c>prog%ne) then
                            call mismatch(index,'WHERE section expression missing');return
                        end if
                        r=prog%expressions(prog%code(pc)%c)%rank
                    end if
                    if(r<1.or.r/=prog%expressions(mask)%rank) call mismatch(index,'WHERE target rank differs')
                class default
                    call mismatch(index,'WHERE body requires assignments')
                end select
            end do
        end subroutine
        subroutine check_forall(index,node)
            integer,intent(in)::index
            type(forall_node),intent(in)::node
            integer::entry,j,k,s,n,body,stmt
            entry=find_instruction(op_forall,node%line,0)
            if(entry==0) then
                call mismatch(index,'FORALL is absent from IR');return
            end if
            if(.not.allocated(node%index_names).or..not.allocated(node%lower_bound_indices).or. &
               .not.allocated(node%upper_bound_indices).or..not.allocated(node%stride_indices).or. &
               .not.allocated(prog%code(entry)%items)) then
                call mismatch(index,'FORALL header storage missing');return
            end if
            n=node%num_indices
            if(n<1.or.n>2) then
                call mismatch(index,'FORALL index count differs');return
            end if
            if(size(node%index_names)/=n.or.size(node%lower_bound_indices)/=n.or. &
               size(node%upper_bound_indices)/=n.or.size(node%stride_indices)/=n.or. &
               size(prog%code(entry)%items)/=4*n) then
                call mismatch(index,'FORALL header size differs');return
            end if
            do j=1,n
                k=4*(j-1);s=symbol_index(trim(node%index_names(j)))
                if(s<1.or.s/=prog%code(entry)%items(k+1)) then
                    call mismatch(index,'FORALL index binding differs');return
                end if
                if(prog%symbols(s)%scope/=current_scope.or.prog%symbols(s)%typ/=ty_integer.or. &
                   prog%symbols(s)%rank/=0.or.prog%symbols(s)%is_parameter.or.prog%symbols(s)%is_dummy) &
                    call mismatch(index,'FORALL index must be a local INTEGER variable')
                call expression(node%lower_bound_indices(j),prog%code(entry)%items(k+2),0)
                call expression(node%upper_bound_indices(j),prog%code(entry)%items(k+3),0)
                call require_scalar(index,prog%code(entry)%items(k+2))
                call require_scalar(index,prog%code(entry)%items(k+3))
                if(prog%code(entry)%items(k+4)/=0) then
                    call expression(node%stride_indices(j),prog%code(entry)%items(k+4),0)
                    call require_scalar(index,prog%code(entry)%items(k+4))
                else if(node%stride_indices(j)/=0) then
                    call mismatch(index,'FORALL stride differs')
                end if
            end do
            if(node%has_mask.neqv.(prog%code(entry)%a/=0)) call mismatch(index,'FORALL mask presence differs')
            if(node%has_mask) then
                call expression(node%mask_expr_index,prog%code(entry)%a,0)
                call require_scalar(index,prog%code(entry)%a)
            end if
            body=0
            if(allocated(node%body_indices)) body=size(node%body_indices)
            if(prog%code(entry)%target/=entry+1+body.or.prog%code(entry)%target>prog%nc+1) then
                call mismatch(index,'FORALL body interval differs');return
            end if
            do j=1,body
                stmt=node%body_indices(j)
                if(.not.front%arena%has_node_at(stmt)) then
                    call mismatch(index,'FORALL body node missing');return
                end if
                select type(assignment=>front%arena%entries(stmt)%node)
                type is(assignment_node)
                    if(assignment%is_keyword_argument.or.prog%code(entry+j)%op/=op_assign.or. &
                       prog%code(entry+j)%line/=assignment%line.or.prog%code(entry+j)%column/=assignment%column) &
                        call mismatch(index,'FORALL assignment order differs')
                class default
                    call mismatch(index,'FORALL body requires assignments')
                end select
            end do
        end subroutine
        subroutine check_if(index,node)
            integer,intent(in)::index
            type(if_node),intent(in)::node
            integer::branch,next_branch,j
            branch=find_instruction(op_branch,node%line,0)
            if(branch==0) then
                call mismatch(index,'IF is absent from IR');return
            end if
            call expression(node%condition_index,prog%code(branch)%a,0)
            call require_scalar(index,prog%code(branch)%a)
            if(.not.allocated(node%elseif_blocks).or.diag%code/=0) return
            do j=1,size(node%elseif_blocks)
                next_branch=prog%code(branch)%target
                if(next_branch<=branch.or.next_branch>prog%nc) then
                    call mismatch(index,'ELSE IF branch target differs');return
                end if
                if(prog%code(next_branch)%op/=op_branch.or.seen_code(next_branch).or. &
                   prog%code(next_branch)%scope/=current_scope) then
                    call mismatch(index,'ELSE IF branch identity differs');return
                end if
                seen_code(next_branch)=.true.;branch=next_branch
                call expression(node%elseif_blocks(j)%condition_index,prog%code(branch)%a,0)
                call require_scalar(index,prog%code(branch)%a)
                if(diag%code/=0) return
            end do
        end subroutine
        subroutine check_loop_transfer(index,pc,label)
            integer,intent(in)::index,pc
            character(:),allocatable,intent(in)::label
            character(63)::name
            integer::k,loop_pc,destination
            if(pc==0) then
                call mismatch(index,'EXIT/CYCLE is absent from IR');return
            end if
            name=''
            if(allocated(label)) name=lower(label)
            if(name/=prog%code(pc)%construct_name) then
                call mismatch(index,'EXIT/CYCLE construct name differs');return
            end if
            loop_pc=0
            do k=pc-1,1,-1
                if(prog%code(k)%op/=op_do.or.prog%code(k)%scope/=current_scope) cycle
                if(prog%code(k)%target<=pc) cycle
                if(len_trim(name)>0) then
                    if(name/=prog%code(k)%construct_name) cycle
                end if
                loop_pc=k;exit
            end do
            if(loop_pc==0.or.prog%code(pc)%a/=loop_pc) then
                call mismatch(index,'EXIT/CYCLE enclosing loop differs');return
            end if
            destination=prog%code(loop_pc)%target
            if(prog%code(pc)%op==op_cycle) destination=destination-1
            if(prog%code(pc)%target/=destination) &
                call mismatch(index,'EXIT/CYCLE destination differs')
        end subroutine
        subroutine check_type_definitions()
            integer::a,b,c,d,t,o,n,p,m,component_len
            type(declaration_query_t)::q
            logical::visible
            do a=1,front%arena%entry_count
                if(.not.front%arena%has_node_at(a)) cycle
                current_scope=node_scope(a)
                select type(node=>front%arena%entries(a)%node)
                type is(derived_type_node)
                    t=0
                    if(.not.allocated(node%name)) then
                        call mismatch(a,'TYPE name missing');return
                    end if
                    do b=1,prog%nt
                        if(prog%derived_types(b)%module_id/=-current_scope) cycle
                        if(trim(prog%derived_types(b)%name)==lower(node%name)) t=b
                    end do
                    if(t==0) then
                        call mismatch(a,'unexpected TYPE definition');return
                    end if
                    if(type_nodes(t)/=0.or.node%has_parameters) then
                        call mismatch(a,'unsupported or duplicate TYPE definition');return
                    end if
                    if(allocated(node%extends_parent)) then
                        if(len_trim(node%extends_parent)>0) call mismatch(a,'TYPE extension unsupported')
                    end if
                    type_nodes(t)=a
                    if(node%line/=prog%derived_types(t)%line.or.node%column/=prog%derived_types(t)%column) &
                        call mismatch(a,'TYPE location differs')
                    visible=.not.prog%module_private(-current_scope)
                    if(type_visibility_set(t)) visible=type_public(t)
                    if(allocated(node%attribute_clause)) then
                        select case(trim(lower(node%attribute_clause)))
                        case('public',', public',',public');visible=.true.
                        case('private',', private',',private');visible=.false.
                        case('')
                        case default
                            call mismatch(a,'unsupported TYPE attributes')
                        end select
                    end if
                    if(visible.neqv.prog%derived_types(t)%is_public) call mismatch(a,'TYPE visibility differs')
                    n=0
                    if(allocated(node%component_indices)) then
                        do b=1,size(node%component_indices)
                            c=node%component_indices(b)
                            if(.not.front%arena%has_node_at(c)) then
                                call mismatch(a,'TYPE component missing');return
                            end if
                            select type(comp=>front%arena%entries(c)%node)
                            type is(comment_node)
                                cycle
                            type is(declaration_node)
                                component_owner(c)=t
                                q=query_declaration(front%arena,c)
                                if(.not.q%found.or.comp%is_array.or.comp%is_pointer.or. &
                                   comp%is_allocatable.or.comp%has_intent.or.comp%is_parameter) then
                                    call mismatch(c,'unsupported TYPE component');return
                                end if
                                do d=1,size(q%names)
                                    n=n+1
                                    if(n>prog%derived_types(t)%ncomponents) then
                                        call mismatch(c,'extra TYPE component');return
                                    end if
                                    if(lower(q%names(d))/=trim(prog%derived_types(t)%component_names(n))) &
                                        call mismatch(c,'TYPE component name differs')
                                    call check_type(c,prog%derived_types(t)%component_types(n),0, &
                                        prog%derived_types(t)%component_kinds(n))
                                    if(prog%derived_types(t)%component_types(n)==ty_character) then
                                        component_len=1
                                        if(q%has_character_length) then
                                            if(.not.allocated(q%character_length_expr)) then
                                                call mismatch(c,'CHARACTER component length missing');return
                                            end if
                                            call check_length_text(c,q%character_length_expr, &
                                                prog%derived_types(t)%component_length_exprs(n),component_len)
                                        else if(prog%derived_types(t)%component_length_exprs(n)/=0) then
                                            call mismatch(c,'unexpected CHARACTER component length expression');return
                                        end if
                                        if(component_len<0.or.component_len>65536.or. &
                                           component_len/=prog%derived_types(t)%component_lengths(n)) &
                                            call mismatch(c,'CHARACTER component length cache differs')
                                    end if
                                    p=prog%derived_types(t)%component_initializers(n)
                                    if(comp%has_initializer.neqv.(p/=0)) then
                                        call mismatch(c,'TYPE component default presence differs');return
                                    end if
                                    if(p/=0) then
                                        if(size(q%names)/=1.or..not.valid_component_defaults(prog,t)) then
                                            call mismatch(c,'invalid TYPE component default metadata');return
                                        end if
                                        ! Bindings are compared after the ordinary declaration map exists.
                                        component_default_ir(c)=p
                                    end if
                                end do
                            class default
                                call mismatch(c,'unsupported TYPE body node')
                            end select
                        end do
                    end if
                    if(n/=prog%derived_types(t)%ncomponents) call mismatch(a,'TYPE component count differs')
                    if(any(prog%derived_types(t)%component_initializers(n+1:)/=0)) &
                        call mismatch(a,'unexpected trailing TYPE component defaults')
                    call check_type_bindings(a,t,node)
                type is(interface_block_node)
                    if(allocated(node%kind)) then
                        if(node%kind=='interface') then
                            call check_generic_definition(a,node)
                            if(diag%code/=0) return
                            cycle
                        end if
                    end if
                    o=0
                    if(.not.allocated(node%kind).or..not.allocated(node%operator)) then
                        call mismatch(a,'operator interface missing');return
                    end if
                    if(node%kind/='operator'.or.node%is_abstract) then
                        call mismatch(a,'unsupported interface');return
                    end if
                    do b=1,prog%no
                        if(prog%operators(b)%module_id/=-current_scope) cycle
                        if(normal_op(node%operator)==normal_op(prog%operators(b)%op)) o=b
                    end do
                    if(o==0) then
                        call mismatch(a,'unexpected operator interface');return
                    end if
                    if(operator_nodes(o)/=0) call mismatch(a,'duplicate operator interface')
                    operator_nodes(o)=a
                    visible=.not.prog%module_private(-current_scope)
                    if(operator_visibility_set(o)) visible=operator_public(o)
                    if(visible.neqv.prog%operators(o)%is_public) call mismatch(a,'operator visibility differs')
                    n=0
                    if(allocated(node%procedure_indices)) then
                        do b=1,size(node%procedure_indices)
                            c=node%procedure_indices(b)
                            if(.not.front%arena%has_node_at(c)) then
                                call mismatch(a,'operator procedure missing');return
                            end if
                            select type(proc=>front%arena%entries(c)%node)
                            type is(module_procedure_node)
                                component_owner(c)=-o
                                if(.not.proc%has_module_prefix.or..not.allocated(proc%procedure_names)) then
                                    call mismatch(c,'operator MODULE PROCEDURE missing');return
                                end if
                                do d=1,size(proc%procedure_names)
                                    n=n+1
                                    if(n>prog%operators(o)%nprocedures) then
                                        call mismatch(c,'extra operator procedure');return
                                    end if
                                    p=prog%operators(o)%procedures(n)
                                    if(p<1.or.p>prog%np) then
                                        call mismatch(c,'operator procedure binding invalid');return
                                    end if
                                    if(lower(proc%procedure_names(d)%s)/=trim(prog%operators(o)%procedure_names(n)).or. &
                                       trim(prog%procedures(p)%name)/=trim(prog%operators(o)%procedure_names(n)).or. &
                                       prog%procedures(p)%module_id/=-current_scope.or.prog%procedures(p)%is_subroutine) &
                                        call mismatch(c,'operator procedure identity differs')
                                    call check_operator_required_operands(c,p,normal_op(node%operator))
                                    if(diag%code/=0) return
                                end do
                            type is(comment_node)
                            class default
                                call mismatch(c,'unsupported operator interface body')
                            end select
                        end do
                    end if
                    if(n/=prog%operators(o)%nprocedures) call mismatch(a,'operator procedure count differs')
                end select
                if(diag%code/=0) return
            end do
            if(any(type_nodes==0)) call fail(diag,'FortFront adapter: missing TYPE definition')
            if(any(operator_nodes==0)) call fail(diag,'FortFront adapter: missing operator interface')
            if(any(generic_nodes==0)) call fail(diag,'FortFront adapter: missing named generic interface')
        end subroutine
        subroutine check_operator_required_operands(index,p,op)
            integer,intent(in)::index,p
            character(*),intent(in)::op
            integer::j,s,n
            logical::intrinsic_symbol,derived,character_operand
            if(.not.allocated(prog%procedures(p)%args)) then
                call mismatch(index,'operator procedure arguments missing');return
            end if
            n=size(prog%procedures(p)%args)
            if(prog%procedures(p)%is_subroutine.or.n<1.or.n>2) then
                call mismatch(index,'defined operators require one- or two-argument functions');return
            end if
            intrinsic_symbol=.false.;derived=.false.;character_operand=.false.
            select case(op)
            case('+','-','*','/','**','==','/=','<','<=','>','>=')
                intrinsic_symbol=.true.
            end select
            if(intrinsic_symbol.and.n/=2) then
                call mismatch(index,'intrinsic-symbol overloads require two operands');return
            end if
            do j=1,n
                s=prog%procedures(p)%args(j)
                if(s<1.or.s>prog%ns) then
                    call mismatch(index,'operator dummy binding invalid');return
                end if
                if(prog%symbols(s)%is_optional) then
                    call mismatch(index,'defined operator arguments cannot be OPTIONAL');return
                end if
                if(prog%symbols(s)%dummy_intent/=1) then
                    call mismatch(index,'defined operator arguments require INTENT(IN)');return
                end if
                derived=derived.or.is_derived_type(prog%symbols(s)%typ)
                character_operand=character_operand.or.prog%symbols(s)%typ==ty_character
            end do
            if(intrinsic_symbol.and..not.derived) then
                if(op/='+'.or..not.character_operand) &
                    call mismatch(index,'intrinsic-symbol overload requires a derived type operand or CHARACTER operand for +')
            end if
        end subroutine
        subroutine check_generic_definition(index,node)
            integer,intent(in)::index
            type(interface_block_node),intent(in)::node
            integer::g,j,k,a,n,p
            logical::visible
            g=0
            if(.not.allocated(node%name).or.node%is_abstract.or.current_scope>=0) then
                call mismatch(index,'named generic interface missing');return
            end if
            do j=1,prog%ng
                if(prog%generics(j)%module_id/=-current_scope) cycle
                if(trim(prog%generics(j)%name)==lower(node%name)) g=j
            end do
            if(g==0) then
                call mismatch(index,'unexpected generic interface');return
            end if
            if(generic_nodes(g)/=0) call mismatch(index,'duplicate generic interface')
            generic_nodes(g)=index
            if(node%line/=prog%generics(g)%line.or.node%column/=prog%generics(g)%column) &
                call mismatch(index,'generic interface location differs')
            visible=.not.prog%module_private(-current_scope)
            if(generic_visibility_set(g)) visible=generic_public(g)
            if(visible.neqv.prog%generics(g)%is_public) call mismatch(index,'generic visibility differs')
            n=0
            if(allocated(node%procedure_indices)) then
                do j=1,size(node%procedure_indices)
                    a=node%procedure_indices(j)
                    if(.not.front%arena%has_node_at(a)) then
                        call mismatch(index,'generic specific AST missing');return
                    end if
                    select type(specific=>front%arena%entries(a)%node)
                    type is(module_procedure_node)
                        component_owner(a)=-max_operators-g
                        if(.not.specific%has_module_prefix.or..not.allocated(specific%procedure_names)) then
                            call mismatch(a,'generic MODULE PROCEDURE missing');return
                        end if
                        do k=1,size(specific%procedure_names)
                            n=n+1
                            if(n>prog%generics(g)%nprocedures) then
                                call mismatch(a,'extra generic specific');return
                            end if
                            p=prog%generics(g)%procedures(n)
                            if(lower(specific%procedure_names(k)%s)/=trim(prog%generics(g)%procedure_names(n)).or. &
                               trim(prog%procedures(p)%name)/=trim(prog%generics(g)%procedure_names(n)).or. &
                               prog%procedures(p)%module_id/=-current_scope) &
                                call mismatch(a,'generic specific identity differs')
                        end do
                    type is(comment_node)
                    class default
                        call mismatch(a,'unsupported generic interface body')
                    end select
                end do
            end if
            if(n/=prog%generics(g)%nprocedures) call mismatch(index,'generic specific count differs')
        end subroutine
        subroutine check_generic_call(index,name,g,chosen,indices,expected)
            integer,intent(in)::index,g,chosen
            character(*),intent(in)::name
            integer,allocatable,intent(in)::indices(:),expected(:)
            type(declaration_binding_t)::binding
            character(:),allocatable::err
            character(63)::keywords(16),intrinsic_names(2)
            integer::n,nf,j,k,a,d,slot,f,winner,best,score,actuals(16),slots(16)
            logical::match
            if(g<1.or.g>prog%ng) then
                call mismatch(index,'generic call binding missing');return
            end if
            if(lower(name)/=trim(prog%generics(g)%name)) then
                call mismatch(index,'generic call name differs');return
            end if
            call resolve_name_in_scope(front%arena,scope_node(),name,binding,err)
            if(.not.binding%found.or.binding%binding_kind/=BINDING_GENERIC_INTERFACE.or. &
               binding%declaration_node_index/=generic_nodes(g)) then
                call mismatch(index,'generic declaration identity differs');return
            end if
            if(.not.allocated(expected)) then
                call mismatch(index,'generic IR arguments missing');return
            end if
            n=0
            if(allocated(indices)) n=size(indices)
            if(n>16.or.n/=count(expected/=0)) then
                call mismatch(index,'generic argument count differs');return
            end if
            intrinsic_names=[character(63)::'string','ncopies']
            if(chosen==0) then
                if(lower(name)/='repeat'.or.size(expected)/=2.or.n/=2) then
                    call mismatch(index,'invalid generic intrinsic fallback');return
                end if
                do j=1,prog%generics(g)%nprocedures
                    f=prog%generics(g)%procedures(j)
                    if(f<1.or.f>prog%np) then
                        call mismatch(index,'REPEAT generic specific binding invalid');return
                    end if
                    if(prog%procedures(f)%is_subroutine) then
                        call mismatch(index,'subroutine-generic REPEAT fallback is outside the supported subset');return
                    end if
                end do
            else
                if(chosen<1.or.chosen>prog%np) then
                    call mismatch(index,'generic chosen procedure missing');return
                end if
                if(size(expected)/=size(prog%procedures(chosen)%args)) then
                    call mismatch(index,'generic argument count differs');return
                end if
            end if
            keywords='';actuals=0
            ! Recover source-order actuals from AST keyword names and the chosen
            ! declaration. check_actual_arguments independently verifies each tree.
            do j=1,n
                a=indices(j)
                if(.not.front%arena%has_node_at(a)) then
                    call mismatch(index,'generic argument AST missing');return
                end if
                select type(arg=>front%arena%entries(a)%node)
                type is(assignment_node)
                    if(.not.arg%is_keyword_argument.or..not.front%arena%has_node_at(arg%target_index)) then
                        call mismatch(a,'generic keyword invalid');return
                    end if
                    select type(target=>front%arena%entries(arg%target_index)%node)
                    type is(identifier_node)
                        if(.not.allocated(target%name)) then
                            call mismatch(a,'generic keyword name missing');return
                        end if
                        keywords(j)=lower(target%name)
                    class default
                        call mismatch(a,'generic keyword name invalid');return
                    end select
                end select
                slot=j
                if(keywords(j)/='') then
                    do slot=1,size(expected)
                        if(chosen==0) then
                            if(intrinsic_names(slot)==keywords(j)) exit
                        else
                            d=prog%procedures(chosen)%args(slot)
                            if(prog%symbols(d)%name==keywords(j)) exit
                        end if
                    end do
                end if
                if(slot>size(expected)) then
                    call mismatch(index,'generic chosen keyword differs');return
                end if
                actuals(j)=expected(slot)
                if(actuals(j)<1.or.actuals(j)>prog%ne) then
                    call mismatch(index,'generic actual missing');return
                end if
            end do
            winner=0;best=-1
            do j=1,prog%generics(g)%nprocedures
                f=prog%generics(g)%procedures(j)
                nf=size(prog%procedures(f)%args)
                if(n>nf) cycle
                match=.true.;slots=0;score=1
                do k=1,n
                    slot=k
                    if(keywords(k)/='') then
                        do slot=1,nf
                            d=prog%procedures(f)%args(slot)
                            if(prog%symbols(d)%name==keywords(k)) exit
                        end do
                    end if
                    if((chosen==0.and.slot>nf).or.(chosen/=0.and.slot>size(expected))) then
                        match=.false.;exit
                    end if
                    if(slots(slot)/=0) then
                        match=.false.;exit
                    end if
                    slots(slot)=1;d=prog%procedures(f)%args(slot);a=actuals(k)
                    if(prog%expressions(a)%typ/=prog%symbols(d)%typ) match=.false.
                    if(prog%symbols(d)%typ==ty_integer.or.prog%symbols(d)%typ==ty_real) then
                        if(prog%expressions(a)%real_kind/=prog%symbols(d)%real_kind) match=.false.
                    end if
                    if(expression_rank(a)/=prog%symbols(d)%rank) then
                        if(prog%procedures(f)%is_elemental) then
                            score=0
                        else
                            match=.false.
                        end if
                    end if
                end do
                do k=1,nf
                    if(slots(k)==0.and..not.prog%symbols(prog%procedures(f)%args(k))%is_optional) match=.false.
                end do
                if(.not.match.or.score<best) cycle
                if(score==best) then
                    call mismatch(index,'ambiguous generic selection');return
                end if
                best=score;winner=f
            end do
            if(winner/=chosen) call mismatch(index,'generic specific selection differs')
        end subroutine
        subroutine check_type_bindings(index,t,node)
            integer,intent(in)::index,t
            type(derived_type_node),intent(in)::node
            integer::n,j,a,b,f,k
            logical::visible,found_write
            character(:),allocatable::target,err
            type(declaration_binding_t)::binding
            n=0;found_write=.false.
            if(allocated(node%binding_indices)) then
                do j=1,size(node%binding_indices)
                    a=node%binding_indices(j)
                    if(.not.front%arena%has_node_at(a)) then
                        call mismatch(index,'TYPE binding missing');return
                    end if
                    select type(q=>front%arena%entries(a)%node)
                    type is(type_binding_node)
                        component_owner(a)=t
                        if(.not.allocated(q%binding_name)) then
                            call mismatch(a,'TYPE binding name missing');return
                        end if
                        if(q%is_final.or.q%is_deferred.or..not.q%pass_arg) &
                            call mismatch(a,'unsupported TYPE binding attributes')
                        if(allocated(q%interface_name)) then
                            if(len_trim(q%interface_name)>0) call mismatch(a,'explicit binding interface unsupported')
                        end if
                        if(allocated(q%pass_name)) then
                            if(len_trim(q%pass_name)>0) call mismatch(a,'named PASS unsupported')
                        end if
                        if(q%is_generic) then
                            if(found_write.or.lower(q%binding_name)/='write(formatted)') then
                                call mismatch(a,'unsupported or duplicate generic binding');return
                            end if
                            if(.not.allocated(q%generic_list)) then
                                call mismatch(a,'WRITE generic target missing');return
                            end if
                            if(size(q%generic_list)/=1) then
                                call mismatch(a,'WRITE generic target count differs');return
                            end if
                            if(lower(q%generic_list(1)%s)/=trim(prog%derived_types(t)%write_binding)) &
                                call mismatch(a,'WRITE generic target differs')
                            if(q%line/=prog%derived_types(t)%write_line.or.q%column/=prog%derived_types(t)%write_column) &
                                call mismatch(a,'WRITE generic location differs')
                            found_write=.true.;cycle
                        end if
                        n=n+1;b=n
                        if(b>prog%derived_types(t)%nbindings) then
                            call mismatch(a,'extra TYPE binding');return
                        end if
                        if(lower(q%binding_name)/=trim(prog%derived_types(t)%binding_names(b))) &
                            call mismatch(a,'TYPE binding name differs')
                        target=q%binding_name
                        if(allocated(q%implementation)) target=q%implementation
                        if(lower(target)/=trim(prog%derived_types(t)%binding_targets(b))) &
                            call mismatch(a,'TYPE binding target differs')
                        visible=.true.
                        if(allocated(q%accessibility)) visible=lower(q%accessibility)/='private'
                        if(visible.neqv.prog%derived_types(t)%binding_public(b)) call mismatch(a,'binding visibility differs')
                        if(q%line/=prog%derived_types(t)%binding_lines(b).or. &
                           q%column/=prog%derived_types(t)%binding_columns(b)) call mismatch(a,'binding location differs')
                        f=prog%derived_types(t)%binding_procedures(b)
                        if(f<1.or.f>prog%np) then
                            call mismatch(a,'binding implementation missing');return
                        end if
                        call resolve_name_in_scope(front%arena,module_node_index(prog%derived_types(t)%module_id), &
                            target,binding,err)
                        if(.not.binding%found.or.binding%declaration_node_index/=procedure_node(f)) &
                            call mismatch(a,'binding implementation identity differs')
                        if(size(prog%procedures(f)%args)<1) then
                            call mismatch(a,'passed-object dummy missing');return
                        end if
                        k=prog%procedures(f)%args(1)
                        if(prog%symbols(k)%typ/=ty_derived_base+t.or..not.prog%symbols(k)%is_class.or. &
                           prog%symbols(k)%rank/=0) call mismatch(a,'passed-object dummy differs')
                        if(prog%derived_types(t)%write_binding==prog%derived_types(t)%binding_names(b)) then
                            if(prog%derived_types(t)%write_procedure/=f) call mismatch(a,'defined WRITE target differs')
                        end if
                    type is(comment_node)
                    class default
                        call mismatch(a,'unsupported TYPE binding node')
                    end select
                end do
            end if
            if(n/=prog%derived_types(t)%nbindings) call mismatch(index,'TYPE binding count differs')
            if(found_write.neqv.(len_trim(prog%derived_types(t)%write_binding)>0)) &
                call mismatch(index,'WRITE generic presence differs')
        end subroutine
        subroutine check_bound_call(index,t,b,f,receiver)
            integer,intent(in)::index,t,b,f,receiver
            type(type_bound_call_query_t)::q
            integer::s,host
            if(t<1.or.t>prog%nt.or.receiver<1.or.receiver>prog%ne) then
                call mismatch(index,'type-bound call metadata invalid');return
            end if
            if(b<1.or.b>prog%derived_types(t)%nbindings) then
                call mismatch(index,'type-bound binding index invalid');return
            end if
            if(prog%derived_types(t)%binding_procedures(b)/=f) call mismatch(index,'type-bound procedure differs')
            s=prog%expressions(receiver)%symbol
            if(prog%expressions(receiver)%kind/=ex_variable.or.s<1.or.s>prog%ns) then
                call mismatch(index,'type-bound receiver must be a scalar variable');return
            end if
            if(prog%symbols(s)%typ/=ty_derived_base+t.or.prog%symbols(s)%rank/=0) &
                call mismatch(index,'type-bound receiver type differs')
            host=0
            if(current_scope>0) host=prog%procedures(current_scope)%module_id
            if(.not.prog%derived_types(t)%binding_public(b).and.host/=prog%derived_types(t)%module_id) &
                call mismatch(index,'private type-bound call outside defining module')
            q=query_type_bound_call(front%arena,index)
            if(.not.q%found.or.q%is_inherited.or.q%is_deferred.or.q%is_generic) then
                call mismatch(index,'type-bound call did not resolve');return
            end if
            if(len_trim(q%implementation)==0) q%implementation=q%binding_name
            if(q%declared_type_index/=type_nodes(t).or.q%receiver_declaration_index/=symbol_declaration(s).or. &
               q%binding_name/=trim(prog%derived_types(t)%binding_names(b)).or. &
               q%implementation/=trim(prog%procedures(f)%name)) call mismatch(index,'type-bound call identity differs')
            if(q%receiver_node_index>0) call expression(q%receiver_node_index,receiver,0)
        end subroutine
        logical function component_assignable(from_type,to_type) result(ok)
            integer,intent(in)::from_type,to_type
            ok=from_type==to_type
            if((from_type==ty_integer.or.from_type==ty_real).and. &
               (to_type==ty_integer.or.to_type==ty_real)) ok=.true.
        end function
        subroutine component_target(index,symbol,component,rhs)
            integer,intent(in)::index,symbol,component,rhs
            integer::t
            t=prog%symbols(symbol)%typ-ty_derived_base
            if(t<1.or.t>prog%nt) then
                call mismatch(index,'component target type invalid');return
            end if
            if(component<1.or.component>prog%derived_types(t)%ncomponents) then
                call mismatch(index,'component target index invalid');return
            end if
            select type(node=>front%arena%entries(index)%node)
            type is(component_access_node)
                if(.not.allocated(node%component_name)) then
                    call mismatch(index,'component target name missing');return
                end if
                if(lower(node%component_name)/=trim(prog%derived_types(t)%component_names(component))) &
                    call mismatch(index,'component target name differs')
                call assignment_target(node%base_expr_index,symbol,0,0,0,0)
                if(rhs<1.or.rhs>prog%ne) then
                    call mismatch(index,'component RHS missing');return
                end if
                if(.not.component_assignable(prog%expressions(rhs)%typ,prog%derived_types(t)%component_types(component))) &
                    call mismatch(index,'component assignment type differs')
            class default
                call mismatch(index,'component target shape differs')
            end select
        end subroutine
        subroutine check_operator_binding(index,e)
            integer,intent(in)::index,e
            integer::o,p,m,j,k,d,a,winner,score,best,host
            logical::visible,match,ambiguous
            winner=0;best=-1;ambiguous=.false.;host=0
            if(current_scope<0) host=-current_scope
            if(current_scope>0) host=prog%procedures(current_scope)%module_id
            do o=1,prog%no
                if(normal_op(prog%operators(o)%op)/=normal_op(prog%expressions(e)%op)) cycle
                m=prog%operators(o)%module_id
                visible=host==m
                if(.not.visible.and.prog%operators(o)%is_public) then
                    do j=1,prog%nu
                        if(prog%uses(j)/=m.or.prog%use_scopes(j)/=-host) cycle
                        if(.not.prog%use_only(j)) then
                            visible=.true.
                        else
                            do k=1,prog%n_only(j)
                                if(trim(prog%only_names(k,j))=='operator('//trim(prog%operators(o)%op)//')') &
                                    visible=.true.
                            end do
                        end if
                    end do
                end if
                if(.not.visible) cycle
                do j=1,prog%operators(o)%nprocedures
                    p=prog%operators(o)%procedures(j)
                    if(.not.allocated(prog%procedures(p)%args)) cycle
                    if(size(prog%procedures(p)%args)/=size(prog%expressions(e)%args)) cycle
                    match=.true.;score=1
                    do k=1,size(prog%expressions(e)%args)
                        d=prog%procedures(p)%args(k);a=prog%expressions(e)%args(k)
                        if(prog%symbols(d)%typ/=prog%expressions(a)%typ.or. &
                           prog%symbols(d)%real_kind/=prog%expressions(a)%real_kind) match=.false.
                        if(prog%symbols(d)%dummy_intent/=1) match=.false.
                        if(prog%symbols(d)%rank/=expression_rank(a)) then
                            if(prog%procedures(p)%is_elemental.and.prog%symbols(d)%rank==0) then
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
                        winner=p;best=score;ambiguous=.false.
                    end if
                end do
            end do
            if(winner==0.or.ambiguous) then
                call mismatch(index,'operator binding missing or ambiguous')
            else if(winner/=prog%expressions(e)%symbol) then
                call mismatch(index,'operator resolution differs')
            end if
        end subroutine
        subroutine check_select(index,node)
            integer,intent(in)::index
            type(select_case_node),intent(in)::node
            integer,allocatable::nodes(:),pcs(:)
            integer::entry,n,j,k,a,b,t,next_pc,finish,v,lo,hi,selector_type,alternatives
            if(diag%code/=0) return
            entry=find_instruction(op_select,node%line,0)
            if(entry==0) then
                call mismatch(index,'SELECT CASE is absent from IR');return
            end if
            call expression(node%selector_index,prog%code(entry)%a,0)
            call require_scalar(index,prog%code(entry)%a)
            if(diag%code/=0) return
            selector_type=prog%expressions(prog%code(entry)%a)%typ
            if(selector_type/=ty_integer.and.selector_type/=ty_logical.and.selector_type/=ty_character) &
                call mismatch(index,'SELECT selector type differs')
            allocate(nodes(0))
            if(allocated(node%case_indices)) nodes=node%case_indices
            if(node%default_index/=0) nodes=[nodes,node%default_index]
            n=size(nodes);allocate(pcs(n));alternatives=0
            do j=1,n
                if(.not.front%arena%has_node_at(nodes(j))) then
                    call mismatch(index,'CASE node missing');return
                end if
                pcs(j)=find_instruction(op_case,front%arena%entries(nodes(j))%node%line,0)
                if(pcs(j)==0) then
                    call mismatch(nodes(j),'CASE is absent from IR');return
                end if
            end do
            ! The AST keeps DEFAULT separately. Reconstruct lexical order.
            do j=2,n
                a=pcs(j);b=nodes(j);k=j-1
                do while(k>=1)
                    if(pcs(k)<a) exit
                    pcs(k+1)=pcs(k);nodes(k+1)=nodes(k);k=k-1
                end do
                pcs(k+1)=a;nodes(k+1)=b
            end do
            finish=prog%code(entry)%target
            if(finish<=entry.or.finish>prog%nc+1) then
                call mismatch(index,'SELECT exit target differs');return
            end if
            if(n==0) then
                if(finish/=entry+1) call mismatch(index,'empty SELECT contains code')
                return
            end if
            if(pcs(1)/=entry+1) call mismatch(index,'SELECT first CASE differs')
            do j=2,n
                if(front%arena%entries(nodes(j))%node%line<front%arena%entries(nodes(j-1))%node%line) &
                    call mismatch(index,'CASE source order differs')
            end do
            do j=1,n
                a=pcs(j);b=nodes(j);next_pc=finish
                if(checked_ranges(b)) call mismatch(b,'CASE block belongs to multiple SELECTs')
                checked_ranges(b)=.true.
                if(j<n) next_pc=pcs(j+1)
                if(a<=entry.or.a>=finish.or.next_pc<=a+1) then
                    call mismatch(b,'CASE instruction interval differs');return
                end if
                if(prog%code(a)%a/=entry.or.prog%code(a)%target/=next_pc.or. &
                   prog%code(a)%scope/=prog%code(entry)%scope) &
                    call mismatch(b,'CASE chain differs')
                if(prog%code(next_pc-1)%op/=op_jump.or.prog%code(next_pc-1)%target/=finish) &
                    call mismatch(b,'CASE exit jump differs')
                if(.not.allocated(prog%code(a)%items)) then
                    call mismatch(b,'CASE values missing');return
                end if
                select type(arm=>front%arena%entries(b)%node)
                type is(case_default_node)
                    if(size(prog%code(a)%items)/=0) call mismatch(b,'DEFAULT has CASE values')
                type is(case_block_node)
                    if(.not.allocated(arm%value_indices)) then
                        call mismatch(b,'CASE values missing');return
                    end if
                    alternatives=alternatives+size(arm%value_indices)
                    if(alternatives>64) then
                        call mismatch(b,'CASE value/range limit exceeded (64)');return
                    end if
                    if(size(prog%code(a)%items)/=2*size(arm%value_indices)) then
                        call mismatch(b,'CASE value count differs');return
                    end if
                    do k=1,size(arm%value_indices)
                        v=arm%value_indices(k);lo=prog%code(a)%items(2*k-1);hi=prog%code(a)%items(2*k)
                        if(.not.front%arena%has_node_at(v)) then
                            call mismatch(b,'CASE value missing');return
                        end if
                        select type(bound=>front%arena%entries(v)%node)
                        type is(case_range_node)
                            checked_ranges(v)=.true.
                            if(selector_type==ty_logical.or.(lo==0.and.hi==0)) &
                                call mismatch(v,'invalid CASE range')
                            if((lo==0).neqv.(bound%start_value==0)) call mismatch(v,'CASE lower bound differs')
                            if((hi==0).neqv.(bound%end_value==0)) call mismatch(v,'CASE upper bound differs')
                            if(lo/=0) call expression(bound%start_value,lo,0)
                            if(hi/=0) call expression(bound%end_value,hi,0)
                        class default
                            if(lo/=hi.or.lo==0) then
                                call mismatch(v,'discrete CASE value differs');return
                            end if
                            call expression(v,lo,0)
                        end select
                        if(diag%code/=0) return
                        do t=1,2
                            v=prog%code(a)%items(2*k-2+t)
                            if(v==0) cycle
                            call require_scalar(b,v)
                            if(diag%code/=0) return
                            if(prog%expressions(v)%typ/=selector_type) call mismatch(b,'CASE value type differs')
                            call check_initializer(b,v,0)
                        end do
                    end do
                class default
                    call mismatch(b,'unexpected CASE node')
                end select
                if(diag%code/=0) return
            end do
        end subroutine
        subroutine check_call_graph()
            ! Analyze reachability from every root, not a DFS postorder. Cycles
            ! must not hide effects from another member of a recursive component.
            integer::p,e,c,s,j,f,n,edge_count,edge,top,node,ios
            integer,allocatable::head(:),targets(:),next_edge(:),pending(:)
            logical,allocatable::visited(:),external_effect(:)
            n=prog%np
            allocate(head(n),targets(prog%ne+prog%nc),next_edge(prog%ne+prog%nc), &
                     pending(n),visited(n),external_effect(n),stat=ios)
            if(ios/=0) then
                call fail(diag,'FortFront adapter: unable to allocate procedure graph');return
            end if
            head=0;edge_count=0;external_effect=.false.
            do e=1,prog%ne
                if(prog%expressions(e)%kind/=ex_user_call) cycle
                p=prog%expressions(e)%scope;f=prog%expressions(e)%symbol
                if(p<=0) cycle
                if(p>n.or.f<1.or.f>n) then
                    call fail(diag,'FortFront adapter: invalid function binding');return
                end if
                edge_count=edge_count+1;targets(edge_count)=f
                next_edge(edge_count)=head(p);head(p)=edge_count
            end do
            do c=1,prog%nc
                p=prog%code(c)%scope
                if(p<=0) cycle
                if(p>n) then
                    call fail(diag,'FortFront adapter: invalid procedure scope');return
                end if
                if(prog%code(c)%op==op_print.or. &
                   prog%code(c)%op==op_write_defined) external_effect(p)=.true.
                s=module_write_target(prog%code(c))
                if(s>0) then
                    if((prog%symbols(s)%scope<0.or.prog%symbols(s)%is_saved.or. &
                       (prog%symbols(s)%scope>0.and.prog%symbols(s)%scope/=p)).and. &
                       .not.prog%symbols(s)%is_parameter) external_effect(p)=.true.
                end if
                if(prog%code(c)%op/=op_call) cycle
                f=prog%code(c)%symbol
                if(f<1.or.f>n) then
                    call fail(diag,'FortFront adapter: invalid CALL binding');return
                end if
                do j=1,size(prog%code(c)%items)
                    s=prog%code(c)%items(j)
                    if(s==0) cycle
                    if(prog%symbols(prog%procedures(f)%args(j))%dummy_intent<2) cycle
                    s=prog%expressions(s)%symbol
                    if(s>0) then
                        if(prog%symbols(s)%scope<0.or.prog%symbols(s)%is_saved.or. &
                       (prog%symbols(s)%scope>0.and.prog%symbols(s)%scope/=p)) external_effect(p)=.true.
                    end if
                end do
                edge_count=edge_count+1;targets(edge_count)=f
                next_edge(edge_count)=head(p);head(p)=edge_count
            end do
            do p=1,n
                visited=.false.;visited(p)=.true.;top=1;pending(top)=p
                do while(top>0)
                    node=pending(top);top=top-1;edge=head(node)
                    do while(edge/=0)
                        f=targets(edge)
                        if(f==p.and..not.prog%procedures(p)%is_recursive) then
                            call fail(diag,'FortFront adapter: recursive cycle requires RECURSIVE');return
                        end if
                        if(.not.visited(f)) then
                            visited(f)=.true.;top=top+1;pending(top)=f
                        end if
                        edge=next_edge(edge)
                    end do
                end do
                if(prog%procedures(p)%is_subroutine.or.prog%procedures(p)%has_impure_prefix) cycle
                if(any(visited.and.external_effect)) then
                    call fail(diag,'FortFront adapter: function transitively performs external effects');return
                end if
            end do
        end subroutine
        subroutine map_units()
            integer::a,b,c,m,p,n,idx,previous,owner,host
            logical,allocatable::dummy_seen(:)
            allocate(dummy_seen(prog%ns),source=.false.)
            do a=1,front%arena%entry_count
                if(.not.front%arena%has_node_at(a)) cycle
                select type(node=>front%arena%entries(a)%node)
                type is(program_node)
                    if(main_node/=0) then
                        call mismatch(a,'multiple main programs'); return
                    end if
                    main_node=a;scope_map(a)=0
                type is(module_node)
                    if(.not.allocated(node%name)) then
                        call mismatch(a,'module name missing'); return
                    end if
                    m=0
                    do b=1,prog%nm
                        if(trim(prog%modules(b))==lower(node%name)) m=b
                    end do
                    if(m==0) then
                        call mismatch(a,'unexpected module'); return
                    end if
                    if(module_node_index(m)/=0) then
                        call mismatch(a,'duplicate module or missing CONTAINS'); return
                    end if
                    module_node_index(m)=a;scope_map(a)=-m
                end select
            end do
            do a=1,front%arena%entry_count
                if(.not.front%arena%has_node_at(a)) cycle
                select type(node=>front%arena%entries(a)%node)
                type is(function_def_node)
                    if(.not.allocated(node%name)) then
                        call mismatch(a,'function name missing'); return
                    end if
                    p=map_procedure(a,node%name,.false.)
                    if(p==0) return
                    call check_prefix(a,node%prefix_keywords,node%is_recursive,node%bind_c_clause,p)
                    n=prog%procedures(p)%result_symbol
                    if(n<1.or.n>prog%ns) then
                        call mismatch(a,'function result missing'); return
                    end if
                    if(allocated(node%result_variable)) then
                        if(len_trim(node%result_variable)>0) then
                            if(lower(node%result_variable)/=trim(prog%symbols(n)%name)) &
                                call mismatch(a,'function RESULT name differs')
                        else
                            if(lower(node%name)/=trim(prog%symbols(n)%name)) &
                                call mismatch(a,'implicit function result differs')
                        end if
                    else
                        if(lower(node%name)/=trim(prog%symbols(n)%name)) &
                            call mismatch(a,'implicit function result differs')
                    end if
                    if( &
                       prog%symbols(n)%scope/=p.or.prog%symbols(n)%is_dummy.or. &
                       (prog%procedures(p)%is_elemental.and.prog%symbols(n)%rank/=0)) &
                        call mismatch(a,'function result identity differs')
                    if(node%has_return_type_in_header) then
                        symbol_declaration(n)=a;seen_symbol(n)=.true.
                        current_scope=p
                        call check_type(a,prog%symbols(n)%typ,0,prog%symbols(n)%real_kind)
                        if(prog%symbols(n)%typ==ty_character) call check_character_header(a,n,node)
                    end if
                    call check_params(a,node%param_indices,p,dummy_seen)
                type is(subroutine_def_node)
                    if(.not.allocated(node%name)) then
                        call mismatch(a,'subroutine name missing'); return
                    end if
                    p=map_procedure(a,node%name,.true.)
                    if(p==0) return
                    call check_prefix(a,node%prefix_keywords,node%is_recursive,node%bind_c_clause,p)
                    if(prog%procedures(p)%result_symbol/=0) call mismatch(a,'subroutine has result')
                    call check_params(a,node%param_indices,p,dummy_seen)
                end select
                if(diag%code/=0) return
            end do
            if(main_node==0.or.any(procedure_node==0).or.any(module_node_index==0)) then
                call fail(diag,'FortFront adapter: missing program, module or procedure'); return
            end if
            call map_body(main_node,0,0)
            do m=1,prog%nm
                call map_body(module_node_index(m),-m,0)
                call check_visibility(m)
            end do
            do p=1,prog%np
                call map_body(procedure_node(p),p,0)
            end do
            do a=1,prog%ns
                if(prog%symbols(a)%scope < -prog%nm.or.prog%symbols(a)%scope>prog%np.or. &
                   (prog%symbols(a)%is_dummy.neqv.dummy_seen(a))) &
                    call fail(diag,'FortFront adapter: symbol scope/dummy cache differs')
            end do
            ! Function code is contiguous before main. Control transfers must
            ! remain in their function (or its one-past-end exit), never main.
            previous=1
            do p=1,prog%np
                if(prog%procedures(p)%first/=previous.or. &
                   prog%procedures(p)%last<previous-1.or.prog%procedures(p)%last>prog%nc) then
                    call fail(diag,'FortFront adapter: invalid function instruction interval')
                    return
                end if
                previous=prog%procedures(p)%last+1
            end do
            if(prog%entry_pc/=previous.or.prog%entry_pc>prog%nc+1) &
                call fail(diag,'FortFront adapter: main entry differs')
            do a=1,prog%nc
                owner=instruction_scope(a)
                if(prog%code(a)%scope/=owner) &
                    call fail(diag,'FortFront adapter: instruction scope cache differs')
                if(prog%code(a)%op==op_next) then
                    b=prog%code(a)%a
                    if(b<1.or.b>=a) then
                        call fail(diag,'FortFront adapter: invalid DO back edge')
                        return
                    end if
                    if(prog%code(b)%op/=op_do.or.instruction_scope(b)/=owner.or. &
                       prog%code(a)%target/=b+1.or.prog%code(b)%target/=a+1.or. &
                       prog%code(a)%d/=prog%code(b)%d.or.prog%code(a)%symbol/=prog%code(b)%symbol) &
                        call fail(diag,'FortFront adapter: DO back edge identity differs')
                end if
                if(prog%code(a)%op==op_jump.or.prog%code(a)%op==op_branch.or. &
                   prog%code(a)%op==op_do.or.prog%code(a)%op==op_next.or.prog%code(a)%op==op_forall.or. &
                   prog%code(a)%op==op_where.or.prog%code(a)%op==op_elsewhere.or. &
                   prog%code(a)%op==op_exit.or.prog%code(a)%op==op_cycle.or. &
                   prog%code(a)%op==op_select.or.prog%code(a)%op==op_case) then
                    b=prog%code(a)%target
                    if(owner>0) then
                        if(b<prog%procedures(owner)%first.or.b>prog%procedures(owner)%last+1) &
                            call fail(diag,'FortFront adapter: function control transfer escapes scope')
                    else
                        if(b<prog%entry_pc.or.b>prog%nc+1) &
                            call fail(diag,'FortFront adapter: main control transfer escapes scope')
                    end if
                end if
            end do
        end subroutine
        integer function map_procedure(index,name,is_subroutine) result(p)
            integer,intent(in)::index
            character(*),intent(in)::name
            logical,intent(in)::is_subroutine
            integer::h,m,j,host
            p=0;h=front%arena%entries(index)%parent_index;m=-1;host=0
            if(h>0) h=find_enclosing_scope(front%arena,h)
            if(h==main_node) m=0
            do j=1,prog%nm
                if(h==module_node_index(j)) m=j
            end do
            if(m<0.and.h>0) then
                do j=1,prog%np
                    if(prog%procedures(j)%line/=front%arena%entries(h)%node%line.or. &
                       prog%procedures(j)%column/=front%arena%entries(h)%node%column) cycle
                    select type(owner=>front%arena%entries(h)%node)
                    type is(function_def_node)
                        if(allocated(owner%name)) then
                            if(lower(owner%name)==prog%procedures(j)%name) host=j
                        end if
                    type is(subroutine_def_node)
                        if(allocated(owner%name)) then
                            if(lower(owner%name)==prog%procedures(j)%name) host=j
                        end if
                    end select
                end do
                if(host>0) m=prog%procedures(host)%module_id
            end if
            if(m<0) then
                call mismatch(index,'procedure outside supported host'); return
            end if
            do j=1,prog%np
                if(prog%procedures(j)%module_id==m.and.prog%procedures(j)%parent_procedure==host.and. &
                   trim(prog%procedures(j)%name)==lower(name)) p=j
            end do
            if(p==0) then
                call mismatch(index,'unexpected procedure'); return
            end if
            if(procedure_node(p)/=0.or.(prog%procedures(p)%is_subroutine.neqv.is_subroutine)) &
                call mismatch(index,'duplicate procedure or kind differs')
            if(m>0) then
                if(prog%procedures(p)%module_name/=prog%modules(m)) call mismatch(index,'module identity differs')
            else
                if(len_trim(prog%procedures(p)%module_name)/=0) call mismatch(index,'internal procedure module differs')
            end if
            procedure_node(p)=index;scope_map(index)=p
            if(front%arena%entries(index)%node%line/=prog%procedures(p)%line.or. &
               front%arena%entries(index)%node%column/=prog%procedures(p)%column) &
                call mismatch(index,'procedure location differs')
        end function
        subroutine check_prefix(index,keywords,recursive_flag,bind_clause,p)
            integer,intent(in)::index,p
            character(16),allocatable,intent(in)::keywords(:)
            character(:),allocatable,intent(in)::bind_clause
            logical,intent(in)::recursive_flag
            logical::pure_flag,simple_flag,elemental_flag,impure_flag,recursive_prefix
            integer::j
            pure_flag=.false.;simple_flag=.false.;elemental_flag=.false.;impure_flag=.false.
            recursive_prefix=.false.
            if(allocated(bind_clause)) then
                if(len_trim(bind_clause)>0) call mismatch(index,'BIND unsupported')
            end if
            if(allocated(keywords)) then
                do j=1,size(keywords)
                    select case(lower(trim(keywords(j))))
                    case('recursive')
                        if(recursive_prefix) call mismatch(index,'duplicate RECURSIVE procedure prefix')
                        recursive_prefix=.true.
                    case('pure')
                        if(pure_flag) call mismatch(index,'duplicate PURE procedure prefix')
                        pure_flag=.true.
                    case('impure')
                        if(impure_flag) call mismatch(index,'duplicate IMPURE procedure prefix')
                        impure_flag=.true.
                    case('elemental')
                        if(elemental_flag) call mismatch(index,'duplicate ELEMENTAL procedure prefix')
                        elemental_flag=.true.
                    case('simple')
                        if(simple_flag) call mismatch(index,'duplicate SIMPLE procedure prefix')
                        simple_flag=.true.
                    case default
                        call mismatch(index,'unsupported procedure prefix')
                    end select
                end do
            end if
            if(recursive_prefix.neqv.recursive_flag) call mismatch(index,'RECURSIVE producer metadata differs')
            if(recursive_flag.neqv.prog%procedures(p)%is_recursive) call mismatch(index,'RECURSIVE attribute differs')
            if(recursive_flag.and.elemental_flag) call mismatch(index,'RECURSIVE ELEMENTAL unsupported')
            if((pure_flag.or.simple_flag.or.(elemental_flag.and..not.impure_flag)).neqv.prog%procedures(p)%is_pure) call mismatch(index,'PURE attribute differs: '//trim(prog%procedures(p)%name))
            if(pure_flag.neqv.prog%procedures(p)%has_pure_prefix) call mismatch(index,'explicit PURE prefix differs')
            if(simple_flag.neqv.prog%procedures(p)%is_simple) call mismatch(index,'SIMPLE attribute differs')
            if(elemental_flag.neqv.prog%procedures(p)%is_elemental) call mismatch(index,'ELEMENTAL attribute differs')
            if(impure_flag.neqv.prog%procedures(p)%has_impure_prefix) call mismatch(index,'IMPURE attribute differs')
            if(impure_flag.and.(pure_flag.or.simple_flag.or..not.elemental_flag)) &
                call mismatch(index,'invalid IMPURE designation')
        end subroutine
        subroutine check_params(index,indices,p,dummy_seen)
            integer,intent(in)::index,p
            integer,allocatable,intent(in)::indices(:)
            logical,intent(inout)::dummy_seen(:)
            integer::n,j
            if(.not.allocated(prog%procedures(p)%args)) then
                call mismatch(index,'IR procedure parameters missing'); return
            end if
            n=0
            if(allocated(indices)) n=size(indices)
            if(n/=size(prog%procedures(p)%args)) then
                call mismatch(index,'procedure parameter count differs'); return
            end if
            do j=1,n
                call check_dummy(indices(j),prog%procedures(p)%args(j),p)
                if(diag%code/=0) return
                dummy_seen(prog%procedures(p)%args(j))=.true.
            end do
        end subroutine
        subroutine check_visibility(m)
            integer,intent(in)::m
            integer::i,j,k,p
            logical::default_private,visible
            logical,allocatable::symbols_public(:),procedures_public(:),symbol_set(:),procedure_set(:)
            allocate(symbols_public(prog%ns),source=.true.)
            allocate(procedures_public(prog%np),source=.true.)
            allocate(symbol_set(prog%ns),source=.false.)
            allocate(procedure_set(prog%np),source=.false.)
            default_private=.false.
            select type(mod=>front%arena%entries(module_node_index(m))%node)
            type is(module_node)
                if(.not.allocated(mod%declaration_indices)) return
                do j=1,size(mod%declaration_indices)
                    i=mod%declaration_indices(j)
                    select type(node=>front%arena%entries(i)%node)
                    type is(visibility_statement_node)
                        if(.not.node%has_list) then
                            default_private=node%is_private
                        else
                            if(.not.allocated(node%names)) then
                                call mismatch(i,'visibility names missing'); return
                            end if
                            do k=1,size(node%names)
                                call set_visibility(node%names(k)%s,.not.node%is_private,i,m, &
                                    symbols_public,procedures_public,symbol_set,procedure_set)
                            end do
                        end if
                    type is(declaration_node)
                        if(allocated(node%accessibility)) then
                            if(len_trim(node%accessibility)>0) then
                                visible=lower(node%accessibility)=='public'
                                if(node%is_multi_declaration.and.allocated(node%var_names)) then
                                    do k=1,size(node%var_names)
                                        call set_visibility(node%var_names(k),visible,i,m, &
                                            symbols_public,procedures_public,symbol_set,procedure_set)
                                    end do
                                else
                                    call set_visibility(node%var_name,visible,i,m, &
                                        symbols_public,procedures_public,symbol_set,procedure_set)
                                end if
                            end if
                        end if
                    type is(derived_type_node)
                    type is(interface_block_node)
                    type is(use_statement_node)
                    type is(implicit_statement_node)
                    type is(comment_node)
                    class default
                        call mismatch(i,'unsupported module declaration')
                    end select
                end do
            end select
            if(default_private.neqv.prog%module_private(m)) call mismatch(module_node_index(m),'module default visibility differs')
            do i=1,prog%ns
                if(prog%symbols(i)%scope/=-m) cycle
                if(.not.symbol_set(i)) symbols_public(i)=.not.default_private
                if(symbols_public(i).neqv.prog%symbols(i)%is_public) &
                    call mismatch(module_node_index(m),'symbol visibility differs')
            end do
            do i=1,prog%np
                if(prog%procedures(i)%module_id/=m.or.prog%procedures(i)%parent_procedure/=0) cycle
                if(.not.procedure_set(i)) procedures_public(i)=.not.default_private
                if(procedures_public(i).neqv.prog%procedures(i)%is_public) &
                    call mismatch(module_node_index(m),'procedure visibility differs')
            end do
        end subroutine
            subroutine set_visibility(name,visible,index,m,symbols_public,procedures_public,symbol_set,procedure_set)
                character(*),intent(in)::name
                logical,intent(in)::visible
                integer,intent(in)::index,m
                logical,intent(inout)::symbols_public(:),procedures_public(:),symbol_set(:),procedure_set(:)
                integer::n
                do n=1,prog%ns
                    if(prog%symbols(n)%scope/=-m.or.trim(prog%symbols(n)%name)/=lower(trim(name))) cycle
                    symbols_public(n)=visible;symbol_set(n)=.true.;return
                end do
                do n=1,prog%np
                    if(prog%procedures(n)%module_id/=m.or.prog%procedures(n)%parent_procedure/=0.or. &
                       trim(prog%procedures(n)%name)/=lower(trim(name))) cycle
                    procedures_public(n)=visible;procedure_set(n)=.true.;return
                end do
                do n=1,prog%nt
                    if(prog%derived_types(n)%module_id/=m.or.trim(prog%derived_types(n)%name)/=lower(trim(name))) cycle
                    type_public(n)=visible;type_visibility_set(n)=.true.;return
                end do
                do n=1,prog%no
                    if(prog%operators(n)%module_id/=m) cycle
                    if(lower(trim(name))/='operator('//trim(prog%operators(n)%op)//')') cycle
                    operator_public(n)=visible;operator_visibility_set(n)=.true.;return
                end do
                do n=1,prog%ng
                    if(prog%generics(n)%module_id/=m.or.trim(prog%generics(n)%name)/=lower(trim(name))) cycle
                    generic_public(n)=visible;generic_visibility_set(n)=.true.;return
                end do
                call mismatch(index,'visibility name differs')
            end subroutine
        subroutine check_inquire_name(index,pc,node)
            integer,intent(in)::index,pc
            type(inquire_statement_node),intent(in)::node
            integer::j,e,seen
            character(:),allocatable::key,spelling,expected
            if(.not.valid_inquire_name(prog,prog%code(pc)))then
                call mismatch(index,'invalid INQUIRE NAME metadata');return
            end if
            if(.not.allocated(node%specifiers).or..not.allocated(node%spec_list))then
                call mismatch(index,'INQUIRE controls missing');return
            end if
            if(size(node%specifiers)/=2.or.node%iostat_var_index/=0.or.node%err_label_index/=0)then
                call mismatch(index,'INQUIRE control count/options differ');return
            end if
            seen=0;expected=''
            do j=1,2
                if(.not.allocated(node%specifiers(j)%name).or..not.allocated(node%specifiers(j)%value))then
                    call mismatch(index,'INQUIRE control metadata missing');return
                end if
                key=lower(node%specifiers(j)%name)
                select case(key)
                case('unit')
                    if(btest(seen,0))then
                        call mismatch(index,'duplicate INQUIRE UNIT');return
                    end if
                    seen=ibset(seen,0);e=prog%code(pc)%a
                case('name')
                    if(btest(seen,1))then
                        call mismatch(index,'duplicate INQUIRE NAME');return
                    end if
                    seen=ibset(seen,1);e=prog%code(pc)%b
                case default
                    call mismatch(index,'unsupported INQUIRE control');return
                end select
                if(symbol_index(node%specifiers(j)%value)/=prog%expressions(e)%symbol)then
                    call mismatch(index,'INQUIRE source binding differs');return
                end if
                call expression(node%specifiers(j)%value_node_index,e,0)
                if(diag%code/=0)return
                if(j>1)expected=expected//','
                expected=expected//key//'='//lower(trim(node%specifiers(j)%value))
            end do
            spelling=''
            do j=1,len(node%spec_list)
                if(node%spec_list(j:j)==' '.or.node%spec_list(j:j)==achar(9))cycle
                spelling=spelling//lower(node%spec_list(j:j))
            end do
            if(seen/=3.or.spelling/=expected)call mismatch(index,'INQUIRE source spelling differs')
        end subroutine
        subroutine check_backspace(index,pc,node)
            integer,intent(in)::index,pc
            type(backspace_statement_node),intent(in)::node
            integer::j,n,e
            character(:),allocatable::spelling,unit_name,status_name
            if(.not.valid_backspace(prog,prog%code(pc))) then
                call mismatch(index,'invalid BACKSPACE metadata');return
            end if
            if(.not.allocated(node%unit_spec).or..not.allocated(node%specifiers)) then
                call mismatch(index,'BACKSPACE controls missing');return
            end if
            if(node%err_label_index/=0) then
                call mismatch(index,'BACKSPACE ERR is unsupported');return
            end if
            n=1
            if(prog%code(pc)%b/=0) n=2
            if(size(node%specifiers)/=n) then
                call mismatch(index,'BACKSPACE control count differs');return
            end if
            do j=1,n
                if(.not.allocated(node%specifiers(j)%name).or..not.allocated(node%specifiers(j)%value)) then
                    call mismatch(index,'BACKSPACE control metadata missing');return
                end if
                e=prog%code(pc)%a
                if(j==1) then
                    if(lower(node%specifiers(j)%name)/='unit') then
                        call mismatch(index,'BACKSPACE UNIT control differs');return
                    end if
                else
                    e=prog%code(pc)%b
                    if(lower(node%specifiers(j)%name)/='iostat'.or. &
                       node%iostat_var_index/=node%specifiers(j)%value_node_index) then
                        call mismatch(index,'BACKSPACE IOSTAT control differs');return
                    end if
                end if
                if(symbol_index(node%specifiers(j)%value)/=prog%expressions(e)%symbol) then
                    call mismatch(index,'BACKSPACE source binding differs');return
                end if
                call expression(node%specifiers(j)%value_node_index,e,0)
                if(diag%code/=0) return
            end do
            spelling=''
            do j=1,len(node%unit_spec)
                if(node%unit_spec(j:j)==' '.or.node%unit_spec(j:j)==achar(9)) cycle
                spelling=spelling//lower(node%unit_spec(j:j))
            end do
            unit_name=lower(trim(node%specifiers(1)%value))
            if(n==1) then
                if(node%iostat_var_index/=0) call mismatch(index,'BACKSPACE unexpected IOSTAT')
                if(spelling/=unit_name.and.spelling/='('//unit_name//')'.and. &
                   spelling/='(unit='//unit_name//')') call mismatch(index,'BACKSPACE unit spelling differs')
            else
                status_name=lower(trim(node%specifiers(2)%value))
                if(spelling/='('//unit_name//',iostat='//status_name//')'.and. &
                   spelling/='(unit='//unit_name//',iostat='//status_name//')') &
                    call mismatch(index,'BACKSPACE control spelling differs')
            end if
        end subroutine
        subroutine check_read(index,pc,node)
            integer,intent(in)::index,pc
            type(read_statement_node),intent(in)::node
            integer::j,n,e,s,a
            logical::external,element_file
            character(:),allocatable::fmt
            external=prog%code(pc)%op==op_read_external
            if(external) then
                if(.not.valid_external_read(prog,prog%code(pc))) then
                    call mismatch(index,'invalid external READ metadata');return
                end if
            else
                if(.not.valid_internal_read(prog,prog%code(pc))) then
                    call mismatch(index,'invalid internal READ metadata');return
                end if
            end if
            if(.not.allocated(node%unit_spec).or..not.allocated(node%format_spec).or. &
               .not.allocated(node%specifiers)) then
                call mismatch(index,'READ controls missing');return
            end if
            s=prog%expressions(prog%code(pc)%a)%symbol
            element_file=.not.external.and.prog%expressions(prog%code(pc)%a)%kind==ex_element
            if(.not.element_file) then
                if(symbol_index(node%unit_spec)/=s) then
                    call mismatch(index,'READ file or format differs');return
                end if
            end if
            if(node%format_expr_index/=0.or. &
               node%err_label_index/=0.or.node%end_label_index/=0.or..not.node%is_formatted) then
                call mismatch(index,'READ file or format differs');return
            end if
            if(allocated(node%namelist_group)) then
                if(len_trim(node%namelist_group)>0) then
                    call mismatch(index,'NAMELIST READ is unsupported');return
                end if
            end if
            n=2
            if(prog%code(pc)%b/=0) n=3
            if(size(node%specifiers)/=n) then
                call mismatch(index,'READ control count differs');return
            end if
            do j=1,n
                if(.not.allocated(node%specifiers(j)%name).or..not.allocated(node%specifiers(j)%value)) then
                    call mismatch(index,'READ control metadata missing');return
                end if
            end do
            if(lower(node%specifiers(1)%name)/='unit'.or.lower(node%specifiers(2)%name)/='fmt'.or. &
               node%specifiers(2)%value/=node%format_spec) then
                call mismatch(index,'READ controls differ');return
            end if
            if(element_file) then
                ! Both producer passes retain the complete token spelling. Do
                ! not reduce either to a base name or fold quoted index text.
                if(.not.allocated(front%tokens))then
                    call mismatch(index,'READ internal element source tokens missing');return
                end if
                if(.not.read_element_unit_text_matches(front%tokens,node))then
                    call mismatch(index,'READ internal element UNIT/control source text differs');return
                end if
            else if(symbol_index(node%specifiers(1)%value)/=s) then
                call mismatch(index,'READ controls differ');return
            end if
            call expression(node%specifiers(1)%value_node_index,prog%code(pc)%a,0)
            if(diag%code/=0) return
            if(external.and.allocated(prog%code(pc)%format)) then
                ! Bind the literal twice: to the producer's control spelling and
                ! its independent literal node, never the guard's token stream.
                fmt=node%format_spec
                if(len(fmt)<2) then
                    call mismatch(index,'external READ requires a literal format');return
                end if
                if((fmt(1:1)/='"'.and.fmt(1:1)/=achar(39)).or.fmt(len(fmt):)/=fmt(1:1)) then
                    call mismatch(index,'external READ requires a literal format');return
                end if
                fmt=dequote(fmt)
                if(len(fmt)/=len(prog%code(pc)%format).or.fmt/=prog%code(pc)%format) then
                    call mismatch(index,'external READ literal format differs');return
                end if
                a=node%specifiers(2)%value_node_index
                if(.not.front%arena%has_node_at(a)) then
                    call mismatch(index,'external READ format node missing');return
                end if
                select type(literal=>front%arena%entries(a)%node)
                type is(literal_node)
                    if(literal%literal_kind/=LITERAL_STRING.or..not.allocated(literal%value)) then
                        call mismatch(index,'external READ format is not a string literal');return
                    end if
                    if(dequote(literal%value)/=fmt) then
                        call mismatch(index,'external READ format source differs');return
                    end if
                class default
                    call mismatch(index,'external READ format node differs');return
                end select
                call check_type(a,ty_character,0,4)
            else
                if(node%format_spec/='*'.or.node%specifiers(2)%value_node_index/=0) then
                    call mismatch(index,'READ requires list-directed format');return
                end if
            end if
            if(n==3) then
                if(lower(node%specifiers(3)%name)/='iostat') then
                    call mismatch(index,'READ supports IOSTAT only');return
                end if
                e=prog%code(pc)%b
                if(node%iostat_var_index/=node%specifiers(3)%value_node_index.or. &
                   symbol_index(node%specifiers(3)%value)/=prog%expressions(e)%symbol) then
                    call mismatch(index,'READ IOSTAT source differs');return
                end if
                call expression(node%iostat_var_index,e,0)
            else if(node%iostat_var_index/=0) then
                call mismatch(index,'READ has unexpected IOSTAT');return
            end if
            n=0
            if(allocated(node%var_indices)) n=size(node%var_indices)
            if(n/=size(prog%code(pc)%items)) then
                call mismatch(index,'READ item count differs');return
            end if
            do j=1,n
                call expression(node%var_indices(j),prog%code(pc)%items(j),0)
            end do
        end subroutine
        subroutine check_standard_write(index,pc,node)
            integer,intent(in)::index,pc
            type(write_statement_node),intent(in)::node
            integer::j,n,mode
            character(:),allocatable::value
            if(.not.node%is_formatted) call mismatch(index,'WRITE formatted metadata missing')
            if(node%format_expr_index/=0) call mismatch(index,'Runtime format expressions require a simple CHARACTER name')
            if(allocated(node%namelist_group)) then
                if(len_trim(node%namelist_group)>0) call mismatch(index,'NAMELIST WRITE is unsupported')
            end if
            if(.not.allocated(node%specifiers)) then
                call mismatch(index,'WRITE controls missing');return
            end if
            n=size(node%specifiers)
            if(n<2.or.n>3.or.(n==3.and.prog%code(pc)%op/=op_print)) then
                call mismatch(index,'WRITE requires unit, format and optional stdout ADVANCE only');return
            end if
            do j=1,n
                if(.not.allocated(node%specifiers(j)%name).or..not.allocated(node%specifiers(j)%value)) then
                    call mismatch(index,'WRITE control metadata missing');return
                end if
            end do
            if(lower(node%specifiers(1)%name)/='unit'.or.lower(node%specifiers(2)%name)/='fmt') &
                call mismatch(index,'WRITE controls differ')
            if(prog%code(pc)%op==op_print) then
                if(prog%code(pc)%symbol==0) then
                    if(node%specifiers(1)%value/='*') call mismatch(index,'WRITE output unit differs')
                else if(symbol_index(node%specifiers(1)%value)/=prog%code(pc)%symbol)then
                    call mismatch(index,'WRITE output unit control binding differs')
                else if(prog%code(pc)%a/=0)then
                    call check_runtime_unit(index,node%specifiers(1)%value,prog%code(pc)%a)
                else if(.not.valid_stdout_unit(prog,prog%code(pc)%symbol,current_scope))then
                    call mismatch(index,'WRITE OUTPUT_UNIT control differs')
                end if
            else
                if(prog%code(pc)%a/=0)then
                    if(.not.allocated(node%unit_spec))then
                        call mismatch(index,'WRITE internal element unit missing');return
                    end if
                    if(lower(node%unit_spec)/=lower(node%specifiers(1)%value))then
                        call mismatch(index,'WRITE internal element unit text differs');return
                    end if
                    call expression(node%specifiers(1)%value_node_index,prog%code(pc)%a,0)
                else if(symbol_index(node%specifiers(1)%value)/=prog%code(pc)%symbol)then
                    call mismatch(index,'WRITE internal unit differs')
                end if
            end if
            if(allocated(node%format_spec)) then
                if(node%specifiers(2)%value/=node%format_spec) call mismatch(index,'WRITE format controls differ')
            else
                call mismatch(index,'WRITE format missing')
            end if
            mode=0
            if(n==3) then
                if(lower(node%specifiers(3)%name)/='advance') then
                    call mismatch(index,'unsupported WRITE control');return
                end if
                value=node%specifiers(3)%value
                if(len(value)<2) then
                    call mismatch(index,'ADVANCE must be a literal');return
                end if
                if(value(1:1)/='"'.and.value(1:1)/=achar(39)) then
                    call mismatch(index,'ADVANCE must be a literal');return
                end if
                value=lower(dequote(value))
                if(value=='no'.and.len(value)==2) then
                    mode=1
                else if(value/='yes'.or.len(value)/=3) then
                    call mismatch(index,'ADVANCE must be YES or NO');return
                end if
                if(.not.allocated(prog%code(pc)%format).and.prog%code(pc)%format_expr==0) &
                    call mismatch(index,'ADVANCE requires an explicit format')
            end if
            if(prog%code(pc)%advance_mode/=mode) call mismatch(index,'ADVANCE control differs')
        end subroutine
        subroutine check_defined_write(index,pc,node)
            integer,intent(in)::index,pc
            type(write_statement_node),intent(in)::node
            integer::j,a,s,stat,msg
            logical::valid
            valid=.false.;stat=0;msg=0
            if(current_scope<=0) then
                call mismatch(index,'defined child WRITE outside procedure');return
            end if
            do j=1,prog%nt
                if(prog%derived_types(j)%write_procedure==current_scope) valid=.true.
            end do
            if(.not.valid) call mismatch(index,'defined child WRITE not in binding implementation')
            if(prog%code(pc)%symbol/=prog%procedures(current_scope)%args(2)) &
                call mismatch(index,'defined child WRITE UNIT differs')
            if(node%err_label_index/=0.or.node%end_label_index/=0) call mismatch(index,'unsupported child WRITE control')
            if(allocated(node%specifiers)) then
                do j=1,size(node%specifiers)
                    if(.not.allocated(node%specifiers(j)%name)) cycle
                    select case(lower(node%specifiers(j)%name))
                    case('unit','fmt')
                        cycle
                    case('iostat','iomsg')
                        if(.not.allocated(node%specifiers(j)%value)) then
                            call mismatch(index,'child WRITE control value missing');return
                        end if
                        s=symbol_index(node%specifiers(j)%value)
                        if(lower(node%specifiers(j)%name)=='iostat') then
                            if(stat/=0) call mismatch(index,'duplicate child IOSTAT')
                            stat=s
                        else
                            if(msg/=0) call mismatch(index,'duplicate child IOMSG')
                            msg=s
                        end if
                    case default
                        call mismatch(index,'unsupported defined child WRITE specifier')
                    end select
                end do
            end if
            if(stat/=prog%code(pc)%a.or.msg/=prog%code(pc)%b) call mismatch(index,'child WRITE status controls differ')
            if(stat>0.and.stat/=prog%procedures(current_scope)%args(5)) call mismatch(index,'child IOSTAT dummy differs')
            if(msg>0.and.msg/=prog%procedures(current_scope)%args(6)) call mismatch(index,'child IOMSG dummy differs')
        end subroutine
        recursive subroutine check_output_item(index,root,depth)
            integer,intent(in)::index,root,depth
            integer::j,n,s
            if(diag%code/=0) return
            if(root<1.or.root>prog%ne) then
                call mismatch(index,'invalid output item or implied-DO nesting');return
            end if
            if(prog%expressions(root)%kind/=ex_output_do) then
                call expression(index,root,0);return
            end if
            if(depth>max_output_do_depth.or..not.valid_output_do(prog,root).or..not.front%arena%has_node_at(index)) then
                call mismatch(index,'invalid output implied-DO metadata');return
            end if
            associate(x=>prog%expressions(root))
            select type(node=>front%arena%entries(index)%node)
            type is(io_implied_do_node)
                if(.not.allocated(node%var_name).or..not.allocated(node%object_indices)) then
                    call mismatch(index,'output implied-DO controls or objects missing');return
                end if
                s=symbol_index(node%var_name);n=size(x%args)
                if(s/=x%symbol.or.size(node%object_indices)/=n.or.node%line/=x%line.or.node%column/=x%column.or. &
                   x%scope/=current_scope) then
                    call mismatch(index,'output implied-DO source identity differs');return
                end if
                if(node%expr_index/=node%object_indices(1)) then
                    call mismatch(index,'output implied-DO first object differs');return
                end if
                call expression(node%start_expr_index,x%left,0)
                call expression(node%end_expr_index,x%right,0)
                if((node%step_expr_index==0).neqv.(x%stride==0)) then
                    call mismatch(index,'output implied-DO step presence differs');return
                end if
                if(x%stride/=0) call expression(node%step_expr_index,x%stride,0)
                do j=1,n
                    call check_output_item(node%object_indices(j),x%args(j),depth+1)
                end do
            class default
                call mismatch(index,'output implied-DO node kind differs')
            end select
            end associate
        end subroutine
        subroutine check_output(index,pc,items,format_spec)
            integer,intent(in)::index,pc
            integer,allocatable,intent(in)::items(:)
            character(:),allocatable,intent(in)::format_spec
            integer::n,j
            character(:),allocatable::fmt,expected_format
            if(current_scope>0.and.prog%code(pc)%op/=op_write_internal) then
                if(prog%procedures(current_scope)%is_pure.or. &
                   (.not.prog%procedures(current_scope)%is_subroutine.and. &
                    .not.prog%procedures(current_scope)%has_impure_prefix)) &
                    call mismatch(index,'output outside main or impure subroutine')
            end if
            if(prog%code(pc)%op==op_print) then
                associate(ins=>prog%code(pc))
                if(ins%a/=0)then
                    if(.not.valid_runtime_output_unit(prog,ins%a,ins%symbol,current_scope)) &
                        call mismatch(index,'invalid runtime output unit metadata')
                else if(ins%symbol/=0) then
                    if(.not.valid_stdout_unit(prog,ins%symbol,current_scope)) &
                        call mismatch(index,'invalid standard-output unit metadata')
                end if
                if(ins%b/=0.or.ins%c/=0.or.ins%d/=0.or.ins%target/=0.or. &
                   ins%component/=0.or.ins%generic_id/=0.or.ins%third/=0.or.ins%bound_type/=0.or.ins%bound_binding/=0.or. &
                   len_trim(ins%construct_name)/=0) call mismatch(index,'invalid standard-output instruction metadata')
                end associate
            end if
            if(prog%code(pc)%op==op_write_internal)then
                associate(ins=>prog%code(pc))
                if(ins%a/=0)then
                    if(.not.valid_internal_write_values(prog,ins)) &
                        call mismatch(index,'invalid internal WRITE element expression effects')
                end if
                if(ins%b/=0.or.ins%c/=0.or.ins%d/=0.or.ins%target/=0.or.ins%component/=0.or. &
                   ins%generic_id/=0.or.ins%third/=0.or.ins%bound_type/=0.or.ins%bound_binding/=0.or. &
                   ins%advance_mode/=0.or.len_trim(ins%construct_name)/=0) &
                    call mismatch(index,'invalid internal WRITE instruction metadata')
                end associate
            end if
            if(.not.allocated(prog%code(pc)%items)) then
                call mismatch(index,'IR output items missing');return
            end if
            n=0
            if(allocated(items)) n=size(items)
            if(n/=size(prog%code(pc)%items)) then
                call mismatch(index,'output item count differs');return
            end if
            fmt='*'
            if(allocated(format_spec)) fmt=format_spec
            if(prog%code(pc)%format_expr/=0) then
                call check_runtime_format(index,fmt,prog%code(pc)%format_expr)
            else if(allocated(prog%code(pc)%format)) then
                call resolved_output_format(index,fmt,expected_format)
                if(diag%code/=0) return
                if(len(expected_format)/=len(prog%code(pc)%format).or.expected_format/=prog%code(pc)%format) &
                    call mismatch(index,'output format differs')
            else if(fmt/='*') then
                call mismatch(index,'unexpected formatted output')
            end if
            do j=1,n
                call check_output_item(items(j),prog%code(pc)%items(j),1)
            end do
        end subroutine
        subroutine check_runtime_unit(index,name,e)
            integer,intent(in)::index,e
            character(*),intent(in)::name
            integer::s
            type(declaration_binding_t)::binding
            character(:),allocatable::err
            s=symbol_index(name)
            if(.not.valid_runtime_output_unit(prog,e,s,current_scope))then
                call mismatch(index,'invalid runtime unit descriptor');return
            end if
            call resolve_name_in_scope(front%arena,scope_node(),name,binding,err)
            if(.not.binding%found.and.prog%symbols(s)%scope<0) &
                call resolve_name_in_scope(front%arena,module_node_index(-prog%symbols(s)%scope),name,binding,err)
            if(.not.binding%found)then
                call mismatch(index,'runtime unit source binding is unresolved');return
            end if
            if(binding%declaration_node_index/=symbol_declaration(s)) &
                call mismatch(index,'runtime unit declaration identity differs')
            call check_type(binding%declaration_node_index,ty_integer,0,prog%symbols(s)%real_kind)
        end subroutine
        subroutine check_runtime_format(index,name,e)
            integer,intent(in)::index,e
            character(*),intent(in)::name
            integer::s
            type(declaration_binding_t)::binding
            character(:),allocatable::err
            s=symbol_index(name)
            if(s<1.or.s>prog%ns.or.e<1.or.e>prog%ne) then
                call mismatch(index,'runtime format name is unresolved');return
            end if
            associate(v=>prog%symbols(s),x=>prog%expressions(e))
            if(v%typ/=ty_character.or.v%rank/=0.or.v%real_kind/=4.or.v%is_parameter.or. &
               x%kind/=ex_variable.or.x%symbol/=s.or.x%scope/=current_scope.or.x%typ/=ty_character.or. &
               x%real_kind/=4.or.x%rank/=0.or.x%extent/=0.or.any(x%dims/=0).or.x%character_len/=v%character_len.or. &
               x%left/=0.or.x%right/=0.or.x%stride/=0.or.x%left2/=0.or.x%right2/=0.or.x%stride2/=0.or. &
               x%left3/=0.or.x%right3/=0.or.x%stride3/=0.or.x%third/=0.or.x%length_expr/=0.or. &
               x%generic_id/=0.or.x%bound_type/=0.or.x%bound_binding/=0.or.x%intrinsic_mask/=0.or. &
               len_trim(x%op)/=0.or.allocated(x%args).or.x%constructor_kind_expr/=0.or.x%parenthesized.or. &
               any(x%triplet.neqv.[.true.,.false.,.false.])) then
                call mismatch(index,'invalid runtime format descriptor');return
            end if
            call resolve_name_in_scope(front%arena,scope_node(),name,binding,err)
            if(.not.binding%found.and.v%scope<0) &
                call resolve_name_in_scope(front%arena,module_node_index(-v%scope),name,binding,err)
            if(.not.binding%found) then
                call mismatch(index,'runtime format source binding is unresolved');return
            end if
            if(binding%declaration_node_index/=symbol_declaration(s)) &
                call mismatch(index,'runtime format declaration identity differs')
            call check_type(binding%declaration_node_index,ty_character,0)
            end associate
        end subroutine
        subroutine resolved_output_format(index,fmt,value)
            integer,intent(in)::index
            character(*),intent(in)::fmt
            character(:),allocatable,intent(out)::value
            integer::s
            type(declaration_binding_t)::binding
            character(:),allocatable::err
            if(len(fmt)>0) then
                if(fmt(1:1)=="'".or.fmt(1:1)=='"') then
                    value=dequote(fmt);return
                end if
            end if
            s=symbol_index(fmt)
            if(s==0) then
                call mismatch(index,'named output format is unresolved');return
            end if
            associate(v=>prog%symbols(s))
            if(.not.v%is_parameter.or..not.v%parameter_ready.or.v%typ/=ty_character.or.v%rank/=0) then
                call mismatch(index,'named output format must be a scalar CHARACTER PARAMETER');return
            end if
            call resolve_name_in_scope(front%arena,scope_node(),fmt,binding,err)
            ! PUBLIC declaration attributes under a module-wide PRIVATE default
            ! may be absent from the public binding query. symbol_index has
            ! independently checked the exact USE list and source visibility.
            if(.not.binding%found.and.v%scope<0) &
                call resolve_name_in_scope(front%arena,module_node_index(-v%scope),fmt,binding,err)
            if(.not.binding%found) then
                call mismatch(index,'named output format source binding is unresolved');return
            end if
            if(binding%declaration_node_index/=symbol_declaration(s)) then
                call mismatch(index,'named output format declaration identity differs');return
            end if
            call check_type(binding%declaration_node_index,ty_character,0)
            call check_parameter(binding%declaration_node_index,s)
            if(diag%code/=0) return
            if(v%constant_value%tag/=ty_character.or..not.allocated(v%constant_value%s)) then
                call mismatch(index,'named output format value is unavailable');return
            end if
            if(v%character_len/=len(v%constant_value%s)) then
                call mismatch(index,'named output format CHARACTER length differs');return
            end if
            value=v%constant_value%s
            end associate
        end subroutine
        subroutine check_timing_query(index,pc,node)
            integer,intent(in)::index,pc
            type(subroutine_call_node),intent(in)::node
            type(declaration_binding_t)::binding
            character(:),allocatable::err
            integer::j,mode
            mode=1;if(lower(node%name)=='cpu_time')mode=2
            if(.not.valid_timing_query(prog,prog%code(pc)).or.prog%code(pc)%d/=mode)then
                call mismatch(index,'invalid timing inquiry metadata');return
            end if
            call resolve_name_in_scope(front%arena,scope_node(),node%name,binding,err)
            if(binding%found.or.symbol_index(node%name)/=0)then
                call mismatch(index,'timing intrinsic is shadowed by a source declaration');return
            end if
            if(current_scope>0)then
                if(prog%procedures(current_scope)%is_pure.or.prog%procedures(current_scope)%is_simple)then
                    call mismatch(index,'timing inquiries are forbidden in PURE or SIMPLE procedures');return
                end if
            end if
            do j=1,size(prog%code(pc)%items)
                if(prog%code(pc)%items(j)==0)cycle
                call check_writable_actual(index,pc,prog%code(pc)%items(j))
            end do
            call check_actual_arguments(index,node%arg_indices,prog%code(pc)%items,0,lower(node%name),0)
        end subroutine
        subroutine check_move_alloc(index,pc,node)
            integer,intent(in)::index,pc
            type(subroutine_call_node),intent(in)::node
            type(declaration_binding_t)::binding
            character(:),allocatable::err
            integer::j
            if(.not.valid_move_alloc(prog,prog%code(pc))) then
                call mismatch(index,'invalid MOVE_ALLOC metadata');return
            end if
            call resolve_name_in_scope(front%arena,scope_node(),node%name,binding,err)
            if(binding%found.or.symbol_index(node%name)/=0) then
                call mismatch(index,'MOVE_ALLOC is shadowed by a source declaration');return
            end if
            do j=1,2
                call check_writable_actual(index,pc,prog%code(pc)%items(j))
            end do
            call check_actual_arguments(index,node%arg_indices,prog%code(pc)%items,0,'move_alloc',0)
        end subroutine
        subroutine check_process_query(index,pc,node)
            integer,intent(in)::index,pc
            type(subroutine_call_node),intent(in)::node
            type(declaration_binding_t)::binding
            character(:),allocatable::err
            integer::j,first,kind
            kind=1;first=1
            if(lower(node%name)=='get_command_argument') then
                kind=2;first=2
            end if
            if(.not.valid_process_query(prog,prog%code(pc)).or.prog%code(pc)%d/=kind) then
                call mismatch(index,'invalid process query metadata');return
            end if
            call resolve_name_in_scope(front%arena,scope_node(),node%name,binding,err)
            if(binding%found.or.symbol_index(node%name)/=0) then
                call mismatch(index,'process query is shadowed by a source declaration');return
            end if
            if(current_scope>0) then
                if(prog%procedures(current_scope)%is_pure.or.prog%procedures(current_scope)%is_simple) then
                    call mismatch(index,'process query is forbidden in PURE or SIMPLE procedures');return
                end if
            end if
            do j=first,size(prog%code(pc)%items)
                if(prog%code(pc)%items(j)==0) cycle
                call check_writable_actual(index,pc,prog%code(pc)%items(j))
            end do
            call check_actual_arguments(index,node%arg_indices,prog%code(pc)%items,0,lower(node%name),0)
        end subroutine
        subroutine check_random_seed(index,pc,node)
            integer,intent(in)::index,pc
            type(subroutine_call_node),intent(in)::node
            type(declaration_binding_t)::binding
            character(:),allocatable::err
            call resolve_name_in_scope(front%arena,scope_node(),node%name,binding,err)
            if(binding%found.or.symbol_index(node%name)/=0) then
                call mismatch(index,'RANDOM_SEED intrinsic is shadowed by a source declaration');return
            end if
            if(allocated(node%arg_indices)) then
                if(size(node%arg_indices)/=0) then
                    call mismatch(index,'RANDOM_SEED supports only an empty argument list');return
                end if
            end if
            associate(ins=>prog%code(pc))
            if(ins%symbol/=0.or.ins%a/=0.or.ins%b/=0.or.ins%c/=0.or.ins%d/=0.or.ins%target/=0.or. &
               ins%component/=0.or.ins%generic_id/=0.or.ins%third/=0.or.ins%bound_type/=0.or.ins%bound_binding/=0.or. &
               allocated(ins%items).or.allocated(ins%format).or.len_trim(ins%construct_name)/=0) then
                call mismatch(index,'invalid RANDOM_SEED instruction metadata');return
            end if
            end associate
            if(current_scope>0) then
                if(prog%procedures(current_scope)%is_pure.or.prog%procedures(current_scope)%is_simple) &
                    call mismatch(index,'RANDOM_SEED is impure')
            end if
        end subroutine
        subroutine check_random_number(index,pc,node)
            integer,intent(in)::index,pc
            type(subroutine_call_node),intent(in)::node
            integer::e,s
            e=prog%code(pc)%a
            if(e<1.or.e>prog%ne) then
                call mismatch(index,'RANDOM_NUMBER argument missing');return
            end if
            s=prog%expressions(e)%symbol
            if(s<1.or.s>prog%ns) then
                call mismatch(index,'RANDOM_NUMBER target binding missing');return
            end if
            if(s/=prog%code(pc)%symbol.or.prog%expressions(e)%typ/=ty_real.or. &
               prog%symbols(s)%typ/=ty_real.or.expression_rank(e)>3) &
                call mismatch(index,'RANDOM_NUMBER target type/rank differs')
            if(current_scope>0) then
                if(prog%procedures(current_scope)%is_pure.or.prog%procedures(current_scope)%is_simple) &
                    call mismatch(index,'RANDOM_NUMBER is impure')
            end if
            call check_writable_actual(index,pc,e)
            call check_actual_arguments(index,node%arg_indices,[e],0,'random_number',0)
        end subroutine
        ! Independent source/IR boundary check: a numeric result does not make
        ! a derived-component operand part of this inquiry subset.
        logical function model_argument_has_component(root) result(found)
            integer,intent(in)::root
            integer,allocatable::marks(:)
            allocate(marks(prog%ne),source=0)
            found=model_argument_component_tree(root,marks,0)
        end function
        recursive logical function model_argument_component_tree(root,marks,depth) result(found)
            integer,intent(in)::root,depth
            integer,intent(inout)::marks(:)
            integer::j,children(10)
            found=.true.
            if(root<1.or.root>prog%ne.or.depth>512) return
            if(marks(root)==1) return
            if(marks(root)==2) then
                found=.false.;return
            end if
            marks(root)=1
            associate(x=>prog%expressions(root))
            if(x%kind==ex_component) return
            children=[x%left,x%right,x%stride,x%left2,x%right2,x%stride2,x%left3,x%right3,x%stride3,x%third]
            do j=1,size(children)
                if(children(j)==0) cycle
                if(model_argument_component_tree(children(j),marks,depth+1)) return
            end do
            if(allocated(x%args)) then
                do j=1,size(x%args)
                    if(x%args(j)==0) cycle
                    if(model_argument_component_tree(x%args(j),marks,depth+1)) return
                end do
            end if
            end associate
            marks(root)=2;found=.false.
        end function
        recursive subroutine check_initializer(index,e,depth)
            integer,intent(in)::index,e,depth
            type(value_t)::value
            type(diagnostic_t)::evaluation_diag
            integer::j,s
            if(diag%code/=0) return
            if(e<1.or.e>prog%ne.or.depth>256) then
                call mismatch(index,'invalid initializer expression');return
            end if
            select case(prog%expressions(e)%kind)
            case(ex_user_call,ex_gather_rows)
                call mismatch(index,'initializer is not a constant expression')
            case(ex_variable,ex_element,ex_section,ex_substring)
                s=prog%expressions(e)%symbol
                if(.not.(prog%expressions(e)%kind==ex_substring.and.s==0)) then
                    if(s<1.or.s>prog%ns) then
                        call mismatch(index,'initializer symbol missing');return
                    end if
                    if(.not.prog%symbols(s)%is_parameter.or..not.prog%symbols(s)%parameter_ready) &
                        call mismatch(index,'initializer is not a defined PARAMETER')
                end if
                if(prog%expressions(e)%kind/=ex_variable) then
                    if(prog%expressions(e)%left/=0) call check_initializer(index,prog%expressions(e)%left,depth+1)
                    if(prog%expressions(e)%right/=0) call check_initializer(index,prog%expressions(e)%right,depth+1)
                    if(prog%expressions(e)%stride/=0) call check_initializer(index,prog%expressions(e)%stride,depth+1)
                    if(prog%expressions(e)%left2/=0) call check_initializer(index,prog%expressions(e)%left2,depth+1)
                    if(prog%expressions(e)%right2/=0) call check_initializer(index,prog%expressions(e)%right2,depth+1)
                    if(prog%expressions(e)%stride2/=0) call check_initializer(index,prog%expressions(e)%stride2,depth+1)
                    if(prog%expressions(e)%third/=0) call check_initializer(index,prog%expressions(e)%third,depth+1)
                    if(prog%expressions(e)%left3/=0) call check_initializer(index,prog%expressions(e)%left3,depth+1)
                    if(prog%expressions(e)%right3/=0) call check_initializer(index,prog%expressions(e)%right3,depth+1)
                    if(prog%expressions(e)%stride3/=0) call check_initializer(index,prog%expressions(e)%stride3,depth+1)
                end if
            case(ex_constructor_index)
                if(.not.valid_constructor_index(prog,e)) call mismatch(index,'invalid constant constructor index')
            case(ex_constructor_do)
                call check_initializer(index,prog%expressions(e)%left,depth+1)
                call check_initializer(index,prog%expressions(e)%right,depth+1)
                if(prog%expressions(e)%stride/=0) call check_initializer(index,prog%expressions(e)%stride,depth+1)
                do j=1,size(prog%expressions(e)%args)
                    call check_initializer(index,prog%expressions(e)%args(j),depth+1)
                end do
            case(ex_unary,ex_binary)
                call check_initializer(index,prog%expressions(e)%left,depth+1)
                if(prog%expressions(e)%kind==ex_binary) &
                    call check_initializer(index,prog%expressions(e)%right,depth+1)
            case(ex_call,ex_constructor)
                if(prog%expressions(e)%kind==ex_call.and.is_bounds_inquiry(prog%expressions(e)%op)) then
                    if(.not.bound_constant_expression(prog,e,0)) &
                        call mismatch(index,'bounds inquiry initializer is not constant')
                    return
                end if
                if(prog%expressions(e)%kind==ex_call.and. &
                   (prog%expressions(e)%op=='minexponent'.or.prog%expressions(e)%op=='maxexponent')) then
                    if(.not.bound_constant_expression(prog,e,0)) call mismatch(index,'exponent inquiry initializer is not constant')
                    return
                end if
                if(prog%expressions(e)%kind==ex_call.and.(prog%expressions(e)%op=='kind'.or.prog%expressions(e)%op=='new_line'.or. &
                   is_numeric_model_inquiry(prog%expressions(e)%op))) return
                if(prog%expressions(e)%kind==ex_call.and.prog%expressions(e)%op=='len') then
                    ! A whole fixed-length CHARACTER designator contributes its
                    ! declared length, not its (possibly undefined) data value.
                    if(allocated(prog%expressions(e)%args)) then
                        if(size(prog%expressions(e)%args)==1) then
                            j=prog%expressions(e)%args(1)
                            if(j>=1.and.j<=prog%ne) then
                                if(prog%expressions(j)%kind==ex_variable.and.prog%expressions(j)%typ==ty_character) then
                                    s=prog%expressions(j)%symbol
                                    if(s>=1.and.s<=prog%ns) then
                                        if(prog%symbols(s)%typ==ty_character.and.prog%symbols(s)%character_len>=0.and. &
                                           prog%expressions(j)%character_len==prog%symbols(s)%character_len) return
                                    end if
                                end if
                            end if
                        end if
                    end if
                end if
                if(prog%expressions(e)%kind==ex_call.and.prog%expressions(e)%op=='shape') then
                    if(allocated(prog%expressions(e)%args)) then
                        if(size(prog%expressions(e)%args)>=1.and.size(prog%expressions(e)%args)<=2) then
                            j=prog%expressions(e)%args(1)
                            if(j>=1.and.j<=prog%ne) then
                                if(prog%expressions(j)%kind==ex_variable) then
                                    s=prog%expressions(j)%symbol
                                    if(s>=1.and.s<=prog%ns) then
                                        if(.not.prog%symbols(s)%is_allocatable.and..not.prog%symbols(s)%assumed_shape.and. &
                                           .not.prog%symbols(s)%is_automatic.and..not.prog%symbols(s)%is_dummy) then
                                            if(size(prog%expressions(e)%args)==2) &
                                                call check_initializer(index,prog%expressions(e)%args(2),depth+1)
                                            return
                                        end if
                                    end if
                                end if
                            end if
                        end if
                    end if
                end if
                do j=1,size(prog%expressions(e)%args)
                    call check_initializer(index,prog%expressions(e)%args(j),depth+1)
                end do
            case default
                call evaluate_constant(prog,e,value,evaluation_diag)
                if(evaluation_diag%code/=0) call mismatch(index,'initializer is not a constant expression')
            end select
        end subroutine
        subroutine check_subroutine_call(index,pc,node)
            integer,intent(in)::index,pc
            type(subroutine_call_node),intent(in)::node
            type(declaration_binding_t)::binding
            character(:),allocatable::err
            integer::p,n,j,d,e,rank,writable,implicit_count
            integer(int64)::dims(3),child_dims(3)
            p=prog%code(pc)%symbol
            if(p<1.or.p>prog%np.or..not.allocated(node%name)) then
                call mismatch(index,'CALL binding missing');return
            end if
            implicit_count=0
            if(prog%code(pc)%bound_type>0) implicit_count=1
            if(implicit_count==1.and.prog%code(pc)%generic_id/=0) &
                call mismatch(index,'CALL has conflicting bound and generic metadata')
            if(.not.prog%procedures(p)%is_subroutine) call mismatch(index,'CALL procedure identity differs')
            if(implicit_count==0.and.prog%code(pc)%generic_id==0.and.lower(node%name)/=trim(prog%procedures(p)%name)) &
                call mismatch(index,'CALL procedure name differs')
            if(current_scope>0) then
                if(prog%procedures(current_scope)%is_simple.and..not.prog%procedures(p)%is_simple) &
                    call mismatch(index,'SIMPLE procedure calls nonsimple subroutine')
                if(prog%procedures(current_scope)%is_pure.and..not.prog%procedures(p)%is_pure) &
                    call mismatch(index,'PURE procedure calls impure subroutine')
            end if
            if(prog%code(pc)%generic_id>0) then
                call check_generic_call(index,node%name,prog%code(pc)%generic_id,p,node%arg_indices,prog%code(pc)%items)
            else if(implicit_count==0) then
                call resolve_name_in_scope(front%arena,scope_node(),node%name,binding,err)
                if(.not.binding%found.or.binding%binding_kind/=BINDING_SUBROUTINE.or. &
                   binding%declaration_node_index/=procedure_node(p)) then
                    call mismatch(index,'CALL declaration identity differs');return
                end if
            end if
            if(diag%code/=0) return
            if(.not.allocated(prog%code(pc)%items).or..not.allocated(prog%procedures(p)%args)) then
                call mismatch(index,'CALL IR arguments missing');return
            end if
            n=0
            if(allocated(node%arg_indices)) n=size(node%arg_indices)
            n=n+implicit_count
            if(n/=count(prog%code(pc)%items/=0).or.size(prog%code(pc)%items)/=size(prog%procedures(p)%args)) then
                call mismatch(index,'CALL argument count differs');return
            end if
            rank=0;dims=0;writable=0
            n=size(prog%code(pc)%items)
            do j=1,n
                e=prog%code(pc)%items(j);d=prog%procedures(p)%args(j)
                if(d<1.or.d>prog%ns) then
                    call mismatch(index,'CALL dummy missing');return
                end if
                if(e==0) then
                    if(.not.prog%symbols(d)%is_optional) call mismatch(index,'missing required actual')
                    cycle
                end if
                if(e<1.or.e>prog%ne.or.d<1.or.d>prog%ns) then
                    call mismatch(index,'CALL argument missing');return
                end if
                if(prog%expressions(e)%typ/=prog%symbols(d)%typ.or. &
                   (.not.prog%procedures(p)%is_elemental.and.expression_rank(e)/=prog%symbols(d)%rank)) &
                    call mismatch(index,'CALL argument type/rank differs')
                if(prog%procedures(p)%is_elemental) then
                    if(prog%symbols(d)%rank/=0) call mismatch(index,'ELEMENTAL dummy must be scalar')
                    if(expression_rank(e)>0) then
                        child_dims=expression_dims(:,e)
                        if(expression_rank(e)==1) child_dims=[expression_extent(e),0_int64,0_int64]
                        if(rank==0) then
                            rank=expression_rank(e);dims=child_dims
                        else
                            if(rank/=expression_rank(e)) call mismatch(index,'ELEMENTAL CALL ranks differ')
                            if(any(dims>=0.and.child_dims>=0.and.dims/=child_dims)) &
                                call mismatch(index,'ELEMENTAL CALL shapes differ')
                        end if
                    end if
                end if
                if((prog%symbols(d)%typ==ty_real.or.prog%symbols(d)%typ==ty_integer)) then
                    if(prog%expressions(e)%real_kind/=prog%symbols(d)%real_kind) &
                        call mismatch(index,'CALL argument kind differs')
                end if
                call check_pointer_actual(index,e,d)
                if(prog%symbols(d)%is_allocatable) call check_allocatable_actual(index,e,d)
                if(prog%symbols(d)%dummy_intent/=1) call check_writable_actual(index,pc,e)
            end do
            if(prog%procedures(p)%is_elemental.and.rank>0) then
                do j=1,n
                    d=prog%procedures(p)%args(j);e=prog%code(pc)%items(j)
                    if(e==0) cycle
                    if(prog%symbols(d)%dummy_intent==1) cycle
                    writable=writable+1
                    if(expression_rank(e)/=rank) call mismatch(index,'ELEMENTAL writable actual must be array')
                end do
                if(writable==0) call mismatch(index,'ELEMENTAL array CALL requires writable dummy')
            end if
            if(implicit_count==1) then
                call check_bound_call(index,prog%code(pc)%bound_type,prog%code(pc)%bound_binding,p,prog%code(pc)%items(1))
                call check_actual_arguments(index,node%arg_indices,prog%code(pc)%items(2:),p,'',0,1)
            else
                call check_actual_arguments(index,node%arg_indices,prog%code(pc)%items,p,'',0)
            end if
        end subroutine
        ! Associate directly from the producer AST. Do not trust or share the
        ! source recognizer's mapping. Signature names are cross-checked against
        ! procedure parameter nodes; every actual expression is matched below.
        recursive subroutine check_actual_arguments(index,indices,expected,proc,name,depth,skip_passed,intrinsic_mask)
            integer,intent(in)::index,expected(:),proc,depth
            integer,allocatable,intent(in)::indices(:)
            character(*),intent(in)::name
            integer,intent(in),optional::skip_passed,intrinsic_mask
            integer::n,j,k,a,nformal,required,out,slots(16),values(16),wrappers(16),offset,mask
            character(63)::names(16),formals(16)
            logical::has_keyword,seen_keyword,reduction,source_parenthesized,actual_tokens_found
            if(diag%code/=0) return
            offset=0
            if(present(skip_passed)) offset=skip_passed
            n=0
            if(allocated(indices)) n=size(indices)
            if(n>16.or.n/=count(expected/=0)) then
                call mismatch(index,'actual argument count differs');return
            end if
            names='';formals='';slots=0;values=0;wrappers=0
            has_keyword=.false.;seen_keyword=.false.
            do j=1,n
                a=indices(j);values(j)=a
                if(.not.front%arena%has_node_at(a)) then
                    call mismatch(index,'actual argument AST missing');return
                end if
                select type(arg=>front%arena%entries(a)%node)
                type is(assignment_node)
                    if(.not.arg%is_keyword_argument.or.arg%is_walrus) then
                        call mismatch(a,'actual assignment is not a keyword');return
                    end if
                    if(allocated(arg%operator)) then
                        if(arg%operator/='=') then
                            call mismatch(a,'keyword operator differs');return
                        end if
                    end if
                    if(.not.front%arena%has_node_at(arg%target_index)) then
                        call mismatch(a,'keyword name missing');return
                    end if
                    select type(target=>front%arena%entries(arg%target_index)%node)
                    type is(identifier_node)
                        if(.not.allocated(target%name)) then
                            call mismatch(a,'keyword name missing');return
                        end if
                        if(len_trim(target%name)<1.or.len_trim(target%name)>63) then
                            call mismatch(a,'keyword name length differs');return
                        end if
                        names(j)=lower(target%name)
                    class default
                        call mismatch(a,'keyword name must be an identifier');return
                    end select
                    values(j)=arg%value_index;wrappers(j)=a
                    has_keyword=.true.;seen_keyword=.true.
                class default
                    if(seen_keyword) then
                        call mismatch(a,'positional actual follows keyword');return
                    end if
                end select
            end do
            if(.not.has_keyword.and.proc==0.and.name/='getcwd'.and.name/='get_command_argument'.and.name/='system_clock'.and.name/='reshape'.and.name/='cshift'.and.name/='eoshift'.and..not.is_bounds_inquiry(name).and..not.is_character_search_intrinsic(name).and..not.is_location_reduction(name)) then
                if((name=='selected_real_kind'.or.is_logical_reduction(name))) then
                    if(.not.present(intrinsic_mask)) then
                        call mismatch(index,'SELECTED_REAL_KIND slots missing');return
                    end if
                    if(n>3) then
                        call mismatch(index,'SELECTED_REAL_KIND argument count differs');return
                    end if
                    if(intrinsic_mask/=2**n-1) then
                        call mismatch(index,'SELECTED_REAL_KIND positional slots differ');return
                    end if
                end if
                do j=1,n
                    call expression(values(j),expected(j),depth)
                end do
                return
            end if
            reduction=.false.;nformal=0;required=0
            if(proc>0) then
                nformal=size(prog%procedures(proc)%args)-offset;required=0
                if(nformal>16) then
                    call mismatch(index,'procedure argument limit differs');return
                end if
                do j=1,nformal
                    formals(j)=prog%symbols(prog%procedures(proc)%args(j+offset))%name
                end do
            else
                select case(name)
                case('system_clock')
                    nformal=3;required=0;formals(:3)=[character(63)::'count','count_rate','count_max']
                case('cpu_time')
                    nformal=1;required=1;formals(1)='time'
                case('move_alloc')
                    nformal=2;required=2;formals(:2)=[character(63)::'from','to']
                case('getcwd')
                    nformal=2;required=1;formals(:2)=[character(63)::'count','status']
                case('get_command_argument')
                    nformal=4;required=1;formals(:4)=[character(63)::'number','value','length','status']
                case('random_number')
                    nformal=1;required=1;formals(1)='harvest'
                case('associated')
                    nformal=2;required=1;formals(:2)=[character(63)::'pointer','target']
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
                    call mismatch(index,'unsupported intrinsic keyword');return
                end select
            end if
            do j=1,n
                k=j
                if(is_location_reduction(name).and.proc==0.and.j>=required+1.and.names(required+1)=='') then
                    ! Resolve the overload from the producer's own operand metadata.
                    select type(actual=>front%arena%entries(values(required+1))%node)
                    class default
                        if(actual%resolved_type_kind==TLOGICAL) then
                            if(j>required+1.and.names(j)=='') then
                                call mismatch(index,'Location intrinsics without DIM require keyword KIND/BACK');return
                            end if
                            k=j+1
                        end if
                    end select
                end if
                if(names(j)/='') then
                    do k=1,nformal
                        if(formals(k)==names(j)) exit
                    end do
                end if
                if(k>nformal) then
                    call mismatch(index,'unknown keyword or excess actual');return
                end if
                if(slots(k)/=0) then
                    call mismatch(index,'repeated actual argument');return
                end if
                slots(k)=j
            end do
            if(any(slots(:required)==0)) then
                call mismatch(index,'missing required actual');return
            end if
            if((name=='selected_real_kind'.or.is_logical_reduction(name).or.name=='reshape'.or.name=='cshift'.or.name=='eoshift'.or.is_bounds_inquiry(name).or.is_character_search_intrinsic(name).or.is_location_reduction(name))) then
                if(.not.present(intrinsic_mask)) then
                    call mismatch(index,'SELECTED_REAL_KIND slots missing');return
                end if
                mask=0
                do k=1,nformal
                    if(slots(k)/=0) mask=ibset(mask,k-1)
                end do
                if(mask/=intrinsic_mask) then
                    call mismatch(index,'SELECTED_REAL_KIND keyword slots differ');return
                end if
            end if
            if(proc>0) then
                if(size(expected)/=nformal) then
                    call mismatch(index,'optional argument slot count differs');return
                end if
                do k=1,nformal
                    if(slots(k)/=0) cycle
                    if(expected(k)/=0.or..not.prog%symbols(prog%procedures(proc)%args(k+offset))%is_optional) then
                        call mismatch(index,'missing required or mismatched optional actual');return
                    end if
                end do
            end if
            if(name=='getcwd'.or.name=='get_command_argument'.or.name=='system_clock') then
                if(size(expected)/=nformal) then
                    call mismatch(index,'process query formal slot count differs');return
                end if
                if(any((slots(:nformal)==0).neqv.(expected==0))) then
                    call mismatch(index,'process query optional slots differ');return
                end if
            end if
            out=0
            do k=1,nformal
                j=slots(k)
                if(j==0) cycle
                out=out+1
                if(proc>0.or.name=='getcwd'.or.name=='get_command_argument'.or.name=='system_clock') out=k
                a=expected(out)
                if(a<1.or.a>prog%ne) then
                    call mismatch(index,'actual argument IR missing');return
                end if
                if(reduction.and.k==2) then
                    if(prog%expressions(a)%typ/=ty_integer.or.expression_rank(a)/=0) then
                        call mismatch(index,'named DIM type/rank differs');return
                    end if
                end if
                if(reduction.and.k==3) then
                    if(prog%expressions(a)%typ/=ty_logical) then
                        call mismatch(index,'named MASK type differs');return
                    end if
                end if
                if(proc>0.and.prog%expressions(a)%kind==ex_substring.and.prog%expressions(a)%third/=0) then
                    source_parenthesized=source_actual_parenthesized(index,j,trim(names(j)),actual_tokens_found)
                    if(.not.actual_tokens_found)then
                        call mismatch(index,'substring actual source parentheses unavailable');return
                    end if
                    if(source_parenthesized.neqv.prog%expressions(a)%parenthesized)then
                        call mismatch(index,'substring actual source parentheses differ');return
                    end if
                end if
                if(proc>0.and.prog%expressions(a)%kind==ex_gather_rows) then
                    source_parenthesized=source_actual_parenthesized(index,j,trim(names(j)),actual_tokens_found)
                    if(.not.actual_tokens_found)then
                        call mismatch(index,'gather actual source parentheses unavailable');return
                    end if
                    if(source_parenthesized.neqv.prog%expressions(a)%parenthesized)then
                        call mismatch(index,'gather actual source parentheses differ');return
                    end if
                    if((.not.prog%expressions(a)%parenthesized.and. &
                        .not.bare_gather_input(prog,a,prog%procedures(proc)%args(k+offset))).or. &
                       prog%symbols(prog%procedures(proc)%args(k+offset))%dummy_intent/=1) then
                        call mismatch(index,'row gather user actual requires a parenthesized INTENT(IN) value');return
                    end if
                end if
                call expression(values(j),a,depth)
                if(wrappers(j)>0) checked_keywords(wrappers(j))=.true.
                if(diag%code/=0) return
            end do
        end subroutine
        ! The producer AST erases grouping parentheses. Recover only the
        ! actual-slot marker from its independent retained token stream; never
        ! infer snapshot/alias semantics from the guarded IR's own marker.
        logical function source_actual_parenthesized(owner,ordinal,keyword,found) result(parenthesized)
            integer,intent(in)::owner,ordinal
            character(*),intent(in)::keyword
            logical,intent(out)::found
            integer::i,j,start,finish,slot,parens,brackets,n,line,column
            parenthesized=.false.;found=.false.
            if(.not.allocated(front%tokens).or..not.front%arena%has_node_at(owner).or.ordinal<1)return
            line=front%arena%entries(owner)%node%line
            column=front%arena%entries(owner)%node%column
            n=size(front%tokens);i=1
            do while(i<=n)
                if(front%tokens(i)%line==line.and.front%tokens(i)%column==column)exit
                i=i+1
            end do
            if(i>n)return
            select type(owner_node=>front%arena%entries(owner)%node)
            type is(call_or_subscript_node)
                ! Postfix function nodes retain the closing parenthesis location
                ! (apply_index_postfix), not the callee's starting token.
                if(front%tokens(i)%kind/=TK_OPERATOR.or.front%tokens(i)%text/=')')return
                parens=1
                do j=i-1,1,-1
                    if(front%tokens(j)%kind/=TK_OPERATOR)cycle
                    if(front%tokens(j)%text==')')parens=parens+1
                    if(front%tokens(j)%text=='(')parens=parens-1
                    if(parens==0)exit
                end do
                if(j<1)return
                i=j
            type is(subroutine_call_node)
                ! CALL nodes retain their statement/callee occurrence. Their
                ! first opening parenthesis starts the explicit actual list.
                do while(i<=n)
                    if(front%tokens(i)%kind==TK_OPERATOR)then
                        if(front%tokens(i)%text=='(')exit
                        if(front%tokens(i)%text==';')return
                    end if
                    i=i+1
                end do
                if(i>n)return
            class default
                return
            end select
            parens=1;brackets=0;slot=1;start=i+1;finish=0
            do j=i+1,n
                if(front%tokens(j)%kind/=TK_OPERATOR)cycle
                select case(front%tokens(j)%text)
                case('[');brackets=brackets+1
                case(']');brackets=brackets-1
                case('(');parens=parens+1
                case(')')
                    parens=parens-1
                    if(parens==0)then
                        if(slot==ordinal)finish=j-1
                        exit
                    end if
                case(',')
                    if(parens==1.and.brackets==0)then
                        if(slot==ordinal)then
                            finish=j-1;exit
                        end if
                        slot=slot+1;start=j+1
                    end if
                end select
                if(parens<0.or.brackets<0)return
            end do
            if(finish<start)return
            i=next_actual_token(start,finish)
            if(i==0)return
            if(len_trim(keyword)>0)then
                if(lower(front%tokens(i)%text)/=keyword)return
                i=next_actual_token(i+1,finish)
                if(i==0)return
                if(front%tokens(i)%kind/=TK_OPERATOR.or.front%tokens(i)%text/='=')return
                i=next_actual_token(i+1,finish)
                if(i==0)return
            end if
            parenthesized=front%tokens(i)%kind==TK_OPERATOR.and.front%tokens(i)%text=='('
            found=.true.
        end function
        integer function next_actual_token(first,last) result(at)
            integer,intent(in)::first,last
            integer::i
            at=0
            do i=first,last
                select case(front%tokens(i)%kind)
                case(TK_NEWLINE,TK_COMMENT,TK_WHITESPACE);cycle
                end select
                if(front%tokens(i)%kind==TK_OPERATOR.and.front%tokens(i)%text=='&')cycle
                at=i;return
            end do
        end function
        subroutine check_module_write_ir(s,owner)
            integer,intent(in)::s,owner
            if(diag%code/=0.or.owner<=0) return
            if(s<1.or.s>prog%ns) then
                call fail(diag,'FortFront adapter: invalid module write symbol');return
            end if
            if(prog%symbols(s)%is_parameter) return
            if(prog%symbols(s)%scope>0.and.prog%symbols(s)%scope/=owner) then
                if(.not.host_symbol_visible(prog,s,owner)) then
                    call fail(diag,'FortFront adapter: unsupported internal procedure host capture');return
                end if
            else if(prog%symbols(s)%scope>=0.and..not.prog%symbols(s)%is_saved) then
                return
            end if
            if(prog%procedures(owner)%is_pure.or.(.not.prog%procedures(owner)%is_subroutine.and. &
               .not.prog%procedures(owner)%has_impure_prefix)) &
                call fail(diag,'FortFront adapter: module write forbidden in this procedure')
        end subroutine
        subroutine check_allocatable_actual(index,e,dummy)
            integer,intent(in)::index,e,dummy
            integer::s
            if(e<1.or.e>prog%ne) then
                call mismatch(index,'missing allocatable actual');return
            end if
            s=prog%expressions(e)%symbol
            if(prog%expressions(e)%kind/=ex_variable.or.prog%expressions(e)%parenthesized.or.s<1.or.s>prog%ns) then
                call mismatch(index,'ALLOCATABLE dummy requires whole allocatable actual');return
            end if
            if(.not.prog%symbols(s)%is_allocatable) call mismatch(index,'ALLOCATABLE actual attribute differs')
            if(prog%symbols(s)%deferred_character.neqv.prog%symbols(dummy)%deferred_character) &
                call mismatch(index,'ALLOCATABLE CHARACTER deferred length differs')
        end subroutine
        subroutine check_writable_actual(index,pc,e)
            integer,intent(in)::index,pc,e
            integer::s,k
            associate(x=>prog%expressions(e))
            if(x%parenthesized.or.(x%kind/=ex_variable.and.x%kind/=ex_element.and.x%kind/=ex_section)) then
                call mismatch(index,'writable argument requires a variable designator'); return
            end if
            s=x%symbol
            if(s<1.or.s>prog%ns) then
                call mismatch(index,'writable argument binding missing'); return
            end if
            call check_module_write_ir(s,current_scope)
            if(prog%symbols(s)%is_parameter.or.prog%symbols(s)%dummy_intent==1) &
                call mismatch(index,'writable argument is read-only')
            do k=1,pc-1
                if(prog%code(k)%scope/=current_scope.or.prog%code(k)%op/=op_do) cycle
                if(prog%code(k)%symbol==s.and.prog%code(k)%target>pc) &
                    call mismatch(index,'writable argument is an active DO variable')
            end do
            end associate
        end subroutine
        subroutine check_dummy(index,symbol,p)
            integer,intent(in)::index,symbol,p
            if(symbol<1.or.symbol>prog%ns.or..not.front%arena%has_node_at(index)) then
                call mismatch(index,'function dummy missing')
                return
            end if
            if(prog%symbols(symbol)%scope/=p.or..not.prog%symbols(symbol)%is_dummy.or. &
               prog%symbols(symbol)%rank>3) call mismatch(index,'function dummy scope/rank differs')
            select type(node=>front%arena%entries(index)%node)
            type is(parameter_declaration_node)
                if(.not.allocated(node%name)) then
                    call mismatch(index,'dummy name missing')
                else if(lower(node%name)/=trim(prog%symbols(symbol)%name)) then
                    call mismatch(index,'dummy order/name differs')
                end if
                if(node%is_optional.neqv.prog%symbols(symbol)%is_optional) &
                    call mismatch(index,'dummy OPTIONAL attribute differs')
                if(node%is_target.neqv.prog%symbols(symbol)%is_target) &
                    call mismatch(index,'dummy TARGET attribute differs')
                if(node%is_alternate_return) &
                    call mismatch(index,'unsupported dummy parameter')
            class default
                call mismatch(index,'unexpected dummy node')
            end select
        end subroutine
        recursive subroutine map_body(index,scope,depth)
            integer,intent(in)::index,scope,depth
            integer::j
            if(diag%code/=0) return
            if(depth>256.or..not.front%arena%has_node_at(index)) then
                call mismatch(index,'invalid statement tree')
                return
            end if
            if(scope_map(index)>-max_modules-1.and.scope_map(index)/=scope) then
                call mismatch(index,'statement shared by different scopes')
                return
            end if
            scope_map(index)=scope
            select type(node=>front%arena%entries(index)%node)
            type is(program_node)
                call map_body_list(node%body_indices,scope,depth+1)
            type is(module_node)
                call map_body_list(node%declaration_indices,scope,depth+1)
            type is(subroutine_def_node)
                call map_body_list(node%body_indices,scope,depth+1)
                call map_body_list(node%param_indices,scope,depth+1)
            type is(function_def_node)
                call map_body_list(node%body_indices,scope,depth+1)
                call map_body_list(node%param_indices,scope,depth+1)
            type is(derived_type_node)
                call map_body_list(node%component_indices,scope,depth+1)
                call map_body_list(node%binding_indices,scope,depth+1)
            type is(interface_block_node)
                call map_body_list(node%procedure_indices,scope,depth+1)
            type is(where_node)
                call map_body_list(node%where_body_indices,scope,depth+1)
                if(allocated(node%elsewhere_clauses)) then
                    do j=1,size(node%elsewhere_clauses)
                        call map_body_list(node%elsewhere_clauses(j)%body_indices,scope,depth+1)
                    end do
                end if
            type is(forall_node)
                call map_body_list(node%body_indices,scope,depth+1)
            type is(do_while_node)
                call map_body_list(node%body_indices,scope,depth+1)
            type is(do_loop_node)
                call map_body_list(node%body_indices,scope,depth+1)
            type is(select_case_node)
                call map_body_list(node%case_indices,scope,depth+1)
                if(node%default_index>0) call map_body(node%default_index,scope,depth+1)
            type is(case_block_node)
                call map_body_list(node%body_indices,scope,depth+1)
            type is(case_default_node)
                call map_body_list(node%body_indices,scope,depth+1)
            type is(if_node)
                call map_body_list(node%then_body_indices,scope,depth+1)
                call map_body_list(node%else_body_indices,scope,depth+1)
                if(allocated(node%elseif_blocks)) then
                    do j=1,size(node%elseif_blocks)
                        call map_body_list(node%elseif_blocks(j)%body_indices,scope,depth+1)
                    end do
                end if
            end select
        end subroutine
        recursive subroutine map_body_list(indices,scope,depth)
            integer,allocatable,intent(in)::indices(:)
            integer,intent(in)::scope,depth
            integer::j
            if(.not.allocated(indices)) return
            do j=1,size(indices)
                if(.not.front%arena%has_node_at(indices(j))) then
                    call mismatch(indices(j),'statement missing'); return
                end if
                select type(child=>front%arena%entries(indices(j))%node)
                type is(function_def_node)
                    cycle
                type is(subroutine_def_node)
                    cycle
                end select
                call map_body(indices(j),scope,depth)
            end do
        end subroutine
        integer function node_scope(index) result(scope)
            integer,intent(in)::index
            integer::n
            scope=scope_map(index)
            if(scope>-max_modules-1) return
            n=find_enclosing_scope(front%arena,index)
            if(n>0) scope=scope_map(n)
        end function
        integer function scope_node() result(index)
            index=main_node
            if(current_scope>0) index=procedure_node(current_scope)
            if(current_scope<0.and.current_scope>=-prog%nm) index=module_node_index(-current_scope)
        end function
        integer function instruction_scope(pc) result(scope)
            integer,intent(in)::pc
            integer::p
            scope=0
            do p=1,prog%np
                if(pc>=prog%procedures(p)%first.and.pc<=prog%procedures(p)%last) scope=p
            end do
        end function
        subroutine check_use(index,node)
            integer,intent(in)::index
            type(use_statement_node),intent(in)::node
            integer::m,n,u,j,symbol,count_imports
            logical::source_module
            if(.not.allocated(node%module_name)) then
                call mismatch(index,'USE name missing');return
            end if
            source_module=.false.
            ! Module nature is bound to the source declaration order, not to
            ! mutable IR USE edges or the spelling ISO_FORTRAN_ENV alone.
            do m=1,prog%nm
                select type(source_module_node=>front%arena%entries(module_node_index(m))%node)
                type is(module_node)
                    if(.not.allocated(source_module_node%name)) cycle
                    if(source_module_node%line>=node%line) cycle
                    if(lower(source_module_node%name)==lower(node%module_name)) source_module=.true.
                end select
            end do
            if(lower(node%module_name)=='iso_fortran_env'.and. &
               (node%is_intrinsic.or.(.not.node%is_non_intrinsic.and..not.source_module))) then
                if(.not.node%has_only.or.node%is_non_intrinsic) then
                    call mismatch(index,'intrinsic ISO_FORTRAN_ENV ONLY required');return
                end if
                count_imports=0
                if(allocated(node%only_list)) then
                    do n=1,size(node%only_list)
                        if(.not.allocated(node%only_list(n)%s)) then
                            call mismatch(index,'intrinsic import name missing');return
                        end if
                        call check_intrinsic_import(index,node%only_list(n)%s,node%only_list(n)%s)
                        if(diag%code/=0) return
                        count_imports=count_imports+1
                    end do
                end if
                if(allocated(node%rename_list)) then
                    if(mod(size(node%rename_list),2)/=0) then
                        call mismatch(index,'intrinsic rename pair incomplete');return
                    end if
                    do n=1,size(node%rename_list),2
                        if(.not.allocated(node%rename_list(n)%s).or..not.allocated(node%rename_list(n+1)%s)) then
                            call mismatch(index,'intrinsic rename name missing');return
                        end if
                        call check_intrinsic_import(index,node%rename_list(n)%s,node%rename_list(n+1)%s)
                        if(diag%code/=0) return
                        count_imports=count_imports+1
                    end do
                end if
                if(count_imports==0) call mismatch(index,'intrinsic ISO_FORTRAN_ENV ONLY list is empty')
                return
            end if
            if(allocated(node%rename_list)) then
                if(size(node%rename_list)>0) then
                    call mismatch(index,'Nonintrinsic USE renaming unsupported');return
                end if
            end if
            if(current_scope>0.or.node%is_intrinsic) then
                call mismatch(index,'module USE inside procedure or nature unsupported');return
            end if
            m=0
            do n=1,prog%nm
                if(lower(node%module_name)==trim(prog%modules(n))) m=n
            end do
            if(m==0) then
                call mismatch(index,'USE module differs');return
            end if
            use_count(m)=use_count(m)+1;u=0
            do n=1,prog%nu
                if(prog%uses(n)==m.and.prog%use_lines(n)==node%line.and.prog%use_scopes(n)==current_scope) u=n
            end do
            if(u==0) then
                call mismatch(index,'USE location differs');return
            end if
            if(node%has_only.neqv.prog%use_only(u)) call mismatch(index,'USE ONLY attribute differs')
            n=0
            if(allocated(node%only_list)) n=size(node%only_list)
            if(n/=prog%n_only(u)) then
                call mismatch(index,'USE ONLY count differs');return
            end if
            do j=1,n
                if(lower(node%only_list(j)%s)/=trim(prog%only_names(j,u))) call mismatch(index,'USE ONLY names differ')
            end do
        end subroutine
        subroutine check_intrinsic_import(index,local_name,remote_name)
            integer,intent(in)::index
            character(*),intent(in)::local_name,remote_name
            integer::symbol
            symbol=symbol_index(local_name)
            if(symbol==0) then
                call mismatch(index,'intrinsic kind import missing');return
            end if
            if(seen_symbol(symbol).or.symbol_declaration(symbol)/=0) then
                call mismatch(index,'duplicate intrinsic kind import');return
            end if
            if(prog%symbols(symbol)%scope/=current_scope.or. &
               trim(prog%symbols(symbol)%intrinsic_import)/=lower(remote_name).or. &
               .not.valid_intrinsic_import(prog%symbols(symbol))) then
                call mismatch(index,'intrinsic kind import identity/value differs');return
            end if
            seen_symbol(symbol)=.true.;symbol_declaration(symbol)=index
        end subroutine
        ! Derive shapes independently of cached IR metadata and FortFront's
        ! unreliable occurrence ranks. Memoization also rejects cyclic IR trees.
        recursive subroutine derive_shape(e,depth)
            integer,intent(in)::e,depth
            integer::symbol,j,child,pid,dummy,wanted_kind,d,rank,wanted_length
            integer::triplet(3)
            type(value_t)::fold_value
            type(diagnostic_t)::fold_diag
            if(diag%code/=0) return
            if(e<1.or.e>prog%ne.or.depth>256) then
                call fail(diag,'FortFront adapter: invalid shape expression or depth')
                return
            end if
            if(shape_state(e)==2) return
            if(shape_state(e)==1) then
                call fail(diag,'FortFront adapter: cyclic expression shape')
                return
            end if
            shape_state(e)=1
            associate(x=>prog%expressions(e))
            wanted_kind=4
            if(x%kind/=ex_constructor_index.and.x%constructor_owner/=0) then
                call fail(diag,'FortFront adapter: unexpected constructor index owner');return
            end if
            if(x%kind/=ex_constructor.and.x%constructor_kind_expr/=0) then
                call fail(diag,'FortFront adapter: unexpected constructor KIND selector');return
            end if
            if(x%kind/=ex_element.and.x%kind/=ex_substring.and.x%third/=0) then
                call fail(diag,'FortFront adapter: unexpected third element subscript');return
            end if
            if(x%kind/=ex_section.and.x%kind/=ex_gather_rows.and. &
               (x%left3/=0.or.x%right3/=0.or.x%stride3/=0.or.x%triplet(3))) then
                call fail(diag,'FortFront adapter: unexpected third section dimension');return
            end if
            select case(x%kind)
            case(ex_constructor_index)
                if(.not.valid_constructor_index(prog,e)) then
                    call fail(diag,'FortFront adapter: invalid constructor index metadata');return
                end if
                expression_rank(e)=0;expression_extent(e)=0_int64
                wanted_kind=prog%symbols(x%symbol)%real_kind
            case(ex_constructor_do)
                symbol=x%symbol
                if(symbol<1.or.symbol>prog%ns.or..not.allocated(x%args)) then
                    call fail(diag,'FortFront adapter: constructor control/body missing');return
                end if
                if(prog%symbols(symbol)%typ/=ty_integer.or.prog%symbols(symbol)%rank/=0.or. &
                   prog%symbols(symbol)%is_parameter.or.prog%symbols(symbol)%is_intrinsic.or. &
                   (prog%symbols(symbol)%real_kind/=4.and.prog%symbols(symbol)%real_kind/=8)) then
                    call fail(diag,'FortFront adapter: constructor index declaration differs');return
                end if
                if(size(x%args)<1.or.size(x%args)>64.or.x%scope<0.or.x%scope>prog%np.or. &
                   x%rank/=1.or.x%extent/=-1_int64.or.any(x%dims/=0).or. &
                   x%typ<ty_integer.or.x%typ>ty_character.or.x%parenthesized.or. &
                   x%length_expr/=0.or.x%generic_id/=0.or.x%bound_type/=0.or.x%bound_binding/=0.or. &
                   x%intrinsic_mask/=0.or.x%left2/=0.or.x%right2/=0.or.x%stride2/=0.or. &
                   x%value%tag/=0.or.allocated(x%value%s).or.allocated(x%value%record).or. &
                   any(x%triplet.neqv.[.true.,.false.,.false.]).or. &
                   (x%op/=''.and.x%op/='character').or.(x%op=='character'.and.x%typ/=ty_character)) then
                    call fail(diag,'FortFront adapter: invalid constructor implied-DO metadata');return
                end if
                triplet=[x%left,x%right,x%stride]
                do j=1,3
                    child=triplet(j)
                    if(j==3.and.child==0) cycle
                    call derive_shape(child,depth+1)
                    if(diag%code/=0) return
                    if(expression_rank(child)/=0.or.prog%expressions(child)%typ/=ty_integer.or. &
                       (prog%expressions(child)%real_kind/=4.and.prog%expressions(child)%real_kind/=8)) then
                        call fail(diag,'FortFront adapter: constructor control must be scalar INTEGER');return
                    end if
                end do
                expression_rank(e)=1;expression_extent(e)=-1_int64
                do j=1,size(x%args)
                    child=x%args(j)
                    call derive_shape(child,depth+1)
                    if(diag%code/=0) return
                    if(j==1) wanted_kind=prog%expressions(child)%real_kind
                    if(expression_rank(child)>1.or.prog%expressions(child)%typ/=x%typ.or. &
                       prog%expressions(child)%real_kind/=wanted_kind) then
                        call fail(diag,'FortFront adapter: constructor implied-DO body type/kind/rank differs');return
                    end if
                end do
            case(ex_output_do)
                if(.not.valid_output_do(prog,e)) then
                    call fail(diag,'FortFront adapter: invalid output implied-DO metadata');return
                end if
                call derive_shape(x%left,depth+1);call derive_shape(x%right,depth+1)
                if(x%stride/=0) call derive_shape(x%stride,depth+1)
                do j=1,size(x%args)
                    call derive_shape(x%args(j),depth+1)
                end do
            case(ex_gather_rows)
                symbol=x%symbol
                if(symbol<1.or.symbol>prog%ns) then
                    call fail(diag,'FortFront adapter: row gather base missing');return
                end if
                rank=prog%symbols(symbol)%rank
                if(rank<1.or.rank>3) then
                    call fail(diag,'FortFront adapter: invalid row gather metadata');return
                end if
                if(count(x%triplet(:rank))/=rank-1.or. &
                   (rank==2.and.any(x%triplet.neqv.[.false.,.true.,.false.])).or. &
                   (rank==1.and.any(x%triplet))) then
                    call fail(diag,'FortFront adapter: invalid row gather axis metadata');return
                end if
                do d=1,rank
                    if(.not.x%triplet(d))exit
                end do
                triplet=[x%left,x%left2,x%left3]
                if(triplet(d)<=0.or.count(triplet/=0)/=1) then
                    call fail(diag,'FortFront adapter: invalid row gather selector metadata');return
                end if
                if(prog%symbols(symbol)%is_pointer.or. &
                   (rank==1.and.x%typ/=ty_character.and.x%typ/=ty_integer.and.x%typ/=ty_real).or. &
                   (rank/=1.and.x%typ/=ty_integer.and.x%typ/=ty_real).or.x%typ/=prog%symbols(symbol)%typ.or. &
                   x%rank/=rank.or.x%extent/=-1_int64.or.any(x%dims/=-1_int64).or. &
                   x%right/=0.or.x%stride/=0.or.x%right2/=0.or.x%stride2/=0.or. &
                   x%right3/=0.or.x%stride3/=0.or.x%third/=0.or. &
                   x%length_expr/=0.or.x%generic_id/=0.or.x%bound_type/=0.or.x%bound_binding/=0.or. &
                   x%intrinsic_mask/=0.or. &
                   (x%typ/=ty_character.and.x%character_len/=-1).or. &
                   (x%typ==ty_character.and.(x%real_kind/=4.or.prog%symbols(symbol)%real_kind/=4.or. &
                    x%character_len/=prog%symbols(symbol)%character_len)).or. &
                   len_trim(x%op)/=0.or.allocated(x%args)) then
                    call fail(diag,'FortFront adapter: invalid row gather metadata');return
                end if
                child=triplet(d);call derive_shape(child,depth+1)
                if(diag%code/=0) return
                if(expression_rank(child)/=1.or.prog%expressions(child)%typ/=ty_integer) then
                    call fail(diag,'FortFront adapter: row gather index must be INTEGER vector');return
                end if
                expression_rank(e)=rank;expression_extent(e)=-1_int64;expression_dims(:,e)=-1_int64
                wanted_kind=prog%symbols(symbol)%real_kind
            case(ex_record)
                pid=x%typ-ty_derived_base
                if(pid<1.or.pid>prog%nt.or..not.allocated(x%args)) then
                    call fail(diag,'FortFront adapter: invalid record constructor');return
                end if
                if(prog%derived_types(pid)%ncomponents<1.or.prog%derived_types(pid)%ncomponents>16) then
                    call fail(diag,'FortFront adapter: invalid record component count');return
                end if
                if(size(x%args)>prog%derived_types(pid)%ncomponents) then
                    call fail(diag,'FortFront adapter: record component count differs');return
                end if
                do j=size(x%args)+1,prog%derived_types(pid)%ncomponents
                    if(prog%derived_types(pid)%component_initializers(j)==0) then
                        call fail(diag,'FortFront adapter: omitted record component has no default');return
                    end if
                end do
                do j=1,size(x%args)
                    child=x%args(j);call derive_shape(child,depth+1)
                    if(diag%code/=0) return
                    if(expression_rank(child)/=0.or..not.component_assignable(prog%expressions(child)%typ, &
                       prog%derived_types(pid)%component_types(j))) &
                        call fail(diag,'FortFront adapter: record component type differs')
                end do
            case(ex_component)
                call derive_shape(x%left,depth+1)
                if(diag%code/=0) return
                pid=prog%expressions(x%left)%typ-ty_derived_base
                if(pid<1.or.pid>prog%nt) then
                    call fail(diag,'FortFront adapter: component base type invalid');return
                end if
                j=x%symbol
                if(j<1.or.j>prog%derived_types(pid)%ncomponents) then
                    call fail(diag,'FortFront adapter: component index invalid');return
                end if
                if(x%typ/=prog%derived_types(pid)%component_types(j).or.expression_rank(x%left)/=0) &
                    call fail(diag,'FortFront adapter: component type differs')
                wanted_kind=prog%derived_types(pid)%component_kinds(j)
                if(x%typ==ty_character)then
                    if(x%real_kind/=wanted_kind.or.x%rank/=0.or.x%extent/=0.or.any(x%dims/=0))then
                        call fail(diag,'FortFront adapter: CHARACTER component metadata differs');return
                    end if
                    associate(base=>prog%expressions(x%left))
                    if(base%kind/=ex_variable.or.base%rank/=0.or.base%extent/=0.or.any(base%dims/=0).or. &
                       base%real_kind/=4.or.base%character_len/=-1.or.base%symbol<1.or.base%symbol>prog%ns)then
                        call fail(diag,'FortFront adapter: CHARACTER component base metadata differs');return
                    end if
                    if(base%typ/=prog%symbols(base%symbol)%typ.or. &
                       base%real_kind/=prog%symbols(base%symbol)%real_kind.or.prog%symbols(base%symbol)%rank/=0)then
                        call fail(diag,'FortFront adapter: CHARACTER component base schema differs');return
                    end if
                    end associate
                end if
            case(ex_literal)
                if(x%value%tag/=x%typ) call fail(diag,'FortFront adapter: literal type cache differs')
                if(x%typ==ty_character.and.x%value%real_kind/=4) &
                    call fail(diag,'FortFront adapter: CHARACTER literal kind cache differs')
                if(x%typ==ty_integer.or.x%typ==ty_real) wanted_kind=x%value%real_kind
            case(ex_substring)
                symbol=x%symbol
                if(symbol==0) then
                    if(x%value%tag/=ty_character.or.x%value%real_kind/=4.or..not.allocated(x%value%s)) then
                        call fail(diag,'FortFront adapter: literal substring base missing');return
                    end if
                    if(len(x%value%s)>65536) then
                        call fail(diag,'FortFront adapter: literal substring base too long');return
                    end if
                else
                    if(symbol<1.or.symbol>prog%ns) then
                        call fail(diag,'FortFront adapter: substring symbol missing');return
                    end if
                    if(prog%symbols(symbol)%typ/=ty_character.or.(prog%symbols(symbol)%rank/=0.and.x%third==0).or. &
                       x%value%tag/=0.or.allocated(x%value%s)) then
                        call fail(diag,'FortFront adapter: invalid substring base');return
                    end if
                end if
                if(x%typ/=ty_character.or.x%stride/=0.or.x%left2/=0.or. &
                   x%right2/=0.or.x%stride2/=0.or.x%left3/=0.or. &
                   x%right3/=0.or.x%stride3/=0.or.any(x%triplet(2:)).or.allocated(x%args).or.x%length_expr/=0) then
                    call fail(diag,'FortFront adapter: invalid scalar substring');return
                end if
                if(symbol>0.and.x%scope>0.and.x%scope<=prog%np) then
                    if(prog%procedures(x%scope)%is_simple.and. &
                       prog%symbols(symbol)%scope/=x%scope.and..not.prog%symbols(symbol)%is_parameter) &
                        call fail(diag,'FortFront adapter: SIMPLE procedure references nonlocal variable')
                end if
                if(x%third/=0) then
                    if(symbol<=0) then
                        call fail(diag,'FortFront adapter: substring element requires an array symbol');return
                    end if
                    child=x%third
                    call derive_shape(child,depth+1)
                    if(diag%code/=0) return
                    associate(base=>prog%expressions(child))
                    if(base%kind/=ex_element.or.base%symbol/=symbol.or.base%typ/=ty_character.or. &
                       base%real_kind/=4.or.prog%symbols(symbol)%real_kind/=4.or.expression_rank(child)/=0) then
                        call fail(diag,'FortFront adapter: invalid substring element base');return
                    end if
                    end associate
                end if
                triplet=[x%left,x%right,0]
                do j=1,2
                    child=triplet(j)
                    if(child==0) cycle
                    call derive_shape(child,depth+1)
                    if(diag%code/=0) return
                    if(expression_rank(child)/=0.or.prog%expressions(child)%typ/=ty_integer) &
                        call fail(diag,'FortFront adapter: substring bounds must be scalar INTEGER')
                end do
            case(ex_variable,ex_element,ex_section)
                symbol=x%symbol
                if(symbol<1.or.symbol>prog%ns) then
                    call fail(diag,'FortFront adapter: shape symbol missing')
                    return
                end if
                if(x%scope>0.and.x%scope<=prog%np) then
                    if(prog%procedures(x%scope)%is_simple.and. &
                       prog%symbols(symbol)%scope/=x%scope.and..not.prog%symbols(symbol)%is_parameter) &
                        call fail(diag,'FortFront adapter: SIMPLE procedure references nonlocal variable')
                end if
                wanted_kind=prog%symbols(symbol)%real_kind
                if(x%kind==ex_variable) then
                    expression_rank(e)=prog%symbols(symbol)%rank
                    if(expression_rank(e)>0) then
                        expression_extent(e)=symbol_extent(symbol)
                        known_extent(e)=expression_extent(e)
                        if(expression_rank(e)>=2) then
                            expression_dims(:,e)=[symbol_dimension(symbol,1),symbol_dimension(symbol,2),symbol_dimension(symbol,3)]
                            if(expression_extent(e)<0_int64) expression_dims(:,e)=-1_int64
                            known_dims(:,e)=expression_dims(:,e)
                        end if
                    end if
                else if(x%kind==ex_section) then
                    rank=prog%symbols(symbol)%rank
                    if(rank<1.or.rank>3.or.x%typ/=prog%symbols(symbol)%typ) then
                        call fail(diag,'FortFront adapter: section binding/type differs'); return
                    end if
                    if(rank==1.and.(x%left2/=0.or.x%right2/=0.or.x%stride2/=0.or.x%triplet(2))) then
                        call fail(diag,'FortFront adapter: unexpected second section dimension'); return
                    end if
                    if(rank<3.and.(x%left3/=0.or.x%right3/=0.or.x%stride3/=0.or.x%triplet(3))) then
                        call fail(diag,'FortFront adapter: unexpected third section dimension'); return
                    end if
                    if(x%third/=0) then
                        call fail(diag,'FortFront adapter: unexpected section element subscript'); return
                    end if
                    expression_rank(e)=count(x%triplet(:rank))
                    if(expression_rank(e)==0) then
                        call fail(diag,'FortFront adapter: section has no triplets'); return
                    end if
                    expression_extent(e)=-1_int64
                    if(expression_rank(e)>=2) expression_dims(:,e)=-1_int64
                    do d=1,rank
                        triplet=[x%left,x%right,x%stride]
                        if(d==2) triplet=[x%left2,x%right2,x%stride2]
                        if(d==3) triplet=[x%left3,x%right3,x%stride3]
                        if(.not.x%triplet(d).and.(triplet(1)==0.or.any(triplet(2:)/=0))) then
                            call fail(diag,'FortFront adapter: invalid scalar section subscript'); return
                        end if
                        do j=1,3
                            child=triplet(j)
                            if(child==0) cycle
                            call derive_shape(child,depth+1)
                            if(diag%code/=0) return
                            if(expression_rank(child)/=0.or.prog%expressions(child)%typ/=ty_integer) then
                                call fail(diag,'FortFront adapter: section triplet must be scalar INTEGER'); return
                            end if
                        end do
                    end do
                else
                    if(prog%symbols(symbol)%rank<1.or.prog%symbols(symbol)%rank>3) &
                        call fail(diag,'FortFront adapter: element binding is not an array')
                    call derive_shape(x%left,depth+1)
                    if(diag%code/=0) return
                    if(expression_rank(x%left)/=0.or.prog%expressions(x%left)%typ/=ty_integer) &
                        call fail(diag,'FortFront adapter: subscript is not scalar INTEGER')
                    if(prog%symbols(symbol)%rank>=2) then
                        call derive_shape(x%right,depth+1)
                        if(diag%code/=0) return
                        if(expression_rank(x%right)/=0.or.prog%expressions(x%right)%typ/=ty_integer) &
                            call fail(diag,'FortFront adapter: second subscript is not scalar INTEGER')
                    else if(x%right/=0) then
                        call fail(diag,'FortFront adapter: unexpected second subscript')
                    end if
                    if(prog%symbols(symbol)%rank==3) then
                        call derive_shape(x%third,depth+1)
                        if(diag%code/=0) return
                        if(expression_rank(x%third)/=0.or.prog%expressions(x%third)%typ/=ty_integer) &
                            call fail(diag,'FortFront adapter: third subscript is not scalar INTEGER')
                    else if(x%third/=0) then
                        call fail(diag,'FortFront adapter: unexpected third subscript')
                    end if
                end if
            case(ex_unary,ex_binary)
                call derive_shape(x%left,depth+1)
                if(diag%code/=0) return
                call merge_shape(e,x%left)
                if(prog%expressions(x%left)%typ==x%typ) wanted_kind=prog%expressions(x%left)%real_kind
                if(x%kind==ex_binary) then
                    call derive_shape(x%right,depth+1)
                    if(diag%code/=0) return
                    call merge_shape(e,x%right)
                    if(prog%expressions(x%right)%typ==x%typ) &
                        wanted_kind=max(wanted_kind,prog%expressions(x%right)%real_kind)
                end if
            case(ex_constructor)
                if(.not.allocated(x%args)) then
                    call fail(diag,'FortFront adapter: constructor elements missing');return
                end if
                if((size(x%args)==0.and.len_trim(x%op)==0).or.x%typ<ty_integer.or.x%typ>ty_character) then
                    call fail(diag,'FortFront adapter: invalid constructor type or size');return
                end if
                if(x%op=='integer'.or.x%op=='real'.or.x%op=='logical') then
                    if(size(x%args)/=0.or.x%character_len/=-1.or.x%length_expr/=0.or. &
                       x%left/=0.or.x%right/=0.or.x%symbol/=0.or.x%stride/=0.or. &
                       x%left2/=0.or.x%right2/=0.or.x%stride2/=0.or.x%generic_id/=0.or. &
                       x%bound_type/=0.or.x%bound_binding/=0.or.x%intrinsic_mask/=0.or. &
                       .not.x%triplet(1).or.x%triplet(2)) then
                        call fail(diag,'FortFront adapter: invalid typed empty constructor metadata');return
                    end if
                    if((x%op=='integer'.and.x%typ/=ty_integer).or. &
                       (x%op=='real'.and.x%typ/=ty_real).or.(x%op=='logical'.and.x%typ/=ty_logical)) then
                        call fail(diag,'FortFront adapter: typed empty constructor type differs');return
                    end if
                    if(x%constructor_kind_expr/=0) then
                        call derive_shape(x%constructor_kind_expr,depth+1)
                        if(diag%code/=0)return
                        child=x%constructor_kind_expr
                        if(x%typ==ty_logical.or.prog%expressions(child)%typ/=ty_integer.or. &
                           (prog%expressions(child)%kind/=ex_literal.and.prog%expressions(child)%kind/=ex_variable).or. &
                           prog%expressions(child)%rank/=0.or..not.bound_constant_expression(prog,child,0)) then
                            call fail(diag,'FortFront adapter: invalid empty constructor KIND');return
                        end if
                        call evaluate_constant(prog,child,fold_value,fold_diag)
                        if(fold_diag%code/=0) then
                            call fail(diag,'FortFront adapter: nonconstant empty constructor KIND');return
                        end if
                        if(fold_value%i/=4.and.fold_value%i/=8) then
                            call fail(diag,'FortFront adapter: unsupported empty constructor KIND');return
                        end if
                        wanted_kind=int(fold_value%i)
                    end if
                    if(x%real_kind/=wanted_kind) then
                        call fail(diag,'FortFront adapter: empty constructor KIND cache differs');return
                    end if
                else if(x%constructor_kind_expr/=0.or.(len_trim(x%op)>0.and.x%op/='character').or. &
                        (x%op=='character'.and.x%typ/=ty_character)) then
                    call fail(diag,'FortFront adapter: invalid constructor type marker');return
                end if
                expression_rank(e)=1
                do j=1,size(x%args)
                    child=x%args(j)
                    call derive_shape(child,depth+1)
                    if(diag%code/=0) return
                    if(j==1) wanted_kind=prog%expressions(child)%real_kind
                    if(expression_rank(child)>1.or.prog%expressions(child)%typ/=x%typ.or. &
                       ((x%typ==ty_real.or.x%typ==ty_integer).and.prog%expressions(child)%real_kind/=wanted_kind)) then
                        call fail(diag,'FortFront adapter: constructor element type/kind/rank differs');return
                    end if
                    if(expression_extent(e)<0) cycle
                    if(expression_rank(child)==0) then
                        expression_extent(e)=expression_extent(e)+1
                    else if(expression_extent(child)<0) then
                        expression_extent(e)=-1
                    else
                        expression_extent(e)=expression_extent(e)+expression_extent(child)
                    end if
                end do
                if(expression_extent(e)>max_array_elements) &
                    call fail(diag,'FortFront adapter: constructor exceeds element limit')
                known_extent(e)=expression_extent(e)
            case(ex_user_call)
                pid=x%symbol
                if(pid<1.or.pid>prog%np) then
                    call fail(diag,'FortFront adapter: function binding missing')
                    return
                end if
                if(.not.allocated(x%args).or..not.allocated(prog%procedures(pid)%args)) then
                    call fail(diag,'FortFront adapter: function arguments missing')
                    return
                end if
                if(size(x%args)/=size(prog%procedures(pid)%args)) then
                    call fail(diag,'FortFront adapter: function argument count differs')
                    return
                end if
                if(prog%procedures(pid)%is_subroutine) call fail(diag,'FortFront adapter: subroutine used as expression')
                if(x%scope>0.and.x%scope<=prog%np) then
                    if(prog%procedures(x%scope)%is_simple.and..not.prog%procedures(pid)%is_simple) &
                        call fail(diag,'FortFront adapter: SIMPLE procedure calls nonsimple function')
                    if(prog%procedures(x%scope)%is_pure.and..not.prog%procedures(pid)%is_pure) &
                        call fail(diag,'FortFront adapter: PURE procedure calls impure function')
                end if
                symbol=prog%procedures(pid)%result_symbol
                if(symbol<1.or.symbol>prog%ns) then
                    call fail(diag,'FortFront adapter: function result missing')
                    return
                end if
                wanted_kind=prog%symbols(symbol)%real_kind
                if(prog%symbols(symbol)%scope/=pid.or. &
                   (prog%procedures(pid)%is_elemental.and.prog%symbols(symbol)%rank/=0).or. &
                   x%typ/=prog%symbols(symbol)%typ) &
                    call fail(diag,'FortFront adapter: function result type/scope differs')
                if(.not.prog%procedures(pid)%is_elemental) then
                    expression_rank(e)=prog%symbols(symbol)%rank
                    if(expression_rank(e)>0) then
                        if(x%typ<ty_integer.or.x%typ>ty_character) &
                            call fail(diag,'FortFront adapter: unsupported array function result type')
                        expression_extent(e)=-1_int64
                        if(expression_rank(e)>=2) expression_dims(:,e)=-1_int64
                    end if
                end if
                do j=1,size(x%args)
                    child=x%args(j);dummy=prog%procedures(pid)%args(j)
                    if(dummy<1.or.dummy>prog%ns) then
                        call fail(diag,'FortFront adapter: function dummy missing')
                        return
                    end if
                    if(child==0) then
                        if(.not.prog%symbols(dummy)%is_optional) &
                            call fail(diag,'FortFront adapter: missing required function argument')
                        cycle
                    end if
                    call derive_shape(child,depth+1)
                    if(diag%code/=0) return
                    call check_pointer_actual(0,child,dummy)
                    if(prog%symbols(dummy)%is_allocatable) call check_allocatable_actual(0,child,dummy)
                    if((.not.prog%procedures(pid)%is_elemental.and. &
                       expression_rank(child)/=prog%symbols(dummy)%rank).or. &
                       prog%expressions(child)%typ/=prog%symbols(dummy)%typ.or. &
                       prog%symbols(dummy)%scope/=pid.or..not.prog%symbols(dummy)%is_dummy) &
                        call fail(diag,'FortFront adapter: function argument type/rank/scope differs')
                    if(prog%procedures(pid)%is_elemental) then
                        if(prog%symbols(dummy)%rank/=0.or.prog%symbols(dummy)%dummy_intent/=1) &
                            call fail(diag,'FortFront adapter: ELEMENTAL function dummy must be scalar INTENT(IN)')
                        call merge_shape(e,child)
                    end if
                    if((prog%symbols(dummy)%typ==ty_real.or.prog%symbols(dummy)%typ==ty_integer)) then
                        if(prog%expressions(child)%real_kind/=prog%symbols(dummy)%real_kind) &
                            call fail(diag,'FortFront adapter: function argument kind differs')
                    end if
                end do
            case(ex_call)
                if(.not.allocated(x%args)) then
                    call fail(diag,'FortFront adapter: missing shape arguments')
                    return
                end if
                if(size(x%args)==0.and.x%op/='selected_real_kind'.and.x%op/='null') then
                    call fail(diag,'FortFront adapter: empty intrinsic arguments');return
                end if
                do j=1,size(x%args)
                    child=x%args(j)
                    call derive_shape(child,depth+1)
                    if(diag%code/=0) return
                    if(x%op/='associated'.and.x%op/='allocated'.and.x%op/='present'.and.x%op/='kind'.and.x%op/='new_line'.and.x%op/='len'.and.x%op/='size'.and.x%op/='lbound'.and.x%op/='ubound'.and. &
                       .not.is_array_transform(x%op).and..not.is_numeric_model_inquiry(x%op)) call merge_shape(e,child)
                end do
                if(x%op=='size') then
                    if(size(x%args)>2.or.(x%op/='size'.and.size(x%args)/=2)) &
                        call fail(diag,'FortFront adapter: array inquiry argument count differs')
                    if(expression_rank(x%args(1))<1.or.expression_rank(x%args(1))>3.or.x%typ/=ty_integer) &
                        call fail(diag,'FortFront adapter: array inquiry type/rank differs')
                    if(size(x%args)==2) then
                        child=x%args(2)
                        if(expression_rank(child)/=0.or.prog%expressions(child)%typ/=ty_integer) &
                            call fail(diag,'FortFront adapter: array inquiry DIM differs')
                        if(x%op/='size') call check_nonoptional_dim(child)
                    end if
                end if
                if(x%op=='real') then
                    dummy=size(x%args)
                    if(dummy<1.or.dummy>2.or.x%intrinsic_mask/=0.or.x%typ/=ty_real.or. &
                       (x%real_kind/=4.and.x%real_kind/=8)) then
                        call fail(diag,'FortFront adapter: REAL count/result differs');return
                    end if
                    child=x%args(1)
                    if((prog%expressions(child)%typ/=ty_real.and.prog%expressions(child)%typ/=ty_integer).or. &
                       (prog%expressions(child)%real_kind/=4.and.prog%expressions(child)%real_kind/=8)) then
                        call fail(diag,'FortFront adapter: REAL operand type/kind differs');return
                    end if
                    if(dummy==2) then
                        child=x%args(2)
                        if(prog%expressions(child)%typ/=ty_integer.or.expression_rank(child)/=0) then
                            call fail(diag,'FortFront adapter: REAL KIND must be scalar INTEGER');return
                        end if
                        call check_bound_cache(0,child,int(x%real_kind,int64))
                    else if(x%real_kind/=4) then
                        call fail(diag,'FortFront adapter: REAL default kind differs');return
                    end if
                end if
                if(x%op=='aint'.or.x%op=='anint'.or.x%op=='asinh'.or.x%op=='acosh') then
                    dummy=size(x%args)
                    if(dummy<1.or.dummy>2.or.x%intrinsic_mask/=0.or.x%typ/=ty_real.or. &
                       ((x%op=='asinh'.or.x%op=='acosh').and.dummy/=1).or. &
                       (x%real_kind/=4.and.x%real_kind/=8)) then
                        call fail(diag,'FortFront adapter: real rounding/inverse count/result differs');return
                    end if
                    child=x%args(1)
                    if(prog%expressions(child)%typ/=ty_real.or. &
                       (prog%expressions(child)%real_kind/=4.and.prog%expressions(child)%real_kind/=8)) then
                        call fail(diag,'FortFront adapter: real rounding/inverse operand differs');return
                    end if
                    if(dummy==2) then
                        child=x%args(2)
                        if(prog%expressions(child)%typ/=ty_integer.or.expression_rank(child)/=0) then
                            call fail(diag,'FortFront adapter: AINT/ANINT KIND differs');return
                        end if
                        call check_bound_cache(0,child,int(x%real_kind,int64))
                    else if(x%real_kind/=prog%expressions(child)%real_kind) then
                        call fail(diag,'FortFront adapter: real rounding/inverse default kind differs');return
                    end if
                end if
                if(is_erf_bessel(x%op)) then
                    dummy=1
                    if(x%op=='bessel_jn'.or.x%op=='bessel_yn') dummy=2
                    if(size(x%args)/=dummy.or.x%intrinsic_mask/=0.or.x%typ/=ty_real) then
                        call fail(diag,'FortFront adapter: ERF/Bessel count/result metadata differs');return
                    end if
                    child=x%args(dummy)
                    if(prog%expressions(child)%typ/=ty_real.or. &
                       (x%real_kind/=4.and.x%real_kind/=8).or.x%real_kind/=prog%expressions(child)%real_kind) then
                        call fail(diag,'FortFront adapter: ERF/Bessel X type/kind differs');return
                    end if
                    if(dummy==2) then
                        child=x%args(1)
                        if(prog%expressions(child)%typ/=ty_integer.or. &
                           (prog%expressions(child)%real_kind/=4.and.prog%expressions(child)%real_kind/=8)) then
                            call fail(diag,'FortFront adapter: Bessel N type/kind differs');return
                        end if
                    end if
                end if
                if(x%op=='dprod'.or.x%op=='tand') then
                    dummy=1
                    if(x%op=='dprod') dummy=2
                    if(size(x%args)/=dummy.or.x%intrinsic_mask/=0.or.x%typ/=ty_real.or. &
                       (x%real_kind/=4.and.x%real_kind/=8)) then
                        call fail(diag,'FortFront adapter: DPROD/TAND result/count differs');return
                    end if
                    do j=1,dummy
                        child=x%args(j)
                        if(prog%expressions(child)%typ/=ty_real.or. &
                           (prog%expressions(child)%real_kind/=4.and.prog%expressions(child)%real_kind/=8)) then
                            call fail(diag,'FortFront adapter: DPROD/TAND operand differs');return
                        end if
                        if(x%op=='dprod'.and.(prog%expressions(child)%real_kind/=4.or.x%real_kind/=8)) then
                            call fail(diag,'FortFront adapter: DPROD kind differs');return
                        end if
                    end do
                    if(x%op=='tand'.and.x%real_kind/=prog%expressions(x%args(1))%real_kind) then
                        call fail(diag,'FortFront adapter: TAND result kind differs');return
                    end if
                end if
                if(x%op=='asin'.or.x%op=='atan'.or.x%op=='atan2') then
                    dummy=size(x%args)
                    if(dummy<1.or.dummy>2.or.(x%op=='asin'.and.dummy/=1).or. &
                       (x%op=='atan2'.and.dummy/=2).or.x%intrinsic_mask/=0.or.x%typ/=ty_real.or. &
                       (x%real_kind/=4.and.x%real_kind/=8)) then
                        call fail(diag,'FortFront adapter: inverse trig count/result metadata differs');return
                    end if
                    do j=1,dummy
                        child=x%args(j)
                        if(prog%expressions(child)%typ/=ty_real.or.x%real_kind/=prog%expressions(child)%real_kind) then
                            call fail(diag,'FortFront adapter: inverse trig operand type/kind differs');return
                        end if
                    end do
                end if
                if(is_degree_trig(x%op).or.x%op=='acos'.or.x%op=='rrspacing') then
                    if(size(x%args)/=1.or.x%intrinsic_mask/=0.or.x%typ/=ty_real) then
                        call fail(diag,'FortFront adapter: ACOS count/result metadata differs');return
                    end if
                    child=x%args(1)
                    if(prog%expressions(child)%typ/=ty_real.or. &
                       (x%real_kind/=4.and.x%real_kind/=8).or.x%real_kind/=prog%expressions(child)%real_kind) then
                        call fail(diag,'FortFront adapter: ACOS operand type/kind differs');return
                    end if
                end if
                if(x%op=='erfc_scaled') then
                    if(size(x%args)/=1.or.x%intrinsic_mask/=0.or.x%typ/=ty_real) then
                        call fail(diag,'FortFront adapter: ERFC_SCALED count/result metadata differs');return
                    end if
                    child=x%args(1)
                    if(prog%expressions(child)%typ/=ty_real.or. &
                       (x%real_kind/=4.and.x%real_kind/=8).or.x%real_kind/=prog%expressions(child)%real_kind) then
                        call fail(diag,'FortFront adapter: ERFC_SCALED operand type/kind differs');return
                    end if
                end if
                if(x%op=='isnan') then
                    if(size(x%args)/=1.or.x%intrinsic_mask/=0.or.x%typ/=ty_logical.or.x%real_kind/=4) then
                        call fail(diag,'FortFront adapter: ISNAN count/result metadata differs');return
                    end if
                    child=x%args(1)
                    if(prog%expressions(child)%typ/=ty_real.or. &
                       (prog%expressions(child)%real_kind/=4.and.prog%expressions(child)%real_kind/=8)) then
                        call fail(diag,'FortFront adapter: ISNAN operand type/kind differs');return
                    end if
                end if
                if(x%op=='spacing'.or.x%op=='nearest') then
                    dummy=1
                    if(x%op=='nearest') dummy=2
                    if(size(x%args)/=dummy.or.x%intrinsic_mask/=0) then
                        call fail(diag,'FortFront adapter: SPACING/NEAREST count/slots differ');return
                    end if
                    child=x%args(1)
                    if(x%typ/=ty_real.or.x%real_kind/=prog%expressions(child)%real_kind) then
                        call fail(diag,'FortFront adapter: SPACING/NEAREST result type/kind differs');return
                    end if
                    do j=1,size(x%args)
                        child=x%args(j)
                        if(prog%expressions(child)%typ/=ty_real.or. &
                           (prog%expressions(child)%real_kind/=4.and.prog%expressions(child)%real_kind/=8)) then
                            call fail(diag,'FortFront adapter: SPACING/NEAREST operand type/kind differs');return
                        end if
                    end do
                end if
                if(x%op=='dim'.or.x%op=='sign'.or.x%op=='log_gamma') then
                    dummy=2
                    if(x%op=='log_gamma') dummy=1
                    if(size(x%args)/=dummy.or.x%intrinsic_mask/=0) then
                        call fail(diag,'FortFront adapter: elementary math count/slots differ');return
                    end if
                    child=x%args(1)
                    if((x%typ/=ty_integer.and.x%typ/=ty_real).or. &
                       (x%op=='log_gamma'.and.x%typ/=ty_real).or. &
                       (x%real_kind/=4.and.x%real_kind/=8)) then
                        call fail(diag,'FortFront adapter: elementary math result type/kind differs');return
                    end if
                    do j=1,size(x%args)
                        child=x%args(j)
                        if(prog%expressions(child)%typ/=x%typ.or.prog%expressions(child)%real_kind/=x%real_kind) then
                            call fail(diag,'FortFront adapter: elementary math operand type/kind differs');return
                        end if
                    end do
                end if
                if(x%op=='fraction'.or.x%op=='exponent'.or.x%op=='set_exponent'.or.x%op=='iachar') then
                    dummy=size(x%args)
                    if(x%intrinsic_mask/=0.or.(x%op=='set_exponent'.and.dummy/=2).or. &
                       (x%op=='iachar'.and.(dummy<1.or.dummy>2)).or. &
                       ((x%op=='fraction'.or.x%op=='exponent').and.dummy/=1)) then
                        call fail(diag,'FortFront adapter: model decomposition count/slots differ');return
                    end if
                    child=x%args(1)
                    if(x%op=='iachar') then
                        if(prog%expressions(child)%typ/=ty_character.or.prog%expressions(child)%real_kind/=4.or. &
                           x%typ/=ty_integer.or.(x%real_kind/=4.and.x%real_kind/=8)) then
                            call fail(diag,'FortFront adapter: IACHAR type/kind differs');return
                        end if
                        if(prog%expressions(child)%character_len>=0.and.prog%expressions(child)%character_len/=1) then
                            call fail(diag,'FortFront adapter: IACHAR C length differs');return
                        end if
                        if(dummy==2) then
                            if(prog%expressions(x%args(2))%typ/=ty_integer.or.expression_rank(x%args(2))/=0) then
                                call fail(diag,'FortFront adapter: IACHAR KIND must be scalar INTEGER');return
                            end if
                            call check_bound_cache(0,x%args(2),int(x%real_kind,int64))
                        else if(x%real_kind/=4) then
                            call fail(diag,'FortFront adapter: IACHAR default kind differs');return
                        end if
                    else
                        if(prog%expressions(child)%typ/=ty_real.or. &
                           (prog%expressions(child)%real_kind/=4.and.prog%expressions(child)%real_kind/=8)) then
                            call fail(diag,'FortFront adapter: model decomposition X type/kind differs');return
                        end if
                        if(x%op=='exponent') then
                            if(x%typ/=ty_integer.or.x%real_kind/=4) then
                                call fail(diag,'FortFront adapter: EXPONENT result differs');return
                            end if
                        else if(x%typ/=ty_real.or.x%real_kind/=prog%expressions(child)%real_kind) then
                            call fail(diag,'FortFront adapter: model decomposition result differs');return
                        end if
                        if(x%op=='set_exponent') then
                            child=x%args(2)
                            if(prog%expressions(child)%typ/=ty_integer.or. &
                               (prog%expressions(child)%real_kind/=4.and.prog%expressions(child)%real_kind/=8)) then
                                call fail(diag,'FortFront adapter: SET_EXPONENT I type/kind differs');return
                            end if
                        end if
                    end if
                end if
                if(x%op=='repeat') then
                    if(size(x%args)/=2.or.x%intrinsic_mask/=0.or.x%typ/=ty_character.or.x%real_kind/=4) then
                        call fail(diag,'FortFront adapter: REPEAT count/result metadata differs');return
                    end if
                    if(prog%expressions(x%args(1))%typ/=ty_character.or.expression_rank(x%args(1))/=0.or. &
                       prog%expressions(x%args(1))%real_kind/=4.or. &
                       prog%expressions(x%args(2))%typ/=ty_integer.or.expression_rank(x%args(2))/=0.or. &
                       (prog%expressions(x%args(2))%real_kind/=4.and.prog%expressions(x%args(2))%real_kind/=8)) then
                        call fail(diag,'FortFront adapter: REPEAT operand type/kind/rank differs');return
                    end if
                end if
                if(x%op=='null') then
                    if(size(x%args)/=0.or.x%typ/=0.or.x%rank/=0.or.x%real_kind/=4.or.x%parenthesized.or. &
                       count(prog%code(:prog%nc)%op==op_pointer_assign.and.prog%code(:prog%nc)%a==e)/=1) &
                        call fail(diag,'FortFront adapter: NULL requires pointer-assignment context')
                end if
                if(x%op=='associated') then
                    if((size(x%args)<1.or.size(x%args)>2).or.x%typ/=ty_logical.or.x%real_kind/=4.or.x%rank/=0.or. &
                       x%extent/=0.or.any(x%dims/=0).or.x%scope<0.or.x%scope>prog%np.or.x%symbol/=0.or.x%left/=0.or.x%right/=0.or. &
                       x%stride/=0.or.x%left2/=0.or.x%right2/=0.or.x%stride2/=0.or.x%length_expr/=0.or. &
                       x%character_len/=-1.or.x%generic_id/=0.or.x%bound_type/=0.or.x%bound_binding/=0.or. &
                       x%intrinsic_mask/=0.or.any(x%triplet.neqv.[.true.,.false.,.false.])) then
                        call fail(diag,'FortFront adapter: ASSOCIATED metadata differs');return
                    end if
                    do j=1,size(x%args)
                        child=x%args(j);dummy=prog%expressions(child)%symbol
                        if(dummy<1.or.dummy>prog%ns) then
                            call fail(diag,'FortFront adapter: ASSOCIATED argument symbol missing');return
                        end if
                        associate(a=>prog%expressions(child),s=>prog%symbols(dummy))
                        if(a%scope/=x%scope.or.a%parenthesized.or. &
                           (a%kind/=ex_variable.and.a%kind/=ex_section).or.a%rank/=1.or. &
                           a%typ/=s%typ.or.a%real_kind/=s%real_kind.or.allocated(a%args).or. &
                           any(a%dims/=0).or.a%length_expr/=0.or.a%character_len/=-1.or. &
                           a%generic_id/=0.or.a%bound_type/=0.or.a%bound_binding/=0.or.a%intrinsic_mask/=0.or.len_trim(a%op)/=0) then
                            call fail(diag,'FortFront adapter: ASSOCIATED argument metadata differs');return
                        end if
                        if(a%kind==ex_variable) then
                            if(s%rank/=1.or.a%left/=0.or.a%right/=0.or.a%stride/=0.or.a%left2/=0.or. &
                               a%right2/=0.or.a%stride2/=0.or.any(a%triplet.neqv.[.true.,.false.,.false.])) then
                                call fail(diag,'FortFront adapter: ASSOCIATED whole argument metadata differs');return
                            end if
                        else
                            if(s%rank<1.or.s%rank>2) then
                                call fail(diag,'FortFront adapter: ASSOCIATED section base rank differs');return
                            end if
                            if(a%extent/=-1.or.count(a%triplet(:s%rank))/=1.or. &
                               (s%rank==1.and.(a%triplet(2).or.a%left2/=0.or.a%right2/=0.or.a%stride2/=0))) then
                                call fail(diag,'FortFront adapter: ASSOCIATED section metadata differs');return
                            end if
                        end if
                        end associate
                    end do
                    child=x%args(1);dummy=prog%expressions(child)%symbol
                    if(prog%expressions(child)%kind/=ex_variable.or.prog%expressions(child)%parenthesized.or. &
                       dummy<1.or.dummy>prog%ns) then
                        call fail(diag,'FortFront adapter: ASSOCIATED requires whole POINTER');return
                    end if
                    if(.not.prog%symbols(dummy)%is_pointer) then
                        call fail(diag,'FortFront adapter: ASSOCIATED requires POINTER attribute');return
                    end if
                    if(size(x%args)==2) then
                        associate(target=>prog%expressions(x%args(2)))
                        j=target%symbol
                        if(target%parenthesized.or.(target%kind/=ex_variable.and.target%kind/=ex_section).or. &
                           target%rank/=1.or.j<1.or.j>prog%ns) then
                            call fail(diag,'FortFront adapter: invalid ASSOCIATED TARGET designator');return
                        end if
                        if(target%typ/=prog%symbols(dummy)%typ.or.target%real_kind/=prog%symbols(dummy)%real_kind) then
                            call fail(diag,'FortFront adapter: ASSOCIATED TARGET type/kind differs');return
                        end if
                        if(prog%symbols(j)%is_pointer) then
                            if(target%kind/=ex_variable) then
                                call fail(diag,'FortFront adapter: ASSOCIATED pointer TARGET must be whole');return
                            end if
                        else if(.not.prog%symbols(j)%is_target.or.prog%symbols(j)%is_allocatable.or. &
                                prog%symbols(j)%is_automatic.or.prog%symbols(j)%scope<0.or.prog%symbols(j)%rank>2) then
                            call fail(diag,'FortFront adapter: unsupported ASSOCIATED TARGET storage');return
                        end if
                        end associate
                    end if
                end if
                if(x%op=='allocated') then
                    if(size(x%args)/=1.or.x%typ/=ty_logical.or.x%real_kind/=4.or.x%rank/=0) then
                        call fail(diag,'FortFront adapter: ALLOCATED metadata differs');return
                    end if
                    child=x%args(1);dummy=prog%expressions(child)%symbol
                    if(prog%expressions(child)%kind/=ex_variable.or.prog%expressions(child)%parenthesized.or. &
                       dummy<1.or.dummy>prog%ns) then
                        call fail(diag,'FortFront adapter: ALLOCATED requires array name');return
                    end if
                    if(.not.prog%symbols(dummy)%is_allocatable) &
                        call fail(diag,'FortFront adapter: ALLOCATED requires allocatable array')
                end if
                if(x%op=='present') then
                    if(size(x%args)/=1.or.x%typ/=ty_logical.or.x%real_kind/=4) then
                        call fail(diag,'FortFront adapter: PRESENT argument count/type differs');return
                    end if
                    child=x%args(1);dummy=prog%expressions(child)%symbol
                    if(prog%expressions(child)%kind/=ex_variable.or.prog%expressions(child)%parenthesized.or. &
                       dummy<1.or.dummy>prog%ns) then
                        call fail(diag,'FortFront adapter: PRESENT requires an optional dummy name');return
                    end if
                    if(.not.prog%symbols(dummy)%is_optional.or..not.prog%symbols(dummy)%is_dummy.or. &
                       prog%symbols(dummy)%scope/=x%scope) &
                        call fail(diag,'FortFront adapter: PRESENT requires a local optional dummy')
                end if
                if(x%op=='merge') then
                    if(size(x%args)/=3) then
                        call fail(diag,'FortFront adapter: MERGE argument count differs');return
                    end if
                    child=x%args(1)
                    if(x%typ<ty_integer.or.x%typ>ty_character.or.x%typ/=prog%expressions(child)%typ.or. &
                       x%typ/=prog%expressions(x%args(2))%typ.or.x%real_kind/=prog%expressions(child)%real_kind.or. &
                       prog%expressions(child)%real_kind/=prog%expressions(x%args(2))%real_kind.or. &
                       prog%expressions(x%args(3))%typ/=ty_logical) then
                        call fail(diag,'FortFront adapter: MERGE source or MASK type differs');return
                    end if
                    if(x%typ==ty_character) then
                        if(prog%expressions(child)%character_len>=0.and.prog%expressions(x%args(2))%character_len>=0.and. &
                           prog%expressions(child)%character_len/=prog%expressions(x%args(2))%character_len) then
                            call fail(diag,'FortFront adapter: MERGE source lengths differ');return
                        end if
                    end if
                end if
                if(x%op=='sinh'.or.x%op=='cosh'.or.x%op=='tanh'.or. &
                    x%op=='sin'.or.x%op=='cos'.or.x%op=='tan'.or.x%op=='log10') then
                    child=x%args(1)
                    if(size(x%args)/=1.or.x%typ/=ty_real.or.prog%expressions(child)%typ/=ty_real) then
                        call fail(diag,'FortFront adapter: trigonometric/hyperbolic intrinsic needs one REAL argument');return
                    end if
                end if
                if(x%op=='nint'.or.x%op=='floor'.or.x%op=='ceiling') then
                    child=x%args(1)
                    if(size(x%args)>2.or.x%typ/=ty_integer.or.prog%expressions(child)%typ/=ty_real.or. &
                       (x%real_kind/=4.and.x%real_kind/=8)) then
                        call fail(diag,'FortFront adapter: rounding intrinsic type or argument count differs');return
                    end if
                    if(size(x%args)==2) then
                        call check_bound_cache(0,x%args(2),int(x%real_kind,int64))
                    else if(x%real_kind/=4) then
                        call fail(diag,'FortFront adapter: rounding intrinsic default kind differs');return
                    end if
                end if
                if(x%op=='dble') then
                    child=x%args(1)
                    if(size(x%args)/=1.or.x%typ/=ty_real.or. &
                       (prog%expressions(child)%typ/=ty_integer.and.prog%expressions(child)%typ/=ty_real)) then
                        call fail(diag,'FortFront adapter: DBLE argument or type differs');return
                    end if
                end if
                if(x%op=='min'.or.x%op=='max') then
                    if(size(x%args)<2.or.size(x%args)>16.or.x%intrinsic_mask/=0.or. &
                       x%symbol/=0.or.x%left/=0.or.x%right/=0.or.x%stride/=0.or. &
                       x%left2/=0.or.x%right2/=0.or.x%stride2/=0.or.x%left3/=0.or.x%right3/=0.or. &
                       x%stride3/=0.or.x%third/=0.or.x%length_expr/=0.or.x%constructor_kind_expr/=0.or. &
                       x%generic_id/=0.or.x%bound_type/=0.or.x%bound_binding/=0.or. &
                       any(x%triplet.neqv.[.true.,.false.,.false.])) then
                        call fail(diag,'FortFront adapter: MIN/MAX argument/count metadata differs');return
                    end if
                    child=x%args(1)
                    if((x%typ/=ty_character.and.x%typ/=ty_integer.and.x%typ/=ty_real).or. &
                       (x%real_kind/=4.and.x%real_kind/=8).or.(x%typ==ty_character.and.x%real_kind/=4)) then
                        call fail(diag,'FortFront adapter: MIN/MAX result type/kind differs');return
                    end if
                    do j=1,size(x%args)
                        child=x%args(j)
                        if(prog%expressions(child)%typ/=x%typ.or.prog%expressions(child)%real_kind/=x%real_kind) then
                            call fail(diag,'FortFront adapter: MIN/MAX operand type/kind differs');return
                        end if
                    end do
                    if(x%typ==ty_character)call check_minmax_character_operands(e)
                end if
                if(is_bit_intrinsic(x%op))then
                    if(.not.valid_bit_intrinsic(prog,e))then
                        call fail(diag,'FortFront adapter: invalid bit intrinsic metadata');return
                    end if
                    if(x%op=='maskl'.or.x%op=='maskr')then
                        if(size(x%args)==2)then
                            if(.not.bound_constant_expression(prog,x%args(2),0))then
                                call fail(diag,'FortFront adapter: MASKL/MASKR KIND must be constant');return
                            end if
                            call check_bound_cache(0,x%args(2),int(x%real_kind,int64))
                            if(diag%code/=0)return
                        end if
                    end if
                    do j=1,size(x%args)
                        if(model_argument_has_component(x%args(j)))then
                            call fail(diag,'FortFront adapter: bit intrinsic component operands unsupported');return
                        end if
                    end do
                end if
                if(is_lexical_intrinsic(x%op)) then
                    if(size(x%args)/=2.or.x%intrinsic_mask/=0.or.x%typ/=ty_logical.or.x%real_kind/=4.or. &
                       x%character_len/=-1) then
                        call fail(diag,'FortFront adapter: lexical result/count metadata differs');return
                    end if
                    do j=1,2
                        child=x%args(j)
                        if(prog%expressions(child)%typ/=ty_character.or.prog%expressions(child)%real_kind/=4) then
                            call fail(diag,'FortFront adapter: lexical operand type/kind differs');return
                        end if
                    end do
                end if
                if(is_lexical_intrinsic(x%op)) call check_lexical_character_operands(e)
                if(is_character_intrinsic(x%op)) call check_character_intrinsic(e)
                if(x%op=='char'.or.x%op=='achar') then
                    child=x%args(1)
                    if(size(x%args)>2.or.x%typ/=ty_character.or.x%real_kind/=4.or. &
                       prog%expressions(child)%typ/=ty_integer) then
                        call fail(diag,'FortFront adapter: CHAR/ACHAR type or argument count differs');return
                    end if
                    if(size(x%args)==2) then
                        child=x%args(2)
                        if(prog%expressions(child)%typ/=ty_integer.or.expression_rank(child)/=0) then
                            call fail(diag,'FortFront adapter: CHAR/ACHAR KIND must be scalar INTEGER');return
                        end if
                        call check_bound_cache(0,child,1_int64)
                    end if
                end if
                if(x%op=='len') then
                    if(size(x%args)/=1.or.x%typ/=ty_integer.or.x%real_kind/=4.or.x%rank/=0.or.x%extent/=0.or.any(x%dims/=0).or. &
                       x%intrinsic_mask/=0.or.x%symbol/=0.or.x%left/=0.or.x%right/=0.or.x%stride/=0.or. &
                       x%left2/=0.or.x%right2/=0.or.x%stride2/=0.or.x%left3/=0.or.x%right3/=0.or. &
                       x%stride3/=0.or.x%third/=0.or.x%length_expr/=0.or.x%generic_id/=0.or. &
                       x%bound_type/=0.or.x%bound_binding/=0.or.x%character_len/=-1.or. &
                       x%constructor_kind_expr/=0.or.any(x%triplet.neqv.[.true.,.false.,.false.])) then
                        call fail(diag,'FortFront adapter: LEN metadata differs');return
                    end if
                    child=x%args(1)
                    if(prog%expressions(child)%typ/=ty_character.or.prog%expressions(child)%real_kind/=4) &
                        call fail(diag,'FortFront adapter: LEN operand type/kind differs')
                    if(prog%expressions(child)%kind==ex_variable) then
                        if(.not.valid_character_len_variable(prog,child)) then
                            call fail(diag,'FortFront adapter: LEN variable metadata differs');return
                        end if
                    end if
                end if
                if(x%op=='trim') then
                    child=x%args(1)
                    if(size(x%args)/=1.or.x%typ/=ty_character.or. &
                       prog%expressions(child)%typ/=ty_character.or.expression_rank(child)/=0) &
                        call fail(diag,'FortFront adapter: TRIM type or argument count differs')
                end if
                if(is_numeric_model_inquiry(x%op)) then
                    if(size(x%args)/=1.or.x%intrinsic_mask/=0.or.x%rank/=0.or.x%extent/=0.or.any(x%dims/=0)) then
                        call fail(diag,'FortFront adapter: numeric model inquiry metadata differs');return
                    end if
                    child=x%args(1)
                    if(x%op=='minexponent'.or.x%op=='maxexponent') then
                        if(.not.exponent_inquiry_operand_supported(prog,child)) then
                            call fail(diag,'FortFront adapter: exponent inquiry subobject operands unsupported');return
                        end if
                    end if
                    if(model_argument_has_component(child)) then
                        call fail(diag,'FortFront adapter: numeric model inquiry component operands are unsupported');return
                    end if
                    if((prog%expressions(child)%typ/=ty_real.and.prog%expressions(child)%typ/=ty_integer).or. &
                       (prog%expressions(child)%real_kind/=4.and.prog%expressions(child)%real_kind/=8).or. &
                       ((x%op=='epsilon'.or.x%op=='tiny'.or.x%op=='minexponent'.or.x%op=='maxexponent').and.prog%expressions(child)%typ/=ty_real)) then
                        call fail(diag,'FortFront adapter: numeric model inquiry argument type/kind differs');return
                    end if
                    if(x%op=='digits'.or.x%op=='radix'.or.x%op=='minexponent'.or.x%op=='maxexponent') then
                        if(x%typ/=ty_integer.or.x%real_kind/=4) then
                            call fail(diag,'FortFront adapter: integer model inquiry result type/kind differs');return
                        end if
                    else if(x%typ/=prog%expressions(child)%typ.or.x%real_kind/=prog%expressions(child)%real_kind) then
                        call fail(diag,'FortFront adapter: numeric model inquiry result type/kind differs');return
                    end if
                end if
                if(x%op=='new_line') then
                    if(size(x%args)/=1.or.x%intrinsic_mask/=0.or.x%typ/=ty_character.or.x%real_kind/=4.or. &
                       x%rank/=0.or.x%extent/=0.or.any(x%dims/=0).or.x%character_len/=1) then
                        call fail(diag,'FortFront adapter: NEW_LINE result metadata differs');return
                    end if
                    child=x%args(1)
                    if(prog%expressions(child)%typ/=ty_character.or.prog%expressions(child)%real_kind/=4.or. &
                       .not.exponent_inquiry_operand_supported(prog,child)) then
                        call fail(diag,'FortFront adapter: NEW_LINE requires whole default CHARACTER operand');return
                    end if
                end if
                if(x%op=='kind') then
                    child=x%args(1)
                    if(size(x%args)/=1.or.x%typ/=ty_integer.or. &
                       prog%expressions(child)%typ<ty_integer.or.prog%expressions(child)%typ>ty_character) &
                        call fail(diag,'FortFront adapter: KIND type or argument count differs')
                end if
                if(x%op=='selected_real_kind') then
                    if(size(x%args)>3.or.x%typ/=ty_integer.or.x%intrinsic_mask<0.or.x%intrinsic_mask>7) then
                        call fail(diag,'FortFront adapter: SELECTED_REAL_KIND metadata differs');return
                    end if
                    if(popcnt(x%intrinsic_mask)/=size(x%args)) then
                        call fail(diag,'FortFront adapter: SELECTED_REAL_KIND slots differ');return
                    end if
                    do j=1,size(x%args)
                        child=x%args(j)
                        if(prog%expressions(child)%typ/=ty_integer.or.expression_rank(child)/=0) then
                            call fail(diag,'FortFront adapter: SELECTED_REAL_KIND needs scalar INTEGER');return
                        end if
                    end do
                end if
                wanted_kind=4
                if(size(x%args)>0) wanted_kind=prog%expressions(x%args(1))%real_kind
                if(x%op=='char'.or.x%op=='achar'.or.x%op=='present'.or.x%op=='real'.or.x%op=='kind'.or.x%op=='selected_int_kind'.or.x%op=='selected_real_kind'.or. &
                   x%op=='size'.or.x%op=='lbound'.or.x%op=='ubound'.or.x%op=='digits'.or.x%op=='radix'.or.x%op=='minexponent'.or.x%op=='maxexponent'.or.x%op=='isnan') wanted_kind=4
                if(is_character_intrinsic(x%op)) wanted_kind=x%real_kind
                if(x%op=='btest'.or.(x%op=='leadz'.or.x%op=='trailz'))wanted_kind=4
                if(x%op=='maskl'.or.x%op=='maskr')wanted_kind=x%real_kind
                if(is_lexical_intrinsic(x%op)) wanted_kind=4
                if(x%op=='bessel_jn'.or.x%op=='bessel_yn') wanted_kind=prog%expressions(x%args(2))%real_kind
                if(x%op=='dble'.or.x%op=='dprod') wanted_kind=8
                if(x%op=='exponent') wanted_kind=4
                if(x%op=='iachar') wanted_kind=x%real_kind
                if(x%op=='aint'.or.x%op=='anint') wanted_kind=x%real_kind
                if(x%op=='real'.or.x%op=='int'.or.x%op=='nint'.or.x%op=='floor'.or.x%op=='ceiling') wanted_kind=x%real_kind
                if(is_array_transform(x%op)) call derive_array_call(e,wanted_kind)
            case default
                call fail(diag,'FortFront adapter: unsupported shape expression')
            end select
            if(x%typ==ty_character) then
                wanted_length=-1
                select case(x%kind)
                case(ex_literal)
                    if(.not.allocated(x%value%s)) then
                        call fail(diag,'FortFront adapter: CHARACTER literal value missing');return
                    end if
                    wanted_length=len(x%value%s)
                case(ex_variable,ex_element,ex_section,ex_gather_rows)
                    wanted_length=prog%symbols(x%symbol)%character_len
                case(ex_component)
                    pid=prog%expressions(x%left)%typ-ty_derived_base
                    wanted_length=prog%derived_types(pid)%component_lengths(x%symbol)
                case(ex_substring)
                    wanted_length=-1
                case(ex_user_call)
                    wanted_length=prog%symbols(prog%procedures(x%symbol)%result_symbol)%character_len
                case(ex_binary)
                    if(x%op/='//'.or.prog%expressions(x%left)%typ/=ty_character.or. &
                       prog%expressions(x%right)%typ/=ty_character) then
                        call fail(diag,'FortFront adapter: CHARACTER concatenation type/operator differs');return
                    end if
                    if(prog%expressions(x%left)%character_len>=0.and.prog%expressions(x%right)%character_len>=0) &
                        wanted_length=prog%expressions(x%left)%character_len+prog%expressions(x%right)%character_len
                case(ex_constructor_do)
                    if(x%op=='character') then
                        wanted_length=x%character_len
                        if(wanted_length<0) then
                            call fail(diag,'FortFront adapter: typed constructor implied-DO length missing');return
                        end if
                    else
                        if(.not.valid_constructor_character_metadata(prog,e)) then
                            call fail(diag,'FortFront adapter: constructor implied-DO CHARACTER length metadata differs');return
                        end if
                        wanted_length=x%character_len
                    end if
                case(ex_constructor)
                    if(x%op=='character') then
                        wanted_length=1
                        if(x%length_expr/=0) then
                            wanted_length=x%character_len
                            call check_bound_cache(0,x%length_expr,int(wanted_length,int64))
                        end if
                    else
                        if(len_trim(x%op)/=0.or.x%length_expr/=0.or.size(x%args)==0) then
                            call fail(diag,'FortFront adapter: untyped CHARACTER constructor differs');return
                        end if
                        if(.not.valid_constructor_character_metadata(prog,e)) then
                            call fail(diag,'FortFront adapter: CHARACTER constructor length metadata differs');return
                        end if
                        wanted_length=x%character_len
                    end if
                case(ex_call)
                    if(x%op=='merge'.or.x%op=='pack'.or.x%op=='reshape'.or.x%op=='cshift'.or.x%op=='eoshift') then
                        wanted_length=prog%expressions(x%args(1))%character_len
                    else if(x%op=='min'.or.x%op=='max') then
                        wanted_length=0
                        do j=1,size(x%args)
                            child=x%args(j)
                            if(wanted_length<0.or.prog%expressions(child)%character_len<0) then
                                wanted_length=-1
                            else
                                wanted_length=max(wanted_length,prog%expressions(child)%character_len)
                            end if
                        end do
                    else if(x%op=='char'.or.x%op=='achar'.or.x%op=='new_line') then
                        wanted_length=1
                    else if(x%op=='adjustl'.or.x%op=='adjustr') then
                        wanted_length=prog%expressions(x%args(1))%character_len
                    else if(x%op=='repeat') then
                        if(bound_constant_expression(prog,x%args(2),0)) then
                            call evaluate_constant(prog,x%args(2),fold_value,fold_diag)
                            if(fold_diag%code==0) then
                                if(fold_value%i<0) then
                                    call fail(diag,'FortFront adapter: negative REPEAT NCOPIES');return
                                end if
                                if(fold_value%i==0) then
                                    wanted_length=0
                                else if(prog%expressions(x%args(1))%character_len>=0) then
                                    wanted_length=prog%expressions(x%args(1))%character_len
                                    if(wanted_length>0) then
                                        if(fold_value%i>65536_int64/int(wanted_length,int64)) then
                                            call fail(diag,'FortFront adapter: REPEAT length exceeds limit');return
                                        end if
                                    end if
                                    wanted_length=int(int(wanted_length,int64)*fold_value%i)
                                end if
                            end if
                        end if
                    else if(x%op=='trim') then
                        call evaluate_constant(prog,x%args(1),fold_value,fold_diag)
                        if(fold_diag%code==0.and.allocated(fold_value%s)) wanted_length=len_trim(fold_value%s)
                    else
                        call fail(diag,'FortFront adapter: unsupported CHARACTER intrinsic')
                    end if
                case default
                    call fail(diag,'FortFront adapter: unsupported CHARACTER expression')
                end select
                if(wanted_length>65536.or.x%character_len/=wanted_length) &
                    call fail(diag,'FortFront adapter: CHARACTER expression length cache differs',x%line,x%column)
            else if(x%kind==ex_binary.and.x%op=='//') then
                call fail(diag,'FortFront adapter: concatenation result type differs',x%line,x%column)
            end if
            if(x%typ==ty_real.or.x%typ==ty_integer) then
                if((wanted_kind/=4.and.wanted_kind/=8).or.x%real_kind/=wanted_kind) &
                    call fail(diag,'FortFront adapter: expression REAL kind cache differs',x%line,x%column)
            end if
            if(expression_rank(e)<0.or.expression_rank(e)>3.or. &
               x%rank/=expression_rank(e).or.x%extent/=expression_extent(e).or. &
               any(x%dims/=expression_dims(:,e))) &
                call fail(diag,'FortFront adapter: expression rank/extent cache differs',x%line,x%column)
            end associate
            shape_state(e)=2
        end subroutine
        subroutine check_eoshift_character_operands(index)
            integer,intent(in)::index
            integer,allocatable::marks(:)
            allocate(marks(prog%ne),source=0)
            call check_eoshift_character_tree(index,marks,0)
        end subroutine
        recursive subroutine check_eoshift_character_tree(index,marks,depth)
            integer,intent(in)::index,depth
            integer,intent(inout)::marks(:)
            integer::j,s,result,children(10)
            if(diag%code/=0)return
            if(index<1.or.index>prog%ne) then
                call fail(diag,'FortFront adapter: EOSHIFT operand index differs');return
            end if
            if(depth>512.or.marks(index)==1)then
                call fail(diag,'FortFront adapter: cyclic EOSHIFT operand',0,0);return
            end if
            if(marks(index)==2)return
            marks(index)=1
            associate(x=>prog%expressions(index))
            if(x%typ==ty_character)then
                if(x%real_kind/=4.or.x%character_len < -1.or.x%character_len>65536)then
                    call fail(diag,'FortFront adapter: EOSHIFT CHARACTER kind/length metadata differs',x%line,x%column);return
                end if
                if(x%kind==ex_literal)then
                    if(.not.allocated(x%value%s))then
                        call fail(diag,'FortFront adapter: missing EOSHIFT CHARACTER literal',x%line,x%column);return
                    end if
                    if(x%value%real_kind/=4.or.x%character_len/=len(x%value%s))then
                        call fail(diag,'FortFront adapter: EOSHIFT CHARACTER literal cache differs',x%line,x%column);return
                    end if
                else if(x%kind==ex_user_call)then
                    s=x%symbol
                    if(s<1.or.s>prog%np)then
                        call fail(diag,'FortFront adapter: invalid EOSHIFT function reference',x%line,x%column);return
                    end if
                    result=prog%procedures(s)%result_symbol
                    if(result<1.or.result>prog%ns)then
                        call fail(diag,'FortFront adapter: invalid EOSHIFT function result',x%line,x%column);return
                    end if
                    if(prog%symbols(result)%typ/=ty_character.or.prog%symbols(result)%real_kind/=4)then
                        call fail(diag,'FortFront adapter: EOSHIFT function result kind differs',x%line,x%column);return
                    end if
                else if(x%kind==ex_variable.or.x%kind==ex_element.or.x%kind==ex_section)then
                    s=x%symbol
                    if(s<1.or.s>prog%ns)then
                        call fail(diag,'FortFront adapter: EOSHIFT declaration missing');return
                    end if
                    if(prog%symbols(s)%real_kind/=4.or.prog%symbols(s)%character_len/=x%character_len)then
                        call fail(diag,'FortFront adapter: EOSHIFT CHARACTER declaration kind differs',x%line,x%column);return
                    end if
                end if
            end if
            children=[x%left,x%right,x%stride,x%left2,x%right2,x%stride2,x%left3,x%right3,x%stride3,x%third]
            do j=1,size(children)
                if(children(j)==0)cycle
                call check_eoshift_character_tree(children(j),marks,depth+1)
                if(diag%code/=0)return
            end do
            if(allocated(x%args))then
                do j=1,size(x%args)
                    if(x%args(j)==0.and.x%kind==ex_user_call)cycle
                    call check_eoshift_character_tree(x%args(j),marks,depth+1)
                    if(diag%code/=0)return
                end do
            end if
            end associate
            marks(index)=2
        end subroutine
        subroutine check_minmax_character_operands(index)
            integer,intent(in)::index
            integer,allocatable::marks(:)
            allocate(marks(prog%ne),source=0)
            call check_minmax_character_tree(index,marks,0)
        end subroutine
        recursive subroutine check_minmax_character_tree(index,marks,depth)
            integer,intent(in)::index,depth
            integer,intent(inout)::marks(:)
            integer::j,s,result,children(10)
            if(diag%code/=0)return
            if(index<1.or.index>prog%ne) then
                call fail(diag,'FortFront adapter: MIN/MAX operand index differs');return
            end if
            if(depth>512.or.marks(index)==1)then
                call fail(diag,'FortFront adapter: cyclic MIN/MAX operand',0,0);return
            end if
            if(marks(index)==2)return
            marks(index)=1
            associate(x=>prog%expressions(index))
            if(x%typ==ty_character)then
                if(x%real_kind/=4.or.x%character_len < -1.or.x%character_len>65536)then
                    call fail(diag,'FortFront adapter: MIN/MAX CHARACTER kind/length metadata differs',x%line,x%column);return
                end if
                if(x%kind==ex_literal)then
                    if(.not.allocated(x%value%s))then
                        call fail(diag,'FortFront adapter: missing MIN/MAX CHARACTER literal',x%line,x%column);return
                    end if
                    if(x%value%real_kind/=4.or.x%character_len/=len(x%value%s))then
                        call fail(diag,'FortFront adapter: MIN/MAX CHARACTER literal cache differs',x%line,x%column);return
                    end if
                else if(x%kind==ex_user_call)then
                    s=x%symbol
                    if(s<1.or.s>prog%np)then
                        call fail(diag,'FortFront adapter: invalid MIN/MAX function reference',x%line,x%column);return
                    end if
                    result=prog%procedures(s)%result_symbol
                    if(result<1.or.result>prog%ns)then
                        call fail(diag,'FortFront adapter: invalid MIN/MAX function result',x%line,x%column);return
                    end if
                    if(prog%symbols(result)%typ/=ty_character.or.prog%symbols(result)%real_kind/=4)then
                        call fail(diag,'FortFront adapter: MIN/MAX function result kind differs',x%line,x%column);return
                    end if
                else if(x%kind==ex_variable.or.x%kind==ex_element.or.x%kind==ex_section)then
                    s=x%symbol
                    if(s<1.or.s>prog%ns)then
                        call fail(diag,'FortFront adapter: MIN/MAX declaration missing');return
                    end if
                    if(prog%symbols(s)%real_kind/=4.or.prog%symbols(s)%character_len/=x%character_len)then
                        call fail(diag,'FortFront adapter: MIN/MAX CHARACTER declaration kind differs',x%line,x%column);return
                    end if
                end if
            end if
            children=[x%left,x%right,x%stride,x%left2,x%right2,x%stride2,x%left3,x%right3,x%stride3,x%third]
            do j=1,size(children)
                if(children(j)==0)cycle
                call check_minmax_character_tree(children(j),marks,depth+1)
                if(diag%code/=0)return
            end do
            if(allocated(x%args))then
                do j=1,size(x%args)
                    if(x%args(j)==0.and.x%kind==ex_user_call)cycle
                    call check_minmax_character_tree(x%args(j),marks,depth+1)
                    if(diag%code/=0)return
                end do
            end if
            end associate
            marks(index)=2
        end subroutine
        subroutine check_lexical_character_operands(index)
            integer,intent(in)::index
            integer,allocatable::marks(:)
            allocate(marks(prog%ne),source=0)
            call check_lexical_character_tree(index,marks,0)
        end subroutine
        recursive subroutine check_lexical_character_tree(index,marks,depth)
            integer,intent(in)::index,depth
            integer,intent(inout)::marks(:)
            integer::j,s,result,children(10)
            if(diag%code/=0)return
            if(index<1.or.index>prog%ne) then
                call fail(diag,'FortFront adapter: lexical operand index differs');return
            end if
            if(depth>512.or.marks(index)==1)then
                call fail(diag,'FortFront adapter: cyclic lexical comparison operand',0,0);return
            end if
            if(marks(index)==2)return
            marks(index)=1
            associate(x=>prog%expressions(index))
            if(x%typ==ty_character)then
                if(x%real_kind/=4.or.x%character_len < -1.or.x%character_len>65536)then
                    call fail(diag,'FortFront adapter: lexical comparison CHARACTER kind/length metadata differs',x%line,x%column);return
                end if
                if(x%kind==ex_literal)then
                    if(.not.allocated(x%value%s))then
                        call fail(diag,'FortFront adapter: missing lexical comparison CHARACTER literal',x%line,x%column);return
                    end if
                    if(x%value%real_kind/=4.or.x%character_len/=len(x%value%s))then
                        call fail(diag,'FortFront adapter: lexical comparison CHARACTER literal cache differs',x%line,x%column);return
                    end if
                else if(x%kind==ex_user_call)then
                    s=x%symbol
                    if(s<1.or.s>prog%np)then
                        call fail(diag,'FortFront adapter: invalid lexical comparison function reference',x%line,x%column);return
                    end if
                    result=prog%procedures(s)%result_symbol
                    if(result<1.or.result>prog%ns)then
                        call fail(diag,'FortFront adapter: invalid lexical comparison function result',x%line,x%column);return
                    end if
                    if(prog%symbols(result)%typ/=ty_character.or.prog%symbols(result)%real_kind/=4)then
                        call fail(diag,'FortFront adapter: lexical comparison function result kind differs',x%line,x%column);return
                    end if
                else if(x%kind==ex_variable.or.x%kind==ex_element.or.x%kind==ex_section)then
                    s=x%symbol
                    if(s<1.or.s>prog%ns)then
                        call fail(diag,'FortFront adapter: lexical declaration missing');return
                    end if
                    if(prog%symbols(s)%real_kind/=4.or.prog%symbols(s)%character_len/=x%character_len)then
                        call fail(diag,'FortFront adapter: lexical comparison CHARACTER declaration kind differs',x%line,x%column);return
                    end if
                end if
            end if
            children=[x%left,x%right,x%stride,x%left2,x%right2,x%stride2,x%left3,x%right3,x%stride3,x%third]
            do j=1,size(children)
                if(children(j)==0)cycle
                call check_lexical_character_tree(children(j),marks,depth+1)
                if(diag%code/=0)return
            end do
            if(allocated(x%args))then
                do j=1,size(x%args)
                    if(x%args(j)==0.and.x%kind==ex_user_call)cycle
                    call check_lexical_character_tree(x%args(j),marks,depth+1)
                    if(diag%code/=0)return
                end do
            end if
            end associate
            marks(index)=2
        end subroutine
        subroutine check_character_intrinsic(index)
            integer,intent(in)::index
            integer::n,j,last_data,kind_arg,wanted_type
            associate(x=>prog%expressions(index))
            n=size(x%args);kind_arg=0;last_data=n
            wanted_type=ty_integer
            if(is_character_search_intrinsic(x%op)) then
                if(n<2.or.n>4.or.x%intrinsic_mask<3.or.x%intrinsic_mask>15) then
                    call fail(diag,'FortFront adapter: invalid character search arguments');return
                end if
                if(iand(x%intrinsic_mask,3)/=3.or.popcnt(x%intrinsic_mask)/=n) then
                    call fail(diag,'FortFront adapter: invalid character search slots');return
                end if
                if(btest(x%intrinsic_mask,3)) then
                    kind_arg=x%args(n);last_data=n-1
                end if
            else if(x%op=='len_trim') then
                if(n<1.or.n>2.or.x%intrinsic_mask/=0) then
                    call fail(diag,'FortFront adapter: invalid LEN_TRIM arguments');return
                end if
                if(n==2) kind_arg=x%args(2)
                last_data=1
            else
                wanted_type=ty_character
                if(n/=1.or.x%intrinsic_mask/=0) then
                    call fail(diag,'FortFront adapter: invalid ADJUSTL/ADJUSTR arguments');return
                end if
            end if
            do j=1,last_data
                if(is_character_search_intrinsic(x%op).and.j==3) then
                    if(prog%expressions(x%args(j))%typ/=ty_logical.or. &
                       prog%expressions(x%args(j))%real_kind/=4) then
                        call fail(diag,'FortFront adapter: Character search BACK type/kind differs');return
                    end if
                else if(prog%expressions(x%args(j))%typ/=ty_character.or. &
                        prog%expressions(x%args(j))%real_kind/=4) then
                    call fail(diag,'FortFront adapter: character intrinsic operand type/kind differs');return
                end if
            end do
            if(x%typ/=wanted_type.or.(x%real_kind/=4.and.x%real_kind/=8)) then
                call fail(diag,'FortFront adapter: character intrinsic result type/kind differs');return
            end if
            if(kind_arg/=0) then
                if(prog%expressions(kind_arg)%typ/=ty_integer.or.expression_rank(kind_arg)/=0) then
                    call fail(diag,'FortFront adapter: character intrinsic KIND must be scalar INTEGER');return
                end if
                call check_bound_cache(0,kind_arg,int(x%real_kind,int64))
            else if(x%real_kind/=4) then
                call fail(diag,'FortFront adapter: character intrinsic default kind differs');return
            end if
            end associate
        end subroutine
        subroutine check_nonoptional_dim(index)
            integer,intent(in)::index
            integer::binding
            if(diag%code/=0) return
            associate(actual=>prog%expressions(index))
            if(actual%kind/=ex_variable.or.actual%parenthesized) return
            binding=actual%symbol
            if(binding<1.or.binding>prog%ns) then
                call fail(diag,'FortFront adapter: DIM binding missing');return
            end if
            if(prog%symbols(binding)%is_optional) &
                call fail(diag,'FortFront adapter: DIM must not be a direct OPTIONAL dummy')
            end associate
        end subroutine
        subroutine derive_pack_call(e,wanted_kind)
            integer,intent(in)::e
            integer,intent(out)::wanted_kind
            integer::a,m,v,j
            wanted_kind=4
            associate(x=>prog%expressions(e))
            if(size(x%args)<2.or.size(x%args)>3) then
                call fail(diag,'FortFront adapter: PACK argument count differs');return
            end if
            a=x%args(1);m=x%args(2)
            if(expression_rank(a)<1.or.expression_rank(a)>2.or. &
               prog%expressions(a)%typ<ty_integer.or.prog%expressions(a)%typ>ty_character) then
                call fail(diag,'FortFront adapter: PACK ARRAY type/rank differs');return
            end if
            if(prog%expressions(m)%typ/=ty_logical.or.prog%expressions(m)%real_kind/=4) then
                call fail(diag,'FortFront adapter: PACK MASK type/kind differs');return
            end if
            if(expression_rank(m)>0) then
                if(expression_rank(a)/=expression_rank(m)) then
                    call fail(diag,'FortFront adapter: PACK MASK rank differs');return
                end if
                if(known_extent(a)>=0.and.known_extent(m)>=0.and.known_extent(a)/=known_extent(m)) then
                    call fail(diag,'FortFront adapter: PACK MASK size differs');return
                end if
                if(expression_rank(a)==2) then
                    do j=1,2
                        if(known_dims(j,a)>=0.and.known_dims(j,m)>=0.and.known_dims(j,a)/=known_dims(j,m)) then
                            call fail(diag,'FortFront adapter: PACK MASK dimensions differ');return
                        end if
                    end do
                end if
            end if
            wanted_kind=prog%expressions(a)%real_kind
            if(size(x%args)==3) then
                v=x%args(3)
                if(expression_rank(v)/=1.or.prog%expressions(v)%typ/=prog%expressions(a)%typ.or. &
                   prog%expressions(v)%real_kind/=wanted_kind) then
                    call fail(diag,'FortFront adapter: PACK VECTOR type/kind/rank differs');return
                end if
                if(prog%expressions(a)%typ==ty_character.and. &
                   prog%expressions(v)%character_len/=prog%expressions(a)%character_len) then
                    call fail(diag,'FortFront adapter: PACK CHARACTER lengths differ');return
                end if
            end if
            if(x%typ/=prog%expressions(a)%typ.or.x%real_kind/=wanted_kind.or. &
               x%character_len/=prog%expressions(a)%character_len) then
                call fail(diag,'FortFront adapter: PACK result type/kind/length differs');return
            end if
            expression_rank(e)=1;expression_extent(e)=-1_int64
            end associate
        end subroutine
        subroutine derive_location_call(e,wanted_kind)
            integer,intent(in)::e
            integer,intent(out)::wanted_kind
            integer::a,b,j,slot,s,d,off
            wanted_kind=4
            associate(x=>prog%expressions(e))
            off=merge(1,0,x%op=='findloc')
            if(size(x%args)<1+off.or.size(x%args)>5+off.or.x%intrinsic_mask<1.or.x%intrinsic_mask>2**(5+off)-1) then
                call fail(diag,'FortFront adapter: location intrinsic count/slots differ');return
            end if
            if(iand(x%intrinsic_mask,2**(1+off)-1)/=2**(1+off)-1.or.popcnt(x%intrinsic_mask)/=size(x%args)) then
                call fail(diag,'FortFront adapter: location intrinsic slots differ');return
            end if
            a=x%args(1)
            if(expression_rank(a)<1.or.expression_rank(a)>2.or. &
               (prog%expressions(a)%typ<ty_integer.or.prog%expressions(a)%typ>merge(ty_character,ty_real,off==1)).or. &
               (prog%expressions(a)%real_kind/=4.and.prog%expressions(a)%real_kind/=8).or. &
               (prog%expressions(a)%typ>=ty_logical.and.prog%expressions(a)%real_kind/=4)) then
                call fail(diag,'FortFront adapter: location intrinsic ARRAY differs');return
            end if
            if(off==1) then
                b=x%args(2)
                if(expression_rank(b)/=0.or.prog%expressions(b)%typ/=prog%expressions(a)%typ.or. &
                   (prog%expressions(b)%real_kind/=4.and.prog%expressions(b)%real_kind/=8).or. &
                   (prog%expressions(b)%typ>=ty_logical.and.prog%expressions(b)%real_kind/=4)) then
                    call fail(diag,'FortFront adapter: FINDLOC VALUE rank/type/kind differs');return
                end if
            end if
            expression_rank(e)=1;expression_extent(e)=int(expression_rank(a),int64)
            if(btest(x%intrinsic_mask,1+off)) then
                expression_rank(e)=expression_rank(a)-1;expression_extent(e)=0_int64
                if(expression_rank(e)>0) expression_extent(e)=-1_int64
            end if
            j=1+off
            do slot=2,5
                if(.not.btest(x%intrinsic_mask,slot-1+off)) cycle
                j=j+1;b=x%args(j)
                if(prog%expressions(b)%kind==ex_variable.and..not.prog%expressions(b)%parenthesized) then
                    s=prog%expressions(b)%symbol
                    if(prog%symbols(s)%is_optional) then
                        call fail(diag,'FortFront adapter: location intrinsic direct OPTIONAL unsupported');return
                    end if
                end if
                select case(slot)
                case(2,4)
                    if(prog%expressions(b)%typ/=ty_integer.or.expression_rank(b)/=0) then
                        call fail(diag,'FortFront adapter: location intrinsic DIM/KIND differs');return
                    end if
                    if(slot==4) then
                        wanted_kind=x%real_kind
                        if(wanted_kind/=4.and.wanted_kind/=8) then
                            call fail(diag,'FortFront adapter: location intrinsic result kind unsupported');return
                        end if
                        call check_bound_cache(0,b,int(wanted_kind,int64))
                    end if
                case(3)
                    if(prog%expressions(b)%typ/=ty_logical.or.prog%expressions(b)%real_kind/=4) then
                        call fail(diag,'FortFront adapter: location intrinsic MASK differs');return
                    end if
                    if(expression_rank(b)>0) then
                        if(expression_rank(a)/=expression_rank(b)) then
                            call fail(diag,'FortFront adapter: location intrinsic MASK rank differs');return
                        end if
                        if(known_extent(a)>=0.and.known_extent(b)>=0.and.known_extent(a)/=known_extent(b)) &
                            call fail(diag,'FortFront adapter: location intrinsic MASK size differs')
                        if(expression_rank(a)==2) then
                            do d=1,2
                                if(known_dims(d,a)>=0.and.known_dims(d,b)>=0.and.known_dims(d,a)/=known_dims(d,b)) &
                                    call fail(diag,'FortFront adapter: location intrinsic MASK dimensions differ')
                            end do
                        end if
                    end if
                case(5)
                    if(prog%expressions(b)%typ/=ty_logical.or.prog%expressions(b)%real_kind/=4.or.expression_rank(b)/=0) &
                        call fail(diag,'FortFront adapter: location intrinsic BACK differs')
                end select
                if(diag%code/=0) return
            end do
            if(x%typ/=ty_integer.or.x%character_len/=-1) &
                call fail(diag,'FortFront adapter: location intrinsic result type differs')
            end associate
        end subroutine
        subroutine derive_shape_inquiry(e,wanted_kind)
            integer,intent(in)::e
            integer,intent(out)::wanted_kind
            integer::n,a,b
            associate(x=>prog%expressions(e))
            n=size(x%args);wanted_kind=4
            if(n<1.or.n>2.or.x%intrinsic_mask/=0) then
                call fail(diag,'FortFront adapter: SHAPE argument count/slots differ');return
            end if
            a=x%args(1)
            if(expression_rank(a)<0.or.expression_rank(a)>3.or.x%typ/=ty_integer.or. &
               prog%expressions(a)%typ<ty_integer.or.prog%expressions(a)%typ>ty_character) then
                call fail(diag,'FortFront adapter: SHAPE SOURCE type/rank differs');return
            end if
            expression_rank(e)=1;expression_extent(e)=int(expression_rank(a),int64)
            expression_dims(:,e)=0_int64
            if(n==2) then
                b=x%args(2)
                if(expression_rank(b)/=0.or.prog%expressions(b)%typ/=ty_integer.or. &
                   (x%real_kind/=4.and.x%real_kind/=8)) then
                    call fail(diag,'FortFront adapter: SHAPE KIND differs');return
                end if
                wanted_kind=x%real_kind
                call check_bound_cache(0,b,int(wanted_kind,int64))
            end if
            end associate
        end subroutine
        subroutine derive_eoshift(e,wanted_kind)
            integer,intent(in)::e
            integer,intent(out)::wanted_kind
            integer::a,b,n,d,j,t
            type(value_t)::v
            associate(x=>prog%expressions(e))
            n=size(x%args)
            if(n<2.or.n>4.or.x%intrinsic_mask<3.or.x%intrinsic_mask>15) then
                call fail(diag,'FortFront adapter: EOSHIFT count/slots differ');return
            end if
            if(iand(x%intrinsic_mask,3)/=3.or.popcnt(x%intrinsic_mask)/=n.or. &
               x%symbol/=0.or.x%left/=0.or.x%right/=0.or.x%stride/=0.or. &
               x%left2/=0.or.x%right2/=0.or.x%stride2/=0.or.x%left3/=0.or.x%right3/=0.or. &
               x%stride3/=0.or.x%third/=0.or.x%length_expr/=0.or.x%constructor_kind_expr/=0.or. &
               x%generic_id/=0.or.x%bound_type/=0.or.x%bound_binding/=0.or.x%constructor_owner/=0.or. &
               any(x%triplet.neqv.[.true.,.false.,.false.])) then
                call fail(diag,'FortFront adapter: EOSHIFT slots/unused metadata differs');return
            end if
            do j=1,n
                b=x%args(j)
                if(prog%expressions(b)%typ/=ty_character.and.prog%expressions(b)%character_len/=-1)then
                    call fail(diag,'FortFront adapter: EOSHIFT noncharacter operand length differs');return
                end if
            end do
            a=x%args(1);b=x%args(2);wanted_kind=prog%expressions(a)%real_kind;t=prog%expressions(a)%typ
            if(expression_rank(a)<1.or.expression_rank(a)>2.or.t<ty_integer.or.t>ty_character.or.x%typ/=t.or. &
               (wanted_kind/=4.and.wanted_kind/=8).or. &
               ((t==ty_character.or.t==ty_logical).and.wanted_kind/=4)) then
                call fail(diag,'FortFront adapter: EOSHIFT ARRAY type/kind/rank differs');return
            end if
            if(t==ty_character.and.(prog%expressions(a)%character_len<0.or.prog%expressions(a)%character_len>65536)) then
                call fail(diag,'FortFront adapter: EOSHIFT requires fixed CHARACTER length');return
            end if
            if(prog%expressions(b)%typ/=ty_integer.or. &
               (prog%expressions(b)%real_kind/=4.and.prog%expressions(b)%real_kind/=8).or. &
               expression_rank(b)<0.or.expression_rank(b)>expression_rank(a)-1) then
                call fail(diag,'FortFront adapter: EOSHIFT SHIFT type/kind/rank differs');return
            end if
            if(btest(x%intrinsic_mask,2)) then
                b=x%args(3)
                if(prog%expressions(b)%typ/=t.or.prog%expressions(b)%real_kind/=wanted_kind.or. &
                   expression_rank(b)<0.or.expression_rank(b)>expression_rank(a)-1.or. &
                   prog%expressions(b)%character_len/=prog%expressions(a)%character_len) then
                    call fail(diag,'FortFront adapter: EOSHIFT BOUNDARY type/kind/length/rank differs');return
                end if
            end if
            d=1
            if(btest(x%intrinsic_mask,3)) then
                b=x%args(n)
                if(prog%expressions(b)%typ/=ty_integer.or.expression_rank(b)/=0.or. &
                   (prog%expressions(b)%real_kind/=4.and.prog%expressions(b)%real_kind/=8)) then
                    call fail(diag,'FortFront adapter: EOSHIFT DIM type/kind/rank differs');return
                end if
                call check_nonoptional_dim(b)
                if(diag%code/=0)return
                d=0
                if(bound_constant_expression(prog,b,0)) then
                    call evaluate_constant(prog,b,v,diag)
                    if(diag%code/=0)return
                    if(v%i<1.or.v%i>expression_rank(a)) then
                        call fail(diag,'FortFront adapter: EOSHIFT DIM outside ARRAY rank');return
                    end if
                    d=int(v%i)
                end if
            end if
            if(d>0) then
                do j=2,2+merge(1,0,btest(x%intrinsic_mask,2))
                    b=x%args(j)
                    if(expression_rank(b)/=1)cycle
                    if(expression_dims(3-d,a)>=0.and.expression_extent(b)>=0.and. &
                       expression_dims(3-d,a)/=expression_extent(b)) then
                        call fail(diag,'FortFront adapter: EOSHIFT SHIFT/BOUNDARY shape differs');return
                    end if
                end do
            end if
            call check_eoshift_character_operands(e)
            if(diag%code/=0)return
            expression_rank(e)=expression_rank(a);expression_extent(e)=expression_extent(a)
            expression_dims(:,e)=expression_dims(:,a)
            end associate
        end subroutine
        subroutine derive_cshift(e,wanted_kind)
            integer,intent(in)::e
            integer,intent(out)::wanted_kind
            integer::a,b,n,d
            type(value_t)::v
            associate(x=>prog%expressions(e))
            n=size(x%args)
            if(n<2.or.n>3) then
                call fail(diag,'FortFront adapter: CSHIFT count/slots differ');return
            end if
            if(x%intrinsic_mask/=2**n-1) then
                call fail(diag,'FortFront adapter: CSHIFT count/slots differ');return
            end if
            a=x%args(1);b=x%args(2);wanted_kind=prog%expressions(a)%real_kind
            if(expression_rank(a)<1.or.expression_rank(a)>2.or. &
               prog%expressions(a)%typ<ty_integer.or.prog%expressions(a)%typ>ty_character.or. &
               x%typ/=prog%expressions(a)%typ) then
                call fail(diag,'FortFront adapter: CSHIFT ARRAY type/rank differs');return
            end if
            if(prog%expressions(a)%typ==ty_character.and.prog%expressions(a)%character_len<0) then
                call fail(diag,'FortFront adapter: CSHIFT requires fixed CHARACTER length');return
            end if
            if(prog%expressions(b)%typ/=ty_integer.or. &
               (prog%expressions(b)%real_kind/=4.and.prog%expressions(b)%real_kind/=8).or. &
               expression_rank(b)<0.or.expression_rank(b)>expression_rank(a)-1) then
                call fail(diag,'FortFront adapter: CSHIFT SHIFT type/rank differs');return
            end if
            d=1
            if(n==3) then
                b=x%args(3)
                if(prog%expressions(b)%typ/=ty_integer.or.expression_rank(b)/=0.or. &
                   (prog%expressions(b)%real_kind/=4.and.prog%expressions(b)%real_kind/=8)) then
                    call fail(diag,'FortFront adapter: CSHIFT DIM type/rank differs');return
                end if
                call check_nonoptional_dim(b)
                if(diag%code/=0) return
                d=0
                if(bound_constant_expression(prog,b,0)) then
                    call evaluate_constant(prog,b,v,diag)
                    if(diag%code/=0) return
                    if(v%i<1.or.v%i>expression_rank(a)) then
                        call fail(diag,'FortFront adapter: CSHIFT DIM outside ARRAY rank');return
                    end if
                    d=int(v%i)
                end if
            end if
            b=x%args(2)
            if(d>0.and.expression_rank(b)==1) then
                if(expression_dims(3-d,a)>=0.and.expression_extent(b)>=0.and. &
                   expression_dims(3-d,a)/=expression_extent(b)) then
                    call fail(diag,'FortFront adapter: CSHIFT SHIFT shape differs');return
                end if
            end if
            expression_rank(e)=expression_rank(a);expression_extent(e)=expression_extent(a)
            expression_dims(:,e)=expression_dims(:,a)
            end associate
        end subroutine
        subroutine derive_bounds_inquiry(e,wanted_kind)
            integer,intent(in)::e
            integer,intent(out)::wanted_kind
            integer::a,b,r
            type(value_t)::v
            type(diagnostic_t)::constant_diag
            wanted_kind=4
            if(.not.valid_bounds_inquiry(prog,e))then
                call fail(diag,'FortFront adapter: invalid LBOUND/UBOUND metadata');return
            end if
            associate(x=>prog%expressions(e))
            a=x%args(1);r=expression_rank(a)
            expression_rank(e)=1;expression_extent(e)=int(r,int64);expression_dims(:,e)=0_int64
            if(btest(x%intrinsic_mask,1))then
                b=x%args(2)
                call check_nonoptional_dim(b)
                if(diag%code/=0)return
                if(bound_constant_expression(prog,b,0))then
                    call evaluate_constant(prog,b,v,constant_diag)
                    if(constant_diag%code/=0)then
                        call fail(diag,'FortFront adapter: LBOUND/UBOUND constant DIM could not be evaluated');return
                    end if
                    if(v%i<1.or.v%i>r)then
                        call fail(diag,'FortFront adapter: LBOUND/UBOUND DIM outside rank');return
                    end if
                end if
                expression_rank(e)=0;expression_extent(e)=0_int64
            end if
            if(btest(x%intrinsic_mask,2))then
                b=x%args(size(x%args))
                if(.not.bound_constant_expression(prog,b,0))then
                    call fail(diag,'FortFront adapter: LBOUND/UBOUND KIND must be constant');return
                end if
                call evaluate_constant(prog,b,v,constant_diag)
                if(constant_diag%code/=0)then
                    call fail(diag,'FortFront adapter: LBOUND/UBOUND constant KIND could not be evaluated');return
                end if
                if(v%tag/=ty_integer.or.(v%i/=4.and.v%i/=8))then
                    call fail(diag,'FortFront adapter: LBOUND/UBOUND KIND unsupported');return
                end if
                wanted_kind=int(v%i)
            end if
            end associate
        end subroutine
        subroutine derive_matrix_call(e,wanted_kind)
            integer,intent(in)::e
            integer,intent(out)::wanted_kind
            integer::a,b,n,r
            type(value_t)::v
            wanted_kind=4
            if(.not.valid_matrix_intrinsic(prog,e))then
                call fail(diag,'FortFront adapter: invalid TRANSPOSE/NORM2 metadata');return
            end if
            associate(x=>prog%expressions(e))
            n=size(x%args);a=x%args(1);r=expression_rank(a)
            wanted_kind=prog%expressions(a)%real_kind
            expression_rank(e)=2
            if(x%op=='norm2')then
                expression_rank(e)=0
                if(n==2)then
                    b=x%args(2)
                    call check_nonoptional_dim(b)
                    if(diag%code/=0)return
                    if(bound_constant_expression(prog,b,0))then
                        call evaluate_constant(prog,b,v,diag)
                        if(diag%code/=0)return
                        if(v%i<1.or.v%i>r)then
                            call fail(diag,'FortFront adapter: NORM2 DIM outside ARRAY rank');return
                        end if
                    end if
                    expression_rank(e)=r-1
                end if
            end if
            expression_extent(e)=0_int64;expression_dims(:,e)=0_int64
            if(expression_rank(e)>0)expression_extent(e)=-1_int64
            if(expression_rank(e)>=2)expression_dims(:,e)=-1_int64
            end associate
        end subroutine
        subroutine derive_array_call(e,wanted_kind)
            integer,intent(in)::e
            integer,intent(out)::wanted_kind
            integer::a,b,n,mask,dim,result_type,j
            associate(x=>prog%expressions(e))
            if(is_bounds_inquiry(x%op))then
                call derive_bounds_inquiry(e,wanted_kind)
                return
            end if
            if(x%op=='transpose'.or.x%op=='norm2')then
                call derive_matrix_call(e,wanted_kind)
                return
            end if
            if(x%op=='eoshift') then
                call derive_eoshift(e,wanted_kind)
                return
            end if
            if(x%op=='cshift') then
                call derive_cshift(e,wanted_kind)
                return
            end if
            if(x%op=='shape') then
                call derive_shape_inquiry(e,wanted_kind)
                return
            end if
            if(is_location_reduction(x%op)) then
                call derive_location_call(e,wanted_kind)
                return
            end if
            if(x%op=='pack') then
                call derive_pack_call(e,wanted_kind)
                return
            end if
            n=size(x%args); a=x%args(1); mask=0; dim=0
            wanted_kind=prog%expressions(a)%real_kind
            result_type=prog%expressions(a)%typ
            if(expression_rank(a)<1.or.expression_rank(a)>2) then
                call fail(diag,'FortFront adapter: array intrinsic ARRAY rank differs'); return
            end if
            if(x%op=='reshape') then
                if(n<2.or.n>4.or.x%intrinsic_mask<3.or.x%intrinsic_mask>15) then
                    call fail(diag,'FortFront adapter: RESHAPE argument count/slots differ');return
                end if
                if(iand(x%intrinsic_mask,3)/=3.or.popcnt(x%intrinsic_mask)/=n.or. &
                   result_type<ty_integer.or.result_type>ty_character) then
                    call fail(diag,'FortFront adapter: RESHAPE SOURCE type/slots differ');return
                end if
                b=x%args(2)
                if(expression_rank(b)/=1.or.prog%expressions(b)%typ/=ty_integer.or. &
                   expression_extent(b)<1.or.expression_extent(b)>2) then
                    call fail(diag,'FortFront adapter: RESHAPE SHAPE must have known size 1 or 2');return
                end if
                expression_rank(e)=int(expression_extent(b))
                if(result_type==ty_character.and.prog%expressions(a)%character_len<0) then
                    call fail(diag,'FortFront adapter: RESHAPE CHARACTER requires fixed length');return
                end if
                if(btest(x%intrinsic_mask,2)) then
                    b=x%args(3)
                    if(expression_rank(b)<1.or.expression_rank(b)>2.or.prog%expressions(b)%typ/=result_type.or. &
                       prog%expressions(b)%real_kind/=wanted_kind) then
                        call fail(diag,'FortFront adapter: RESHAPE PAD type/kind/rank differs');return
                    end if
                    if(result_type==ty_character.and. &
                       prog%expressions(b)%character_len/=prog%expressions(a)%character_len) then
                        call fail(diag,'FortFront adapter: RESHAPE PAD length differs');return
                    end if
                end if
                if(btest(x%intrinsic_mask,3)) then
                    b=x%args(n)
                    if(expression_rank(b)/=1.or.prog%expressions(b)%typ/=ty_integer) then
                        call fail(diag,'FortFront adapter: RESHAPE ORDER type/rank differs');return
                    end if
                    if(expression_extent(b)>=0.and.expression_extent(b)/=expression_rank(e)) then
                        call fail(diag,'FortFront adapter: RESHAPE ORDER size differs');return
                    end if
                end if
                do j=3,n
                    b=x%args(j)
                    if(prog%expressions(b)%kind/=ex_variable.or.prog%expressions(b)%parenthesized) cycle
                    if(prog%symbols(prog%expressions(b)%symbol)%is_optional) then
                        call fail(diag,'FortFront adapter: RESHAPE direct OPTIONAL PAD/ORDER unsupported');return
                    end if
                end do
            else if(is_logical_reduction(x%op)) then
                if(result_type/=ty_logical.or.prog%expressions(a)%real_kind/=4.or.x%intrinsic_mask<1.or.x%intrinsic_mask>7.or. &
                   .not.btest(x%intrinsic_mask,0).or.popcnt(x%intrinsic_mask)/=n.or. &
                   (x%op/='count'.and.btest(x%intrinsic_mask,2))) then
                    call fail(diag,'FortFront adapter: logical reduction MASK/slots differ');return
                end if
                wanted_kind=4
                if(x%op=='count') result_type=ty_integer
                do j=2,n
                    b=x%args(j)
                    if(prog%expressions(b)%typ/=ty_integer.or.expression_rank(b)/=0) then
                        call fail(diag,'FortFront adapter: logical reduction DIM/KIND differs');return
                    end if
                end do
                if(btest(x%intrinsic_mask,1)) then
                    call check_nonoptional_dim(x%args(2))
                    if(diag%code/=0) return
                    expression_rank(e)=expression_rank(a)-1
                end if
                if(btest(x%intrinsic_mask,2)) then
                    wanted_kind=x%real_kind
                    if(wanted_kind/=4.and.wanted_kind/=8) then
                        call fail(diag,'FortFront adapter: COUNT result kind unsupported');return
                    end if
                    call check_bound_cache(0,x%args(n),int(wanted_kind,int64))
                end if
            else if(is_array_reduction(x%op)) then
                if(n>3.or.(result_type/=ty_integer.and.result_type/=ty_real)) then
                    call fail(diag,'FortFront adapter: reduction arguments/type differ'); return
                end if
                if(n>=2) then
                    b=x%args(2)
                    if(prog%expressions(b)%typ==ty_integer.and.expression_rank(b)==0) then
                        call check_nonoptional_dim(b)
                        if(diag%code/=0) return
                        dim=2
                    else if(prog%expressions(b)%typ==ty_logical.and.n==2) then
                        mask=2
                    else
                        call fail(diag,'FortFront adapter: reduction DIM/MASK differs'); return
                    end if
                end if
                if(n==3) mask=3
                if(mask/=0) then
                    b=x%args(mask)
                    if(prog%expressions(b)%typ/=ty_logical) then
                        call fail(diag,'FortFront adapter: reduction MASK type differs'); return
                    end if
                    if(expression_rank(b)>0) then
                        if(expression_rank(a)/=expression_rank(b)) then
                            call fail(diag,'FortFront adapter: reduction MASK rank differs'); return
                        end if
                        if(known_extent(a)>=0.and.known_extent(b)>=0.and.known_extent(a)/=known_extent(b)) &
                            call fail(diag,'FortFront adapter: reduction MASK size differs')
                        if(expression_rank(a)==2) then
                            do j=1,2
                                if(known_dims(j,a)>=0.and.known_dims(j,b)>=0.and. &
                                   known_dims(j,a)/=known_dims(j,b)) &
                                    call fail(diag,'FortFront adapter: reduction MASK dimensions differ')
                            end do
                        end if
                    end if
                end if
                if(dim/=0) expression_rank(e)=expression_rank(a)-1
            else
                if(n/=2) then
                    call fail(diag,'FortFront adapter: product argument count differs'); return
                end if
                b=x%args(2)
                if(expression_rank(b)<1.or.expression_rank(b)>2) then
                    call fail(diag,'FortFront adapter: product operand rank differs'); return
                end if
                if(result_type==ty_logical.and.prog%expressions(b)%typ==ty_logical) then
                    result_type=ty_logical
                else if((result_type==ty_integer.or.result_type==ty_real).and. &
                    (prog%expressions(b)%typ==ty_integer.or.prog%expressions(b)%typ==ty_real)) then
                    result_type=ty_integer; wanted_kind=4
                    if(prog%expressions(a)%typ==ty_integer.and.prog%expressions(b)%typ==ty_integer) &
                        wanted_kind=max(prog%expressions(a)%real_kind,prog%expressions(b)%real_kind)
                    if(prog%expressions(a)%typ==ty_real) then
                        result_type=ty_real; wanted_kind=prog%expressions(a)%real_kind
                    end if
                    if(prog%expressions(b)%typ==ty_real) then
                        result_type=ty_real; wanted_kind=max(wanted_kind,prog%expressions(b)%real_kind)
                    end if
                else
                    call fail(diag,'FortFront adapter: product operand type differs'); return
                end if
                if(x%op=='dot_product') then
                    if(expression_rank(a)/=1.or.expression_rank(b)/=1) &
                        call fail(diag,'FortFront adapter: DOT_PRODUCT rank differs')
                    if(known_extent(a)>=0.and.known_extent(b)>=0.and.known_extent(a)/=known_extent(b)) &
                        call fail(diag,'FortFront adapter: DOT_PRODUCT sizes differ')
                else
                    if(expression_rank(a)==1.and.expression_rank(b)==1) &
                        call fail(diag,'FortFront adapter: MATMUL requires matrix operand')
                    expression_rank(e)=expression_rank(a)+expression_rank(b)-2
                end if
            end if
            if(x%typ/=result_type) call fail(diag,'FortFront adapter: array intrinsic result type differs')
            if(is_logical_reduction(x%op).and.x%real_kind/=wanted_kind) &
                call fail(diag,'FortFront adapter: logical reduction result kind differs')
            if(expression_rank(e)>0) expression_extent(e)=-1_int64
            if(expression_rank(e)>=2) expression_dims(:,e)=-1_int64
            end associate
        end subroutine
        subroutine merge_shape(e,child)
            integer,intent(in)::e,child
            integer::d
            if(expression_rank(child)==0) return
            if(expression_rank(e)/=0.and.expression_rank(e)/=expression_rank(child)) then
                call fail(diag,'FortFront adapter: nonconformable expression ranks');return
            end if
            if(known_extent(child)>=0_int64) then
                if(known_extent(e)>=0_int64.and.known_extent(e)/=known_extent(child)) then
                    call fail(diag,'FortFront adapter: nonconformable expression shapes')
                    return
                end if
                known_extent(e)=known_extent(child)
            end if
            if(expression_rank(child)>=2) then
                do d=1,expression_rank(child)
                    if(known_dims(d,child)<0_int64) cycle
                    if(known_dims(d,e)>=0_int64.and.known_dims(d,e)/=known_dims(d,child)) then
                        call fail(diag,'FortFront adapter: nonconformable dimension extents');return
                    end if
                    known_dims(d,e)=known_dims(d,child)
                end do
            end if
            if(expression_rank(e)==0) then
                expression_extent(e)=expression_extent(child)
                expression_dims(:,e)=expression_dims(:,child)
            else if(expression_extent(e)<0_int64.or.expression_extent(child)<0_int64) then
                expression_extent(e)=-1_int64
                if(expression_rank(child)>=2) expression_dims(:,e)=-1_int64
            end if
            expression_rank(e)=expression_rank(child)
        end subroutine
        integer(int64) function symbol_dimension(symbol,dim) result(extent)
            integer,intent(in)::symbol,dim
            integer(int64)::lo,hi
            if(dim>prog%symbols(symbol)%rank) then
                extent=1_int64;return
            end if
            if(prog%symbols(symbol)%assumed_shape.or.prog%symbols(symbol)%is_automatic.or.prog%symbols(symbol)%is_allocatable.or.prog%symbols(symbol)%is_pointer) then
                extent=-1_int64
                return
            end if
            extent=0_int64
            lo=prog%symbols(symbol)%lower_bound;hi=prog%symbols(symbol)%upper_bound
            if(dim==2) then
                lo=prog%symbols(symbol)%lower_bound2;hi=prog%symbols(symbol)%upper_bound2
            end if
            if(dim==3) then
                lo=prog%symbols(symbol)%lower_bound3;hi=prog%symbols(symbol)%upper_bound3
            end if
            ! Bounds are default INTEGER constants. Check before subtraction.
            if(lo < -2147483648_int64.or.lo > 2147483647_int64.or. &
               hi < -2147483648_int64.or.hi > 2147483647_int64) then
                call fail(diag,'FortFront adapter: invalid array bound cache')
                return
            end if
            extent=max(0_int64,hi-lo+1_int64)
            if(extent>2147483647_int64) call fail(diag,'FortFront adapter: dimension extent exceeds limit')
        end function
        integer(int64) function symbol_extent(symbol) result(extent)
            integer,intent(in)::symbol
            integer(int64)::dims(3)
            integer::d
            dims=1_int64
            do d=1,prog%symbols(symbol)%rank
                dims(d)=symbol_dimension(symbol,d)
                if(diag%code/=0) then
                    extent=0_int64;return
                end if
            end do
            extent=shape_size(dims)
            if(extent>max_array_elements) call fail(diag,'FortFront adapter: array extent exceeds limit')
        end function
        subroutine require_scalar(index,e)
            integer,intent(in)::index,e
            if(diag%code/=0) return
            if(e<1.or.e>prog%ne) then
                call mismatch(index,'scalar expression missing')
                return
            end if
            if(expression_rank(e)/=0) call mismatch(index,'scalar expression required')
        end subroutine
        subroutine check_assignment(index,symbol,subscript,e,section,component)
            integer,intent(in)::index,symbol,subscript,e
            integer,intent(in),optional::section,component
            integer::target_type,t
            if(diag%code/=0) return
            if(e<1.or.e>prog%ne) then
                call mismatch(index,'assignment expression missing')
                return
            end if
            if(prog%symbols(symbol)%is_parameter.or.prog%symbols(symbol)%dummy_intent==1) &
                call mismatch(index,'assignment to PARAMETER or INTENT(IN) dummy')
            target_type=prog%symbols(symbol)%typ
            if(present(component)) then
                if(component>0) then
                    t=target_type-ty_derived_base
                    if(t<1.or.t>prog%nt) then
                        call mismatch(index,'component assignment type invalid');return
                    end if
                    if(component>prog%derived_types(t)%ncomponents) then
                        call mismatch(index,'component assignment index invalid');return
                    end if
                    target_type=prog%derived_types(t)%component_types(component)
                end if
            end if
            if(is_derived_type(target_type).or.is_derived_type(prog%expressions(e)%typ)) then
                if(target_type/=prog%expressions(e)%typ) call mismatch(index,'derived assignment type differs')
            end if
            if(present(section)) then
                if(section/=0) return ! Section conformance is evaluated at runtime.
            end if
            if(subscript/=0.or.prog%symbols(symbol)%rank==0) then
                call require_scalar(index,e)
            else if(expression_rank(e)>0) then
                if(expression_rank(e)/=prog%symbols(symbol)%rank) &
                    call mismatch(index,'assignment array ranks differ')
                if(expression_rank(e)>=2.and..not.prog%symbols(symbol)%assumed_shape.and..not.prog%symbols(symbol)%is_automatic.and..not.prog%symbols(symbol)%is_allocatable) then
                    if(any(known_dims(:,e)>=0_int64.and. &
                       known_dims(:,e)/=[symbol_dimension(symbol,1),symbol_dimension(symbol,2),symbol_dimension(symbol,3)])) &
                        call mismatch(index,'assignment dimension extents differ')
                end if
                if(known_extent(e)>=0_int64.and.symbol_extent(symbol)>=0_int64.and. &
                   known_extent(e)/=symbol_extent(symbol)) &
                    call mismatch(index,'assignment array extents differ')
            end if
        end subroutine
        subroutine mismatch(index,message)
            integer,intent(in)::index
            character(*),intent(in)::message
            integer::line,column
            line=0; column=0
            if(front%arena%has_node_at(index)) then
                line=front%arena%entries(index)%node%line
                column=front%arena%entries(index)%node%column
            end if
            call fail(diag,'FortFront adapter disagreement: '//message,line,column)
        end subroutine
        integer function symbol_index(name) result(index)
            character(*),intent(in)::name
            integer::n,host,u,m
            index=0
            do n=1,prog%ns
                if(trim(prog%symbols(n)%name)==lower(trim(name)).and.prog%symbols(n)%scope==current_scope) then
                    index=n;return
                end if
            end do
            host=current_scope
            if(current_scope>0) then
                host=prog%procedures(current_scope)%parent_procedure
                if(host>0) then
                    do n=1,prog%ns
                        if(prog%symbols(n)%scope/=host) cycle
                        if(trim(prog%symbols(n)%name)==lower(trim(name))) then
                            index=n;return
                        end if
                    end do
                end if
                host=-prog%procedures(current_scope)%module_id
            end if
            if(current_scope>0) then
                do n=1,prog%ns
                    if(prog%symbols(n)%scope/=host) cycle
                    if(host==0.and..not.prog%symbols(n)%is_parameter) cycle
                    if(trim(prog%symbols(n)%name)==lower(trim(name))) then
                        index=n;return
                    end if
                end do
            end if
            do u=1,prog%nu
                if(prog%use_scopes(u)/=host) cycle
                m=prog%uses(u)
                if(prog%use_only(u)) then
                    if(.not.any(prog%only_names(1:prog%n_only(u),u)==lower(trim(name)))) cycle
                end if
                do n=1,prog%ns
                    if(prog%symbols(n)%scope/=-m.or..not.prog%symbols(n)%is_public) cycle
                    if(trim(prog%symbols(n)%name)/=lower(trim(name))) cycle
                    if(index/=0) then
                        index=0;return
                    end if
                    index=n
                end do
            end do
        end function
        integer function find_instruction(op,line,symbol) result(index)
            integer,intent(in)::op,line,symbol
            integer::n
            index=0
            do n=1,prog%nc
                if(seen_code(n)) cycle
                if(current_scope>0) then
                    if(n<prog%procedures(current_scope)%first.or.n>prog%procedures(current_scope)%last) cycle
                else if(current_scope==0) then
                    if(n<prog%entry_pc) cycle
                else
                    cycle
                end if
                if(prog%code(n)%scope/=current_scope) cycle
                if(prog%code(n)%op/=op .or. prog%code(n)%line/=line) cycle
                if(symbol/=0) then
                    if(prog%code(n)%symbol/=symbol) cycle
                end if
                seen_code(n)=.true.
                index=n
                return
            end do
        end function
        subroutine check_type(index,expected,rank,real_kind)
            integer,intent(in)::index,expected
            integer,intent(in),optional::rank,real_kind
            type(resolved_type_query_t)::q
            integer::tag,kind,wanted_rank
            q=query_resolved_type(front%arena,index)
            wanted_rank=0
            if(present(rank)) wanted_rank=rank
            if(is_derived_type(expected)) then
                tag=expected-ty_derived_base
                if(tag<1.or.tag>prog%nt) then
                    call mismatch(index,'derived type ID invalid');return
                end if
                if(.not.q%found.or.q%type_kind/=TDERIVED.or.q%rank/=wanted_rank) then
                    call mismatch(index,'derived type/rank unresolved');return
                end if
                if(q%derived_type_name/=trim(prog%derived_types(tag)%name)) &
                    call mismatch(index,'derived type name differs')
                if(.not.q%derived_type_binding%found.or. &
                   q%derived_type_binding%declaration_node_index/=type_nodes(tag)) &
                    call mismatch(index,'derived type binding differs')
                return
            end if
            tag=0; kind=4
            select case(expected)
            case(ty_integer)
                tag=TINT
                if(present(real_kind)) kind=real_kind
            case(ty_real)
                tag=TREAL
                if(present(real_kind)) kind=real_kind
            case(ty_logical);tag=TLOGICAL
            case(ty_character);tag=TCHAR;kind=1
            end select
            if(.not.q%found .or. q%type_kind/=tag .or. q%rank/=wanted_rank .or. q%kind_value/=kind) &
                call mismatch(index,'resolved type/rank/kind differs or is unavailable')
        end subroutine
        subroutine check_initializer_shape(index,symbol,e)
            integer,intent(in)::index,symbol,e
            integer(int64)::dims(3)
            type(diagnostic_t)::evaluation_diag
            if(diag%code/=0) return
            if(expression_rank(e)<2) return
            dims=expression_dims(:,e)
            if(any(dims<0)) then
                call evaluate_constant_shape(prog,e,dims,evaluation_diag)
                if(evaluation_diag%code/=0) then
                    call mismatch(index,'invalid declaration initializer shape');return
                end if
            end if
            if(any(dims/=[symbol_dimension(symbol,1),symbol_dimension(symbol,2),symbol_dimension(symbol,3)])) &
                call mismatch(index,'array initializer dimensions differ')
        end subroutine
        subroutine check_parameter(index,symbol)
            integer,intent(in)::index,symbol
            type(value_t)::value
            type(value_t),allocatable::values(:)
            type(diagnostic_t)::evaluation_diag
            integer::j,n,e,k
            if(diag%code/=0) return
            if(.not.prog%symbols(symbol)%parameter_ready) then
                call mismatch(index,'PARAMETER must be defined');return
            end if
            e=prog%symbols(symbol)%initializer_expr
            call check_initializer(index,e,0)
            if(diag%code/=0) return
            if(prog%symbols(symbol)%rank>0) then
                n=int(symbol_extent(symbol))
                if(expression_rank(e)>0) then
                    if(expression_rank(e)/=prog%symbols(symbol)%rank.or. &
                       (expression_extent(e)>=0.and.expression_extent(e)/=n)) &
                        call mismatch(index,'array PARAMETER initializer rank/extent differs')
                    call check_initializer_shape(index,symbol,e)
                    if(diag%code/=0) return
                end if
                if(.not.allocated(prog%symbols(symbol)%constant_values)) then
                    call mismatch(index,'array PARAMETER cache missing');return
                end if
                if(size(prog%symbols(symbol)%constant_values)/=n) then
                    call mismatch(index,'array PARAMETER cache size differs');return
                end if
                if(expression_rank(e)==0) then
                    call evaluate_constant(prog,e,value,evaluation_diag, &
                        prog%symbols(symbol)%typ,prog%symbols(symbol)%real_kind)
                    allocate(values(n),source=value)
                else
                    call evaluate_constant_array(prog,e,values,evaluation_diag, &
                        prog%symbols(symbol)%typ,prog%symbols(symbol)%real_kind)
                end if
                if(evaluation_diag%code/=0) then
                    call mismatch(index,'invalid array PARAMETER initializer');return
                end if
                if(size(values)/=n) then
                    call mismatch(index,'array PARAMETER initializer shape differs');return
                end if
                do j=1,n
                    if(values(j)%tag==ty_character.and.allocated(values(j)%s)) then
                        k=prog%symbols(symbol)%character_len
                        values(j)%s=values(j)%s(:min(k,len(values(j)%s)))//repeat(' ',max(0,k-len(values(j)%s)))
                    end if
                    if(.not.same_value(values(j),prog%symbols(symbol)%constant_values(j))) &
                        call mismatch(index,'array PARAMETER cache differs')
                end do
            else
                call evaluate_constant(prog,e,value,evaluation_diag, &
                    prog%symbols(symbol)%typ,prog%symbols(symbol)%real_kind)
                if(evaluation_diag%code/=0) then
                    call mismatch(index,'PARAMETER initializer is not a valid constant');return
                end if
                if(value%tag==ty_character.and.allocated(value%s)) then
                    if(prog%symbols(symbol)%character_len>=0) &
                        value%s=value%s(:min(len(value%s),prog%symbols(symbol)%character_len))// &
                        repeat(' ',max(0,prog%symbols(symbol)%character_len-len(value%s)))
                end if
                if(.not.same_value(value,prog%symbols(symbol)%constant_value)) &
                    call mismatch(index,'PARAMETER cache differs from initializer')
            end if
        end subroutine
        logical function same_value(value,cached) result(same)
            type(value_t),intent(in)::value,cached
            same=value%tag==cached%tag
            select case(value%tag)
            case(ty_integer);same=same.and.value%i==cached%i.and.value%real_kind==cached%real_kind
            case(ty_real);same=same.and.value%r==cached%r.and.value%real_kind==cached%real_kind
            case(ty_logical);same=same.and.(value%l.eqv.cached%l)
            case(ty_character)
                same=same.and.allocated(value%s).and.allocated(cached%s)
                if(same) same=len(value%s)==len(cached%s).and.value%s==cached%s
            case default; same=.false.
            end select
        end function
        subroutine check_character_header(index,symbol,node)
            integer,intent(in)::index,symbol
            type(function_def_node),intent(in)::node
            type(declaration_query_t)::d
            character(:),allocatable::text,compact
            integer::j,k
            if(.not.allocated(node%return_type)) then
                call mismatch(index,'CHARACTER function header missing');return
            end if
            text=lower(trim(node%return_type));compact=''
            do j=1,len(text)
                if(text(j:j)/=' '.and.text(j:j)/=achar(9)) compact=compact//text(j:j)
            end do
            if(len(compact)==0) then
                call mismatch(index,'CHARACTER function header empty');return
            end if
            if(compact=='character') then
                d%has_character_length=.false.
            else if(index_char(compact,'character(')==1.and.compact(len(compact):)==')') then
                d%has_character_length=.true.
                text=compact(11:len(compact)-1)
                if(index_char(text,'len=')==1) text=text(5:)
                d%character_length_expr=text
            else
                call mismatch(index,'CHARACTER function header differs');return
            end if
            call check_character_length(index,symbol,d)
        end subroutine
        subroutine check_character_length(index,symbol,d)
            integer,intent(in)::index,symbol
            type(declaration_query_t),intent(in)::d
            integer::n,ios,e,j,initializer
            character(:),allocatable::text
            type(value_t)::value
            type(diagnostic_t)::evaluation_diag
            if(prog%symbols(symbol)%rank<0.or.prog%symbols(symbol)%rank>3.or.prog%symbols(symbol)%character_len < -1.or. &
               prog%symbols(symbol)%character_len>65536) then
                call mismatch(index,'CHARACTER length/rank outside supported bounds');return
            end if
            n=1;e=prog%symbols(symbol)%length_expr
            if(prog%symbols(symbol)%is_dummy.and.prog%symbols(symbol)%character_len<0.and.e/=0) then
                if(.not.valid_character_length_dummy(prog,symbol)) then
                    call mismatch(index,'invalid specification-length ALLOCATABLE CHARACTER dummy');return
                end if
            end if
            if(d%has_character_length) then
                if(.not.allocated(d%character_length_expr)) then
                    call mismatch(index,'CHARACTER length missing');return
                end if
                text=trim(adjustl(d%character_length_expr))
                if(text==':') then
                    n=-1
                    if(.not.prog%symbols(symbol)%is_allocatable.or..not.prog%symbols(symbol)%deferred_character.or.e/=0) &
                        call mismatch(index,'deferred CHARACTER declaration differs')
                else if(text=='*') then
                    n=-1
                    if(d%is_parameter.and.prog%symbols(symbol)%is_parameter.and. &
                       .not.prog%symbols(symbol)%is_dummy.and.e==0) then
                        initializer=prog%symbols(symbol)%initializer_expr
                        call check_initializer(index,initializer,0)
                        if(diag%code/=0) return
                        if(prog%expressions(initializer)%typ/=ty_character) then
                            call mismatch(index,'inferred CHARACTER initializer type differs');return
                        end if
                        if(prog%expressions(initializer)%rank==0) then
                            call evaluate_constant(prog,initializer,value,evaluation_diag)
                            if(evaluation_diag%code/=0) then
                                call mismatch(index,'invalid inferred CHARACTER initializer');return
                            end if
                            n=len(value%s)
                        else
                            n=prog%expressions(initializer)%character_len
                        end if
                        if(n<0.or.n>65536) then
                            call mismatch(index,'invalid inferred CHARACTER length');return
                        end if
                    else if(.not.prog%symbols(symbol)%is_dummy.or.e/=0) then
                        call mismatch(index,'assumed CHARACTER length differs')
                    end if
                else
                    if(len(text)==0) then
                        call mismatch(index,'CHARACTER length missing');return
                    end if
                    call check_length_text(index,text,e,n)
                end if
            else if(e/=0) then
                call mismatch(index,'unexpected CHARACTER length expression')
            end if
            if(prog%symbols(symbol)%deferred_character) then
                if(.not.d%has_character_length) then
                    call mismatch(index,'deferred CHARACTER length syntax absent');return
                end if
                if(text/=':') call mismatch(index,'deferred CHARACTER length syntax differs')
            end if
            if(prog%symbols(symbol)%character_len/=n) call mismatch(index,'CHARACTER length cache differs')
        end subroutine
        subroutine check_constructor_type(index,spec,e)
            integer,intent(in)::index
            character(*),intent(in)::spec
            type(expr_t),intent(in)::e
            character(:),allocatable::text,compact
            integer::j,n
            compact=''
            do j=1,len_trim(spec)
                if(spec(j:j)/=' '.and.spec(j:j)/=achar(9)) compact=compact//lower(spec(j:j))
            end do
            if(e%op=='integer'.or.e%op=='real'.or.e%op=='logical') then
                n=len_trim(e%op)
                if(compact==trim(e%op)) then
                    if(e%constructor_kind_expr/=0.or.e%real_kind/=4) &
                        call mismatch(index,'default empty constructor KIND differs')
                else if(len(compact)>n+2) then
                    if(compact(:n+1)/=trim(e%op)//'('.or.compact(len(compact):)/=')') then
                        call mismatch(index,'empty constructor type specification differs');return
                    end if
                    text=compact(n+2:len(compact)-1)
                    if(index_char(text,'kind=')==1) text=text(6:)
                    if(.not.length_text_matches(text,e%constructor_kind_expr,0)) then
                        call mismatch(index,'empty constructor KIND source binding differs');return
                    end if
                    if(prog%expressions(e%constructor_kind_expr)%scope/=current_scope) &
                        call mismatch(index,'empty constructor KIND scope differs')
                else
                    call mismatch(index,'empty constructor type specification differs')
                end if
                return
            end if
            n=1
            if(compact=='character') then
                if(e%length_expr/=0) call mismatch(index,'constructor length expression differs')
            else if(index_char(compact,'character(')==1.and.compact(len(compact):)==')') then
                text=compact(11:len(compact)-1)
                if(index_char(text,'len=')==1) text=text(5:)
                call check_length_text(index,text,e%length_expr,n)
            else
                call mismatch(index,'constructor type specification differs');return
            end if
            if(e%typ/=ty_character.or.e%character_len/=n) call mismatch(index,'constructor CHARACTER length differs')
        end subroutine
        subroutine check_length_text(index,text,e,n)
            integer,intent(in)::index,e
            character(*),intent(in)::text
            integer,intent(out)::n
            type(value_t)::v
            type(diagnostic_t)::d
            character(:),allocatable::compact
            integer::j
            character::quote
            n=-2;compact='';quote=achar(0)
            if(e<1.or.e>prog%ne) then
                call mismatch(index,'CHARACTER length expression missing');return
            end if
            do j=1,len_trim(text)
                if(quote/=achar(0)) then
                    compact=compact//text(j:j)
                    if(text(j:j)==quote) quote=achar(0)
                else if(text(j:j)==achar(39).or.text(j:j)=='"') then
                    quote=text(j:j);compact=compact//quote
                else if(text(j:j)/=' '.and.text(j:j)/=achar(9)) then
                    compact=compact//lower(text(j:j))
                end if
            end do
            if(.not.length_text_matches(compact,e,0)) then
                call mismatch(index,'CHARACTER length expression differs: '//compact);return
            end if
            if(prog%expressions(e)%typ/=ty_integer.or.prog%expressions(e)%rank/=0) then
                call mismatch(index,'CHARACTER length must be scalar INTEGER');return
            end if
            call evaluate_constant(prog,e,v,d)
            if(d%code/=0) then
                if(.not.valid_automatic_bound(prog,e,current_scope)) then
                    call mismatch(index,'unsupported CHARACTER specification expression');return
                end if
                n=-1
            else
                if(v%tag/=ty_integer.or.v%i>65536) then
                    call mismatch(index,'CHARACTER length outside bounds');return
                end if
                n=int(max(0_int64,v%i))
            end if
        end subroutine
        ! FortFront retains CHARACTER lengths as text, rather than an AST child.
        ! Match that independent text to the guarded expression tree, including
        ! precedence and scoped symbol identity. Never merely trust its cache.
        recursive logical function length_text_matches(text,root,depth) result(ok)
            character(*),intent(in)::text
            integer,intent(in)::root,depth
            integer::j,k,level,split,priority,best,width,start,arg,ios,n,sym,subscripts(3),slot,equal,formal
            integer(int64)::ival
            character(:),allocatable::t,op,part,literal,err
            type(declaration_binding_t)::binding
            logical::saw_keyword
            logical,allocatable::seen(:)
            character::quote
            logical,allocatable::quoted(:)
            ok=.false.
            if(depth>128.or.root<1.or.root>prog%ne) return
            t=text;n=len(t)
            if(n==0) return
            allocate(quoted(n),source=.false.);quote=achar(0)
            do j=1,n
                if(quote/=achar(0)) then
                    quoted(j)=.true.
                    if(t(j:j)==quote) quote=achar(0)
                else if(t(j:j)==achar(39).or.t(j:j)=='"') then
                    quote=t(j:j);quoted(j)=.true.
                end if
            end do
            ! Strip only parentheses that enclose this entire expression.
            do while(n>=2)
                if(t(1:1)/='('.or.t(n:n)/=')') exit
                level=0
                do j=1,n
                    if(quoted(j)) cycle
                    if(t(j:j)=='(') level=level+1
                    if(t(j:j)==')') level=level-1
                    if(level==0) exit
                end do
                if(j/=n) exit
                t=t(2:n-1);quoted=quoted(2:n-1);n=len(t)
            end do
            if(n==0) return
            ! Choose the outermost binary operator. Last at equal precedence
            ! for left associativity; first for exponentiation.
            level=0;split=0;best=99;width=0;j=1
            do while(j<=n)
                if(quoted(j)) then
                    j=j+1;cycle
                end if
                if(t(j:j)=='(') level=level+1
                if(t(j:j)==')') level=level-1
                priority=99;k=1
                if(level==0.and.j>1) then
                    select case(t(j:j))
                    case('+','-')
                        if(index('+-*/(,',t(j-1:j-1))==0) priority=1
                    case('*','/')
                        priority=2
                        if(j<n) then
                            if(t(j:j+1)=='**') then
                                priority=3;k=2
                            end if
                        end if
                    end select
                end if
                if(priority<best.or.(priority==best.and.priority<3)) then
                    best=priority;split=j;width=k
                end if
                j=j+k
            end do
            associate(e=>prog%expressions(root))
            if(best==3.and.(t(1:1)=='+'.or.t(1:1)=='-')) split=0
            if(split>0) then
                if(e%kind/=ex_binary.or.trim(e%op)/=t(split:split+width-1)) return
                ok=length_text_matches(t(:split-1),e%left,depth+1)
                if(ok) ok=length_text_matches(t(split+width:),e%right,depth+1)
                return
            end if
            if(t(1:1)=='+'.or.t(1:1)=='-') then
                if(e%kind/=ex_unary.or.trim(e%op)/=t(1:1)) return
                ok=length_text_matches(t(2:),e%left,depth+1);return
            end if
            select case(e%kind)
            case(ex_literal)
                if(e%typ==ty_character) then
                    if(.not.allocated(e%value%s).or.n<2) return
                    quote=t(1:1)
                    if((quote/=achar(39).and.quote/='"').or.t(n:n)/=quote) return
                    literal='';j=2
                    do while(j<n)
                        literal=literal//t(j:j)
                        if(t(j:j)==quote) then
                            if(j+1>=n) return
                            if(t(j+1:j+1)/=quote) return
                            j=j+1
                        end if
                        j=j+1
                    end do
                    ok=e%value%tag==ty_character.and.literal==e%value%s
                    return
                end if
                if(e%typ/=ty_integer.or.e%value%tag/=ty_integer) return
                part=t;k=index(part,'_')
                if(k>0) then
                    read(part(k+1:),*,iostat=ios)j
                    if(ios/=0) then
                        sym=symbol_index(part(k+1:))
                        if(sym<1.or.sym>prog%ns) return
                        if(.not.prog%symbols(sym)%is_parameter.or..not.prog%symbols(sym)%parameter_ready.or. &
                           prog%symbols(sym)%typ/=ty_integer.or.prog%symbols(sym)%rank/=0) return
                        if(prog%symbols(sym)%constant_value%i/=e%real_kind) return
                    else if(j/=e%real_kind) then
                        return
                    end if
                    part=part(:k-1)
                else if(e%real_kind/=4) then
                    return
                end if
                read(part,*,iostat=ios)ival
                ok=ios==0
                if(ok) ok=ival==e%value%i
            case(ex_variable)
                ok=symbol_index(t)==e%symbol
            case(ex_element)
                k=index(t,'(')
                if(k<2.or.t(n:n)/=')') return
                sym=symbol_index(t(:k-1))
                if(sym<1.or.sym>prog%ns.or.sym/=e%symbol) return
                if(prog%symbols(sym)%rank<1.or.prog%symbols(sym)%rank>3.or.e%rank/=0) return
                subscripts=[e%left,e%right,e%third]
                start=k+1;level=0;arg=0
                do j=k+1,n
                    if(quoted(j)) cycle
                    if(t(j:j)=='(') level=level+1
                    if(t(j:j)==')') level=level-1
                    if((t(j:j)/=','.or.level/=0).and.j/=n) cycle
                    arg=arg+1
                    if(arg>prog%symbols(sym)%rank) return
                    if(.not.length_text_matches(t(start:j-1),subscripts(arg),depth+1)) return
                    start=j+1
                end do
                ok=arg==prog%symbols(sym)%rank
            case(ex_call,ex_user_call)
                if(.not.allocated(e%args)) return
                if(e%kind==ex_call.and.e%op=='len'.and.n>4) then
                    if(t(n-3:n)=='%len') then
                        if(size(e%args)/=1.or.e%typ/=ty_integer.or.e%real_kind/=4.or.e%rank/=0) return
                        sym=e%args(1)
                        if(sym<1.or.sym>prog%ne) return
                        if(prog%expressions(sym)%kind/=ex_variable.or.prog%expressions(sym)%typ/=ty_character.or. &
                           prog%expressions(sym)%parenthesized) return
                        ok=length_text_matches(t(:n-4),sym,depth+1)
                        return
                    end if
                end if
                k=index(t,'(')
                if(k<2.or.t(n:n)/=')') return
                if(e%kind==ex_user_call) then
                    if(.not.valid_automatic_bound(prog,root,current_scope)) return
                    if(t(:k-1)/=trim(prog%procedures(e%symbol)%name)) return
                    call resolve_name_in_scope(front%arena,scope_node(),t(:k-1),binding,err)
                    if(.not.binding%found.or.binding%binding_kind/=BINDING_FUNCTION.or. &
                       binding%declaration_node_index/=procedure_node(e%symbol)) return
                else if(t(:k-1)/=trim(e%op)) then
                    return
                end if
                if(size(e%args)==0) then
                    ok=k==n-1;return
                end if
                allocate(seen(size(e%args)),source=.false.);saw_keyword=.false.
                start=k+1;level=0;arg=0
                do j=k+1,n
                    if(quoted(j)) cycle
                    if(t(j:j)=='(') level=level+1
                    if(t(j:j)==')') level=level-1
                    if((t(j:j)/=','.or.level/=0).and.j/=n) cycle
                    arg=arg+1
                    if(arg>size(e%args)) return
                    part=t(start:j-1);slot=arg
                    if(e%kind==ex_user_call) then
                        equal=0;priority=0
                        do formal=1,len(part)
                            if(quoted(start+formal-1)) cycle
                            if(part(formal:formal)=='(') priority=priority+1
                            if(part(formal:formal)==')') priority=priority-1
                            if(part(formal:formal)=='='.and.priority==0) equal=formal
                        end do
                        if(equal>0) then
                            saw_keyword=.true.;slot=0
                            do formal=1,size(e%args)
                                sym=prog%procedures(e%symbol)%args(formal)
                                if(part(:equal-1)==trim(prog%symbols(sym)%name)) slot=formal
                            end do
                            if(slot==0) return
                            part=part(equal+1:)
                        else if(saw_keyword) then
                            return
                        end if
                    else if(e%op=='len'.and.index(part,'string=')==1) then
                        part=part(8:)
                    end if
                    if(seen(slot)) return
                    seen(slot)=.true.
                    if(.not.length_text_matches(part,e%args(slot),depth+1)) return
                    start=j+1
                end do
                ok=arg==size(e%args).and.all(seen)
            end select
            end associate
        end function
        subroutine check_allocation_group(index,pc,vars,stat_index,errmsg_index,spec)
            integer,intent(in)::index,pc,stat_index,errmsg_index
            integer,allocatable,intent(in)::vars(:)
            character(:),allocatable,optional,intent(in)::spec
            integer::j,n,q
            if(.not.allocated(vars)) then
                call mismatch(index,'allocation object list missing');return
            end if
            n=size(vars)
            if(n<1.or.n>max_allocation_objects.or.n>prog%nc-pc+1) then
                call mismatch(index,'allocation object count differs');return
            end if
            if(n==1) then
                if(prog%code(pc)%c/=0.or.prog%code(pc)%d/=0.or.prog%code(pc)%target/=0) then
                    call mismatch(index,'single-object allocation group metadata differs');return
                end if
            else
                if(.not.valid_allocation_group(prog,pc).or.prog%code(pc)%c/=n) then
                    call mismatch(index,'invalid multi-object allocation group or bound dependencies');return
                end if
            end if
            do j=1,n
                q=pc+j-1
                if(j>1) then
                    if(seen_code(q)) then
                        call mismatch(index,'allocation object already matched');return
                    end if
                    seen_code(q)=.true.
                end if
                if(present(spec)) call check_allocation_type(index,q,spec)
                call check_allocation(index,q,vars(j:j),stat_index,errmsg_index)
                if(diag%code/=0) return
            end do
            if(n>1.and.stat_index/=0) then
                q=prog%code(pc)%a
                if(q>=1.and.q<=prog%ne) call check_module_write_ir(prog%expressions(q)%symbol,current_scope)
            end if
        end subroutine
        subroutine check_allocation_type(index,pc,spec)
            integer,intent(in)::index,pc
            character(:),allocatable,intent(in)::spec
            character(:),allocatable::compact,text
            integer::j,e,s
            character::quote
            e=prog%code(pc)%b;s=prog%code(pc)%symbol
            if(s<1.or.s>prog%ns) then
                call mismatch(index,'invalid allocation symbol');return
            end if
            if(e==0) then
                if(allocated(spec).or.prog%symbols(s)%deferred_character) &
                    call mismatch(index,'allocation type specification differs')
                return
            end if
            if(.not.allocated(spec).or..not.prog%symbols(s)%deferred_character) then
                call mismatch(index,'typed allocation requires deferred CHARACTER');return
            end if
            compact='';quote=achar(0)
            do j=1,len_trim(spec)
                if(quote/=achar(0)) then
                    compact=compact//spec(j:j)
                    if(spec(j:j)==quote) quote=achar(0)
                else if(spec(j:j)==achar(39).or.spec(j:j)=='"') then
                    quote=spec(j:j);compact=compact//quote
                else if(spec(j:j)/=' '.and.spec(j:j)/=achar(9)) then
                    compact=compact//lower(spec(j:j))
                end if
            end do
            if(index_char(compact,'character(')/=1.or.compact(len(compact):)/=')') then
                call mismatch(index,'allocation CHARACTER type differs');return
            end if
            text=compact(11:len(compact)-1)
            if(index_char(text,'len=')==1) text=text(5:)
            if(.not.length_text_matches(text,e,0)) then
                call mismatch(index,'allocation CHARACTER length expression differs');return
            end if
            call require_scalar(index,e)
            if(diag%code/=0) return
            if(prog%expressions(e)%typ/=ty_integer) call mismatch(index,'allocation length is not INTEGER')
        end subroutine
        subroutine check_allocation(index,pc,vars,stat_index,errmsg_index)
            integer,intent(in)::index,pc,stat_index,errmsg_index
            integer,intent(in)::vars(:)
            integer::s,d,a,lo,hi,t,bounds(3)
            character(63)::array_name
            type(declaration_binding_t)::binding
            character(:),allocatable::err
            associate(ins=>prog%code(pc))
            s=ins%symbol
            if(s<1.or.s>prog%ns) then
                call mismatch(index,'invalid allocation target');return
            end if
            if(.not.prog%symbols(s)%is_allocatable.or.prog%symbols(s)%dummy_intent==1) then
                call mismatch(index,'allocation target must be writable ALLOCATABLE');return
            end if
            if(.not.allocated(ins%items)) then
                call mismatch(index,'allocation target or shape missing');return
            end if
            if(size(vars)/=1) then
                call mismatch(index,'allocation supports one target');return
            end if
            a=vars(1)
            if(.not.front%arena%has_node_at(a)) then
                call mismatch(index,'allocation target node missing');return
            end if
            if(ins%op==op_deallocate) then
                if(size(ins%items)/=0) call mismatch(index,'unexpected DEALLOCATE bounds')
                select type(v=>front%arena%entries(a)%node)
                type is(identifier_node)
                    if(symbol_index(v%name)/=s) call mismatch(index,'DEALLOCATE binding differs')
                    ! DO/IF bodies are not independent Fortran scoping units.
                    ! Use the same verified lexical scope as ALLOCATE below.
                    call resolve_name_in_scope(front%arena,scope_node(),v%name,binding,err)
                    if(.not.binding%found.or.binding%declaration_node_index/=symbol_declaration(s)) &
                        call mismatch(index,'DEALLOCATE declaration identity differs')
                class default
                    call mismatch(index,'DEALLOCATE requires array name')
                end select
            else
                if(size(ins%items)/=2*prog%symbols(s)%rank) then
                    call mismatch(index,'allocation bounds differ from rank');return
                end if
                bounds=0;array_name=''
                select type(v=>front%arena%entries(a)%node)
                type is(identifier_node)
                    if(prog%symbols(s)%rank/=0) then
                        call mismatch(index,'ALLOCATE array requires bounds');return
                    end if
                    array_name=v%name
                type is(call_or_subscript_node)
                    if(.not.allocated(v%name).or..not.allocated(v%arg_indices)) then
                        call mismatch(index,'ALLOCATE designator missing');return
                    end if
                    if(size(v%arg_indices)/=prog%symbols(s)%rank) then
                        call mismatch(index,'ALLOCATE rank differs');return
                    end if
                    array_name=v%name;bounds(:prog%symbols(s)%rank)=v%arg_indices
                type is(array_slice_node)
                    if(v%num_dimensions/=prog%symbols(s)%rank.or..not.front%arena%has_node_at(v%array_index)) then
                        call mismatch(index,'ALLOCATE rank/base differs');return
                    end if
                    select type(base=>front%arena%entries(v%array_index)%node)
                    type is(identifier_node)
                        array_name=base%name
                    class default
                        call mismatch(index,'ALLOCATE base must be array name');return
                    end select
                    bounds(:prog%symbols(s)%rank)=v%bounds_indices(:prog%symbols(s)%rank)
                class default
                    call mismatch(index,'ALLOCATE designator differs');return
                end select
                if(symbol_index(array_name)/=s) then
                    call mismatch(index,'ALLOCATE binding differs');return
                end if
                call resolve_name_in_scope(front%arena,scope_node(),array_name,binding,err)
                if(.not.binding%found.or.binding%declaration_node_index/=symbol_declaration(s)) &
                    call mismatch(index,'ALLOCATE declaration identity differs')
                do d=1,prog%symbols(s)%rank
                    lo=ins%items(2*d-1);hi=ins%items(2*d);t=bounds(d)
                    call require_scalar(index,hi)
                    if(diag%code/=0) return
                    if(prog%expressions(hi)%typ/=ty_integer) call mismatch(index,'allocation bound must be INTEGER')
                    if(lo==0) then
                        call expression(t,hi,0)
                    else
                        call require_scalar(index,lo)
                        if(diag%code/=0) return
                        if(prog%expressions(lo)%typ/=ty_integer) call mismatch(index,'allocation bound must be INTEGER')
                        if(.not.front%arena%has_node_at(t)) then
                            call mismatch(index,'allocation bound missing');return
                        end if
                        select type(bound=>front%arena%entries(t)%node)
                        type is(range_expression_node)
                            checked_ranges(t)=.true.
                            if(bound%stride_index>0) call mismatch(index,'unexpected allocation stride')
                            call expression(bound%start_index,lo,0);call expression(bound%end_index,hi,0)
                        class default
                            call mismatch(index,'allocation lower bound differs')
                        end select
                    end if
                end do
            end if
            if(.not.valid_allocation_message(prog,ins))then
                call mismatch(index,'invalid ERRMSG control or allocation bound dependencies');return
            end if
            if((errmsg_index==0).neqv.(ins%third==0))then
                call mismatch(index,'allocation ERRMSG differs');return
            end if
            if(ins%third/=0)then
                call expression(errmsg_index,ins%third,0)
                if(diag%code/=0)return
                if(.not.valid_allocation_output(prog,ins%third,ty_character,ins%scope))then
                    call mismatch(index,'invalid allocation ERRMSG target metadata');return
                end if
                t=prog%expressions(ins%third)%symbol
                if(t==s)then
                    call mismatch(index,'allocation ERRMSG aliases its allocation object');return
                end if
                call check_module_write_ir(t,current_scope)
                if(diag%code/=0)return
            end if
            if((stat_index==0).neqv.(ins%a==0)) call mismatch(index,'allocation STAT differs')
            if(ins%a/=0) then
                call expression(stat_index,ins%a,0)
                if(diag%code/=0) return
                t=prog%expressions(ins%a)%symbol
                if(prog%expressions(ins%a)%kind/=ex_variable.or.t<1.or.t>prog%ns.or. &
                   prog%expressions(ins%a)%parenthesized) then
                    call mismatch(index,'allocation STAT must be variable');return
                end if
                if(prog%symbols(t)%rank/=0.or.prog%symbols(t)%typ/=ty_integer.or. &
                   prog%symbols(t)%is_parameter.or.prog%symbols(t)%dummy_intent==1.or. &
                   prog%symbols(t)%scope/=ins%scope) call mismatch(index,'allocation STAT must be writable local INTEGER')
            end if
            end associate
        end subroutine
        subroutine check_shape(index,symbol,d)
            integer,intent(in)::index,symbol
            type(declaration_query_t),intent(in)::d
            integer::dim,j,lower_expr,upper_expr
            integer(int64)::lower_bound,upper_bound
            if(d%is_array.neqv.(prog%symbols(symbol)%rank>0)) then
                call mismatch(index,'declaration rank differs')
                return
            end if
            if(prog%symbols(symbol)%rank==0) then
                if(prog%symbols(symbol)%is_automatic) call mismatch(index,'scalar marked automatic array')
                return
            end if
            if(prog%symbols(symbol)%is_automatic) then
                if(prog%symbols(symbol)%scope<=0.or.prog%symbols(symbol)%is_optional.or. &
                   prog%symbols(symbol)%is_allocatable.or.prog%symbols(symbol)%is_parameter.or.prog%symbols(symbol)%assumed_shape.or. &
                   prog%symbols(symbol)%initializer_expr/=0) then
                    call mismatch(index,'invalid automatic array declaration');return
                end if
            end if
            if(prog%symbols(symbol)%is_dummy.and..not.prog%symbols(symbol)%assumed_shape.and. &
               .not.prog%symbols(symbol)%is_allocatable) then
                if(prog%symbols(symbol)%rank<3.and. &
                   (prog%symbols(symbol)%lower_expr3/=0.or.prog%symbols(symbol)%upper_expr3/=0)) &
                    call mismatch(index,'unexpected explicit-shape third dimension')
                if(prog%symbols(symbol)%rank<2.and. &
                   (prog%symbols(symbol)%lower_expr2/=0.or.prog%symbols(symbol)%upper_expr2/=0)) &
                    call mismatch(index,'unexpected explicit-shape second dimension')
            end if
            if(.not.allocated(d%dimension_indices)) then
                call mismatch(index,'array bounds missing')
                return
            end if
            if(size(d%dimension_indices)/=prog%symbols(symbol)%rank) then
                call mismatch(index,'array rank differs')
                return
            end if
            do j=1,prog%symbols(symbol)%rank
                lower_expr=prog%symbols(symbol)%lower_expr;upper_expr=prog%symbols(symbol)%upper_expr
                lower_bound=prog%symbols(symbol)%lower_bound;upper_bound=prog%symbols(symbol)%upper_bound
                if(j==2) then
                    lower_expr=prog%symbols(symbol)%lower_expr2;upper_expr=prog%symbols(symbol)%upper_expr2
                    lower_bound=prog%symbols(symbol)%lower_bound2;upper_bound=prog%symbols(symbol)%upper_bound2
                end if
                if(j==3) then
                    lower_expr=prog%symbols(symbol)%lower_expr3;upper_expr=prog%symbols(symbol)%upper_expr3
                    lower_bound=prog%symbols(symbol)%lower_bound3;upper_bound=prog%symbols(symbol)%upper_bound3
                end if
                if(lower_expr==0) then
                    if(lower_bound/=1_int64) &
                        call mismatch(index,'default lower bound cache differs')
                else
                    call check_declaration_bound(index,lower_expr,lower_bound,symbol)
                end if
                if(.not.prog%symbols(symbol)%assumed_shape.and..not.prog%symbols(symbol)%is_allocatable.and..not.prog%symbols(symbol)%is_pointer) &
                    call check_declaration_bound(index,upper_expr,upper_bound,symbol)
                if(diag%code/=0) return
                dim=d%dimension_indices(j)
                if(.not.front%arena%has_node_at(dim)) then
                    call mismatch(index,'array bound node missing')
                    return
                end if
                if(prog%symbols(symbol)%assumed_shape.or.prog%symbols(symbol)%is_allocatable.or.prog%symbols(symbol)%is_pointer) then
                    if((.not.prog%symbols(symbol)%is_dummy.and..not.prog%symbols(symbol)%is_allocatable.and..not.prog%symbols(symbol)%is_pointer).or.upper_expr/=0.or. &
                       upper_bound/=lower_bound-1_int64) &
                        call mismatch(index,'assumed-shape metadata differs')
                    select type(bound=>front%arena%entries(dim)%node)
                    type is(range_expression_node)
                        checked_ranges(dim)=.true.
                        if(bound%stride_index>0.or.bound%end_index>0) call mismatch(dim,'assumed-shape bounds differ')
                        if(lower_expr==0) then
                            if(bound%start_index>0) call mismatch(dim,'unexpected assumed-shape lower bound')
                        else
                            call expression(bound%start_index,lower_expr,0)
                        end if
                    class default
                        call mismatch(dim,'assumed-shape range missing')
                    end select
                else if(lower_expr==0) then
                    call expression(dim,upper_expr,0)
                else
                    select type(bound=>front%arena%entries(dim)%node)
                    type is(range_expression_node)
                        checked_ranges(dim)=.true.
                        if(bound%stride_index>0) call mismatch(dim,'unexpected bound stride')
                        call expression(bound%start_index,lower_expr,0)
                        call expression(bound%end_index,upper_expr,0)
                    class default
                        call mismatch(dim,'explicit lower bound missing')
                    end select
                end if
            end do
        end subroutine
        subroutine check_declaration_bound(index,root,cached,symbol)
            integer,intent(in)::index,root,symbol
            integer(int64),intent(in)::cached
            type(value_t)::value
            type(diagnostic_t)::constant_diag
            if(.not.prog%symbols(symbol)%is_automatic) then
                call check_bound_cache(index,root,cached);return
            end if
            if(root<1.or.root>prog%ne) then
                call mismatch(index,'automatic bound expression missing');return
            end if
            call require_scalar(index,root)
            if(diag%code/=0) return
            if(prog%expressions(root)%typ/=ty_integer) then
                call mismatch(index,'automatic bound must be scalar INTEGER');return
            end if
            ! Constant dimensions still carry checked caches. Nonconstant bounds
            ! must satisfy the restricted specification-expression contract.
            call evaluate_constant(prog,root,value,constant_diag)
            if(constant_diag%code==0) then
                if(value%tag/=ty_integer.or.value%i/=cached) call mismatch(index,'array bound cache differs from expression')
            else if(prog%symbols(symbol)%is_dummy) then
                if(.not.valid_dummy_bound(prog,root,prog%symbols(symbol)%scope)) &
                    call mismatch(index,'unsupported explicit-shape dummy bound expression')
            else if(.not.valid_automatic_bound(prog,root,prog%symbols(symbol)%scope)) then
                call mismatch(index,'unsupported automatic bound expression')
            end if
        end subroutine
        subroutine check_bound_cache(index,bound_expr,cached)
            integer,intent(in)::index,bound_expr
            integer(int64),intent(in)::cached
            type(value_t)::value
            type(diagnostic_t)::evaluation_diag
            if(diag%code/=0) return
            if(bound_expr<1.or.bound_expr>prog%ne) then
                call mismatch(index,'array bound expression missing')
                return
            end if
            call require_scalar(index,bound_expr)
            if(diag%code/=0) return
            if(prog%expressions(bound_expr)%typ/=ty_integer) then
                call mismatch(index,'array bound expression must be INTEGER')
                return
            end if
            call evaluate_constant(prog,bound_expr,value,evaluation_diag)
            if(evaluation_diag%code/=0) then
                call mismatch(index,'array bound is not a valid integer constant')
                return
            end if
            if(value%tag/=ty_integer.or.value%i/=cached) &
                call mismatch(index,'array bound cache differs from expression')
        end subroutine
        subroutine assignment_target(index,symbol,subscript,section,subscript2,subscript3)
            integer,intent(in)::index,symbol,subscript,section,subscript2,subscript3
            type(declaration_binding_t)::binding
            character(:),allocatable::err
            if(subscript==0.and.(subscript2/=0.or.subscript3/=0)) then
                call mismatch(index,'unexpected second target subscript');return
            end if
            if(section/=0) then
                if(section<1.or.section>prog%ne) then
                    call mismatch(index,'section target missing')
                    return
                end if
                if(subscript/=0.or.(prog%expressions(section)%kind/=ex_section.and. &
                   prog%expressions(section)%kind/=ex_substring).or. &
                   prog%expressions(section)%symbol/=symbol) then
                    call mismatch(index,'section target differs')
                    return
                end if
                call expression(index,section,0)
                return
            end if
            if(subscript/=0) then
                call array_reference(index,symbol,subscript,0,subscript2=subscript2,subscript3=subscript3)
                return
            end if
            select type(node=>front%arena%entries(index)%node)
            type is(identifier_node)
                ! Nested DO parent links can leave occurrence metadata unresolved.
                ! Verify the exact declaration, as for RHS identifier references.
                call resolve_identifier_binding(front%arena,index,binding,err)
                if(.not.binding%found) &
                    call resolve_name_in_scope(front%arena,scope_node(),node%name,binding,err)
                if(.not.binding%found) then
                    call mismatch(index,'assignment target binding unresolved')
                else if(binding%declaration_node_index/=symbol_declaration(symbol)) then
                    call mismatch(index,'assignment target declaration identity differs')
                else
                    call check_type(binding%declaration_node_index,prog%symbols(symbol)%typ, &
                        prog%symbols(symbol)%rank,prog%symbols(symbol)%real_kind)
                end if
            class default
                call mismatch(index,'assignment target shape differs')
            end select
        end subroutine
        subroutine check_intrinsic_array_binding(index,symbol,binding,rank)
            integer,intent(in)::index,symbol,rank
            type(declaration_binding_t),intent(in)::binding
            if(.not.valid_intrinsic_import(prog%symbols(symbol)).or. &
               trim(prog%symbols(symbol)%intrinsic_import)/='integer_kinds'.or. &
               .not.seen_symbol(symbol).or.symbol_declaration(symbol)<=0.or.rank<0.or.rank>1) then
                call mismatch(index,'invalid intrinsic array import');return
            end if
            if(.not.binding%found.or.binding%binding_kind/=BINDING_INTRINSIC_ARRAY.or. &
               binding%association/=ASSOCIATION_USE.or.binding%declaration_node_index/=0.or. &
               binding%node_index/=symbol_declaration(symbol)) then
                call mismatch(index,'intrinsic array USE identity differs');return
            end if
            if(.not.allocated(binding%name).or..not.allocated(binding%remote_name).or. &
               .not.allocated(binding%module_name)) then
                call mismatch(index,'intrinsic array binding names missing');return
            end if
            if(lower(binding%name)/=trim(prog%symbols(symbol)%name).or. &
               lower(binding%remote_name)/='integer_kinds'.or. &
               lower(binding%module_name)/='iso_fortran_env') then
                call mismatch(index,'intrinsic array remote identity differs');return
            end if
            if(binding%scope_node_index/=find_enclosing_scope(front%arena,binding%node_index)) then
                call mismatch(index,'intrinsic array owning USE scope differs');return
            end if
            ! No fabricated declaration node: check the independently produced
            ! occurrence type/rank, while normal subscript-tree checks follow.
            call check_type(index,ty_integer,rank,4)
        end subroutine
        recursive subroutine array_reference(index,symbol,subscript,depth,section,subscript2,subscript3)
            integer,intent(in)::index,symbol,subscript,depth
            integer,intent(in),optional::section,subscript2,subscript3
            integer::second,third,d
            type(declaration_binding_t)::binding
            character(:),allocatable::err
            if(diag%code/=0) return
            if(symbol<1.or.symbol>prog%ns) then
                call mismatch(index,'array symbol missing')
                return
            end if
            if(.not.present(section)) then
                if(subscript<1.or.subscript>prog%ne) then
                    call mismatch(index,'array subscript expression missing')
                    return
                end if
                call require_scalar(index,subscript)
                if(diag%code/=0) return
                if(prog%expressions(subscript)%typ/=ty_integer) then
                    call mismatch(index,'array subscript must be INTEGER')
                    return
                end if
            end if
            if(prog%symbols(symbol)%rank<1.or.prog%symbols(symbol)%rank>3) then
                call mismatch(index,'array reference has scalar binding')
                return
            end if
            second=0;third=0
            if(present(subscript2)) second=subscript2
            if(present(subscript3)) third=subscript3
            if(present(section)) then
                if(second/=0.or.third/=0) then
                    call mismatch(index,'unexpected second section expression');return
                end if
            else if(prog%symbols(symbol)%rank>=2) then
                call require_scalar(index,second)
                if(diag%code/=0) return
                if(prog%expressions(second)%typ/=ty_integer) then
                    call mismatch(index,'second array subscript must be INTEGER');return
                end if
            else if(second/=0) then
                call mismatch(index,'unexpected second array subscript');return
            end if
            if(.not.present(section)) then
                if(prog%symbols(symbol)%rank==3) then
                    call require_scalar(index,third)
                    if(diag%code/=0) return
                    if(prog%expressions(third)%typ/=ty_integer) then
                        call mismatch(index,'third array subscript must be INTEGER');return
                    end if
                else if(third/=0) then
                    call mismatch(index,'unexpected third array subscript');return
                end if
            end if
            select type(node=>front%arena%entries(index)%node)
            type is(call_or_subscript_node)
                if(.not.allocated(node%name)) then
                    call mismatch(index,'array name missing')
                    return
                end if
                ! FortFront resolves a slice base but does not semantically visit
                ! calls inside its triplet expressions, and can omit the flag
                ! on dummy/local elements and USE-associated module arrays. For
                ! these cases allow the absent flag; exact declaration binding,
                ! declared type/rank, and scalar INTEGER index are still checked.
                if(symbol_index(node%name)/=symbol.or.node%is_intrinsic.or. &
                   (.not.node%is_array_access.and.triplet_depth==0.and.current_scope==0.and. &
                    .not.prog%symbols(symbol)%is_parameter.and.prog%symbols(symbol)%scope>=0)) then
                    call mismatch(index,'array reference binding differs')
                    return
                end if
                if(.not.allocated(node%arg_indices)) then
                    call mismatch(index,'array subscript missing')
                    return
                end if
                if(size(node%arg_indices)/=prog%symbols(symbol)%rank) then
                    call mismatch(index,'array subscript count differs')
                    return
                end if
                call resolve_name_in_scope(front%arena,scope_node(),node%name,binding,err)
                if(.not.binding%found) then
                    call mismatch(index,'array binding unresolved')
                    return
                end if
                if(prog%symbols(symbol)%is_intrinsic) then
                    if(present(section)) then
                        call check_intrinsic_array_binding(index,symbol,binding,expression_rank(section))
                    else
                        call check_intrinsic_array_binding(index,symbol,binding,0)
                    end if
                    if(diag%code/=0)return
                else
                    if(binding%declaration_node_index/=symbol_declaration(symbol)) then
                        call mismatch(index,'array declaration identity differs')
                        return
                    end if
                    ! Ordinary arrays retain their exact declaration identity.
                    call check_type(binding%declaration_node_index,prog%symbols(symbol)%typ, &
                        prog%symbols(symbol)%rank,prog%symbols(symbol)%real_kind)
                end if
                if(present(section)) then
                    do d=1,prog%symbols(symbol)%rank
                        call section_range(node%arg_indices(d),section,depth+1,d)
                    end do
                else
                    call expression(node%arg_indices(1),subscript,depth+1)
                    if(second/=0) call expression(node%arg_indices(2),second,depth+1)
                    if(third/=0) call expression(node%arg_indices(3),third,depth+1)
                end if
            class default
                call mismatch(index,'array reference shape differs')
            end select
        end subroutine
        recursive subroutine substring_reference(index,e,depth)
            integer,intent(in)::index,e,depth
            integer::s,range,j,actual(3),expected(3)
            type(declaration_binding_t)::binding
            character(:),allocatable::err,name
            associate(x=>prog%expressions(e))
            s=x%symbol
            if(s<0.or.s>prog%ns) then
                call mismatch(index,'substring symbol missing');return
            end if
            if(x%typ/=ty_character.or.x%rank/=0.or.x%character_len/=-1.or. &
               x%real_kind/=4.or.x%extent/=0.or.any(x%dims/=0).or. &
               x%stride/=0.or.x%left2/=0.or.x%right2/=0.or.x%stride2/=0.or. &
               x%left3/=0.or.x%right3/=0.or.x%stride3/=0.or.any(x%triplet(2:)).or. &
               x%length_expr/=0.or.allocated(x%args)) then
                call mismatch(index,'invalid scalar substring metadata');return
            end if
            range=0
            select type(node=>front%arena%entries(index)%node)
            type is(array_slice_node)
                if(node%num_dimensions/=1) then
                    call mismatch(index,'substring bounds missing');return
                end if
                if(.not.front%arena%has_node_at(node%array_index)) then
                    call mismatch(index,'substring base or bounds differ');return
                end if
                if(x%third/=0) then
                    call expression(node%array_index,x%third,depth+1)
                    if(diag%code/=0) return
                else
                select type(base=>front%arena%entries(node%array_index)%node)
                type is(identifier_node)
                    if(s==0.or..not.allocated(base%name)) then
                        call mismatch(index,'substring name missing');return
                    end if
                    name=base%name
                type is(literal_node)
                    if(s/=0.or..not.allocated(base%value).or..not.allocated(x%value%s)) then
                        call mismatch(index,'literal substring base differs');return
                    end if
                    if(base%literal_kind/=LITERAL_STRING.or.x%value%tag/=ty_character.or. &
                       len(dequote(base%value))/=len(x%value%s).or.dequote(base%value)/=x%value%s) then
                        call mismatch(index,'literal substring value differs');return
                    end if
                    call check_type(node%array_index,ty_character,0,4)
                class default
                    call mismatch(index,'substring requires a scalar CHARACTER name or literal');return
                end select
                end if
                range=node%bounds_indices(1)
            type is(call_or_subscript_node)
                if(s==0.or.x%third/=0.or..not.allocated(node%name).or..not.allocated(node%arg_indices)) then
                    call mismatch(index,'substring name or bounds missing');return
                end if
                if(size(node%arg_indices)/=1.or.node%is_intrinsic.or.node%is_array_access) then
                    call mismatch(index,'substring structure differs');return
                end if
                name=node%name;range=node%arg_indices(1)
            class default
                call mismatch(index,'substring syntax differs');return
            end select
            if(s>0.and.x%third==0) then
                if(symbol_index(name)/=s) then
                    call mismatch(index,'substring binding differs');return
                end if
                call resolve_name_in_scope(front%arena,scope_node(),name,binding,err)
                if(.not.binding%found.or.binding%declaration_node_index/=symbol_declaration(s)) then
                    call mismatch(index,'substring declaration identity differs');return
                end if
                call check_type(binding%declaration_node_index,ty_character,0,prog%symbols(s)%real_kind)
            end if
            if(.not.front%arena%has_node_at(range)) then
                call mismatch(index,'substring range missing');return
            end if
            select type(node=>front%arena%entries(range)%node)
            type is(range_expression_node)
                checked_ranges(range)=.true.
                actual=[node%start_index,node%end_index,node%stride_index]
                expected=[x%left,x%right,0]
                do j=1,3
                    if(expected(j)==0) then
                        if(actual(j)/=0) call mismatch(index,'unexpected substring bound or stride')
                    else if(actual(j)<=0) then
                        call mismatch(index,'substring bound missing')
                    else
                        call require_scalar(index,expected(j))
                        if(diag%code/=0) return
                        if(prog%expressions(expected(j))%typ/=ty_integer) then
                            call mismatch(index,'substring bound must be INTEGER');return
                        end if
                        triplet_depth=triplet_depth+1
                        call expression(actual(j),expected(j),depth+1)
                        triplet_depth=triplet_depth-1
                    end if
                end do
            class default
                call mismatch(index,'substring range differs');return
            end select
            end associate
        end subroutine
        recursive subroutine section_reference(index,e,depth)
            integer,intent(in)::index,e,depth
            integer::symbol,d
            type(declaration_binding_t)::binding
            character(:),allocatable::err
            if(diag%code/=0) return
            symbol=prog%expressions(e)%symbol
            select type(node=>front%arena%entries(index)%node)
            type is(array_slice_node)
                if(node%num_dimensions/=prog%symbols(symbol)%rank.or.node%is_character_substring) then
                    call mismatch(index,'section rank or substring differs')
                    return
                end if
                if(.not.front%arena%has_node_at(node%array_index)) then
                    call mismatch(index,'section base missing')
                    return
                end if
                select type(base=>front%arena%entries(node%array_index)%node)
                type is(identifier_node)
                    if(.not.allocated(base%name)) then
                        call mismatch(index,'section base name missing')
                        return
                    end if
                    if(symbol_index(base%name)/=symbol) then
                        call mismatch(index,'section base binding differs')
                        return
                    end if
                    call resolve_name_in_scope(front%arena,scope_node(),base%name,binding,err)
                    if(.not.binding%found) then
                        call mismatch(index,'section binding unresolved')
                        return
                    end if
                    if(prog%symbols(symbol)%is_intrinsic) then
                        call check_intrinsic_array_binding(node%array_index,symbol,binding,1)
                        if(diag%code/=0)return
                    else
                        if(binding%declaration_node_index/=symbol_declaration(symbol)) then
                            call mismatch(index,'section declaration identity differs')
                            return
                        end if
                        call check_type(binding%declaration_node_index,prog%expressions(e)%typ, &
                            prog%symbols(symbol)%rank,prog%expressions(e)%real_kind)
                    end if
                class default
                    call mismatch(index,'section base is not an array name')
                end select
                do d=1,prog%symbols(symbol)%rank
                    call section_range(node%bounds_indices(d),e,depth+1,d)
                end do
            class default
                call mismatch(index,'section shape differs')
            end select
        end subroutine
        recursive subroutine section_range(index,e,depth,dim)
            integer,intent(in)::index,e,depth,dim
            integer::actual(3),expected(3),j
            if(.not.front%arena%has_node_at(index)) then
                call mismatch(index,'section range missing')
                return
            end if
            expected=[prog%expressions(e)%left,prog%expressions(e)%right,prog%expressions(e)%stride]
            if(dim==2) expected=[prog%expressions(e)%left2,prog%expressions(e)%right2,prog%expressions(e)%stride2]
            if(dim==3) expected=[prog%expressions(e)%left3,prog%expressions(e)%right3,prog%expressions(e)%stride3]
            if(.not.prog%expressions(e)%triplet(dim)) then
                triplet_depth=triplet_depth+1
                call expression(index,expected(1),depth+1)
                triplet_depth=triplet_depth-1
                return
            end if
            select type(node=>front%arena%entries(index)%node)
            type is(range_expression_node)
                checked_ranges(index)=.true.
                actual=[node%start_index,node%end_index,node%stride_index]
                do j=1,3
                    if(expected(j)==0) then
                        if(actual(j)>0) call mismatch(index,'unexpected section triplet operand')
                    else if(actual(j)<=0) then
                        call mismatch(index,'section triplet operand missing')
                    else
                        triplet_depth=triplet_depth+1
                        call expression(actual(j),expected(j),depth+1)
                        triplet_depth=triplet_depth-1
                    end if
                end do
            class default
                call mismatch(index,'section range shape differs')
            end select
        end subroutine
        ! Check every edge, rather than trusting a syntax-style tag or merely
        ! finding an executable DO somewhere above an expression.
        logical function ast_constructor_loop(index) result(implied)
            integer,intent(in)::index
            integer::child,parent,n
            implied=.false.;child=index
            if(.not.front%arena%has_node_at(child)) return
            select type(node=>front%arena%entries(child)%node)
            type is(do_loop_node)
            class default
                return
            end select
            do n=1,front%arena%entry_count
                parent=front%arena%entries(child)%parent_index
                if(.not.front%arena%has_node_at(parent)) return
                select type(node=>front%arena%entries(parent)%node)
                type is(array_literal_node)
                    if(.not.allocated(node%element_indices)) return
                    implied=any(node%element_indices==child);return
                type is(do_loop_node)
                    if(.not.allocated(node%body_indices)) return
                    if(.not.any(node%body_indices==child)) return
                    child=parent
                class default
                    return
                end select
            end do
        end function
        logical function ast_in_constructor_body(index,owner) result(in_body)
            integer,intent(in)::index,owner
            integer::child,parent,n
            in_body=.false.;child=index
            if(.not.front%arena%has_node_at(child)) return
            do n=1,front%arena%entry_count
                parent=front%arena%entries(child)%parent_index
                if(.not.front%arena%has_node_at(parent)) return
                if(parent==owner) then
                    select type(node=>front%arena%entries(parent)%node)
                    type is(do_loop_node)
                        if(allocated(node%body_indices)) in_body=any(node%body_indices==child)
                    end select
                    return
                end if
                child=parent
            end do
        end function
        logical function ast_in_constructor_control(index,owner) result(in_control)
            integer,intent(in)::index,owner
            integer::child,parent,n
            in_control=.false.;child=index
            if(.not.front%arena%has_node_at(child)) return
            do n=1,front%arena%entry_count
                parent=front%arena%entries(child)%parent_index
                if(.not.front%arena%has_node_at(parent)) return
                if(parent==owner) then
                    select type(node=>front%arena%entries(parent)%node)
                    type is(do_loop_node)
                        in_control=any([node%start_expr_index,node%end_expr_index,node%step_expr_index]==child)
                    end select
                    return
                end if
                child=parent
            end do
        end function
        recursive subroutine constructor_loop_expression(index,expected,node,depth)
            integer,intent(in)::index,expected,depth
            type(do_loop_node),intent(in)::node
            type(declaration_binding_t)::binding
            character(:),allocatable::err
            integer::symbol,n,child,controls(3),source_controls(3)
            associate(e=>prog%expressions(expected))
            if(e%kind/=ex_constructor_do.or..not.ast_constructor_loop(index)) then
                call mismatch(index,'constructor implied-DO source/IR kind differs');return
            end if
            if(constructor_depth+constructor_control_depth>=max_constructor_do_depth) then
                call mismatch(index,'constructor implied-DO nesting exceeds limit');return
            end if
            if(constructor_depth==0.and.constructor_control_depth==0) then
                if(.not.valid_constructor_do(prog,expected)) then
                    call mismatch(index,'invalid constructor implied-DO lexical tree');return
                end if
            end if
            if(.not.allocated(node%var_name).or..not.allocated(node%body_indices).or..not.allocated(e%args)) then
                call mismatch(index,'constructor implied-DO control/body missing');return
            end if
            if(node%is_concurrent.or.node%line/=e%line.or.node%column/=e%column.or. &
               size(node%body_indices)/=size(e%args)) then
                call mismatch(index,'constructor implied-DO location/body count differs');return
            end if
            symbol=symbol_index(node%var_name)
            if(symbol<1.or.symbol/=e%symbol) then
                call mismatch(index,'constructor index source binding differs');return
            end if
            call resolve_name_in_scope(front%arena,scope_node(),node%var_name,binding,err)
            if(.not.binding%found.or.binding%declaration_node_index/=symbol_declaration(symbol)) then
                call mismatch(index,'constructor index declaration identity differs');return
            end if
            call check_type(binding%declaration_node_index,ty_integer,0,prog%symbols(symbol)%real_kind)
            call check_type(index,e%typ,1,e%real_kind)
            do n=1,constructor_depth
                if(prog%expressions(constructor_ir_stack(n))%symbol==symbol) then
                    call mismatch(index,'nested constructor index reuses enclosing index');return
                end if
            end do
            if(constructor_character_context>=0) then
                if(e%op/='character'.or.e%character_len/=constructor_character_context) then
                    call mismatch(index,'typed constructor implied-DO CHARACTER context differs');return
                end if
            else if(e%op=='character') then
                call mismatch(index,'unexpected typed constructor implied-DO');return
            end if
            controls=[e%left,e%right,e%stride]
            source_controls=[node%start_expr_index,node%end_expr_index,node%step_expr_index]
            constructor_control_depth=constructor_control_depth+1
            constructor_control_ast(constructor_control_depth)=index
            constructor_control_ir(constructor_control_depth)=expected
            do n=1,3
                child=source_controls(n)
                if(n==3.and.child==0.and.controls(n)==0) cycle
                if(.not.front%arena%has_node_at(child).or.controls(n)==0) then
                    call mismatch(index,'constructor implied-DO bound/stride differs');exit
                end if
                if(front%arena%entries(child)%parent_index/=index) then
                    call mismatch(index,'constructor implied-DO control parent differs');exit
                end if
                ! The current counter has no value here. Only a metadata-only
                ! inquiry can refer to it; enclosing body counters have values.
                call expression(child,controls(n),depth+1)
                if(diag%code/=0) exit
            end do
            constructor_control_ast(constructor_control_depth)=0
            constructor_control_ir(constructor_control_depth)=0
            constructor_control_depth=constructor_control_depth-1
            if(diag%code/=0) return
            constructor_depth=constructor_depth+1
            constructor_ast_stack(constructor_depth)=index
            constructor_ir_stack(constructor_depth)=expected
            do n=1,size(e%args)
                child=node%body_indices(n)
                if(.not.front%arena%has_node_at(child)) then
                    call mismatch(index,'constructor implied-DO body expression missing');exit
                end if
                if(front%arena%entries(child)%parent_index/=index) then
                    call mismatch(index,'constructor implied-DO body parent differs');exit
                end if
                call expression(child,e%args(n),depth+1)
                if(diag%code/=0) exit
            end do
            constructor_ast_stack(constructor_depth)=0
            constructor_ir_stack(constructor_depth)=0
            constructor_depth=constructor_depth-1
            checked_constructor_nodes(index)=diag%code==0
            end associate
        end subroutine
        recursive subroutine expression(index,expected,depth)
            integer,intent(in)::index,expected,depth
            integer::n,ios,s,underscore,kind_symbol,literal_kind,owner_level,saved_character_context,control_level,source_count
            logical::metadata_inquiry
            integer(int64)::iv
            real(real32)::rv4
            real(real64)::rv
            character(:),allocatable::text,err
            type(declaration_binding_t)::binding
            if(diag%code/=0) return
            if(depth>256) then
                call mismatch(index,'expression depth limit exceeded')
                return
            end if
            if(expected<1 .or. expected>prog%ne) then
                call mismatch(index,'invalid IR expression')
                return
            end if
            if(.not.front%arena%has_node_at(index)) then
                call mismatch(index,'missing expression node')
                return
            end if
            associate(e=>prog%expressions(expected))
            if(e%kind==ex_output_do) then
                call mismatch(index,'output implied-DO is not a value expression');return
            end if
            if(e%scope/=current_scope) then
                call mismatch(index,'expression scope differs')
                return
            end if
            if(e%kind==ex_variable.and.e%symbol>=1.and.e%symbol<=prog%ns) then
                if(prog%symbols(e%symbol)%is_allocatable.and.prog%symbols(e%symbol)%rank==0) then
                    if(e%typ/=ty_character.or.e%real_kind/=4.or.e%rank/=0.or.e%extent/=0.or. &
                       any(e%dims/=0).or.e%character_len/=prog%symbols(e%symbol)%character_len.or. &
                       e%left/=0.or.e%right/=0.or.e%stride/=0.or.e%left2/=0.or.e%right2/=0.or. &
                       e%stride2/=0.or.e%left3/=0.or.e%right3/=0.or.e%stride3/=0.or.e%third/=0.or. &
                       e%length_expr/=0.or.e%generic_id/=0.or.e%bound_type/=0.or.e%bound_binding/=0.or. &
                       e%intrinsic_mask/=0.or.len_trim(e%op)/=0.or.allocated(e%args).or. &
                       e%constructor_kind_expr/=0.or.any(e%triplet.neqv.[.true.,.false.,.false.])) then
                        call mismatch(index,'invalid scalar ALLOCATABLE CHARACTER expression descriptor');return
                    end if
                end if
            end if
            ! FortFront erases unary plus, while the IR retains the syntax.
            if(e%kind==ex_unary .and. e%op=='+') then
                call expression(index,e%left,depth+1)
                return
            end if
            select type(node=>front%arena%entries(index)%node)
            type is(literal_node)
                if(e%kind/=ex_literal .or. .not.allocated(node%value)) then
                    call mismatch(index,'literal shape differs')
                    return
                end if
                text=node%value
                ios=0
                if(e%typ==ty_real.or.e%typ==ty_integer) then
                    literal_kind=4
                    literal_kind=e%real_kind
                    underscore=index_char(text,'_')
                    if(underscore>0) then
                        kind_symbol=symbol_index(text(underscore+1:))
                        if(kind_symbol>0) then
                            if(.not.prog%symbols(kind_symbol)%is_parameter.or. &
                               prog%symbols(kind_symbol)%typ/=ty_integer.or. &
                               prog%symbols(kind_symbol)%constant_value%i/=literal_kind) ios=1
                        else
                            read(text(underscore+1:),*,iostat=ios) n
                            if(ios==0.and.n/=literal_kind) ios=1
                        end if
                        text=text(:underscore-1)
                    else
                        n=4
                        if(index_char(lower(text),'d')>0) n=8
                        if(n/=literal_kind) ios=1
                    end if
                    if(ios/=0) then
                        call mismatch(index,'literal kind differs');return
                    end if
                end if
                select case(e%typ)
                case(ty_integer)
                    read(text,*,iostat=ios) iv
                    if(ios==0) then
                        if(iv/=e%value%i) ios=1
                    end if
                case(ty_real)
                    if(e%real_kind==4) then
                        read(text,*,iostat=ios) rv4
                        rv=real(rv4,real64)
                    else
                        read(text,*,iostat=ios) rv
                    end if
                    if(ios==0) then
                        if(rv/=e%value%r) ios=1
                    end if
                case(ty_logical)
                    if((lower(text)=='.true.').neqv.e%value%l) ios=1
                case(ty_character)
                    if(dequote(text)/=e%value%s) ios=1
                case default
                    ios=1
                end select
                if(ios/=0) call mismatch(index,'literal value differs')
            type is(identifier_node)
                if((e%kind/=ex_variable.and.e%kind/=ex_constructor_index).or..not.allocated(node%name)) then
                    call mismatch(index,'variable shape differs')
                    return
                end if
                s=symbol_index(node%name)
                if(s/=e%symbol .or. s==0) then
                    call mismatch(index,'variable binding differs')
                    return
                end if
                owner_level=0
                do n=constructor_depth,1,-1
                    if(prog%expressions(constructor_ir_stack(n))%symbol==s) then
                        owner_level=n;exit
                    end if
                end do
                control_level=0
                do n=constructor_control_depth,1,-1
                    if(prog%expressions(constructor_control_ir(n))%symbol==s) then
                        control_level=n;exit
                    end if
                end do
                if(e%kind==ex_constructor_index) then
                    if(.not.valid_constructor_index(prog,expected)) then
                        call mismatch(index,'invalid constructor index metadata');return
                    end if
                    if(owner_level>0) then
                        if(e%constructor_owner/=constructor_ir_stack(owner_level).or. &
                           .not.ast_in_constructor_body(index,constructor_ast_stack(owner_level))) then
                            call mismatch(index,'constructor index owner/source ancestry differs');return
                        end if
                    else if(control_level>0.and.constructor_metadata_depth>0) then
                        if(e%constructor_owner/=constructor_control_ir(control_level).or. &
                           .not.ast_in_constructor_control(index,constructor_control_ast(control_level))) then
                            call mismatch(index,'constructor metadata inquiry owner/source ancestry differs');return
                        end if
                    else
                        call mismatch(index,'constructor index is outside its lexical value scope');return
                    end if
                    call check_type(index,ty_integer,0,e%real_kind)
                else if(owner_level/=0.or.control_level/=0) then
                    call mismatch(index,'constructor index was replaced by outer storage');return
                end if
                if(prog%symbols(s)%is_intrinsic) then
                    if(symbol_declaration(s)==0) call mismatch(index,'intrinsic kind import unverified')
                    return
                end if
                call resolve_identifier_binding(front%arena,index,binding,err)
                if(.not.binding%found) then
                    ! Some loop expression parent links are absent upstream.
                    ! Use the independently mapped enclosing statement scope.
                    call resolve_name_in_scope(front%arena,scope_node(),node%name,binding,err)
                end if
                ! The public binding query can miss PUBLIC declaration attributes
                ! under a module-wide PRIVATE default. symbol_index already checks
                ! the independently matched USE list and visibility. For selectors,
                ! require exact binding in that validated originating module.
                if(.not.binding%found.and.selector_depth>0.and.prog%symbols(s)%is_parameter.and. &
                   prog%symbols(s)%scope<0) then
                    call resolve_name_in_scope(front%arena,module_node_index(-prog%symbols(s)%scope), &
                        node%name,binding,err)
                end if
                if(.not.binding%found) then
                    call mismatch(index,'variable binding unresolved')
                else if(binding%declaration_node_index/=symbol_declaration(s)) then
                    call mismatch(index,'resolved declaration identity differs')
                else
                    call check_type(binding%declaration_node_index,e%typ,prog%symbols(s)%rank,e%real_kind)
                end if
            type is(component_access_node)
                if(e%kind==ex_call.and.e%op=='len') then
                    if(.not.allocated(node%component_name).or..not.allocated(e%args)) then
                        call mismatch(index,'CHARACTER %LEN inquiry is incomplete');return
                    end if
                    if(lower(node%component_name)/='len'.or.size(e%args)/=1.or. &
                       e%typ/=ty_integer.or.e%real_kind/=4.or.e%rank/=0) then
                        call mismatch(index,'CHARACTER %LEN inquiry metadata differs');return
                    end if
                    s=e%args(1)
                    if(s<1.or.s>prog%ne) then
                        call mismatch(index,'CHARACTER %LEN base is invalid');return
                    end if
                    if(prog%expressions(s)%kind/=ex_variable.or.prog%expressions(s)%typ/=ty_character.or. &
                       prog%expressions(s)%parenthesized) then
                        call mismatch(index,'CHARACTER %LEN requires a whole variable');return
                    end if
                    call expression(node%base_expr_index,s,depth+1)
                    call check_type(index,ty_integer,0,4)
                    return
                end if
                if(e%kind/=ex_component.or..not.allocated(node%component_name)) then
                    call mismatch(index,'component expression differs');return
                end if
                s=prog%expressions(e%left)%typ-ty_derived_base
                if(lower(node%component_name)/=trim(prog%derived_types(s)%component_names(e%symbol))) &
                    call mismatch(index,'component name differs')
                call expression(node%base_expr_index,e%left,depth+1)
            type is(binary_op_node)
                if(.not.allocated(node%operator)) then
                    call mismatch(index,'operator missing')
                    return
                end if
                if(e%kind==ex_unary) then
                    if(e%op=='-' .and. node%is_unary_minus) then
                        call expression(node%right_index,e%left,depth+1)
                    else if(e%op=='.not.' .and. lower(node%operator)=='.not.') then
                        call expression(node%right_index,e%left,depth+1)
                    else
                        call mismatch(index,'unary operator differs')
                    end if
                else if(e%kind==ex_user_call.and.len_trim(e%op)>0) then
                    if(normal_op(node%operator)/=normal_op(e%op).or.size(e%args)<1.or.size(e%args)>2) then
                        call mismatch(index,'overloaded operator differs');return
                    end if
                    call check_operator_binding(index,expected)
                    if(e%op(1:1)=='.'.and.normal_op(e%op)==trim(e%op)) &
                        call check_type(index,e%typ,e%rank,e%real_kind)
                    if(e%op=='+'.and.size(e%args)==2) then
                        if(prog%expressions(e%args(1))%typ==ty_character.or. &
                           prog%expressions(e%args(2))%typ==ty_character) &
                            call check_type(index,e%typ,e%rank,e%real_kind)
                    end if
                    if(size(e%args)==1) then
                        if(node%left_index/=0) call mismatch(index,'unary defined operator has extra operand')
                        call expression(node%right_index,e%args(1),depth+1)
                    else
                        call expression(node%left_index,e%args(1),depth+1)
                        call expression(node%right_index,e%args(2),depth+1)
                    end if
                else if(e%kind==ex_binary) then
                    if(normal_op(node%operator)/=normal_op(e%op)) then
                        call mismatch(index,'binary operator differs')
                        return
                    end if
                    call expression(node%left_index,e%left,depth+1)
                    call expression(node%right_index,e%right,depth+1)
                else
                    call mismatch(index,'binary expression shape differs')
                end if
            type is(do_loop_node)
                call constructor_loop_expression(index,expected,node,depth)
            type is(array_literal_node)
                if(e%kind/=ex_constructor.or..not.allocated(node%element_indices)) then
                    call mismatch(index,'constructor shape differs');return
                end if
                if(e%op=='character'.or.e%op=='integer'.or.e%op=='real'.or.e%op=='logical') then
                    if(.not.allocated(node%type_spec)) then
                        call mismatch(index,'typed CHARACTER constructor missing');return
                    end if
                    call check_constructor_type(index,node%type_spec,e)
                    if(e%op/='character') call check_type(index,e%typ,1,e%real_kind)
                else if(allocated(node%type_spec)) then
                    if(len_trim(node%type_spec)>0) then
                        call mismatch(index,'unexpected typed constructor');return
                    end if
                end if
                if(size(node%element_indices)/=size(e%args)) then
                    call mismatch(index,'constructor element count differs');return
                end if
                saved_character_context=constructor_character_context
                constructor_character_context=-1
                if(e%op=='character') constructor_character_context=e%character_len
                do n=1,size(e%args)
                    call expression(node%element_indices(n),e%args(n),depth+1)
                end do
                constructor_character_context=saved_character_context
            type is(array_slice_node)
                if(e%kind==ex_substring) then
                    call substring_reference(index,expected,depth);return
                end if
                if(e%kind/=ex_section.and.e%kind/=ex_gather_rows) then
                    call mismatch(index,'section expression shape differs')
                    return
                end if
                call section_reference(index,expected,depth)
            type is(call_or_subscript_node)
                if(e%kind==ex_record) then
                    s=e%typ-ty_derived_base
                    if(.not.allocated(node%name)) then
                        call mismatch(index,'record constructor missing');return
                    end if
                    source_count=0
                    if(allocated(node%arg_indices)) source_count=size(node%arg_indices)
                    if(lower(node%name)/=trim(prog%derived_types(s)%name).or. &
                       source_count/=size(e%args)) then
                        call mismatch(index,'record constructor differs');return
                    end if
                    call resolve_name_in_scope(front%arena,scope_node(),node%name,binding,err)
                    if(.not.binding%found.or.binding%declaration_node_index/=type_nodes(s)) &
                        call mismatch(index,'constructor type binding differs')
                    do n=1,size(e%args)
                        call expression(node%arg_indices(n),e%args(n),depth+1)
                    end do
                    return
                end if
                if(e%kind==ex_substring) then
                    call substring_reference(index,expected,depth);return
                end if
                if(e%kind==ex_section.or.e%kind==ex_gather_rows) then
                    call array_reference(index,e%symbol,0,depth,expected)
                    return
                end if
                if(e%kind==ex_element) then
                    if(e%symbol<1.or.e%symbol>prog%ns) then
                        call mismatch(index,'array element symbol missing')
                        return
                    end if
                    if(e%typ/=prog%symbols(e%symbol)%typ) then
                        call mismatch(index,'array element type differs')
                        return
                    end if
                    call array_reference(index,e%symbol,e%left,depth,subscript2=e%right,subscript3=e%third)
                    return
                end if
                if(e%kind==ex_user_call.and.e%bound_type>0) then
                    call check_bound_call(index,e%bound_type,e%bound_binding,e%symbol,e%args(1))
                    call check_actual_arguments(index,node%arg_indices,e%args(2:),e%symbol,'',depth+1,1)
                    return
                end if
                if(e%kind==ex_user_call) then
                    ! The AST intrinsic flag is a lexical name hint (COUNT/SUM
                    ! may name module functions). The resolved declaration below
                    ! is the authority, including exact function identity.
                    if(.not.allocated(node%name).or.node%is_array_access) then
                        call mismatch(index,'function call shape differs')
                        return
                    end if
                    s=e%symbol
                    if(s<1.or.s>prog%np) then
                        call mismatch(index,'function binding missing')
                        return
                    end if
                    if(e%generic_id>0) then
                        call check_generic_call(index,node%name,e%generic_id,s,node%arg_indices,e%args)
                    else
                        if(lower(node%name)/=trim(prog%procedures(s)%name)) then
                            call mismatch(index,'function name differs');return
                        end if
                        call resolve_name_in_scope(front%arena,scope_node(),node%name,binding,err)
                        if(.not.binding%found.or.binding%binding_kind/=BINDING_FUNCTION.or. &
                           binding%declaration_node_index/=procedure_node(s)) then
                            call mismatch(index,'function declaration identity differs');return
                        end if
                    end if
                    if(diag%code/=0) return
                    call check_actual_arguments(index,node%arg_indices,e%args,s,'',depth+1)
                    if(prog%procedures(s)%is_elemental) call check_type(index,e%typ,e%rank,e%real_kind)
                    return
                end if
                if(e%kind/=ex_call .or. .not.allocated(node%name)) then
                    call mismatch(index,'intrinsic call shape differs')
                    return
                end if
                if(lower(node%name)/=trim(e%op) .or. node%is_array_access) then
                    call mismatch(index,'intrinsic call differs')
                    return
                end if
                if(e%op=='repeat') then
                    ! Recover source binding independently: dropping generic_id
                    ! from intrinsic IR must not bypass user-specific priority.
                    call resolve_name_in_scope(front%arena,scope_node(),node%name,binding,err)
                    if(binding%found) then
                        if(binding%binding_kind/=BINDING_GENERIC_INTERFACE) then
                            call mismatch(index,'REPEAT intrinsic is shadowed by a source declaration');return
                        end if
                        s=0
                        do n=1,prog%ng
                            if(generic_nodes(n)==binding%declaration_node_index) then
                                s=n;exit
                            end if
                        end do
                        if(s==0) then
                            call mismatch(index,'REPEAT generic declaration missing');return
                        end if
                        call check_generic_call(index,node%name,s,0,node%arg_indices,e%args)
                        if(diag%code/=0) return
                    else if(symbol_index(node%name)/=0) then
                        call mismatch(index,'REPEAT intrinsic is shadowed by a source object');return
                    end if
                end if
                if(is_erf_bessel(e%op)) then
                    call resolve_name_in_scope(front%arena,scope_node(),node%name,binding,err)
                    if(binding%found.or.symbol_index(node%name)/=0) then
                        call mismatch(index,'ERF/Bessel intrinsic is shadowed by a source declaration');return
                    end if
                end if
                if(is_bit_intrinsic(e%op).or.e%op=='min'.or.e%op=='max'.or.is_lexical_intrinsic(e%op).or.is_degree_trig(e%op).or.e%op=='new_line'.or.e%op=='digits'.or.e%op=='rrspacing'.or. &
                   e%op=='asin'.or.e%op=='atan'.or.e%op=='atan2'.or.e%op=='acos') then
                    call resolve_name_in_scope(front%arena,scope_node(),node%name,binding,err)
                    if(binding%found.or.symbol_index(node%name)/=0) then
                        call mismatch(index,'Inverse trig intrinsic is shadowed by a source declaration');return
                    end if
                end if
                if(e%op=='erfc_scaled') then
                    call resolve_name_in_scope(front%arena,scope_node(),node%name,binding,err)
                    if(binding%found.or.symbol_index(node%name)/=0) then
                        call mismatch(index,'ERFC_SCALED intrinsic is shadowed by a source declaration');return
                    end if
                end if
                if(e%op=='isnan'.or.e%op=='cshift'.or.e%op=='eoshift') then
                    ! Resolve intrinsically only when no source
                    ! object, function or generic binds the same spelling.
                    call resolve_name_in_scope(front%arena,scope_node(),node%name,binding,err)
                    if(binding%found.or.symbol_index(node%name)/=0) then
                        if(e%op=='isnan') call mismatch(index,'ISNAN intrinsic is shadowed by a source declaration')
                        if(e%op=='cshift') call mismatch(index,'CSHIFT intrinsic is shadowed by a source declaration')
                        if(e%op=='eoshift') call mismatch(index,'EOSHIFT intrinsic is shadowed by a source declaration')
                        return
                    end if
                end if
                if(e%op=='char') then
                    ! CHAR is no longer reserved. Its lexical intrinsic hint is
                    ! insufficient when source scope binds a data object,
                    ! function or generic of the same name.
                    call resolve_name_in_scope(front%arena,scope_node(),node%name,binding,err)
                    if(binding%found.or.symbol_index(node%name)/=0) then
                        call mismatch(index,'CHAR intrinsic is shadowed by a source declaration');return
                    end if
                end if
                if(.not.allocated(node%arg_indices)) then
                    if((e%op=='selected_real_kind'.or.e%op=='null').and.size(e%args)==0.and.e%intrinsic_mask==0) return
                    call mismatch(index,'intrinsic arguments missing')
                    return
                end if
                if(size(node%arg_indices)/=size(e%args)) then
                    call mismatch(index,'intrinsic argument count differs')
                    return
                end if
                metadata_inquiry=.false.
                if(constructor_control_depth>0.and.size(e%args)==1) then
                    metadata_inquiry=e%op=='bit_size'.or.e%op=='kind'.or.e%op=='digits'.or.e%op=='radix'.or.e%op=='huge'
                    if(e%op=='len') then
                        n=e%args(1)
                        if(n>=1.and.n<=prog%ne) metadata_inquiry=prog%expressions(n)%character_len>=0
                    end if
                end if
                if(metadata_inquiry) then
                    call resolve_name_in_scope(front%arena,scope_node(),node%name,binding,err)
                    if(binding%found.or.symbol_index(node%name)/=0) then
                        call mismatch(index,'constructor metadata inquiry is shadowed by a source declaration');return
                    end if
                    metadata_inquiry=.true.
                    constructor_metadata_depth=constructor_metadata_depth+1
                end if
                call check_actual_arguments(index,node%arg_indices,e%args,0,trim(e%op),depth+1,intrinsic_mask=e%intrinsic_mask)
                if(metadata_inquiry) constructor_metadata_depth=constructor_metadata_depth-1
            class default
                call mismatch(index,'unsupported expression node')
            end select
            end associate
        end subroutine
    end subroutine
    ! Read-only spelling guard, separate from the complete AST-to-IR expression
    ! checker. Exposed for native corruption tests, never a producer injection API.
    logical function read_element_unit_text_matches(tokens,node) result(ok)
        type(token_t),intent(in)::tokens(:)
        type(read_statement_node),intent(in)::node
        integer::i,j,n,at,count,depth
        character(:),allocatable::text
        ok=.false.;n=size(tokens);at=0;count=0
        if(.not.allocated(node%unit_spec).or..not.allocated(node%specifiers))return
        if(size(node%specifiers)<1)return
        if(.not.allocated(node%specifiers(1)%value))return
        do i=1,n
            if(tokens(i)%line/=node%line.or.tokens(i)%column/=node%column)cycle
            if(.not.allocated(tokens(i)%text))return
            if(lower(tokens(i)%text)/='read')cycle
            at=i;count=count+1
        end do
        if(count/=1)return
        i=next_token(at+1)
        if(i>n)return
        if(.not.allocated(tokens(i)%text))return
        if(tokens(i)%kind/=TK_OPERATOR.or.tokens(i)%text/='(')return
        i=next_token(i+1)
        if(i>n)return
        if(.not.allocated(tokens(i)%text))return
        ! UNIT= is optional; an array actually named UNIT is not a keyword.
        if(lower(tokens(i)%text)=='unit')then
            j=next_token(i+1)
            if(j>n)return
            if(.not.allocated(tokens(j)%text))return
            if(tokens(j)%kind==TK_OPERATOR.and.tokens(j)%text=='=')i=next_token(j+1)
        end if
        text='';depth=0
        do while(i<=n)
            if(.not.allocated(tokens(i)%text))return
            if(tokens(i)%kind==TK_NEWLINE.or.tokens(i)%kind==TK_COMMENT)return
            if(tokens(i)%kind==TK_OPERATOR)then
                select case(tokens(i)%text)
                case('(')
                    depth=depth+1
                    if(depth>256)return
                case(')')
                    if(depth==0)return
                    depth=depth-1
                case(',')
                    if(depth==0)then
                        if(len(text)==0)return
                        ! Preserve case and quoted content, not merely a name.
                        ok=node%unit_spec==text.and.node%specifiers(1)%value==text
                        return
                    end if
                case(';')
                    return
                end select
            end if
            text=text//tokens(i)%text
            i=next_token(i+1)
        end do
    contains
        integer function next_token(first) result(k)
            integer,intent(in)::first
            k=first
            do while(k<=n)
                if(tokens(k)%kind/=TK_WHITESPACE)return
                k=k+1
            end do
        end function
    end function
    integer function index_char(text,char) result(n)
        character(*),intent(in)::text,char
        n=index(text,char)
    end function
    function normal_op(op) result(out)
        character(*),intent(in)::op
        character(:),allocatable::out
        out=lower(trim(op))
        select case(out)
        case('.eq.');out='=='
        case('.ne.');out='/='
        case('.lt.');out='<'
        case('.le.');out='<='
        case('.gt.');out='>'
        case('.ge.');out='>='
        end select
    end function
    function dequote(text) result(out)
        character(*),intent(in)::text
        character(:),allocatable::out
        integer::i,n
        out='';n=len(text)
        if(n<2) return
        i=2
        do while(i<n)
            out=out//text(i:i)
            if(text(i:i)==text(1:1)) i=i+1
            i=i+1
        end do
    end function
end module
