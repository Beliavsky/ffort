program p
implicit none
real::aa
aa=1
call fill(aa)
contains
subroutine fill(xx)
real,intent(in)::xx
call random_number(xx)
end subroutine
end program p
