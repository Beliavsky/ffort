program p
implicit none
call f([logical::])
contains
subroutine f(a)
integer,intent(in)::a(:)
end subroutine
end program
