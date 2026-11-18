program main
implicit none
real(4),target::a(-3:4),b(8)
real(4),pointer::p(:),q(:)
p=>a
q=>a(:)
print *,associated(p,a),associated(p,q),associated(target=a,pointer=p),associated(pointer=p)
q=>b
print *,associated(p,q),associated(p,b)
end program
