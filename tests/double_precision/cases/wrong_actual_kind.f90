program p
implicit none
double precision::x
x=identity(1.0)
print *,1
contains
doubleprecision function identity(y) result(z)
double precision,intent(in)::y
z=y
end function
end program
