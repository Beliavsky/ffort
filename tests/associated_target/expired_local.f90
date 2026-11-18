program main
implicit none
integer,target::a(2)
integer,pointer::p(:)
call escape(p)
print *,associated(p,a)
contains
subroutine escape(p)
integer,pointer,intent(out)::p(:)
integer,target::local(2)
p=>local
end subroutine
end program
