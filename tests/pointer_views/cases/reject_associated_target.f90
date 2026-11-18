program main
implicit none
integer,target::a(2)
integer,pointer::p(:)
p=>a
if(associated(p,a)) stop
end program
