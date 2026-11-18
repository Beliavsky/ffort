program p
implicit none
character(4),allocatable::x(:)
integer::n
allocate(x(-1:2))
x=['abcd','efgh','ijkl','mnop']
n=4
call outer(n,x)
if(n/=1.or.len(x)/=4.or.size(x)/=2) error stop 1
print '(a)',x(1)
print '(a)',x(2)
contains
subroutine outer(n,a)
integer,intent(inout)::n
character(len=n),allocatable,intent(inout)::a(:)
call inner(n,a)
end subroutine
subroutine inner(n,a)
integer,intent(inout)::n
character(len=n),allocatable,intent(inout)::a(:)
n=1
a=a(0:1)
end subroutine
end program
