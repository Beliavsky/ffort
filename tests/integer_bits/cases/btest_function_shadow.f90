program p
print *,btest(7)
contains
integer function btest(x)
integer,intent(in)::x
btest=x+1
end function
end program
