! Synthetic release 0.32 composition fixture; no original utility body.
program main
implicit none
integer,target::a(3)
integer,pointer::p(:),q(:)
logical::have,linked
a=4
p=>a
call reset(p)
call probe(p,have,linked)
print *,have,linked
call probe(have=have,linked=linked)
print *,have,linked
q=>p
call reset()
print *,associated(q)
p=>a(2:1)
print *,associated(p),size(p),shape(p),findloc(p,4)
contains
subroutine reset(x)
integer,pointer,intent(inout),optional::x(:)
if(present(x)) nullify(x)
end subroutine
subroutine probe(x,have,linked)
integer,pointer,intent(in),optional::x(:)
logical,intent(out)::have,linked
have=present(x)
linked=.false.
if(present(x)) linked=associated(x)
end subroutine
end program
