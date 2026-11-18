program p
implicit none
call f([integer(8)::])
contains
subroutine f(a)
integer,intent(in)::a(:)
end subroutine
end program
