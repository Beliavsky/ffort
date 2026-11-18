module texts
implicit none
character(*),parameter::prefix=trim("hello  ")
end module
program p
use texts,only:prefix
implicit none
character(*),parameter::message=prefix//"!"
print '(a)',message
call local()
contains
subroutine local()
character(*),parameter::inside=trim("local  ")//"!"
print '(a)',inside
end subroutine
end program
