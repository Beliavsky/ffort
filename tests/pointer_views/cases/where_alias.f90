program main
implicit none
integer,target::a(4)
integer,pointer::p(:)
a=[1,2,3,4]
p=>a
where(p>2) p=-p
if(any(a/=[1,2,-3,-4])) error stop 1
print *,1
end program
