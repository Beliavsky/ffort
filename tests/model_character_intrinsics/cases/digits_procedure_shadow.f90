program p
implicit none
print *,digits(2)
contains
integer function digits(x)
integer,intent(in)::x
digits=x+1
end function
end program
