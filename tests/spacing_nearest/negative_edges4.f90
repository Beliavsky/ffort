program p
implicit none

real(4)::x
x=huge(1.0_4)
print *,spacing(-1.0_4)==spacing(1.0_4),nearest(x,-1.0_4)<x,nearest(-x,1.0_4)>-x
print *,spacing(x)>0,spacing(x)==spacing(-x)
end program
