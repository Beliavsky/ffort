program p
print *,iand(7)
contains
integer function iand(x)
integer,intent(in)::x
iand=x+1
end function
end program
