program p
print *,findloc(2)
contains
integer function findloc(x)
integer,intent(in)::x
findloc=x+1
end function
end program
