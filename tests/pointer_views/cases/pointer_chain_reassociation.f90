program main
implicit none
integer,target::a(3),b(2)
integer,pointer::p(:),q(:)
a=[1,2,3]
b=[4,5]
p=>a
q=>p
p=>b
q(2)=8
p(1)=9
if(a(2)/=8.or.b(1)/=9) error stop 1
nullify(p)
if(associated(p).or..not.associated(q)) error stop 2
q(1)=7
if(a(1)/=7) error stop 3
p=>a
q=>null()
p=>q
if(associated(q).or.associated(p)) error stop 4
print *,1
end program
