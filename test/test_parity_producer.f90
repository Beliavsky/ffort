! SPDX-License-Identifier: MIT
program test_parity_producer
    use fortfront_compiler
    use ast_nodes_core,only:call_or_subscript_node
    use type_system_unified,only:TLOGICAL
    implicit none
    type(compiler_frontend_result_t)::front
    type(compiler_frontend_options_t)::opts
    character(*),parameter::nl=new_line('a')
    integer::j,n,r
    opts%input_mode=INPUT_MODE_STANDARD;opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.;opts%run_semantics=.true.
    call compile_frontend_from_string('program p'//nl//'implicit none'//nl// &
        'logical::a(2,3)'//nl//'a=.true.'//nl// &
        'print *,parity(a),parity(mask=a,dim=1),parity(dim=2,mask=a)'//nl//'end program',front,opts)
    if(.not.front%success())error stop 'PARITY producer rejected'
    n=0
    do j=1,front%arena%entry_count
        if(.not.front%arena%has_node_at(j))cycle
        select type(x=>front%arena%entries(j)%node)
        type is(call_or_subscript_node)
            if(x%name/='parity')cycle
            n=n+1;r=1
            if(n==1)r=0
            if(.not.x%resolved_type_found.or.x%resolved_type_kind/=TLOGICAL.or. &
               x%resolved_kind_value/=4.or.x%resolved_rank/=r)error stop 'PARITY independent metadata differs'
        end select
    end do
    if(n/=3)error stop 'PARITY producer count differs'
    print *, 'PASS: PARITY producer scalar and DIM result metadata:',n
end program
