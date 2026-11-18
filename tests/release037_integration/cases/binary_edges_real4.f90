program main
implicit none
real(4)::t,u,z,n,h
integer::e
t=tiny(0.0_4)
u=t*epsilon(t)
z=-0.0_4
n=nearest(z,1.0_4)
h=huge(t)
e=exponent(u)
write(*,'("subnormal:",6(1x,i0))')e,merge(1,0,fraction(u)==0.5_4), &
merge(1,0,set_exponent(0.5_4,-148)==u),merge(1,0,spacing(u)==t), &
merge(1,0,n==u),merge(1,0,nearest(0.0_4,-1.0_4)==-u)
write(*,'("zero:",5(1x,i0))')int(sign(1.0_4,fraction(z))),exponent(z), &
int(sign(1.0_4,set_exponent(z,huge(0_8)))), &
int(sign(1.0_4,nearest(-u,1.0_4))),int(sign(1.0_4,nearest(u,-1.0_4)))
write(*,'("normal:",6(1x,i0))')merge(1,0,nearest(t,-1.0_4)==t-u), &
merge(1,0,spacing(t)==t),merge(1,0,set_exponent(fraction(h),exponent(h))==h), &
merge(1,0,nearest(h,-1.0_4)<h),merge(1,0,spacing(h)==2.0_4**104), &
merge(1,0,u>0)
print *,u,spacing(h)
end program
