module original_string_integer
implicit none
contains
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
program test_original
use original_string_integer
implicit none
character(20)::words(3)
integer::j
print '(a)', '<'//trim(str_int(0))//'>'
print '(a)', '<'//trim(str_int(1234))//'>'
print '(a)', '<'//trim(str_int(-35,ndigits=5))//'>'
print '(a)', '<'//trim(str_int(-35,ndigits=1))//'>'
print '(a)', '<'//trim(str_int(17,prefix='id='))//'>'
print '(a)', '<'//trim(str_int(7,ndigits=2,prefix='v='))//'>'
print '(a)', '<'//trim(str_int(2147483647))//'>'
words=str_int([0,7,-12],ndigits=3)
do j=1,3
print '(a)', '<'//trim(words(j))//'>'
end do
end program
