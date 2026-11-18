! Synthetic release 0.32 composition fixture; no original utility body.
program main
implicit none
integer,target::a(3,2)
integer,pointer::p(:),q(:)
a=0
call outer(a,p,1)
q=>p
p=[1,2,3]
call outer(a,p,2)
p=q+10
call outer(a,p,1)
p(3)=7
print *,a,q,findloc(q,7),associated(p)
contains
subroutine outer(x,v,c)
integer,target,intent(inout)::x(:,:)
integer,pointer,intent(out)::v(:)
integer,intent(in)::c
call inner(x,v,c)
end subroutine
subroutine inner(x,v,c)
integer,target,intent(inout)::x(:,:)
integer,pointer,intent(out)::v(:)
integer,intent(in)::c
v=>x(:,c)
end subroutine
end program
