! SPDX-License-Identifier: MIT
program test_clock_samples
    use, intrinsic :: iso_fortran_env, only: int64,real32,real64
    use, intrinsic :: ieee_arithmetic, only: ieee_value,ieee_quiet_nan,ieee_positive_inf
    use fi_ir, only: value_t,ty_integer,ty_real
    use fi_clock
    implicit none
    type(clock_sample_t)::s
    type(value_t)::v(3)
    integer::checks,k,rk,mask,j,types(3),kinds(3),ck,which
    integer(int64)::limit,actual_limit
    logical::ok
    checks=0
    do k=4,8,4
        do rk=4,8,4
            do mask=0,7
                types=0;kinds=0
                do j=1,3
                    if(.not.btest(mask,j-1))cycle
                    types(j)=ty_integer;kinds(j)=k
                    if(j==2)then
                        types(j)=ty_real;kinds(j)=rk
                    end if
                end do
                ck=timing_request_kind(1,types,kinds)
                call expect(ck==4.or.ck==8,'legal request kind')
                limit=huge(0_int64);if(ck==4)limit=2147483647_int64
                do which=1,4
                    s=clock_sample_t(count=17_int64,rate=1000_int64,maximum=limit)
                    if(which==2)s%count=limit
                    if(which==3)s%count=0
                    if(which==4)s=clock_sample_t(count=-limit,rate=0_int64,maximum=0_int64)
                    call timing_sample_values(1,types,kinds,s,v,ok)
                    call expect(ok,'available boundary/wrap/unavailable accepted')
                    do j=1,3
                        if(types(j)==0)then
                            call expect(v(j)%tag==0,'omitted output remains empty')
                        else
                            call expect(v(j)%tag==types(j).and.v(j)%real_kind==kinds(j),'output kind and type')
                            if(j==1)then
                                actual_limit=huge(0_int64);if(kinds(j)==4)actual_limit=2147483647_int64
                                if(which==4)then
                                    call expect(v(j)%i==-actual_limit,'sentinel maps to COUNT kind')
                                else
                                    call expect(v(j)%i==s%count,'count exact')
                                end if
                            else if(j==2)then
                                call expect(v(j)%r==real(s%rate,real64),'real rate exact test value')
                            else
                                call expect(v(j)%i==s%maximum,'maximum exact')
                            end if
                        end if
                    end do
                end do
            end do
        end do
    end do
    types=[ty_integer,ty_integer,ty_integer];kinds=4
    do which=1,10
        s=clock_sample_t(count=1_int64,rate=1000_int64,maximum=2147483647_int64)
        select case(which)
        case(1);s%count=-1
        case(2);s%count=2147483648_int64
        case(3);s%rate=-1
        case(4);s%rate=2147483648_int64
        case(5);s%maximum=-1
        case(6);s%maximum=2147483648_int64
        case(7);s%rate=0
        case(8);s%cpu=1
        case(9);s%cpu=ieee_value(0.0_real64,ieee_quiet_nan)
        case(10);s%cpu=ieee_value(0.0_real64,ieee_positive_inf)
        end select
        call timing_sample_values(1,types,kinds,s,v,ok)
        call expect(.not.ok,'malformed clock sample rejected')
    end do
    kinds=[4,8,4];call expect(timing_request_kind(1,types,kinds)==0,'mixed INTEGER kinds rejected')
    kinds=4;types(2)=ty_real
    do j=1,3
        kinds(j)=2;call expect(timing_request_kind(1,types,kinds)==0,'unsupported kind rejected');kinds(j)=4
    end do
    types=0;kinds=0;kinds(2)=4
    call expect(timing_request_kind(1,types,kinds)==0,'absent slot metadata rejected')
    do k=4,8,4
        types=[ty_real,0,0];kinds=[k,0,0]
        do which=1,4
            s=clock_sample_t()
            select case(which)
            case(1);s%cpu=0
            case(2);s%cpu=1.23456789012345_real64
            case(3);s%cpu=-1
            case(4);s%cpu=real(huge(0.0_real32),real64)
            end select
            call timing_sample_values(2,types,kinds,s,v,ok)
            call expect(ok,'finite CPU sample accepted')
            call expect(v(1)%tag==ty_real.and.v(1)%real_kind==k,'CPU kind')
            if(k==4)then
                call expect(v(1)%r==real(real(s%cpu,real32),real64),'CPU REAL32 rounding')
            else
                call expect(v(1)%r==s%cpu,'CPU REAL64 preservation')
            end if
        end do
        do which=1,4
            s=clock_sample_t()
            select case(which)
            case(1);s%cpu=ieee_value(0.0_real64,ieee_quiet_nan)
            case(2);s%cpu=ieee_value(0.0_real64,ieee_positive_inf)
            case(3);s%count=1
            case(4);s%rate=1
            end select
            call timing_sample_values(2,types,kinds,s,v,ok)
            call expect(.not.ok,'invalid CPU sample rejected')
        end do
        call sample_processor_clock(2,k,s,ok)
        call expect(ok,'real host CPU call')
        call timing_sample_values(2,types,kinds,s,v,ok)
        call expect(ok,'real host CPU contract, including negative unavailable value')
        types=ty_integer;kinds=k
        call sample_processor_clock(1,k,s,ok)
        call expect(ok,'real host SYSTEM_CLOCK call')
        call timing_sample_values(1,types,kinds,s,v,ok)
        call expect(ok,'real host SYSTEM_CLOCK contract')
    end do
    types=[ty_real,0,0];kinds=[4,0,0];s=clock_sample_t(cpu=huge(0.0_real64))
    call timing_sample_values(2,types,kinds,s,v,ok)
    call expect(.not.ok,'CPU narrowing overflow rejected')
    s=clock_sample_t(cpu=-tiny(0.0_real64))
    call timing_sample_values(2,types,kinds,s,v,ok)
    call expect(.not.ok,'negative unavailable sentinel cannot round to zero')
    call expect(timing_request_kind(0,types,kinds)==0,'invalid mode')
    print '(a,i0)', 'clock sample checks: ',checks
contains
    subroutine expect(condition,label)
        logical,intent(in)::condition
        character(*),intent(in)::label
        checks=checks+1
        if(.not.condition)then
            print *, 'FAIL ',label
            stop 1
        end if
    end subroutine
end program
