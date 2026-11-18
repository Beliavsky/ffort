program main
implicit none
integer,target::a(8),b(8)
integer,pointer::p(:),q(:)
p=>a;q=>p;q=>b
print *,associated(p,a),associated(p,q),associated(p,b)
nullify(q)
print *,associated(p,a),associated(p,q),associated(q,p),associated(q,q)
end program
