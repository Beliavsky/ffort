program p
implicit none

print *,parity([spacing(1.)>0,nearest(1.,1.)>1.]),epsilon(nearest(1.,1.0))==epsilon(1.)
end program
