module utility_slice
implicit none
private
public :: dp,long_int,i64,if_else_real,if_else_int,int_tf ,if_else
integer,parameter :: dp=selected_real_kind(15,307)
integer,parameter :: long_int=selected_int_kind(15)
integer,parameter :: i64=long_int
integer,parameter :: itrue=1
integer,parameter :: ifalse=0
real(dp),parameter :: tiny_real=1.0d-10
interface if_else
module procedure if_else_real,if_else_int
end interface
contains
elemental function if_else_real(tf,xtrue,xfalse) result(xx)
logical      , intent(in) :: tf
real(kind=dp), intent(in) :: xtrue,xfalse
real(kind=dp)             :: xx
if (tf) then
   xx = xtrue
else
   xx = xfalse
end if
end function if_else_real

elemental function if_else_int(tf,itrue,ifalse) result(ii)
logical      , intent(in) :: tf
integer      , intent(in) :: itrue,ifalse
integer                   :: ii
if (tf) then
   ii = itrue
else
   ii = ifalse
end if
end function if_else_int

elemental function int_tf(tf) result(i)
! convert logical variable to integer
logical, intent(in) :: tf
integer             :: i
if (tf) then
   i = itrue
else
   i = ifalse
end if
end function int_tf

end module
program test_slice
use utility_slice
implicit none
print *, if_else(.true.,1.0_dp,0.0_dp),if_else(.false.,1.0_dp,0.0_dp)
print *, if_else([.true.,.false.],10,20)
print *, int_tf([.true.,.false.,.true.])
end program
