module m
implicit none
contains
elemental function strip(xx,xchar) result(yy)
! replace trailing characters of xx that equal xchar with a space
character (len=*), intent(in) :: xx
character (len=1), intent(in) :: xchar
character (len=len(xx))       :: yy
integer                       :: i,nlen
yy = xx
nlen = len(xx)
if (nlen < 1) return
do i=nlen,1,-1
   if (yy(i:i) == " ") cycle
   if (yy(i:i) == xchar) then
      yy(i:i) = " "
   else
      return
   end if
end do
end function strip
end module
program test
use m
implicit none
character(4)::arr(3)
if(strip('abc***  ','*')/='abc     ') error stop 1
if(strip('','*')/='') error stop 2
if(strip(' abc ','x')/=' abc ') error stop 3
arr=strip(['a***','b** ','c   '],'*')
if(any(arr/=['a   ','b   ','c   '])) error stop 4
print '(a)',strip('abc***  ','*')
end program
