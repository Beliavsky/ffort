program p
implicit none
print *,doubleprecision(3.0d0)
contains
doubleprecision function doubleprecision(x)
double precision,intent(in)::x
doubleprecision=x+1.0d0
end function
end program
