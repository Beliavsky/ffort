module buffer_ops
implicit none
interface operator(+)
module procedure join
end interface
interface build
module procedure make_buffer
end interface
contains
function join(a,b) result(s)
character(*),intent(in)::a,b
character(:),allocatable::s
s=a//b
end function
function make_buffer(n,tail) result(s)
integer,intent(in)::n
character(*),intent(in),optional::tail
character(:),allocatable::s
character(8)::temp
write(temp,'(i0)') n
s=trim(temp)
if(present(tail)) s=s+tail
end function
subroutine forward(s)
character(:),allocatable,intent(out)::s
s=build(12)+',34'
end subroutine
end module
program main
use buffer_ops
implicit none
character(:),allocatable::s
integer::a,b,ios
call forward(s)
read(s,*,iostat=ios) a,b
if(ios/=0.or.a/=12.or.b/=34) error stop 1
s=build(9,tail=',8')
read(s,*,iostat=ios) a,b
if(ios/=0.or.a/=9.or.b/=8) error stop 2
write(*,'(a)') '['+s+']'
end program
