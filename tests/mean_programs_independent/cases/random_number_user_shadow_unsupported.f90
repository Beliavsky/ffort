program p
implicit none
real::aa
call random_number(aa)
print *,aa
contains
subroutine random_number(xx)
real,intent(out)::xx
xx=0.25
end subroutine
end program p
