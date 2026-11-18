program integration_main
use,intrinsic::iso_fortran_env,only:ik=>int64
implicit none
integer(ik),target::a(2)
integer(ik),pointer::p(:)
write(*,'(a)')'before'
call escape(p)
write(*,'(l1)')associated(p,a)
contains
subroutine escape(p)
integer(ik),pointer,intent(out)::p(:)
integer(ik),target::local(2)
p=>local
end subroutine
end program
