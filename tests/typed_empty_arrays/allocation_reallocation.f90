program p
implicit none
integer,allocatable::a(:)
real(8),allocatable::b(:)
a=[3,4]
a=[integer::]
if(.not.allocated(a).or.size(a)/=0) error stop 1
b=[real(8)::]
if(.not.allocated(b).or.size(b)/=0) error stop 2
a=[1,2,3]
a=[integer::]
if(size(a)/=0) error stop 3
print *, 'PASS' 
end program
