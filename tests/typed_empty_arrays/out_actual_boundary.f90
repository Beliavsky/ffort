program p
implicit none
call f([integer::])
contains
subroutine f(a)
integer,intent(out)::a(:)
a=1
end subroutine
end program
