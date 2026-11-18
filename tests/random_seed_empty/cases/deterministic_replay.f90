program p
implicit none
real(8)::a(2),b(2)
call random_number(a)
call random_seed()
call random_number(b)
if(any(a/=b)) error stop 1
if(a(1)/=1760180303d0/2147483647d0) error stop 2
print '(a)','seed-ok'
end program
