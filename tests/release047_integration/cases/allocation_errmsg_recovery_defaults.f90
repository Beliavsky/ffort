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
integer,allocatable::a(:)
integer::s
character(8)::msg
msg='KEEP'
allocate(a(2),stat=s,errmsg=msg)
print '(l1,a,a,a)',s==0,'[',msg,']'
a=3
allocate(a(4),stat=s,errmsg=msg)
print '(l1,l1,3i3)',s/=0,msg/='KEEP',size(a),a(1),x%a
end program
