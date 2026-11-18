program p
implicit none
print *,isnan(2)
contains
logical function isnan(x)
integer,intent(in)::x
isnan=x==2
end function
end program
