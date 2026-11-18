program p
implicit none
real::a(2,2)
a=reshape([0.,30.,45.,60.],[2,2])
print *,tand(a)
end program
