program p
implicit none
double precision :: a(3)
call random_seed()
call random_number(a)
print '(3(l1,1x))',all(a>=0.0_8),all(a<1.0_8),kind(real(a,kind=4))==4
end program
