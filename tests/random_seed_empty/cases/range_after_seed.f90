program p
implicit none
real(8)::a(2,3,2)
integer::i,j,k
call random_seed()
call random_number(a)
do k=1,2
do j=1,3
do i=1,2
if(a(i,j,k)<0d0.or.a(i,j,k)>=1d0) error stop 1
end do
end do
end do
print '(a)','seed-ok'
end program
