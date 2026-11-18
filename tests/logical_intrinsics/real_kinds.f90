program p
implicit none
real :: a(3)
real(8) :: b(3)
a=[-1.5,0.0,2.25]
b=dble(a)
print *,merge(a,0.5,a>0),kind(merge(a,0.5,.true.))
print *,merge(1.0d0,b,b<0),kind(merge(1.0d0,b,.false.))
print *,dble(-9223372036854775807_8-1_8),dble(0_8),dble(1.25)
end program
