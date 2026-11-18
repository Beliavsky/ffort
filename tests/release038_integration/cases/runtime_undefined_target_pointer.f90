program integration_main
implicit none
integer,target::a(3)
integer,pointer::p(:),q(:)
nullify(p)
write(*,'(a)')'before'
write(*,'(l1)')associated(p,q)
end program
