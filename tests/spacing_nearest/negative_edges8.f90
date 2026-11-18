program p
implicit none

real(8)::x
x=huge(1.0_8)
print *,spacing(-1.0_8)==spacing(1.0_8),nearest(x,-1.0_8)<x,nearest(-x,1.0_8)>-x
print *,spacing(x)>0,spacing(x)==spacing(-x)
end program
