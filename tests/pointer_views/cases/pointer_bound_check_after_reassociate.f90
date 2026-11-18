program main
integer,target::a(-2:2),b(2)
integer,pointer::p(:)
a=1
b=2
p=>a
if(size(p)/=5.or.lbound(p,1)/=-2) error stop 1
p=>b
if(size(p)/=2.or.lbound(p,1)/=1) error stop 2
print *,1
end
