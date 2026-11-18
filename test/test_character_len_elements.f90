! SPDX-License-Identifier: MIT
program test_character_len_elements
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::source='program main'//nl//'implicit none'//nl// &
        'character(4)::a(1,1,1)'//nl//'call work(a,1)'//nl//'contains'//nl// &
        'subroutine work(x,n)'//nl//'integer,intent(in)::n'//nl// &
        'character(*),intent(in)::x(:,:,:)'//nl// &
        'character(len=len(x(n,1,1)))::y'//nl// &
        'if(len(y)/=4) error stop 1'//nl//'end subroutine'//nl//'end program'
    type(program_t)::p
    type(diagnostic_t)::d
    integer::which,j,item,len_call,xsym,checks
    checks=0
    do which=1,13
        call parse_subset(source,p,d)
        call expect(d%code==0,'fixture parser')
        item=0;len_call=0
        do j=1,p%ne
            if(p%expressions(j)%kind==ex_element)item=j
        end do
        do j=1,p%ne
            if(p%expressions(j)%op/='len')cycle
            if(.not.allocated(p%expressions(j)%args))cycle
            if(size(p%expressions(j)%args)/=1)cycle
            if(p%expressions(j)%args(1)==item)len_call=j
        end do
        call expect(item>0.and.len_call>0,'fixture LEN element')
        xsym=p%expressions(item)%symbol
        select case(which)
        case(2);p%expressions(item)%character_len=2
        case(3);p%expressions(item)%left=0
        case(4);p%expressions(item)%right=0
        case(5);p%expressions(item)%third=0
        case(6);p%expressions(item)%third=p%ne+1
        case(7);p%expressions(item)%scope=999
        case(8);p%expressions(item)%kind=ex_variable
        case(9);p%expressions(p%expressions(item)%left)%typ=ty_real
        case(10);p%symbols(xsym)%is_optional=.true.
        case(11);p%expressions(len_call)%args=[p%ne+1]
        case(12);p%expressions(len_call)%args=[integer::]
        case(13);p%expressions(item)%stride=p%expressions(item)%left
        end select
        call verify_frontend(source,p,d)
        call expect((d%code==0).eqv.(which==1),'adapter')
        d=diagnostic_t()
        call execute_program(p,d)
        call expect((d%code==0).eqv.(which==1),'runtime')
        if(which/=1)checks=checks+2
    end do
    print *, 'PASS: CHARACTER LEN element specification mutations:',checks
contains
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        if(ok)return
        print *,label,' mutation=',which
        if(allocated(d%message))print *,d%message
        error stop 1
    end subroutine
end program
