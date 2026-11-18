program main
implicit none
integer,target::a(8),b(8)
integer,pointer::p(:),q(:)
nullify(p);q=>a
print *,associated(p,a),associated(p,q)
nullify(q)
print *,associated(p,q)
end program
