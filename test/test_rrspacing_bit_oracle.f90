! SPDX-License-Identifier: MIT
program test_rrspacing_bit_oracle
    use, intrinsic::iso_fortran_env,only:int32,int64,real32,real64
    use, intrinsic::ieee_arithmetic,only:ieee_is_negative
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_runtime,only:evaluate_constant
    implicit none
    type(program_t)::p
    type(diagnostic_t)::d
    type(value_t)::v
    integer::k,bits,emax,step,ef,j,sgn,checks
    integer(int64)::mant,masks(5),word,wanted,limit
    integer(int32)::word4
    real(real32)::x4
    real(real64)::x8
    character(80)::literal
    character(*),parameter::nl=new_line('a')
    character(:),allocatable::source
    checks=0
    do k=4,8,4
      bits=23;emax=254;step=17
      if(k==8)then
        bits=52;emax=2046;step=127
      end if
      limit=ishft(1_int64,bits)
      masks=[0_int64,1_int64,limit/3,limit-2,limit-1]
      do ef=0,emax+step,step
        do j=1,size(masks)
          mant=masks(j);word=ior(ishft(int(min(ef,emax),int64),bits),mant)
          wanted=mant
          if(ef>0)wanted=wanted+limit
          if(ef==0.and.wanted/=0)then
            do while(wanted<limit)
              wanted=wanted*2
            end do
          end if
          do sgn=0,1
            if(k==4)then
              word4=int(word,int32)
              if(sgn==1)word4=ibset(word4,31)
              x4=transfer(word4,x4)
              write(literal,'(es26.17e3)')real(x4,real64)
              source='program p'//nl//'print *,rrspacing('//trim(adjustl(literal))//'_4)'//nl//'end program'
            else
              if(sgn==1)word=ibset(word,63)
              x8=transfer(word,x8)
              write(literal,'(es26.17e3)')x8
              source='program p'//nl//'print *,rrspacing('//trim(adjustl(literal))//'_8)'//nl//'end program'
            end if
            call parse_subset(source,p,d)
            call expect(d%code==0,'parse')
            call evaluate_constant(p,p%code(1)%items(1),v,d)
            call expect(d%code==0,'evaluate')
            call expect(v%tag==ty_real.and.v%real_kind==k,'metadata')
            call expect(v%r==real(wanted,real64),'independent normalized-significand oracle')
            if(wanted==0)call expect(.not.ieee_is_negative(v%r),'positive zero')
          end do
        end do
      end do
    end do
    print *,'PASS: RRSPACING independent bit-pattern assertions:',checks
contains
    subroutine expect(ok,label)
      logical,intent(in)::ok
      character(*),intent(in)::label
      checks=checks+1
      if(ok)return
      print *,k,ef,j,sgn,label
      print *,source
      if(allocated(d%message))print *,d%message
      error stop 1
    end subroutine
end program
