program p
implicit none
real(8) :: x(-1:1,2:3),z(0),unknown
integer(8) :: y(3,2)
x=reshape([-2.9d0,-0.5d0,0.0d0,0.5d0,1.9d0,2.5d0],[3,2])
y=nint(x,kind=8)
print *,y,ceiling(x(:,3:2:-1),kind=8),floor(x(-1:1:2,2:3))
print *,sum(nint(z,8)),size(floor(z)),sum(ceiling(z)),size(log10(z))
print *,size(unknown+nint(z)),size(log10(z)+unknown)
print *,log10(abs(x)+1.0d0)
end program
