program p
implicit none

real,target::a(3)
real,pointer::q(:)
a=1;q=>a
print *,nearest(q,1d0)>q,spacing(q)==epsilon(1.)
end program
