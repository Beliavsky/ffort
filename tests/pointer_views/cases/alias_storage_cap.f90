program main
integer,target::a(131072)
integer,pointer::p(:),q(:)
p=>a
q=>p
p(131072)=9
if(a(131072)/=9.or.q(131072)/=9) error stop 1
print *,1
end
