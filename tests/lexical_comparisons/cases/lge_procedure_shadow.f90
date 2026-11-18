program p
print *,lge(7)
contains
integer function lge(x)
integer,intent(in)::x
lge=x+1
end function
end program
