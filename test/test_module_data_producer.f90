! SPDX-License-Identifier: MIT
program test_module_data_producer
    use fortfront_compiler, only: compiler_frontend_result_t,compiler_frontend_options_t, &
        compile_frontend_from_string,INPUT_MODE_STANDARD,OPERATING_MODE_STRICT
    use frontend_compiler_resolution, only: declaration_binding_t,resolve_name_in_scope
    use ast_nodes_core, only: program_node
    implicit none
    type(compiler_frontend_result_t)::front
    type(compiler_frontend_options_t)::opts
    type(declaration_binding_t)::binding
    character(:),allocatable::err
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='module state'//nl//'private'//nl// &
        'integer,public::counter=2,vec(2)=1'//nl//'integer::hidden=3'//nl//'end module'//nl// &
        'module other'//nl//'integer,private::secret=3'//nl//'end module'//nl// &
        'program main'//nl//'use state'//nl//'use other'//nl// &
        'counter=7'//nl//'vec(2)=9'//nl//'print *,counter,vec(2)'//nl//'end program'
    integer::i,main
    opts%input_mode=INPUT_MODE_STANDARD;opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.;opts%run_semantics=.true.
    call compile_frontend_from_string(source,front,opts)
    if(.not.front%success()) then
        if(allocated(front%error_msg)) print *,front%error_msg
        error stop 'public module attribute producer rejection'
    end if
    main=0
    do i=1,front%arena%entry_count
        if(.not.front%arena%has_node_at(i)) cycle
        select type(node=>front%arena%entries(i)%node)
        type is(program_node)
            main=i
        end select
    end do
    if(main==0) error stop 'main scope missing'
    call resolve_name_in_scope(front%arena,main,'counter',binding,err)
    if(.not.binding%found) error stop 'PUBLIC scalar not exported'
    call resolve_name_in_scope(front%arena,main,'vec',binding,err)
    if(.not.binding%found) error stop 'PUBLIC second array not exported'
    call resolve_name_in_scope(front%arena,main,'hidden',binding,err)
    if(binding%found) error stop 'private default leaked'
    call resolve_name_in_scope(front%arena,main,'secret',binding,err)
    if(binding%found) error stop 'PRIVATE attribute leaked'
    print '(a)','PASS: module declaration PUBLIC/PRIVATE producer binding identities'
end program
