program p
print *,llt(7)
contains
integer function llt(x)
integer,intent(in)::x
llt=x+1
end function
end program
