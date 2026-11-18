program p
implicit none
real::aa
call fill(aa)
contains
elemental subroutine fill(xx)
real,intent(out)::xx
call random_number(xx)
end subroutine
end program p
