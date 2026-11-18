program main
implicit none
integer,target::a(6)
integer,pointer::p(:),q(:)
a=[1,2,3,4,5,6]
p=>a(6:1:-1)
q=>p(2:6:2)
q=[9,8,7]
if(any(a/=[7,2,8,4,9,6])) error stop 1
print *,1
end program
