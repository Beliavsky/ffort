program main
implicit none
real(8)::t,u,z,n,h
integer::e
t=tiny(0.0_8)
u=t*epsilon(t)
z=-0.0_8
n=nearest(z,1.0_8)
h=huge(t)
e=exponent(u)
write(*,'("subnormal:",6(1x,i0))')e,merge(1,0,fraction(u)==0.5_8), &
merge(1,0,set_exponent(0.5_8,-1073)==u),merge(1,0,spacing(u)==t), &
merge(1,0,n==u),merge(1,0,nearest(0.0_8,-1.0_8)==-u)
write(*,'("zero:",5(1x,i0))')int(sign(1.0_8,fraction(z))),exponent(z), &
int(sign(1.0_8,set_exponent(z,huge(0_8)))), &
int(sign(1.0_8,nearest(-u,1.0_8))),int(sign(1.0_8,nearest(u,-1.0_8)))
write(*,'("normal:",6(1x,i0))')merge(1,0,nearest(t,-1.0_8)==t-u), &
merge(1,0,spacing(t)==t),merge(1,0,set_exponent(fraction(h),exponent(h))==h), &
merge(1,0,nearest(h,-1.0_8)<h),merge(1,0,spacing(h)==2.0_8**971), &
merge(1,0,u>0)
print *,u,spacing(h)
end program
