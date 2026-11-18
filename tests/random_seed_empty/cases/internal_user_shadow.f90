program p
implicit none
integer::x
call random_seed(x)
print *,x
contains
pure subroutine random_seed(x)
integer,intent(out)::x
x=9
end subroutine
end program
