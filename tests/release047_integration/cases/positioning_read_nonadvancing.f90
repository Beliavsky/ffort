module types
implicit none
type::dt
integer::a=7
real::y=2.5
end type
end module
program p
use types
implicit none
type(dt)::x
integer::u,n
u=27
write(*,'(a,t2,a)',advance='no')'ABCD','x'
read(u,*)n
write(*,'(tr1,i1)')n
print '(i1)',x%a
end program
