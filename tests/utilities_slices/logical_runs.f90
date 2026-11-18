module utility_slice
implicit none
private
public :: dp,long_int,i64,max_consecutive,first_true,first_false,last_true
integer,parameter :: dp=selected_real_kind(15,307)
integer,parameter :: long_int=selected_int_kind(15)
integer,parameter :: i64=long_int
integer,parameter :: itrue=1
integer,parameter :: ifalse=0
real(dp),parameter :: tiny_real=1.0d-10
contains
function max_consecutive(tf) result(nmax)
logical, intent(in) :: tf(:)
integer             :: nmax
integer             :: i,ntrue
nmax = 0
ntrue = 0
do i=1,size(tf)
   if (tf(i)) then
      ntrue = ntrue + 1
   else
      ntrue = 0
   end if
   nmax = max(nmax,ntrue) 
end do
end function max_consecutive

pure function first_true(tf) result(i1)
! return the location of the first true element in tf(:), 0 if none true
logical, intent(in) :: tf(:)
integer             :: i1
integer             :: i
i1 = 0
do i=1,size(tf)
   if (tf(i)) then
      i1 = i
      return
   end if
end do
end function first_true

pure function first_false(tf) result(i1)
! return the location of the first false element in tf(:), 0 if all .true.
logical, intent(in) :: tf(:)
integer             :: i1
integer             :: i
i1 = 0
do i=1,size(tf)
   if (.not. tf(i)) then
      i1 = i
      return
   end if
end do
end function first_false

pure function last_true(tf) result(i1)
! return position of last true element of tf(:), 0 if no true elements
logical, intent(in) :: tf(:)
integer             :: i1
integer             :: i
i1 = 0
do i=size(tf),1,-1
   if (tf(i)) then
      i1 = i
      return
   end if
end do
end function last_true

end module
program test_slice
use utility_slice
implicit none
print *, max_consecutive([1,1,0,0,0,1,1,1,0]>0)
print *, max_consecutive([1,1,1]>0),max_consecutive([0,0,0]>0)
print *, first_true([.false.,.true.,.false.]),first_false([.true.,.true.,.false.])
print *, last_true([.true.,.false.,.true.]),first_true([.false.,.false.])
end program
