program p
implicit none
double precision :: x
x=identity(2.25d0)
print *,kind(x),x
contains
doubleprecision function identity(y) result(z)
double precision,intent(in)::y
z=y
end function
end program
