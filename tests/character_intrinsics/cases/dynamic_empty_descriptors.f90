module m
contains
subroutine check(s)
character(*),intent(in)::s(:)
print *,len(adjustl(s)),len(adjustr(s)),size(adjustl(s)),sum(len_trim(s))
end subroutine
end module
program p
use m
character(5)::z(0)
call check(z)
end program
