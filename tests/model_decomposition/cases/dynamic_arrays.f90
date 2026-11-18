program p
implicit none
real,allocatable::x(:)
integer(8),allocatable::i(:)
allocate(x(3));allocate(i(3));x=[1.,2.,3.];i=[1_8,2_8,3_8]
print *,set_exponent(x,i),fraction(x),exponent(x)
end program
