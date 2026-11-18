program p
implicit none
character(65536),allocatable::x(:)
call fill(65536,x)
if(size(x)/=1.or.len(x)/=65536) error stop 1
print '(a)','ok'
contains
subroutine fill(n,a)
integer,intent(in)::n
character(len=n),allocatable,intent(out)::a(:)
integer::s
allocate(a(-7:248),stat=s)
if(s/=0.or.size(a)/=256.or.len(a)/=65536) error stop 2
deallocate(a)
allocate(a(257),stat=s)
if(s==0.or.allocated(a).or.len(a)/=65536) error stop 3
allocate(a(1),stat=s)
if(s/=0) error stop 4
end subroutine
end program
