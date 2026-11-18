program p
implicit none
real, save :: a(3)=[-1.0,0.0,1.0]
real(kind=8)::b(3)
b=acos(real(a,8))
print '(3(l1,1x))',b(1)>3.14_8,b(2)>1.57_8,b(3)==0.0_8
end program
