! SPDX-License-Identifier: MIT
! Read-only host clocks plus a deterministic sample-to-values boundary.
! Ordinary execution always calls sample_processor_clock. Tests may construct
! samples directly, but no clock injection is exposed through execution or CLI.
module fi_clock
    use, intrinsic :: iso_fortran_env, only:int64,real32,real64
    use, intrinsic :: ieee_arithmetic, only:ieee_is_finite
    use fi_ir, only:value_t,ty_integer,ty_real
    implicit none
    private
    public :: clock_sample_t, timing_request_kind, sample_processor_clock, timing_sample_values
    type :: clock_sample_t
        integer(int64)::count=0_int64,rate=0_int64,maximum=0_int64
        real(real64)::cpu=0.0_real64
    end type
contains
    integer function timing_request_kind(mode,types,kinds) result(clock_kind)
        integer,intent(in)::mode,types(3),kinds(3)
        integer::j,integer_kind
        clock_kind=0;integer_kind=0
        if(mode==2)then
            if(types(1)/=ty_real.or.(kinds(1)/=4.and.kinds(1)/=8))return
            if(any(types(2:)/=0).or.any(kinds(2:)/=0))return
            clock_kind=kinds(1);return
        end if
        if(mode/=1)return
        do j=1,3
            if(types(j)==0)then
                if(kinds(j)/=0)return
                cycle
            end if
            if(kinds(j)/=4.and.kinds(j)/=8)return
            if(j==2)then
                if(types(j)/=ty_integer.and.types(j)/=ty_real)return
            else
                if(types(j)/=ty_integer)return
            end if
            if(types(j)==ty_integer)then
                if(integer_kind/=0.and.integer_kind/=kinds(j))return
                integer_kind=kinds(j)
            end if
        end do
        ! Documented processor selection, matching GNU's bounded kind4/8
        ! behavior: a present lower-kind REAL rate also selects the kind4 clock.
        clock_kind=8
        if(all(types==0).or.any(kinds==4))clock_kind=4
    end function
    subroutine sample_processor_clock(mode,clock_kind,sample,ok)
        integer,intent(in)::mode,clock_kind
        type(clock_sample_t),intent(out)::sample
        logical,intent(out)::ok
        integer::c4,r4,m4
        integer(int64)::c8,r8,m8
        real(real32)::cpu4
        real(real64)::cpu8
        sample=clock_sample_t();ok=.false.
        if(clock_kind/=4.and.clock_kind/=8)return
        select case(mode)
        case(1)
            if(clock_kind==4)then
                call system_clock(c4,r4,m4)
                sample%count=int(c4,int64);sample%rate=int(r4,int64);sample%maximum=int(m4,int64)
            else
                call system_clock(c8,r8,m8)
                sample%count=c8;sample%rate=r8;sample%maximum=m8
            end if
        case(2)
            if(clock_kind==4)then
                call cpu_time(cpu4);sample%cpu=real(cpu4,real64)
            else
                call cpu_time(cpu8);sample%cpu=cpu8
            end if
        case default
            return
        end select
        ok=.true.
    end subroutine
    subroutine timing_sample_values(mode,types,kinds,sample,values,ok)
        integer,intent(in)::mode,types(3),kinds(3)
        type(clock_sample_t),intent(in)::sample
        type(value_t),intent(out)::values(3)
        logical,intent(out)::ok
        integer::clock_kind,j
        integer(int64)::limit,n,output_limit
        real(real64)::r
        logical::unavailable
        values=value_t();ok=.false.
        clock_kind=timing_request_kind(mode,types,kinds)
        if(clock_kind==0)return
        if(.not.ieee_is_finite(sample%cpu))return
        if(mode==2)then
            if(sample%count/=0.or.sample%rate/=0.or.sample%maximum/=0)return
            r=sample%cpu
            if(clock_kind==4)then
                if(r>real(huge(0.0_real32),real64).or.r< -real(huge(0.0_real32),real64))return
                r=real(real(r,real32),real64)
                if(sample%cpu<0.0_real64.and.r>=0.0_real64)return
            end if
            if(.not.ieee_is_finite(r))return
            values(1)=value_t(tag=ty_real,real_kind=clock_kind,r=r);ok=.true.;return
        end if
        if(sample%cpu/=0.0_real64)return
        limit=huge(0_int64)
        if(clock_kind==4)limit=2147483647_int64
        unavailable=sample%rate==0.and.sample%maximum==0.and.sample%count==-limit
        if(.not.unavailable)then
            if(sample%rate<1.or.sample%rate>limit.or.sample%maximum<0.or.sample%maximum>limit.or. &
               sample%count<0.or.sample%count>sample%maximum)return
        end if
        do j=1,3
            if(types(j)==0)cycle
            select case(j)
            case(1)
                n=sample%count
                if(unavailable)then
                    output_limit=huge(0_int64)
                    if(kinds(j)==4)output_limit=2147483647_int64
                    n=-output_limit
                end if
            case(2);n=sample%rate
            case(3);n=sample%maximum
            end select
            if(types(j)==ty_integer)then
                output_limit=huge(0_int64)
                if(kinds(j)==4)output_limit=2147483647_int64
                if(n< -output_limit.or.n>output_limit)return
                values(j)=value_t(tag=ty_integer,real_kind=kinds(j),i=n)
            else
                r=real(n,real64)
                if(kinds(j)==4)r=real(real(n,real32),real64)
                if(.not.ieee_is_finite(r))return
                values(j)=value_t(tag=ty_real,real_kind=kinds(j),r=r)
            end if
        end do
        ok=.true.
    end subroutine
end module
