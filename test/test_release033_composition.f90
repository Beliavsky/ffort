! SPDX-License-Identifier: MIT
! Synthetic cross-feature checks. No original utility code is embedded here.
program test_release033_composition
    use, intrinsic::iso_fortran_env,only:int64
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='module m'//nl//'implicit none'//nl//'contains'//nl// &
        'pure integer function span(n) result(v)'//nl//'integer,intent(in)::n'//nl// &
        'v=n+1'//nl//'end function'//nl// &
        'recursive subroutine visit(depth,value,letters)'//nl// &
        'integer,intent(in)::depth'//nl//'integer,intent(out)::value'//nl// &
        'character(len=3),intent(out)::letters'//nl// &
        'integer::a(span(depth)),entry'//nl//'character(len=span(depth))::s'//nl// &
        'integer,save::counter=0'//nl//"character(len=3),save::word='abc'"//nl// &
        "if(counter==0.and.word/='abc') error stop 1"//nl// &
        'counter=counter+1'//nl//'entry=counter'//nl//'a=counter'//nl// &
        "word=word(2:)//'x'"//nl//'s=word'//nl// &
        'if(depth>0) call visit(depth-1,value,letters)'//nl// &
        'if(any(a/=entry)) error stop 2'//nl// &
        'if(size(a)/=depth+1.or.len(s)/=depth+1) error stop 3'//nl// &
        'value=counter'//nl//'letters=word'//nl//'end subroutine'//nl// &
        'subroutine fill(x,n)'//nl//'integer,intent(in)::n'//nl// &
        'integer,target,intent(inout)::x(n)'//nl//'integer::work(span(n-1))'//nl// &
        'integer::calls=0'//nl//'calls=calls+1'//nl//'work=10+calls'//nl// &
        'x=work'//nl//'end subroutine'//nl//'end module'//nl// &
        'program main'//nl//'use m'//nl//'implicit none'//nl// &
        'integer::value'//nl//'character(len=3)::letters'//nl// &
        'integer,target::data(5)'//nl//'integer,pointer::view(:)'//nl// &
        'call visit(2,value,letters)'//nl// &
        "if(value/=3.or.letters/='xxx') error stop 4"//nl// &
        'call visit(0,value,letters)'//nl// &
        "if(value/=4.or.letters/='xxx') error stop 5"//nl// &
        'data=[0,1,2,3,4]'//nl//'view=>data'//nl// &
        'call fill(data,2)'//nl//'call fill(data,3)'//nl// &
        'if(any(view/=[12,12,12,3,4])) error stop 6'//nl// &
        'if(any(findloc(view,3)/=[4])) error stop 7'//nl//'end program'
    type(program_t)::p
    type(diagnostic_t)::d
    integer::mutation,j,stage,checks,arr,chars,saved,savedchars,explicit,view,work,span,root,arg,init,res
    integer(int64)::budget,steps
    checks=0
    do mutation=1,12
        do stage=1,2
            call fresh()
            select case(mutation)
            case(1)
                ! A valid dynamic bound cannot become a SAVE initializer cache.
                p%symbols(saved)%initializer_expr=root
            case(2)
                ! Automatic objects cannot acquire another local's SAVE storage.
                p%symbols(arr)%is_saved=.true.
                p%symbols(arr)%initializer_expr=init
                p%symbols(arr)%parameter_ready=.true.
            case(3)
                ! Shared storage does not turn a mutable local into an eligible actual.
                p%expressions(arg)%symbol=saved
            case(4)
                p%symbols(res)%is_saved=.true.
                p%symbols(res)%initializer_expr=init
            case(5)
                p%symbols(saved)%scope=span
            case(6)
                p%procedures(span)%is_pure=.false.
            case(7)
                ! Fixed saved CHARACTER metadata cannot borrow a dynamic length.
                p%symbols(savedchars)%length_expr=p%symbols(chars)%length_expr
            case(8)
                p%symbols(saved)%constant_value%i=99_int64
            case(9)
                ! Explicit-dummy function bounds remain outside this increment.
                p%symbols(explicit)%upper_expr=p%symbols(work)%upper_expr
            case(10)
                p%symbols(view)%is_saved=.true.
                p%symbols(view)%initializer_expr=init
            case(11)
                p%expressions(root)%args(1)=root
            case(12)
                p%expressions(p%symbols(chars)%length_expr)%symbol=p%symbols(saved)%scope
            end select
            d=diagnostic_t()
            if(stage==1) then
                call verify_frontend(source,p,d)
                call expect(d%code==1,'adapter rejects corrupt cross-feature IR')
            else
                call execute_program(p,d,max_steps=10000_int64)
                call expect(d%code==2,'runtime rejects corrupt cross-feature IR')
                call expect(allocated(d%message),'runtime rejection has diagnostic')
                call expect(index(d%message,'STOP')==0,'metadata rejected before user assertion')
            end if
            checks=checks+1
        end do
    end do
    call fresh()
    do j=1,3
        d=diagnostic_t()
        call execute_program(p,d)
        call expect(d%code==0,'repeated root resets saved recursion and pointer state')
        call expect(p%symbols(saved)%constant_value%i==0_int64,'saved integer initializer remains immutable')
        call expect(p%symbols(savedchars)%constant_value%s=='abc','saved CHARACTER initializer remains immutable')
        checks=checks+1
    end do
    ! A one-step-short run has already changed both shared stores. The next root
    ! must restore them and recompute specification extents from the same IR.
    budget=100000_int64;d=diagnostic_t()
    call execute_program(p,d,budget_remaining=budget)
    call expect(d%code==0,'measure complete root budget')
    steps=100000_int64-budget
    call expect(steps>1_int64,'nontrivial root budget')
    budget=steps-1_int64;d=diagnostic_t()
    call execute_program(p,d,budget_remaining=budget)
    call expect(d%code==2.and.budget==0_int64,'late failure consumes shared root budget')
    call expect(index(d%message,'execution step limit exceeded')>0,'late failure is budget exhaustion')
    checks=checks+1
    d=diagnostic_t();call execute_program(p,d)
    call expect(d%code==0,'fresh SAVE and spec-call state after late root failure')
    checks=checks+1
    print '(a,i0,a)','PASS: release 0.33 composition: ',checks,' metadata/reset/budget checks'
contains
    subroutine fresh()
        d=diagnostic_t();call parse_subset(source,p,d)
        call expect(d%code==0,'composition parser baseline')
        call verify_frontend(source,p,d)
        call expect(d%code==0,'composition adapter baseline')
        call execute_program(p,d)
        call expect(d%code==0,'composition runtime baseline')
        arr=0;chars=0;saved=0;savedchars=0;explicit=0;view=0;work=0;span=1
        do j=1,p%ns
            select case(p%symbols(j)%name)
            case('a');arr=j
            case('s');chars=j
            case('counter');saved=j
            case('word');savedchars=j
            case('x');explicit=j
            case('view');view=j
            case('work');work=j
            end select
        end do
        call expect(min(arr,chars,saved,savedchars,explicit,view,work)>0,'composition symbol identities')
        root=p%symbols(arr)%upper_expr;arg=p%expressions(root)%args(1)
        init=p%symbols(saved)%initializer_expr;res=p%procedures(span)%result_symbol
    end subroutine
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        if(ok)return
        print *,label,' mutation=',mutation,' stage=',stage,' code=',d%code
        if(allocated(d%message))print *,d%message
        error stop 1
    end subroutine
end program
