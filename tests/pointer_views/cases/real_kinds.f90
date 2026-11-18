program main
implicit none
real(4),target::a(2)
real(8),target::b(2)
real(4),pointer::p(:)
real(8),pointer::q(:)
a=[1.0,2.0]
b=[3.0_8,4.0_8]
p=>a
q=>b
p=p*2.0
q=q+0.5_8
if(any(a/=[2.0,4.0]).or.any(b/=[3.5_8,4.5_8])) error stop 1
print *,1
end program
