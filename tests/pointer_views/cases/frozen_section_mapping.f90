program main
integer,target::a(6)
integer,pointer::p(:)
integer::lo,hi,k
a=[1,2,3,4,5,6]
lo=2
hi=6
k=2
p=>a(lo:hi:k)
lo=1
hi=3
k=1
p=[9,8,7]
if(any(a/=[1,9,3,8,5,7])) error stop 1
print *,1
end
