program p
print *,min(7)
contains
integer function min(x)
integer,intent(in)::x
min=x+1
end function
end program
