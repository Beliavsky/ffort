module utility_slice
implicit none
private
public :: dp,long_int,i64,default_integer
integer,parameter :: dp=selected_real_kind(15,307)
integer,parameter :: long_int=selected_int_kind(15)
integer,parameter :: i64=long_int
integer,parameter :: itrue=1
integer,parameter :: ifalse=0
real(dp),parameter :: tiny_real=1.0d-10
contains
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
program test_slice
use utility_slice
implicit none
print *, default_integer(10),default_integer(10,20)
end program
