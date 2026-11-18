module m
contains
subroutine f(x,z)
character(*),intent(in)::x,z
character(8)::a(2)
a=[x,z]
print "(a)","UNREACHED"
end subroutine
end module
program p
use m
call f("a","bb")
end program
