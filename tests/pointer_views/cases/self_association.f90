program main
implicit none
integer,target::a(2)
integer,pointer::p(:)
a=[1,2]
p=>a
p=>p
p(2)=9
if(a(2)/=9) error stop 1
print *,1
end program
