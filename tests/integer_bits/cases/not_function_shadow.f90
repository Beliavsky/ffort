program p
print *,not(7)
contains
integer function not(x)
integer,intent(in)::x
not=x+1
end function
end program
