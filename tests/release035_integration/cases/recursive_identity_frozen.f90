module composition
implicit none
contains
recursive subroutine host(depth,answer)
integer,intent(in)::depth
integer,intent(out)::answer
integer::work(depth+1),marker
work=depth
marker=10*depth
call child()
contains
recursive subroutine child()
integer::below
below=0
if(depth>0)call host(depth-1,below)
call sibling()
answer=below+marker+sum(work)
end subroutine
subroutine sibling()
work=work+1
marker=marker+sum(work)
end subroutine
end subroutine
end module
program main
use composition
implicit none
integer::answer
call host(3,answer)
write(*,'("depth3:",1x,i0)')answer
call host(1,answer)
write(*,'("depth1:",1x,i0)')answer
call host(0,answer)
write(*,'("depth0:",1x,i0)')answer
end program
