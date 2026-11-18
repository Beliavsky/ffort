program p
print *,lgt(7)
contains
integer function lgt(x)
integer,intent(in)::x
lgt=x+1
end function
end program
