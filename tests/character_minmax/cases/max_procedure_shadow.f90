program p
print *,max(7)
contains
integer function max(x)
integer,intent(in)::x
max=x+1
end function
end program
