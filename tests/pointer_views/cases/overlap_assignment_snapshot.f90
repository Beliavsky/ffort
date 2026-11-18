program main
implicit none
integer,target::a(5)
integer,pointer::p(:)
a=[1,2,3,4,5]
p=>a
p(2:5)=p(1:4)
if(any(a/=[1,1,2,3,4])) error stop 1
p(1:4)=a(2:5)
if(any(a/=[1,2,3,4,4])) error stop 2
print *,1
end program
