program main
implicit none
integer,target::a(8),b(8)
integer,pointer::p(:),q(:)
integer::i
p=>a;i=0
print *,associated(p,a(1:2:i))
end program
