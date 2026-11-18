program p
print *,ieor(7)
contains
integer function ieor(x)
integer,intent(in)::x
ieor=x+1
end function
end program
