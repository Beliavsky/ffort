program p
implicit none
real::a,b
integer::i
call random_seed()
call random_number(a)
do i=1,3
call random_seed()
call random_number(b)
if(a/=b) error stop 1
end do
print '(a)','seed-ok'
end program
