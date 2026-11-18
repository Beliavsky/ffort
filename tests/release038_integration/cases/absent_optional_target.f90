program integration_main
implicit none
integer,target::a(3)
integer,pointer::p(:)
p=>a
call probe(p)
write(*,'(a)')'ok'
contains
subroutine probe(p,t)
integer,pointer,intent(in)::p(:)
integer,target,optional,intent(in)::t(:)
if(.not.associated(p,t))error stop 1
end subroutine
end program
