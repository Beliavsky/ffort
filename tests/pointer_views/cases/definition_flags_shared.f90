program main
implicit none
integer,target::a(2)
integer,pointer::p(:),q(:)
p=>a
q=>p
p(1)=7
a(2)=8
if(any(q/=[7,8])) error stop 1
print *,1
end program
