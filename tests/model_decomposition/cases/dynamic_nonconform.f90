program p
implicit none
real,allocatable::x(:)
integer,allocatable::i(:)
allocate(x(2));allocate(i(3));x=1.;i=2
print *,set_exponent(x,i)
end program
