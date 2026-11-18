! SPDX-License-Identifier: MIT
program test_character_intrinsics
    use, intrinsic :: iso_fortran_env, only: int64
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: evaluate_constant,execute_program
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    type(value_t)::v
    character(*),parameter::nl=new_line('a')
    character(:),allocatable::source,op,call_text,expression
    integer::family,mutation,mode,e,j,k,checks,form,last
    checks=0
    do family=1,4
        select case(family)
        case(1);op='index';call_text="index(kind=8,back=.true.,substring='a',string='aba')"
        case(2);op='len_trim';call_text="len_trim(kind=8,string=' a ')"
        case(3);op='adjustl';call_text="adjustl(string=' a ')"
        case(4);op='adjustr';call_text="adjustr(string=' a ')"
        end select
        source='program p'//nl//'print *,'//call_text//nl//'end program'
        do mutation=0,18
            call parse_subset(source,p,d)
            call expect(d%code==0,'parse')
            e=0
            do j=1,p%ne
                if(p%expressions(j)%op==op)e=j
            end do
            call expect(e>0,'call found')
            last=size(p%expressions(e)%args)
            select case(mutation)
            case(1);p%expressions(e)%typ=ty_logical
            case(2);p%expressions(e)%real_kind=12-p%expressions(e)%real_kind
            case(3);p%expressions(e)%rank=1;p%expressions(e)%extent=0
            case(4);p%expressions(e)%args(1)=0
            case(5);p%expressions(e)%args=[integer::]
            case(6);p%expressions(e)%args(1)=p%ne+1
            case(7);p%expressions(p%expressions(e)%args(1))%typ=ty_integer
            case(8);p%expressions(e)%args=[p%expressions(e)%args,p%expressions(e)%args]
            case(9);p%expressions(e)%extent=1
            case(10);p%expressions(e)%dims=[1_int64,2_int64,1_int64]
            case(11);p%expressions(e)%args(1)=e
            case(12);deallocate(p%expressions(e)%args)
            case(13);p%expressions(e)%real_kind=16
            case(14);p%expressions(e)%intrinsic_mask=2
            case(15)
                if(family<=2) then
                    k=p%expressions(e)%args(last);p%expressions(k)%value%i=16
                else
                    p%expressions(e)%character_len=4
                end if
            case(16)
                if(family<=2) then
                    k=p%expressions(e)%args(last);p%expressions(k)%rank=1;p%expressions(k)%extent=1
                else
                    p%expressions(p%expressions(e)%args(1))%real_kind=8
                end if
            case(17)
                if(family==1) then
                    p%expressions(p%expressions(e)%args(3))%typ=ty_integer
                else if(family==2) then
                    p%expressions(p%expressions(e)%args(2))%typ=ty_logical
                else
                    p%expressions(e)%character_len=-1
                end if
            case(18)
                if(family==1) then
                    p%expressions(p%expressions(e)%args(3))%real_kind=8
                else
                    p%expressions(p%expressions(e)%args(1))%rank=3
                end if
            end select
            call verify_frontend(source,p,d)
            call expect((d%code==0).eqv.(mutation==0),'adapter rejects mutation')
            do mode=1,2
                d=diagnostic_t()
                if(mode==1) then
                    call evaluate_constant(p,e,v,d)
                else
                    k=p%ne+1;p%ne=k
                    p%expressions(k)=expr_t(kind=ex_call,op='kind',typ=ty_integer,args=[e])
                    call evaluate_constant(p,k,v,d)
                end if
                call expect((d%code==0).eqv.(mutation==0),'runtime rejects mutation')
                if(mutation/=0)cycle
                if(mode==2) then
                    k=1
                    if(family<=2)k=8
                    call expect(v%tag==ty_integer.and.v%i==k,'KIND result')
                else
                    select case(family)
                    case(1);call expect(v%tag==ty_integer.and.v%i==3.and.v%real_kind==8,'INDEX value')
                    case(2);call expect(v%tag==ty_integer.and.v%i==2.and.v%real_kind==8,'LEN_TRIM value')
                    case(3);call expect(v%tag==ty_character.and.v%s=='a  ','ADJUSTL value')
                    case(4);call expect(v%tag==ty_character.and.v%s=='  a','ADJUSTR value')
                    end select
                end if
            end do
        end do
        do form=1,4
            call_text=op//'(z)'
            if(family==1)call_text="index(z,'a')"
            select case(form)
            case(1);expression=call_text
            case(2)
                expression='('//call_text//')'
                if(family<=2)expression=call_text//'+len_trim(z)'
                if(family>=3)expression=call_text//"//'x'"
            case(3)
                expression='len_trim('//call_text//')'
                if(family<=2)expression='sum('//call_text//')'
            case(4)
                expression='len('//call_text//')'
                if(family<=2)expression='abs(-'//call_text//')'
            end select
            source='program p'//nl//'character(3)::z(0)'//nl//'print *,'//expression//nl//'end program'
            do mutation=0,5
                call parse_subset(source,p,d)
                call expect(d%code==0,'empty parse')
                do j=1,p%ne
                    if(p%expressions(j)%op==op)then
                        e=j;exit
                    end if
                end do
                select case(mutation)
                case(1);p%expressions(e)%real_kind=16
                case(2);p%expressions(e)%typ=ty_logical
                case(3);p%expressions(e)%args=[p%expressions(e)%args,p%expressions(e)%args,p%expressions(e)%args]
                case(4);p%expressions(e)%rank=0
                case(5);p%expressions(e)%args(1)=e
                end select
                call execute_program(p,d)
                call expect((d%code==0).eqv.(mutation==0),'empty metadata validation')
            end do
        end do
    end do
    print *, 'PASS: character intrinsic assertions:',checks
contains
    subroutine expect(ok,label)
        logical,intent(in)::ok
        character(*),intent(in)::label
        checks=checks+1
        if(ok)return
        print *, 'FAIL: ',label,' intrinsic ',op,' mutation ',mutation,' mode ',mode,' form ',form
        if(allocated(d%message))print *,d%message
        error stop 1
    end subroutine
end program
