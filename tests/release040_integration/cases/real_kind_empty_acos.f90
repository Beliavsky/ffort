program p
implicit none
real(kind=8) :: a(0),b(0)
b=acos(real(a,kind=8))
print '(3(i0,1x))',size(b),kind(b),kind(real(b))
end program
