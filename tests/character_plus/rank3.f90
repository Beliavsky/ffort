module original_character_plus
implicit none
interface operator(+)
module procedure char_plus_char,char_plus_int
end interface
interface operator(.plus.)
module procedure char_plus_char,char_plus_int
end interface
interface str
module procedure str_int
end interface
contains
elemental function char_plus_char(c1,c2) result(c12)
! trim two strings and add them
character (len=*),   intent(in) :: c1,c2
character (len=len(c1)+len(c2)) :: c12
c12 = trim(c1) // trim(c2)
end function char_plus_char

elemental function char_plus_int(c1,i) result(c12)
! add a string to an integer
character (len=*),   intent(in) :: c1
integer          ,   intent(in) :: i
character (len=*), parameter :: cdelim_ = "_"
character (len=len(c1)+len(cdelim_)+20) :: c12
c12 = trim(c1) // cdelim_ // trim(str(i))
end function char_plus_int

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
program p
use original_character_plus
implicit none
character(1)::a(2,2,2)
integer::b(2,2,2)
a="z"
b=1
print '(a,"|")',a+b
end program
