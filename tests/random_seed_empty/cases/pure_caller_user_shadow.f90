program p
implicit none
integer::x
call wrapper(x)
print *,x
contains
pure subroutine wrapper(x)
integer,intent(out)::x
call random_seed(x)
end subroutine
pure subroutine random_seed(x)
integer,intent(out)::x
x=5
end subroutine
end program
