module m
implicit none
interface repeat
module procedure repeat_char
end interface
contains
pure function repeat_char(n,xx) result(yy)
! repeat 1-D array of character variables with xx repeated n times
integer          , intent(in) :: n
character (len=*), intent(in) :: xx
character (len=len(xx))       :: yy(n)
integer                       :: i
yy = (/(xx,i=1,n)/)
end function repeat_char

elemental function str_int(i,ndigits,prefix) result(ch)
! convert integer to character
integer         ,intent(in)           :: i
integer         ,intent(in), optional :: ndigits
character(len=*),intent(in), optional :: prefix
character(len=20)  :: ch
integer            :: temp, digit,nlen,nzeros
ch = ""
temp = abs(i)
do
   digit = mod(temp,10) + 1
   ch = "0123456789"(digit:digit) // ch
   temp = temp/10
   if (temp == 0) exit  ! I'd sure like an UNTIL statement
end do
if (present(ndigits)) then
   nlen = len_trim(ch)
   nzeros = ndigits - nlen
   if (nzeros > 0) ch = repeat("0",nzeros) // ch
end if
if (i < 0) ch = "-" // trim(ch)
if (present(prefix)) ch = trim(prefix) // trim(ch)
end function str_int
end module
program main
use m
implicit none
print "(a)",trim(str_int(42,ndigits=5))
print "(a)",repeat("x",3)
print "(a)",repeat(2,"q")
end program
