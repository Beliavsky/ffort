program p
call f("zz","aaa")
contains
subroutine f(a,b)
character(*),intent(in)::a,b
write(*,"(a)")min(a,b)
write(*,'(*(i0,1x))')len(min(a,b))
end subroutine
end program
