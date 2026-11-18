program p
implicit none
real(8)::x,a(3),z=0.0_8
real(8),allocatable::b(:)
integer::i
print *,kind(real(x)),kind(real(a,8)),kind(real(i,8))
print *,kind(real(b,4)),kind(real(1.0_8/z,4))
end program p
