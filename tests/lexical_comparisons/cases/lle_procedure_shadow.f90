program p
print *,lle(7)
contains
integer function lle(x)
integer,intent(in)::x
lle=x+1
end function
end program
