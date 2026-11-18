! SPDX-License-Identifier: MIT
program test_eoshift
    use,intrinsic::iso_fortran_env,only:int64
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program,evaluate_constant,evaluate_constant_array
    implicit none
    character(*),parameter::nl=new_line('a')
    type(program_t)::p
    type(diagnostic_t)::d
    type(value_t)::v
    type(value_t),allocatable::values(:)
    character(:),allocatable::source,expr,decl,items
    character(40)::num
    integer::checks,form,mutation,e,a,b,c,dim,j,k,m,r,cols,axis,shift,pos,row,col,source_pos,wanted,q
    integer(int64)::state,expected_state
    checks=0
    ! Adapter, direct runtime and unevaluated KIND independently reject bad IR.
    do form=1,3
        decl='';expr='eoshift(["ab","cd"],1,"! ",dim=1)'
        if(form==3)then
            decl='character(2)::a(0,2),b(2)'//nl//'integer::s(2)'//nl//'s=0;b="! "'//nl
            expr='eoshift(a,s,b,dim=1)'
        end if
        if(form==2)expr='kind('//expr//')'
        source='program p'//nl//'implicit none'//nl//decl//'print *,'//expr//nl//'end program'
        do mutation=0,47
            call parse_subset(source,p,d);call expect(d%code==0,'baseline parse')
            e=0
            do j=1,p%ne
                if(p%expressions(j)%op=='eoshift')e=j
            end do
            call expect(e>0,'EOSHIFT occurrence')
            a=p%expressions(e)%args(1);b=p%expressions(e)%args(2)
            c=p%expressions(e)%args(3);dim=p%expressions(e)%args(4)
            select case(mutation)
            case(1);p%expressions(e)%typ=ty_integer
            case(2);p%expressions(e)%real_kind=8
            case(3);p%expressions(e)%rank=4
            case(4);p%expressions(e)%extent=99
            case(5);p%expressions(e)%dims=[1_int64,2_int64,3_int64]
            case(6);p%expressions(e)%intrinsic_mask=3
            case(7);p%expressions(e)%args=[integer::]
            case(8);p%expressions(e)%args=[a]
            case(9);p%expressions(e)%args=[a,b,c,dim,dim]
            case(10);deallocate(p%expressions(e)%args)
            case(11);p%expressions(e)%args(1)=0
            case(12);p%expressions(e)%args(3)=p%ne+1
            case(13);p%expressions(e)%args(2)=e
            case(14);p%expressions(a)%typ=ty_integer
            case(15);p%expressions(a)%real_kind=8
            case(16);p%expressions(a)%rank=3
            case(17);p%expressions(a)%extent=99
            case(18);p%expressions(a)%character_len=65537
            case(19);p%expressions(b)%typ=ty_real
            case(20);p%expressions(b)%real_kind=16
            case(21);p%expressions(b)%rank=2
            case(22);p%expressions(c)%typ=ty_integer
            case(23);p%expressions(c)%real_kind=8
            case(24);p%expressions(c)%character_len=1
            case(25);p%expressions(c)%rank=2
            case(26);p%expressions(dim)%typ=ty_real
            case(27);p%expressions(dim)%real_kind=16
            case(28);p%expressions(dim)%rank=1
            case(29);p%expressions(dim)%value%i=0
            case(30);p%expressions(e)%character_len=0
            case(31);p%expressions(e)%left=a
            case(32);p%expressions(e)%symbol=1
            case(33);p%expressions(e)%length_expr=a
            case(34);p%expressions(e)%constructor_kind_expr=a
            case(35);p%expressions(e)%triplet(2)=.true.
            case(36);p%expressions(e)%constructor_owner=1
            case(37)
                if(form==3)then
                    p%symbols(p%expressions(c)%symbol)%real_kind=8
                else
                    p%expressions(c)%value%real_kind=8
                end if
            case(38)
                if(form==3)then
                    p%symbols(p%expressions(c)%symbol)%character_len=3
                else
                    p%expressions(c)%value%s='!!!'
                end if
            case(39)
                if(form==3)then
                    p%symbols(p%expressions(c)%symbol)%typ=ty_integer
                else
                    deallocate(p%expressions(c)%value%s)
                end if
            case(40);p%expressions(b)%dims=[1_int64,0_int64,0_int64]
            case(41);p%expressions(c)%dims=[1_int64,0_int64,0_int64]
            case(42);p%expressions(e)%generic_id=1
            case(43);p%expressions(e)%bound_type=1
            case(44);p%expressions(e)%stride2=b
            case(45);p%expressions(a)%dims=[9_int64,9_int64,9_int64]
            case(46);p%expressions(b)%character_len=0
            case(47);p%expressions(dim)%character_len=0
            end select
            call verify_frontend(source,p,d)
            call expect((d%code==0).eqv.(mutation==0),'adapter mutation guard')
            d=diagnostic_t();call execute_program(p,d,max_steps=20000_int64)
            call expect((d%code==0).eqv.(mutation==0),'runtime mutation guard')
            k=p%ne+1;p%ne=k;p%expressions(k)=expr_t(kind=ex_call,op='kind',typ=ty_integer,args=[e])
            d=diagnostic_t();call evaluate_constant(p,k,v,d)
            call expect((d%code==0).eqv.(mutation==0),'KIND mutation guard')
            if(mutation==0)call expect(v%i==1,'default CHARACTER kind')
        end do
    end do
    ! Independent position arithmetic across non-square extents and both axes.
    do r=1,4
      do cols=1,4
        items=''
        do j=1,r*cols
            write(num,'(i0)')j
            if(j>1)items=items//','
            items=items//trim(num)
        end do
        do dim=1,2
          do shift=-6,6
            source='program p'//nl//'print *,eoshift(reshape(['//items//'],['//itoa(r)//','//itoa(cols)// &
                ']),'//itoa(shift)//',boundary=-9,dim='//itoa(dim)//')'//nl//'end program'
            call parse_subset(source,p,d);call expect(d%code==0,'matrix parse')
            e=0
            do j=1,p%ne
                if(p%expressions(j)%op=='eoshift')e=j
            end do
            call expect(e>0,'matrix expression')
            call verify_frontend(source,p,d);call expect(d%code==0,'matrix adapter')
            call evaluate_constant_array(p,e,values,d);call expect(d%code==0,'matrix evaluation')
            call expect(size(values)==r*cols,'matrix result size')
            axis=r;if(dim==2)axis=cols
            do j=1,r*cols
                row=modulo(j-1,r);col=(j-1)/r;pos=row
                if(dim==2)pos=col
                pos=pos+shift;wanted=-9
                if(pos>=0.and.pos<axis)then
                    if(dim==1)row=pos
                    if(dim==2)col=pos
                    wanted=row+col*r+1
                end if
                call expect(values(j)%tag==ty_integer.and.values(j)%i==wanted,'independent end-shift element')
            end do
          end do
        end do
      end do
    end do
    ! Full machine minimum is saturated before adding or negating it.
    source='program p'//nl//'integer(8)::s'//nl//'s=-huge(0_8)-1_8'//nl// &
        'if(any(eoshift([1,2,3],s,-9)/=-9))error stop 1'//nl//'end program'
    call parse_subset(source,p,d);call expect(d%code==0,'machine-min parse')
    call verify_frontend(source,p,d);call expect(d%code==0,'machine-min adapter')
    call execute_program(p,d);call expect(d%code==0,'machine-min saturated result')
    ! KIND does not invoke ARRAY, SHIFT, BOUNDARY or DIM functions.
    source='program p'//nl//'if(kind(eoshift(draw(),amount(),edge(),axis()))/=8)error stop 1'//nl// &
        'contains'//nl//'function draw() result(a)'//nl//'real(8)::a(3)'//nl// &
        'call random_number(a)'//nl//'end function'//nl// &
        'integer function amount()'//nl//'real(8)::x'//nl//'call random_number(x)'//nl//'amount=1'//nl//'end function'//nl// &
        'real(8) function edge()'//nl//'call random_number(edge)'//nl//'end function'//nl// &
        'integer function axis()'//nl//'real(8)::x'//nl//'call random_number(x)'//nl//'axis=1'//nl//'end function'//nl//'end program'
    call parse_subset(source,p,d);call expect(d%code==0,'KIND effects parse')
    state=104729_int64;call execute_program(p,d,random_state=state)
    call expect(d%code==0,'KIND effects execution');call expect(state==104729_int64,'KIND no draws')
    ! Evaluation invokes each control only once, not per selected result element.
    source=source(:index(source,'if(kind')-1)//'real(8)::a(3)'//nl//'a=eoshift(draw(),amount(),edge(),axis())'//nl// &
        source(index(source,'contains'):)
    call parse_subset(source,p,d);call expect(d%code==0,'effects parse')
    expected_state=104729_int64
    do j=1,6
        expected_state=modulo(expected_state*16807_int64,2147483647_int64)
    end do
    state=104729_int64;call execute_program(p,d,random_state=state)
    call expect(d%code==0,'effects execution');call expect(state==expected_state,'exactly six random draws')
    ! Shared DAG is legal; an indirect operand cycle fails without stack overflow.
    source='program p'//nl//'print *,kind(eoshift([1,2],1,-9))'//nl//'end program'
    call parse_subset(source,p,d);call expect(d%code==0,'DAG parse')
    e=0
    do j=1,p%ne
        if(p%expressions(j)%op=='eoshift')e=j
    end do
    p%expressions(e)%args(3)=p%expressions(e)%args(2)
    call execute_program(p,d);call expect(d%code==0,'shared DAG accepted')
    a=p%expressions(e)%args(1);p%expressions(a)%args(1)=e
    d=diagnostic_t();call execute_program(p,d,max_steps=20000_int64)
    call expect(d%code==2,'indirect cycle rejected')
    print *,'PASS: EOSHIFT native assertions:',checks
contains
    function itoa(n)result(s)
        integer,intent(in)::n
        character(:),allocatable::s
        character(32)::b
        write(b,'(i0)')n;s=trim(b)
    end function
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(.not.ok)then
            print *,'FAIL',trim(label),'form/mutation',form,mutation,'code',d%code
            if(allocated(d%message))print *,d%message
            error stop 1
        end if
    end subroutine
end program
