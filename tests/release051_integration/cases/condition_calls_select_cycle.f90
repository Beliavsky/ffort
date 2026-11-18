module observer
implicit none
integer::calls=0
contains
impure elemental logical function continue_loop(n)
integer,intent(in)::n
calls=calls+1
continue_loop=n<4
end function
end module
program main
use observer
implicit none
integer::n,s
n=0;s=0
outer: do while(continue_loop(n))
n=n+1
select case(n)
case(2);cycle outer
case default;s=s+n
end select
end do outer
print '(i0,1x,i0,1x,i0)',n,s,calls
end program
