! Synthetic minimal module and driver; original procedure bodies below retain source bytes.
module original_names_slice
implicit none
interface default
 module procedure default_integer
end interface
contains
function variable_names(n,prefix,suffix,imin) result(names)
! construct variable names from integers
integer          , intent(in)           :: n
character (len=*), intent(in), optional :: prefix
character (len=*), intent(in), optional :: suffix
integer          , intent(in), optional :: imin
character (len=100)                     :: names(n)
integer                                 :: i,j,imin_
imin_ = default(1,imin)
names = ""
do i=1,n
   j = imin_ + i - 1
   if (present(prefix)) names(i) = prefix
   names(i) = trim(names(i)) // str_int(j)
   if (present(suffix)) names(i) = trim(names(i)) // suffix
end do
end function variable_names
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
elemental function default_integer(def,opt) result(ii)
! return opt if it is present, otherwise def (integer arguments and result)
integer, intent(in)           :: def
integer, intent(in), optional :: opt
integer                       :: ii
if (present(opt)) then
   ii = opt
else
   ii = def
end if
end function default_integer
end module
program original_names_driver
use original_names_slice
implicit none
character(100) :: names(4),defaults(2),empty(0)
integer :: i
names=variable_names(4,prefix='v',suffix='_x',imin=-2)
do i=1,4
 print '(a)',trim(names(i))
end do
defaults=variable_names(2)
print '(a)',trim(defaults(1))
print '(a)',trim(defaults(2))
empty=variable_names(n=0,suffix='!')
print *,shape(empty),len(empty),size(empty)
end program
